unit form_adapter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, LMessages,
  StdCtrls, ButtonPanel, ExtCtrls, Messages, Windows;

type

  TButtonState = record
    pressed:boolean;
    DownWhen:longint;
  end;

  { TAdapterForm }

  TAdapterForm = class(TForm)
    Button_Clear: TButton;
    Button_MemoRec: TToggleBox;
    Memo1: TMemo;
    Splitter1: TSplitter;
    procedure Button_ClearClick(Sender: TObject);
    procedure Button_MemoRecChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure FormShow(Sender: TObject);
  protected
    procedure WndProc(var TheMessage:TLMessage); override;
  private
    Memo_Recorded:boolean; //是否记录
    Exec_Command:string;   //快捷键命令行临时储存字符串

    TButtonStates:array[1..255] of TButtonState;

  protected
    procedure CommandInitialize;       //命令行重置
    procedure CommandAppend(key:char); //命令行更新
    procedure CommandExecute;          //命令行执行

    procedure MessageBroadcast(TheMessage:TLMessage);

    procedure RecordAufScript(str:string);


  public
    procedure HookProc(var Msg:TMessage);//message WM_USER+100;

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
  Self.Memo_Recorded:=true;
  GlobalExpressionList.TryAddExp('sel',narg('',IntToStr(Self.Handle),''));
end;

procedure TAdapterForm.FormHide(Sender: TObject);
begin
  Self.Button_MemoRec.Checked:=false;
end;

procedure TAdapterForm.FormShow(Sender: TObject);
begin
  Self.Button_MemoRec.Checked:=true;
end;

procedure TAdapterForm.Button_ClearClick(Sender: TObject);
begin
  Self.Memo1.Clear;
end;

procedure TAdapterForm.Button_MemoRecChange(Sender: TObject);
begin
  if (Sender as TToggleBox).Checked then Self.Memo_Recorded:=true
  else Self.Memo_Recorded:=false;
end;

procedure TAdapterForm.WndProc(var TheMessage:TLMessage);//快捷键激活；同步器、脚本群发；录制器发送。
label inherit;
begin

  case TheMessage.msg of
    WM_USER+MessageOffset:;
    WM_CHAR,WM_SYSCHAR,WM_KEYDOWN,
    WM_KEYUP,WM_SYSKEYDOWN,WM_SYSKEYUP,
    WM_LButtonDown,WM_LButtonUp,WM_LButtonDblClk,
    WM_RButtonDown,WM_RButtonUp,WM_RButtonDblClk,
    WM_MButtonDown,WM_MButtonUp,WM_MButtonDblClk:
      begin
        Self.MessageBroadcast(TheMessage);
      end;
    else ;
  end;
  //消息处理完以后记录消息
  if not Self.Memo_Recorded then goto inherit;
  case TheMessage.msg of
    WM_USER+MessageOffset,WM_CHAR,WM_SYSCHAR,
    WM_KEYDOWN,WM_KEYUP,WM_SYSKEYDOWN,WM_SYSKEYUP,
    WM_LButtonDown,WM_LButtonUp,WM_LButtonDblClk,
    WM_RButtonDown,WM_RButtonUp,WM_RButtonDblClk,
    WM_MButtonDown,WM_MButtonUp,WM_MButtonDblClk:
      begin
        Self.Memo1.Append(IntToStr(TheMessage.msg)+#9+IntToStr(TheMessage.wParam)+#9+IntToStr(TheMessage.lParam));
      end;
    else goto inherit;
  end;

inherit:
  inherited WndProc(TheMessage);
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
  Self.Exec_Command:='';
end;
procedure TAdapterForm.CommandAppend(key:char);
begin
  Self.Exec_Command:=Self.Exec_Command+key;
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

procedure TAdapterForm.HookProc(var Msg:TMessage);
var x,y:integer;
    i,kx{35转0,37转1}:byte;
    NowTimeNumber,NowTmp:longint;

begin
  x := pMouseHookStruct(Msg.LParam)^.pt.X;
  y := pMouseHookStruct(Msg.LParam)^.pt.Y;


end;

end.

