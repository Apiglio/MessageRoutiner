//{$define HookAdapter}//主单元也有一个需要同步修改

unit form_adapter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, LMessages,
  StdCtrls, ExtCtrls, Windows, Dos;

const
  MessageOffset  = 100;

type

  TRecTimeMode = (rtmWaittimer=0,rtmSleep=1);
  TRecSyntaxMode = (smRapid=0,smChar=1,smMono=2);
  TButtonState = record
    pressed:boolean;
    DownWhen:longint;
  end;

  { TAdapterForm }

  TAdapterForm = class(TForm)
    Button_Clear: TButton;
    Button_MemoRec: TToggleBox;
    Memo_debug: TMemo;
    Splitter1: TSplitter;
    procedure Button_ClearClick(Sender: TObject);
    procedure Button_MemoRecChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure FormShow(Sender: TObject);

  private
    procedure DebugLine(str:string);

  protected
    procedure WndProc(var TheMessage:TLMessage);override;
    procedure HookProc(var TheMessage:TMessage);message WM_USER+MessageOffset;
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
        Exec_Command:string; //快捷键命令行临时储存字符串
      end;
    end;

  public
    Option:record
      Rec:record
        BKeybd,BMouse:boolean;//是否记录键盘或鼠标消息
        TimeMode:TRecTimeMode;
        SyntaxMode:TRecSyntaxMode;
      end;//录制器设置
      Sync:record end;//同步器与异步器设置
      Shortcut:record end;//键盘快捷键设置
    end;//所有设置
    property RecordMode:boolean read FRecordMode write FRecordMode default false;
    property SynchronicMode:boolean read FSynchronicMode write FSynchronicMode default false;
    property ShortcutMode:boolean read FShortcutMode write FShortcutMode default false;

  protected
    procedure CommandInitialize;       //键盘快捷键：命令行重置
    procedure CommandAppend(key:char); //键盘快捷键：命令行更新
    procedure CommandExecute;          //键盘快捷键：命令行执行

    procedure MessageBroadcast(TheMessage:TLMessage);//同步器、异步器、转发器：消息广播

    procedure RecordAufScript(str:string);//录制器：添加代码

    procedure SynchronicProc(Msg:TMessage);//同步器异步器过程
    procedure RecordProc(Msg:TMessage);//录制器过程
    procedure ShortcutProc(Msg:TMessage);//键盘快捷键过程
    procedure DuplicateProc(Msg:TMessage);//转发器过程


  end;

var
  AdapterForm: TAdapterForm;

implementation
uses MessageRoutiner_Unit, Apiglio_Useful;

{$R *.lfm}


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

procedure TAdapterForm.FormCreate(Sender: TObject);
begin
  Self.FRecordMode:=true;
  GlobalExpressionList.TryAddExp('sel',narg('',IntToStr(Self.Handle),''));
  {$ifdef HookAdapter}
  with Form_Routiner do
    begin
      KeybdHookEnabled:=false;
      MouseHookEnabled:=false;
      KeybdHook;
      //MouseHook;//初始不开鼠标钩子
  end;
  {$endif}
end;

procedure TAdapterForm.FormHide(Sender: TObject);
begin
  Self.Button_MemoRec.Checked:=false;
end;

procedure TAdapterForm.FormShow(Sender: TObject);
begin
  Self.Button_MemoRec.Checked:=true;
end;

procedure TAdapterForm.DebugLine(str:String);
begin
  RecordAufScript(str);
end;

procedure TAdapterForm.Button_ClearClick(Sender: TObject);
begin
  Self.Memo_debug.Clear;
end;

procedure TAdapterForm.Button_MemoRecChange(Sender: TObject);
begin
  if (Sender as TToggleBox).Checked then Self.FRecordMode:=true
  else Self.FRecordMode:=false;
end;

procedure TAdapterForm.WndProc(var TheMessage:TLMessage);//快捷键激活；同步器、脚本群发；录制器发送。
label inherit;
var Translated_Msg:TLMessage;
begin
  //Self.DebugLine('Msg='+IntToStr(TheMessage.msg)+' w='+IntToStr(TheMessage.wParam)+' l='+IntToStr(TheMessage.lParam));
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
  //Self.DebugLine('Msg='+IntToStr(Translated_Msg.msg)+' w='+IntToStr(Translated_Msg.wParam)+' l='+IntToStr(Translated_Msg.lParam));


  if Self.FSynchronicMode then SynchronicProc(Translated_Msg);//同步器
  if Self.FShortcutMode then ShortcutProc(Translated_Msg);//键盘快捷键
  if Self.FRecordMode then RecordProc(Translated_Msg);//录制器

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

procedure TAdapterForm.HookProc(var TheMessage:TMessage);
begin
  Self.DebugLine('Msg='+IntToStr(TheMessage.msg)+' w='+IntToStr(TheMessage.wParam)+' l='+IntToStr(TheMessage.lParam));
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
end;
procedure TAdapterForm.CommandExecute;
begin
  //结构未实现
end;

procedure TAdapterForm.RecordAufScript(str:string);
begin
  with Form_Routiner do
  AufScriptFrames[PageControl.ActivePageIndex].Frame.Memo_cmd.Lines.Append(str);
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
function GetTimeNumber:longint;
var h,m,s,ms:word;
begin
  gettime(h,m,s,ms);
  result:=ms*10+s*1000+m*60000+h*3600000;
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
        //录制模式下鼠标原点设置
        if (Self.Status.Rec.SettingOri)and(Msg.msg=WM_LButtonUp) then begin
          Self.Status.Rec.MouseOri.x:=Msg.wParam;
          Self.Status.Rec.MouseOri.y:=Msg.lParam;
          Self.Status.Rec.SettingOri:=false;
          Form_Routiner.Button_MouseOri.Enabled:=true;
          Form_Routiner.Button_MouseOri.Caption:='('+IntToStr(Msg.wParam)+','+IntToStr(Msg.lParam)+')';
        end;
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
end;
procedure TAdapterForm.ShortcutProc(Msg:TMessage);//快捷方式过程
begin

end;
procedure TAdapterForm.DuplicateProc(Msg:TMessage);//转发器过程
begin
  Self.MessageBroadcast(Msg);
end;

end.

