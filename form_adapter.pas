{$define HookAdapter}//主单元也有一个需要同步修改

unit form_adapter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, LMessages,
  StdCtrls, ExtCtrls, Windows, Dos;

const
  MessageOffset = 100;
  ShortcutCount = 31;

type

  TRecTimeMode = (rtmWaittimer=0,rtmSleep=1);
  TRecSyntaxMode = (smRapid=0,smChar=1,smMono=2);
  TShortcutMode = (scmDblCheck=0,scmDownUp=1,scmLoop=2,scmPoly=3);
  //DblCheck 双击+命令+确认      DownUp 按下+命令+抬起
  //Loop     GTA秘籍循环检测     Poly   多键按下
  TButtonState = record
    pressed:boolean;
    DownWhen:longint;
  end;

  { TAdapterForm }

  TAdapterForm = class(TForm)
    Image1: TImage;
    Label_auther: TLabel;
    Label_AD: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure FormShow(Sender: TObject);

  private
    procedure DebugLine(str:string);

  protected
    procedure WndProc(var TheMessage:TLMessage);override;
  private
    FRecordMode:boolean;     //是否记录
    FSynchronicMode:boolean; //是否同步
    FShortcutMode:boolean;   //是否启用键盘快捷键

    Status:record
      Rec:record
        SettingOri:boolean;//是否处在设置鼠标动作原点的状态
        MouseOri:record x,y:longint;end;//鼠标记录的坐标原点
        LastRecTime:longint;//录制过程中表示上一个记录时间，作差用来确定sleep的参数
        FirstRecTime:longint;//录制过程中表示第一个记录时间，作差用来确定waittimer的参数
        LastMessage:TMessage;
      end;
      Sync:record
        ButtonStates:array[1..255] of TButtonState;//异步器按键状态

      end;
      Shortcut:record
        Exec_Command:string;//快捷键命令行临时储存字符串
        KeyDown:array[0..255]of boolean;//每个键按是否按下的状态
        LastTime:array[0..255]of dword;//每一个按键上一次按下的时间
        LastKey:byte;//上一次按下的键
        ListenKey:boolean;//是否读取指令，Loop模式和Poly模式始终为true
      end;
    end;
  public
    Option:record
      Rec:record
        BKeybd,BMouse:boolean;//是否记录键盘或鼠标消息
        TimeMode:TRecTimeMode;
        SyntaxMode:TRecSyntaxMode;
      end;//录制器设置
      Sync:record

      end;//同步器与异步器设置
      Shortcut:record
        Mode:TShortcutMode;
        StartKey,EndKey:byte; //双击按键与确认按键，scmDblCheck时有效
        DoubleGap:word;       //双击最大毫秒限制，scmDblCheck时有效
        DownUpKey:byte;       //按下抬起检测按键，scmDownUp时有效

        ScriptFiles:array[0..ShortcutCount]of record
          command:string;//存入的时候需要转为小写！！！
          filename:string;
        end;
      end;//键盘快捷键设置
    end;
    property RecordMode:boolean read FRecordMode write FRecordMode;
    property SynchronicMode:boolean read FSynchronicMode write FSynchronicMode;
    property ShortcutMode:boolean read FShortcutMode write FShortcutMode;
    property SetMouseOriMode:boolean read Status.Rec.SettingOri write Status.Rec.SettingOri;

  public
    procedure StartRecord;                  //录制器：开始录制
    procedure EndRecord;                    //录制器：结束录制

  protected
    procedure CommandInitialize;            //键盘快捷键：命令行重置
    procedure CommandAppend(key:char);      //键盘快捷键：命令行更新
    procedure CommandExecute;               //键盘快捷键：命令行执行

    procedure MessageBroadcast(TheMessage:TLMessage);//同步器、异步器、转发器：消息广播

    procedure RecordAufScript(str:string);  //录制器：添加代码


    procedure SynchronicProc(Msg:TMessage); //同步器异步器过程
    procedure RecordProc(Msg:TMessage);     //录制器过程
    procedure ShortcutProc(Msg:TMessage);   //键盘快捷键过程
    procedure DuplicateProc(Msg:TMessage);  //转发器过程
    procedure MouseOriSetting(Msg:TMessage);//鼠标原点设置过程


  end;

var
  AdapterForm: TAdapterForm;

implementation
uses MessageRoutiner_Unit, Apiglio_Useful;

{$R *.lfm}

function StrToHex(inp:string):string;
var i:integer;
begin
  result:='';
  for i:=1 to length(inp) do
    begin
      result:=result+IntToHex(ord(inp[i]),2);
    end;
end;

function KeyMsgToChar(km:longint):string;
begin
  case km of
    WM_KEYDOWN,WM_SYSKEYDOWN:result:='"D"';
    WM_KEYUP,WM_SYSKEYUP:result:='"U"';
    else result:='""';
  end;
end;
function MouseMsgToChar(km:longint):string;
begin
  case km of
    WM_LButtonDown:result:='"LD"';
    WM_MButtonDown:result:='"MD"';
    WM_RButtonDown:result:='"RD"';
    WM_LButtonUp:result:='"LU"';
    WM_MButtonUp:result:='"MU"';
    WM_RButtonUp:result:='"RU"';
    WM_LButtonDblClk:result:='"LB"';
    WM_MButtonDblClk:result:='"MB"';
    WM_RButtonDblClk:result:='"RB"';
    else result:='""';
  end;
end;
function KeyToChar(km:byte):string;
begin
  case km of
    65..90,48..57:result:='"'+chr(km)+'"';
    112..123:result:='@k_f'+IntToStr(km-111);
    8:result:='@k_bksp';
    9:result:='@k_tab';
    12:result:='@k_clear';
    13:result:='@k_enter';
    16:result:='@k_shift';
    17:result:='@k_ctrl';
    18:result:='@k_alt';
    19:result:='@k_pause';
    20:result:='@k_capelk';
    27:result:='@k_esc';
    32:result:='@k_space';
    33:result:='@k_pgup';
    34:result:='@k_pgdn';
    35:result:='@k_end';
    36:result:='@k_home';
    37:result:='@k_left';
    38:result:='@k_up';
    39:result:='@k_right';
    40:result:='@k_down';
    41:result:='@k_sel';
    42:result:='@k_print';
    43:result:='@k_exec';
    44:result:='@k_snapshot';
    45:result:='@k_ins';
    46:result:='@k_del';
    47:result:='@k_help';
    91:result:='@k_lwin';
    92:result:='@k_rwin';
    144:result:='@k_numlk';
    160:result:='@k_lshift';
    161:result:='@k_rshift';
    162:result:='@k_lctrl';
    163:result:='@k_rctrl';
    164:result:='@k_lalt';
    165:result:='@k_ralt';
    else result:=IntToStr(km);
  end;
end;

function GetTimeNumber:longint;
var h,m,s,ms:word;
begin
  gettime(h,m,s,ms);
  result:=ms*10+s*1000+m*60000+h*3600000;
end;

procedure TAdapterForm.FormCreate(Sender: TObject);
begin
  Self.FRecordMode:=true;
  GlobalExpressionList.TryAddExp('sel',narg('',IntToStr(Self.Handle),''));
  Self.FRecordMode:=false;
  Self.FSynchronicMode:=false;
  Self.FShortcutMode:=true;
  with Self.Option do
    begin
      Rec.SyntaxMode:=smRapid;
      Rec.TimeMode:=rtmSleep;
    end;
  {$ifdef HookAdapter}
  with Form_Routiner do
    begin
      KeybdHookEnabled:=false;
      MouseHookEnabled:=false;
      KeybdHook;
      //MouseHook;//初始不开鼠标钩子
  end;
  {$endif}
  Self.ShortcutMode:=true;
  with Self.Option.Shortcut do
    begin
      //Mode:=scmDblCheck;
      Mode:=scmDownUp;
      StartKey:=32;
      EndKey:=13;
      DoubleGap:=300;
      DownUpKey:=45;//Insert

    end;

end;

procedure TAdapterForm.FormHide(Sender: TObject);
begin

end;

procedure TAdapterForm.FormShow(Sender: TObject);
begin

end;

procedure TAdapterForm.DebugLine(str:String);
begin
  RecordAufScript(str);
end;

procedure TAdapterForm.WndProc(var TheMessage:TLMessage);//快捷键激活；同步器、脚本群发；录制器发送。
label inherit;
var Translated_Msg:TLMessage;
begin
  if TheMessage.msg=WM_USER+MessageOffset then
    begin
      Translated_Msg.msg:=TheMessage.wParam;
      Translated_Msg.wParam:=pMouseHookStruct(TheMessage.LParam)^.pt.X;
      Translated_Msg.lParam:=pMouseHookStruct(TheMessage.LParam)^.pt.Y;
    end
  else begin
    DuplicateProc(TheMessage);//转发器
    goto inherit;
  end;

  if (Self.FSynchronicMode) and (not Self.Status.Shortcut.ListenKey) then
    SynchronicProc(Translated_Msg);//同步器

  if Self.FShortcutMode then
    ShortcutProc(Translated_Msg);//键盘快捷键

  if (Self.Status.Rec.SettingOri)and(Translated_Msg.msg=WM_LButtonUp) then
    Self.MouseOriSetting(Translated_Msg);//鼠标录制原点设置

  if Self.FRecordMode then
    RecordProc(Translated_Msg);//录制器


inherit:
  case TheMessage.msg of
    WM_USER+MessageOffset,WM_CHAR,WM_SYSCHAR,
    WM_KEYDOWN,WM_KEYUP,WM_SYSKEYDOWN,WM_SYSKEYUP,
    WM_LButtonDown,WM_LButtonUp,WM_LButtonDblClk,
    WM_RButtonDown,WM_RButtonUp,WM_RButtonDblClk,
    WM_MButtonDown,WM_MButtonUp,WM_MButtonDblClk:;
  else
    inherited WndProc(TheMessage);
  end;
end;

procedure TAdapterForm.MessageBroadcast(TheMessage:TLMessage);
var pi:byte;
begin
  for pi:=0 to SynCount do
    begin
      if Form_Routiner.CheckBoxs[pi].Checked then
        begin
          PostMessage(Form_Routiner.Buttons[pi].sel_hwnd,TheMessage.msg,TheMessage.wParam,TheMessage.lParam);
        end;
    end;

end;

procedure TAdapterForm.CommandInitialize;
begin
  Self.Status.Shortcut.Exec_Command:='';
end;
procedure TAdapterForm.CommandAppend(key:char);
begin
  Self.Status.Shortcut.Exec_Command:=Self.Status.Shortcut.Exec_Command+key;
  //Form_Routiner.StatusBar.Panels.Items[0].Text:=Self.Status.Shortcut.Exec_Command;
end;
procedure TAdapterForm.CommandExecute;
var str:string;
    num:word;
    pi:integer;
begin
  if Self.Status.Shortcut.Exec_Command='' then exit;
  str:=lowercase(Self.Status.Shortcut.Exec_Command);



  case str of
    #$C0:Form_Routiner.Button_Wnd_SynthesisClick(Form_Routiner.Button_Wnd_Synthesis);
    '1','2','3','4','5','6','7','8','9','0':
      begin
        pi:=(ord(str[1])-ord('0')+9) mod 10;
        RecordAufScript('|'+IntToStr(pi)+'|');
        if pi<=SynCount then Form_Routiner.CheckBoxs[pi].Checked:=not Form_Routiner.CheckBoxs[pi].Checked;
      end;
    //异步器暂时停用，快捷键无效
    '=1','=2','=3','=4','=5','=6','=7','=8','=9','=0':;
    '-1','-2','-3','-4','-5','-6','-7','-8','-9','-0':;
    else
      begin
        //RecordAufScript('|'+StrToHex(Self.Status.Shortcut.Exec_Command)+'|');
        pi:=0;
        for pi:=0 to ShortcutCount do
          begin
            if (str=Self.Option.Shortcut.ScriptFiles[pi].command) then
              begin
                Form_Routiner.SCAufs[pi].Script.command('load "'+Self.Option.Shortcut.ScriptFiles[pi].filename+'"');
              end;
          end;
      end;
  end;
  //RecordAufScript(Self.Status.Shortcut.Exec_Command);
end;

procedure TAdapterForm.RecordAufScript(str:string);
begin
  with Form_Routiner do
  AufScriptFrames[PageControl.ActivePageIndex].Frame.Memo_cmd.Lines.Append(str);
end;
procedure TAdapterForm.StartRecord;
begin
  Self.FRecordMode:=true;
  Self.Status.Rec.LastRecTime:=GetTimeNumber;
  Self.Status.Rec.FirstRecTime:=GetTimeNumber;
  if Self.Option.Rec.TimeMode=rtmWaittimer then RecordAufScript('settimer');
end;
procedure TAdapterForm.EndRecord;
begin
  Self.FRecordMode:=false;
end;

procedure TAdapterForm.SynchronicProc(Msg:TMessage);//同步器过程（包括异步器）
begin
  case Msg.msg of
    WM_CHAR,WM_SYSCHAR,WM_KEYDOWN,
    WM_KEYUP,WM_SYSKEYDOWN,WM_SYSKEYUP,
    WM_LButtonDown,WM_LButtonUp,WM_LButtonDblClk,
    WM_RButtonDown,WM_RButtonUp,WM_RButtonDblClk,
    WM_MButtonDown,WM_MButtonUp,WM_MButtonDblClk:
      begin
        Self.MessageBroadcast(Msg);
      end;
    else ;
  end;
end;

procedure TAdapterForm.RecordProc(Msg:TMessage);//录制器过程
var NowTimeNumber,NowTmp:longint;
begin
  CASE Msg.msg OF
    WM_CHAR,WM_SYSCHAR:;
    WM_KEYDOWN,WM_KEYUP,WM_SYSKEYDOWN,WM_SYSKEYUP:
      BEGIN
        if not Self.Option.Rec.BKeybd then exit;//没有选择键盘消息录制则退出
        if (Self.Status.Rec.LastMessage.msg=Msg.msg) and (Self.Status.Rec.LastMessage.wParam=Msg.wParam) then exit;//重复消息则退出
        NowTimeNumber:=GetTimeNumber;
        if NowTimeNumber<Self.Status.Rec.LastRecTime then inc(NowTimeNumber,86400000);//跨子夜时间处理
        case Self.Option.Rec.TimeMode of
          rtmSleep:    RecordAufScript('sleep '+IntToStr(NowTimeNumber-Self.Status.Rec.LastRecTime));
          rtmWaittimer:RecordAufScript('waittimer '+IntToStr(NowTimeNumber-Self.Status.Rec.FirstRecTime));
        end;
        case Self.Option.Rec.SyntaxMode of
          smChar:      RecordAufScript('keybd @win,'+KeyMsgToChar(Msg.msg)+','+KeyToChar(Msg.wParam));
          smRapid:     RecordAufScript('post @win,'+IntToStr(Msg.msg)+','+IntToStr(Msg.wParam)+','+IntToStr((Msg.wParam shl 16) + 1));
          smMono:;
        end;
        Self.Status.Rec.LastRecTime:=NowTimeNumber;
      END;
    WM_LButtonDown,WM_LButtonUp,WM_LButtonDblClk,
    WM_RButtonDown,WM_RButtonUp,WM_RButtonDblClk,
    WM_MButtonDown,WM_MButtonUp,WM_MButtonDblClk:
      BEGIN
        //录制
        if not Self.Option.Rec.BMouse then exit;//没有选择鼠标消息录制则退出
        NowTimeNumber:=GetTimeNumber;
        if NowTimeNumber<Self.Status.Rec.LastRecTime then inc(NowTimeNumber,86400000);//跨子夜时间处理
        case Self.Option.Rec.TimeMode of
          rtmSleep:
            RecordAufScript('sleep '+IntToStr(NowTimeNumber-Self.Status.Rec.LastRecTime));
          rtmWaittimer:
            RecordAufScript('waittimer '+IntToStr(NowTimeNumber-Self.Status.Rec.FirstRecTime));
        end;
        CASE Self.Option.Rec.SyntaxMode OF
          smChar:
            RecordAufScript('mouse @win,'+MouseMsgToChar(Msg.msg)+','
              +IntToStr(Msg.wParam-Self.Status.Rec.MouseOri.x)+','
              +IntToStr(Msg.lParam-Self.Status.Rec.MouseOri.y));
          smRapid:
            RecordAufScript('post @win,'+IntToStr(Msg.msg)+',0,'
              +IntToStr((word(Msg.lParam-Self.Status.Rec.MouseOri.y) shl 16)
              +dword(Msg.wParam-Self.Status.Rec.MouseOri.x)));
        END;
        Self.Status.Rec.LastRecTime:=NowTimeNumber;
      END;
    ELSE ;
  END;
  Self.Status.Rec.LastMessage:=Msg;
end;
procedure TAdapterForm.ShortcutProc(Msg:TMessage);//快捷方式过程
var key:byte;
    time:longint;
begin
  key:=Msg.wParam mod 256;
  time:=GetTimeNumber;

  case Msg.msg of
    WM_KEYDOWN,WM_SYSKEYDOWN:
      begin
        Self.Status.Shortcut.KeyDown[key]:=true;
        case Self.Option.Shortcut.Mode of
          scmDblCheck:
            begin
              if Self.Status.Shortcut.ListenKey and (Self.Option.Shortcut.EndKey=key) then
                begin
                  Self.Status.Shortcut.ListenKey:=false;
                  Self.CommandExecute;
                end;
              if (key=Self.Status.Shortcut.LastKey) and (key=Self.Option.Shortcut.StartKey) and
              (Self.Option.Shortcut.DoubleGap>dword(time-Self.Status.Shortcut.LastTime[key])) then
                begin
                  Self.CommandInitialize;
                  Self.Status.Shortcut.ListenKey:=true;
                end;
            end;
          scmDownUp:
          begin
            if key=Self.Option.Shortcut.DownUpKey then
              begin
                Form_Routiner.KeybdBlockOn;
                Self.CommandInitialize;
                Self.Status.Shortcut.ListenKey:=true;
              end;
          end;
          scmLoop:;
          scmPoly:;
        end;
        Self.Status.Shortcut.LastKey:=key;
      end;
    WM_KEYUP,WM_SYSKEYUP:
      begin
        Self.Status.Shortcut.KeyDown[key]:=false;
        case Self.Option.Shortcut.Mode of
          scmDblCheck:
            begin
              if Self.Status.Shortcut.ListenKey then Self.CommandAppend(char(key));
            end;
          scmDownUp:
            begin
              if Self.Status.Shortcut.ListenKey and (Self.Option.Shortcut.DownUpKey=key) then
                begin
                  Self.Status.Shortcut.ListenKey:=false;
                  Self.CommandExecute;
                  Form_Routiner.KeybdBlockOff;
                end;
              if Self.Status.Shortcut.ListenKey then Self.CommandAppend(char(key));
            end;
          scmLoop:;
          scmPoly:;
        end;
        Self.Status.Shortcut.LastTime[key]:=time;
      end
    else ;
  end;

end;
procedure TAdapterForm.DuplicateProc(Msg:TMessage);//转发器过程
begin
  case Msg.msg of
    WM_CHAR,WM_SYSCHAR,WM_KEYDOWN,
    WM_KEYUP,WM_SYSKEYDOWN,WM_SYSKEYUP,
    WM_LButtonDown,WM_LButtonUp,WM_LButtonDblClk,
    WM_RButtonDown,WM_RButtonUp,WM_RButtonDblClk,
    WM_MButtonDown,WM_MButtonUp,WM_MButtonDblClk:
      begin
        Self.MessageBroadcast(Msg);
      end;
    else ;
  end;
end;
procedure TAdapterForm.MouseOriSetting(Msg:TMessage);//鼠标原点设置过程
begin
  Self.Status.Rec.MouseOri.x:=Msg.wParam;
  Self.Status.Rec.MouseOri.y:=Msg.lParam;
  Self.Status.Rec.SettingOri:=false;
  Form_Routiner.Button_MouseOri.Enabled:=true;
  Form_Routiner.Button_MouseOri.Caption:='('+IntToStr(Msg.wParam)+','+IntToStr(Msg.lParam)+')';
end;

end.

