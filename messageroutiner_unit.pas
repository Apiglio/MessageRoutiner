//{$define insert}

unit MessageRoutiner_Unit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Messages,
  Windows, StdCtrls, ComCtrls, ExtCtrls, Menus, Buttons, CheckLst, Dos,
  LazUTF8{$ifndef insert}, Apiglio_Useful, aufscript_frame{$endif};

const

  version_number='0.1.4';

  RuleCount    = 9;{不能大于31，否则设置保存会出问题}
  SynCount     = 4;{不能大于9，也不推荐9}
  ButtonColumn = 9;{不能大于31，否则设置保存会出问题}

  gap=5;
  sp_thick=6;
  WindowsListW=300;
  //ARVControlH=170;
  ARVControlW=150;
  SynchronicH=28;
  SynchronicW=36;
  MainMenuH=24;
  MinAufButtonW=450;


type

  TLayoutSet = (Lay_Command=0,Lay_Advanced=1,Lay_Synchronic=2,Lay_Buttons=3,Lay_Recorder=4,Lay_Customer=5);
  TRecTimeMode = (rtmWaittimer=0,rtmSleep=1);

  { TWindow }
  TWindow = class(TObject)
  public
    info:record
      hd:HWND;
      name:utf8string;
      Left,Top,Height,Width:word;
    end;
    child:TList;
    parent:TWindow;
    node:TObject;
    constructor Create(_hd:HWND;_name:utf8string;_Left,_Top,_Width,_Height:word);
  end;


  { TARVButton & TARVEdit }

  TARVButton = class(TButton)
    published
      Edit:TEdit;
      procedure ButtonClick(Sender:TObject);
      constructor Create(AOwner:TComponent);
    public
      sel_hwnd:hwnd;
      expression:string;
      WindowIndex:byte;
  end;
  TARVEdit = class(TEdit)
    published
      Button:TButton;
      procedure EditOnChange(Sender:TObject);
      constructor Create(AOwner:TComponent);
  end;
  TARVCheckBox = class(TCheckBox)
    public
      procedure CheckOnChange(Sender:TObject);
  end;

  THoldButton = class(TButton)
  public
    keymessage:array[0..3]of byte;
  private
    procedure HoldMouseDown(Sender: TObject;Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure HoldMouseUp(Sender: TObject;Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  public
    constructor Create(AOwner:TComponent);
  end;

  TTimerLag = class(TTimer)
  public
    next_message:record
      hwnd,msg,wparam,lparam:longint;
    end;
    waiting:boolean;
    constructor Create(AOwner:TComponent);
    procedure NextMessage(delay,hwnd,msg,wparam,lparam:dword);
    procedure OnSend(Sender:TObject);
  end;

  TAufScriptFrame = class(TComponent)
  public
     Frame:TFrame_AufScript;
  end;

  TWinAuf = class(TAuf)
  public
    WindowIndex:byte;
  end;

  TAufButton = class(TButton)
    constructor Create(AOwner:TComponent;AWinAuf:TWinAuf);
    procedure ButtonLeftUp;
    procedure ButtonRightUp;
    procedure ButtonMouseUp(Sender: TObject; Button: TMouseButton;
                          Shift: TShiftState; X, Y: Integer);
    procedure AufRun;
    procedure AufPause;
    procedure AufResume;
    procedure AufStop;
    procedure RenewCmd;

  public
    Auf:TWinAuf;//只存指针，不新建Auf
    cmd:TStrings;
    WindowIndex:byte;
    ColumnIndex:byte;
    ScriptFile:string;
    WindowChangeable:boolean;
  end;

  { TForm_Routiner }

  TForm_Routiner = class(TForm)
    Button_MouseOri: TButton;
    Button_excel: TButton;
    Button_TreeViewFresh: TButton;
    Button_Wnd_Record: TButton;
    Button_advanced: TButton;
    Button_Wnd_Synthesis: TButton;
    CheckGroup_KeyMouse: TCheckGroup;
    Edit_TimerOffset: TEdit;
    Edit_TreeView: TEdit;
    GroupBox_OffsetSetting: TGroupBox;
    GroupBox_RecOption: TScrollBox;
    Label_MouseOri: TLabel;
    Label_filter: TLabel;
    Label_TimerOffset: TLabel;
    Label_TimerOffset_Unit: TLabel;
    MainMenu: TMainMenu;
    Memo_TmpRec: TMemo;
    Memo_Tmp: TMemo;
    MenuItem_Lay_SaveOption: TMenuItem;
    MenuItem_Lay_Div: TMenuItem;
    MenuItem_Lay_Customer: TMenuItem;
    MenuItem_Lay_Customer_Apply: TMenuItem;
    MenuItem_Lay_Customer_Save: TMenuItem;
    RadioGroup_DelayMode: TRadioGroup;
    ScrollBox_Synchronic: TScrollBox;
    ScrollBox_WndView: TScrollBox;
    ScrollBox_AufButton: TScrollBox;
    ScrollBox_HoldButton: TScrollBox;
    ScrollBox_WndList: TScrollBox;
    Splitter_SyncV: TSplitter;
    Splitter_LeftH: TSplitter;
    Splitter_ButtonV: TSplitter;
    Splitter_RightH: TSplitter;
    Splitter_RecH: TSplitter;
    Splitter_RightV: TSplitter;
    Splitter_MainV: TSplitter;
    Splitter_LeftV: TSplitter;
    WindowPosPad: TShape;
    MenuItem_Exit: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem_Func_Basic: TMenuItem;
    MenuItem_RunPerformance: TMenuItem;
    MenuItem_Func_Rec: TMenuItem;
    MenuItem_Func_Buttons: TMenuItem;
    MenuItem_Func_Diff: TMenuItem;
    MenuItem_Lay_Record: TMenuItem;
    MenuItem_Lay_Buttons: TMenuItem;
    MenuItem_Lay_SynChronic: TMenuItem;
    MenuItem_Setting_Lag: TMenuItem;
    MenuItem_Function: TMenuItem;
    MenuItem_Opt_licence: TMenuItem;
    MenuItem_Opt_About: TMenuItem;
    MenuItem_Layout: TMenuItem;
    MenuItem_Option: TMenuItem;
    MenuItem_Func_Auf: TMenuItem;
    MenuItem_Func_Key: TMenuItem;
    MenuItem_Func_Syn: TMenuItem;
    MenuItem_Lay_simple: TMenuItem;
    MenuItem_Lay_advanced: TMenuItem;
    MenuItem_Opt_setting: TMenuItem;
    PageControl: TPageControl;
    RadioGroup_RecSyntaxMode: TRadioGroup;
    TreeView_Wnd: TTreeView;
    WindowPosPadWind: TShape;

    procedure Button_advancedClick(Sender: TObject);
    procedure Button_excelClick(Sender: TObject);
    procedure Button_excelMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Button_MouseOriKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Button_MouseOriMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure CheckGroup_KeyMouseItemClick(Sender: TObject; Index: integer);
    procedure RadioGroup_DelayModeClick(Sender: TObject);
    procedure TreeViewEditOnChange(Sender:TObject);
    procedure Button_TreeViewFreshClick(Sender: TObject);
    procedure Button_Wnd_RecordClick(Sender: TObject);
    procedure Button_Wnd_SynthesisClick(Sender: TObject);
    procedure Edit_TreeViewChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure GroupBox_RecOptionResize(Sender: TObject);
    procedure Memo_TmpKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Memo_TmpRecKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure MenuItem_ExitClick(Sender: TObject);
    procedure MenuItem_Func_AufClick(Sender: TObject);
    procedure MenuItem_Func_BasicClick(Sender: TObject);
    procedure MenuItem_Func_ButtonsClick(Sender: TObject);
    procedure MenuItem_Func_DiffClick(Sender: TObject);
    procedure MenuItem_Func_KeyClick(Sender: TObject);
    procedure MenuItem_Func_RecClick(Sender: TObject);
    procedure MenuItem_Func_SynClick(Sender: TObject);
    procedure MenuItem_Lay_advancedClick(Sender: TObject);
    procedure MenuItem_Lay_ButtonsClick(Sender: TObject);
    procedure MenuItem_Lay_Customer_ApplyClick(Sender: TObject);
    procedure MenuItem_Lay_Customer_SaveClick(Sender: TObject);
    procedure MenuItem_Lay_RecordClick(Sender: TObject);
    procedure MenuItem_Lay_SaveOptionClick(Sender: TObject);
    procedure MenuItem_Lay_simpleClick(Sender: TObject);
    procedure MenuItem_Lay_SynChronicClick(Sender: TObject);
    procedure MenuItem_Opt_AboutClick(Sender: TObject);
    procedure MenuItem_Opt_licenceClick(Sender: TObject);
    procedure MenuItem_RunPerformanceClick(Sender: TObject);
    procedure MenuItem_Setting_LagClick(Sender: TObject);
    procedure PageControlChange(Sender: TObject);
    procedure PageControlResize(Sender: TObject);
    procedure RadioGroup_RecHookModeSelectionChanged(Sender: TObject);
    procedure RadioGroup_RecSyntaxModeSelectionChanged(Sender: TObject);
    procedure ScrollBox_AufButtonResize(Sender: TObject);
    procedure ScrollBox_HoldButtonResize(Sender: TObject);
    procedure ScrollBox_SynchronicResize(Sender: TObject);
    procedure ScrollBox_WndListResize(Sender: TObject);
    procedure ScrollBox_WndViewResize(Sender: TObject);
    procedure TreeView_WndChange(Sender: TObject; Node: TTreeNode);
    procedure WindowPosPadViceChange(Sender: TObject);

  private
    Tim:TTimer;//因为不知道怎么处理汉字输入法造成连续的OnChange事件，迫不得已采用延时50ms检测连续输入的办法。
  public
    Layout:record
      LayoutCode:TLayoutSet;//布局类型
      customer_layout:record
        MainV,SyncV,ButtV,LeftH,RightH,RecH,Width,Height:longint;
      end;
    end;
    Setting:record
      AufButtonAct1:TShiftState;
      AufButtonAct2:TMouseButton;
      AufButtonSetting1:TShiftState;
      AufButtonSetting2:TMouseButton;
      AufButtonHalt1:TShiftState;
      AufButtonHalt2:TMouseButton;
      HoldButtonSetting1:TShiftState;
      HoldButtonSetting2:TMouseButton;
    end;
  public
    WinAuf:array[0..SynCount]of TWinAuf;//每个窗口的专用Auf
    AufButtons:array[0..SynCount,0..ButtonColumn]of TAufButton;//面板按键
    HoldButtons:array[0..31]of THoldButton;//鼠标代键
    Edits:array[0..SynCount]of TARVEdit;
    Buttons:array[0..SynCount]of TARVButton;
    CheckBoxs:array[0..SynCount]of TARVCheckBox;
    AufScriptFrames:array[0..RuleCount] of TAufScriptFrame;

  public //同步器、异步器
    Synthesis_mode:boolean;//为真时向所有选中的TARVButton.sel_hwnd窗体广播
    Key_State:record
      ctrl,alt,shift,win:boolean;
      NumKey:array[0..SynCount]of boolean;//数字键按下状态
      Number:array[0..SynCount]of boolean;//是否抬起，用于放置一次按下触发多次事件
      Gross:boolean;//总闸是否抬起，用于放置一次按下触发多次事件
    end;
    SynSetting:array[0..SynCount]of record
      mode_lag:boolean;//是否延时抬起
      adjusting_lag:integer;//按下时长与延长抬起时间的比例(%)
      adjusting_step:integer;//一次快捷调整的幅度(%)
      keypress_time:array[0..1]of longint;//按下时的时间(0-left 1-right)
    end;
    KeyLag:array[0..SynCount,0..1]of TTimerLag;

  public //录制器
    Record_Mode:boolean;//为真时向当前标签页记录消息
    RecKey,RecMouse:boolean;//是否记录键盘或鼠标消息
    RecTimeMode:TRecTimeMode;
    SettingOri:boolean;//是否处在设置鼠标动作原点的状态
    MouseOri:record x,y:longint;end;//鼠标记录的坐标原点
    LastRecTime:longint;//录制过程中表示上一个记录时间，作差用来确定sleep的参数
    FirstRecTime:longint;//录制过程中表示第一个记录时间，作差用来确定waittimer的参数
    LastMessage:TMessage;
    TimeOffset:longint;//rtmWaittimer模式的初始时间

  public
    procedure SaveOption;
    procedure LoadOption;
  public
    KeybdHookEnabled,MouseHookEnabled:boolean;
    procedure GetMessageUpdate(var Msg:TMessage);message WM_USER+100;
    procedure MouseHook;
    procedure MouseUnHook;
    procedure KeybdHook;
    procedure KeybdUnHook;
  public
    procedure CurrentAufStrAdd(str:string);inline;
    procedure WindowsFilter;
    procedure SetLayout(layoutcode:byte);
    procedure ReDrawWndPos;
  end;

var
  Form_Routiner: TForm_Routiner;
  WndRoot:TWindow;
  Desktop:record
    Width,Height:longint;
  end;

implementation
uses form_settinglag, form_aufbutton, form_manual, form_runperformance, unit_holdbuttonsetting;

{$R *.lfm}

function StartHookK(MsgID:Word):Bool;stdcall;external 'DesktopCommander_keyboard_dll.dll' name 'StartHook';
function StopHookK:Bool;stdcall;external 'DesktopCommander_keyboard_dll.dll' name 'StopHook';
procedure SetCallHandleK(sender:HWND);stdcall;external 'DesktopCommander_keyboard_dll.dll' name 'SetCallHandle';

function StartHookM(MsgID:Word):Bool;stdcall;external 'DesktopCommander_mouse_dll.dll' name 'StartHook';
function StopHookM:Bool;stdcall;external 'DesktopCommander_mouse_dll.dll' name 'StopHook';
procedure SetCallHandleM(sender:HWND);stdcall;external 'DesktopCommander_mouse_dll.dll' name 'SetCallHandle';
procedure SetTrackMouseMoveM(onoff:byte);stdcall;external 'DesktopCommander_mouse_dll.dll' name 'SetTrackMouseMove';


procedure qk(str:string);deprecated;
begin
  Form_Routiner.AufScriptFrames[Form_Routiner.PageControl.ActivePageIndex].Frame.Auf.Script.writeln(str);
end;
procedure qkm(str:string);deprecated;
begin
  MessageBox(0,PChar(str),'Error',MB_OK);
end;

function GetTimeNumber:longint;
var h,m,s,ms:word;
begin
  gettime(h,m,s,ms);
  result:=ms*10+s*1000+m*60000+h*3600000;
end;
function GetTimeStr:string;
var h,m,s,ms:word;
begin
  gettime(h,m,s,ms);
  result:=Usf.zeroplus(h,2)+':'+Usf.zeroplus(m,2)+':'+Usf.zeroplus(s,2)+'.'+Usf.zeroplus(ms,2);
end;

procedure MouseActByteToMouseActSetting(MouseActByte:byte;var shift:TShiftState;var button:TMouseButton);
var butt:byte;
begin
  butt:=(not MouseActByte) and $07;
  if butt=7 then raise Exception.Create('Invalid MouseActByte');
  button:=TMouseButton(butt);
  shift:=[];
  if MouseActByte and $80 <> 0 then shift:=shift+[ssCtrl];
  if MouseActByte and $40 <> 0 then shift:=shift+[ssShift];
  if MouseActByte and $20 <> 0 then shift:=shift+[ssAlt];
end;
function MouseActSettingToMouseActByte(shift:TShiftState;button:TMouseButton):byte;
begin
  result:=(not byte(button)) and $07;
  if ssCtrl  in shift then result:=result or $80;
  if ssShift in shift then result:=result or $40;
  if ssAlt   in shift then result:=result or $20;
end;

procedure process_sleep(n:longint);
var t0,t1,t2:longint;
begin
  t0:=GetTimeNumber;
  t2:=t0+n;
  repeat
    t1:=GetTimeNumber;
    if t1<t0 then inc(t1,86400000);
    Application.ProcessMessages;
  until t1>=t2;
end;

procedure _gettime(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  AufScpt.IO_fptr.echo(AAuf.Owner,'TimeStr='+GetTimeStr);
  AufScpt.IO_fptr.echo(AAuf.Owner,'TimeNum='+IntToStr(GetTimeNumber));
end;
procedure _resize(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    w,h:word;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  w:=round(AufScpt.to_double(AAuf.nargs[1].pre,AAuf.nargs[1].arg));
  h:=round(AufScpt.to_double(AAuf.nargs[1].pre,AAuf.nargs[2].arg));
  Form_Routiner.Width:=w;
  Form_Routiner.Height:=h;
end;

procedure WinAufEnding(Sender:TObject);
var i,j:byte;
begin
  i:=((Sender as TAufScript).Auf as TWinAuf).WindowIndex;
  for j:=0 to ButtonColumn do
    begin
      Form_Routiner.AufButtons[i,j].Enabled:=true;
      Form_Routiner.AufButtons[i,j].Font.Bold:=false;
    end;
end;

procedure WinAufStr(Sender:TObject;str:string);
var tmp:byte;
begin
  if str='' then exit;
  if (Sender as TAufScript).PSW.haltoff then exit;
  tmp:=MessageBox(0,PChar(utf8towincp('是否继续执行？')+#13+#10+utf8towincp('错误信息：'+str)),'WinAuf',MB_RETRYCANCEL);
  if tmp=IDCANCEL then (Sender as TAufScript).Stop;
end;

procedure ClearWindows(wnd:TWindow);
var i:integer;

begin
  if not assigned(wnd) then exit;
  //renew_writeln('deleting '+wnd.info.name);
  Application.ProcessMessages;
  while wnd.child.count <> 0 do
    begin
      ClearWindows(TWindow(wnd.child.Extract(wnd.child.first)));
    end;
  wnd.child.free;
  wnd.free;
end;

procedure GetChildWindows(wnd:TWindow;filter:string='');
var hd:HWND;
    info:tagWindowInfo;
    w,h:word;
    title:string;
    ttmp:{PChar}array[0..199]of char;
    new_wnd:TWindow;
begin
  hd:=GetWindow(wnd.info.hd,GW_CHILD);
  while hd<>0 do
    begin
      //getmem(ttmp,200);
      GetWindowText(hd,ttmp,200);
      title:=ttmp;
      ////freemem(ttmp);
      title:=Usf.ExPChar(wincptoutf8(title));
      GetWindowInfo(hd,info);
      w:=info.rcWindow.Right-info.rcWindow.Left;
      h:=info.rcWindow.Bottom-info.rcWindow.Top;
      new_wnd:=TWindow.Create(hd,title,info.rcWindow.Left,info.rcWindow.Top,w,h);
      new_wnd.parent:=Wnd;
      wnd.child.add(new_wnd);

      IF (filter='') or (pos(lowercase(filter),lowercase(title))>0) THEN BEGIN
        if (new_wnd.parent.node)=nil then begin
          Form_Routiner.TreeView_Wnd.Items.add(
            nil,
            '['+IntToHex(hd,8)+']'+title)
        end else begin
          Form_Routiner.TreeView_Wnd.Items.addchild(
            (new_wnd.parent.node) as TTreeNode,
            '['+IntToHex(hd,8)+']'+title);
        end;
        new_wnd.node:=Form_Routiner.TreeView_Wnd.Items[Form_Routiner.TreeView_Wnd.Items.count-1];
        (new_wnd.node as TTreeNode).data:=new_wnd;
        GetChildWindows(new_wnd);
      END;

      hd:=GetNextWindow(hd,GW_HWNDNEXT);

    end;
end;


procedure WndFinder(filter:string='');
var hd:HWND;
    info:tagWindowInfo;
begin
  ClearWindows(WndRoot);
  hd:=GetDesktopWindow;//得到桌面窗口
  WndRoot:=TWindow.Create(hd,'WndRoot',0,0,0,0);
  WndRoot.parent:=nil;
  WndRoot.node:=nil;

  GetWindowInfo(hd,info);
  Desktop.Width:=info.rcWindow.Right-info.rcWindow.Left;
  Desktop.Height:=info.rcWindow.Bottom-info.rcWindow.Top;

  GetChildWindows(WndRoot,filter);
end;


{ COMMAND }

procedure print_version(Sender:TObject);
var AAuf:TAuf;
    AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  AufScpt.writeln('Apiglio Message Routiner');
  AufScpt.writeln('- version '+version_number+' -');
  AufScpt.writeln('- by Apiglio -');
end;

procedure SendString(Sender:TObject);
var hd:longint;
    str:string;
    i:integer;
    AAuf:TAuf;
    AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  hd:=Round(AufScpt.to_double(AAuf.nargs[1].pre,AAuf.nargs[1].arg));
  str:=utf8towincp(AAuf.nargs[2].arg);
  for i:=1 to length(str) do
    begin
      sendmessage(hd,WM_CHAR,ord(str[i]),0);
    end;
end;

procedure SendWideString(Sender:TObject);
var hd:longint;
    str:string;
    i:integer;
    AAuf:TAuf;
    AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  hd:=Round(AufScpt.to_double(AAuf.nargs[1].pre,AAuf.nargs[1].arg));
  str:=AAuf.nargs[2].arg;
  if odd(length(str)) then begin AufScpt.IO_fptr.echo(AAuf.Owner,'错误：widestring长度为奇数');exit end;
  for i:=2 to length(str) div 2 do
    begin
      sendmessage(hd,WM_IME_CHAR,(ord(str[i-1]) shl 8) + ord(str[i]),0);
    end;
end;

procedure SendM(Sender:TObject);
var hd,msg,wparam,lparam:longint;
    AAuf:TAuf;
    AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  hd:=Round(AufScpt.to_double(AAuf.nargs[1].pre,AAuf.nargs[1].arg));
  msg:=Round(AufScpt.to_double(AAuf.nargs[2].pre,AAuf.nargs[2].arg));
  case AAuf.nargs[3].pre of
    '"':wparam:=ord(AAuf.nargs[3].arg[1]);
    else wparam:=Round(AufScpt.to_double(AAuf.nargs[3].pre,AAuf.nargs[3].arg));
  end;
  case AAuf.nargs[3].pre of
    '"':lparam:=ord(AAuf.nargs[4].arg[1]);
    else lparam:=Round(AufScpt.to_double(AAuf.nargs[4].pre,AAuf.nargs[4].arg));
  end;
  SendMessage(hd,msg,wparam,lparam);
end;

procedure PostM(Sender:TObject);
var hd,msg,wparam,lparam:longint;
    AAuf:TAuf;
    AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  hd:=Round(AufScpt.to_double(AAuf.nargs[1].pre,AAuf.nargs[1].arg));
  msg:=Round(AufScpt.to_double(AAuf.nargs[2].pre,AAuf.nargs[2].arg));
  case AAuf.nargs[3].pre of
    '"':wparam:=ord(AAuf.nargs[3].arg[1]);
    else wparam:=Round(AufScpt.to_double(AAuf.nargs[3].pre,AAuf.nargs[3].arg));
  end;
  case AAuf.nargs[3].pre of
    '"':lparam:=ord(AAuf.nargs[4].arg[1]);
    else lparam:=Round(AufScpt.to_double(AAuf.nargs[4].pre,AAuf.nargs[4].arg));
  end;
  PostMessage(hd,msg,wparam,lparam);
end;

procedure KeyPress_Event(Sender:TObject);
var hd,key,delay:longint;
    AAuf:TAuf;
    AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  hd:=Round(AufScpt.to_double(AAuf.nargs[1].pre,AAuf.nargs[1].arg));
  case AAuf.nargs[2].pre of
    '"':key:=ord(AAuf.nargs[2].arg[1]);
    else key:=Round(AufScpt.to_double(AAuf.nargs[2].pre,AAuf.nargs[2].arg));
  end;


  delay:=Round(AufScpt.to_double(AAuf.nargs[3].pre,AAuf.nargs[3].arg));
  if delay=0 then delay:=50;
  PostMessage(hd,WM_KeyDown,key,(key shl 32)+1);
  process_sleep(delay);
  PostMessage(hd,WM_KeyUp,key,(key shl 32)+1);

end;

procedure Mouse_Event(Sender:TObject);//mouse @w,"L/M/R"+"D/U/B",x,y
var hd,msg,wparam,lparam:longint;
    x,y:word;
    AAuf:TAuf;
    AufScpt:TAufScript;
    buttonmode:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  hd:=Round(AufScpt.to_double(AAuf.nargs[1].pre,AAuf.nargs[1].arg));
  try
    buttonmode:=AufScpt.TryToString(AAuf.nargs[2]);
    if length(buttonmode)<>2 then raise Exception.Create('');
  except
    AufScpt.send_error('警告：mouse指令第2参数需要是长度为2的字符串，代码未执行！');
    exit;
  end;
  try
    x:=AufScpt.TryToDWord(AAuf.nargs[3]);
  except
    AufScpt.send_error('警告：mouse指令第3参数错误，代码未执行！');
    exit;
  end;
  try
    y:=AufScpt.TryToDWord(AAuf.nargs[4]);
  except
    AufScpt.send_error('警告：mouse指令第4参数错误，代码未执行！');
    exit;
  end;
  case lowercase(buttonmode) of
    'ld':msg:=WM_LButtonDown;
    'md':msg:=WM_MButtonDown;
    'rd':msg:=WM_RButtonDown;
    'lu':msg:=WM_LButtonUp;
    'mu':msg:=WM_MButtonUp;
    'ru':msg:=WM_RButtonUp;
    'lb':msg:=WM_LBUTTONDBLCLK;
    'mb':msg:=WM_MBUTTONDBLCLK;
    'rb':msg:=WM_RBUTTONDBLCLK;
    else begin
      AufScpt.send_error('警告：mouse指令第2参数错误，代码未执行！');
      exit;
    end;
  end;
  wparam:=0;
  lparam:=(x shl 16) + y;
  SendMessage(hd,msg,wparam,lparam);
end;


procedure CostumerFuncInitialize(AAuf:TAuf);
begin
  //AAuf.Script.add_func('resize',@_resize,'w,h','修改当前窗口尺寸');
  AAuf.Script.add_func('about',@print_version,'','版本信息');
  //AAuf.Script.add_func('now',@_gettime,'','当前时间');
  AAuf.Script.add_func('string',@SendString,'hwnd,str','向窗口输入字符串');
  AAuf.Script.add_func('widestring',@SendWideString,'hwnd,str','向窗口输入汉字字符串');
  AAuf.Script.add_func('keypress',@KeyPress_Event,'hwnd,key,deley','调用KeyPress_Event');
  AAuf.Script.add_func('mouse',@Mouse_Event,'hwnd,buttonmode,x,y','调用Mouse_Event');
  AAuf.Script.add_func('post',@PostM,'hwnd,msg,w,l','调用Postmessage');
  AAuf.Script.add_func('send',@SendM,'hwnd,msg,w,l','调用Sendmessage');
end;
procedure GlobalExpressionInitialize;
begin
  GlobalExpressionList.TryAddExp('WM_CREATE',narg('','1',''));
  GlobalExpressionList.TryAddExp('WM_DESTROY',narg('','2',''));
  GlobalExpressionList.TryAddExp('WM_MOVE',narg('','3',''));
  GlobalExpressionList.TryAddExp('WM_SIZE',narg('','5',''));
  GlobalExpressionList.TryAddExp('WM_ACTIVATE',narg('','6',''));
  GlobalExpressionList.TryAddExp('WM_SETFOCUS',narg('','7',''));
  GlobalExpressionList.TryAddExp('WM_KILLFOCUS',narg('','8',''));
  GlobalExpressionList.TryAddExp('WM_ENABLE',narg('','10',''));
  GlobalExpressionList.TryAddExp('WM_SETREDRAW',narg('','11',''));
  GlobalExpressionList.TryAddExp('WM_SETTEXT',narg('','12',''));
  GlobalExpressionList.TryAddExp('WM_GETTEXT',narg('','13',''));
  GlobalExpressionList.TryAddExp('WM_GETTEXTLENGTH',narg('','14',''));
  GlobalExpressionList.TryAddExp('WM_PAINT',narg('','15',''));
  GlobalExpressionList.TryAddExp('WM_CLOSE',narg('','16',''));
  GlobalExpressionList.TryAddExp('WM_QUERYENDSESSION',narg('','17',''));
  GlobalExpressionList.TryAddExp('WM_QUIT',narg('','18',''));
  GlobalExpressionList.TryAddExp('WM_QUERYOPEN',narg('','19',''));
  GlobalExpressionList.TryAddExp('WM_ERASEBKGND',narg('','20',''));
  GlobalExpressionList.TryAddExp('WM_SYSCOLORCHANGE',narg('','21',''));
  GlobalExpressionList.TryAddExp('WM_ENDSESSION',narg('','22',''));
  GlobalExpressionList.TryAddExp('WM_SHOWWINDOW',narg('','24',''));
  GlobalExpressionList.TryAddExp('WM_ACTIVATEAPP',narg('','28',''));
  GlobalExpressionList.TryAddExp('WM_FONTCHANGE',narg('','29',''));
  GlobalExpressionList.TryAddExp('WM_TIMECHANGE',narg('','30',''));
  GlobalExpressionList.TryAddExp('WM_CANCELMODE',narg('','31',''));
  GlobalExpressionList.TryAddExp('WM_SETCURSOR',narg('','32',''));
  GlobalExpressionList.TryAddExp('WM_MOUSEACTIVATE',narg('','33',''));
  GlobalExpressionList.TryAddExp('WM_CHILDACTIVATE',narg('','34',''));
  GlobalExpressionList.TryAddExp('WM_QUEUESYNC',narg('','35',''));
  GlobalExpressionList.TryAddExp('WM_GETMINMAXINFO',narg('','36',''));
  GlobalExpressionList.TryAddExp('WM_PAINTICON',narg('','38',''));
  GlobalExpressionList.TryAddExp('WM_ICONERASEBKGND',narg('','39',''));
  GlobalExpressionList.TryAddExp('WM_NEXTDLGCTL',narg('','40',''));
  GlobalExpressionList.TryAddExp('WM_SPOOLERSTATUS',narg('','42',''));
  GlobalExpressionList.TryAddExp('WM_DRAWITEM',narg('','43',''));
  GlobalExpressionList.TryAddExp('WM_MEASUREITEM',narg('','44',''));
  GlobalExpressionList.TryAddExp('WM_DELETEITEM',narg('','45',''));
  GlobalExpressionList.TryAddExp('WM_VKEYTOITEM',narg('','46',''));
  GlobalExpressionList.TryAddExp('WM_CHARTOITEM',narg('','47',''));
  GlobalExpressionList.TryAddExp('WM_SETFONT',narg('','48',''));
  GlobalExpressionList.TryAddExp('WM_GETFONT',narg('','49',''));
  GlobalExpressionList.TryAddExp('WM_SETHOTKEY',narg('','50',''));
  GlobalExpressionList.TryAddExp('WM_GETHOTKEY',narg('','51',''));
  GlobalExpressionList.TryAddExp('WM_QUERYDRAGICON',narg('','55',''));
  GlobalExpressionList.TryAddExp('WM_COMPAREITEM',narg('','57',''));
  GlobalExpressionList.TryAddExp('WM_COMPACTING',narg('','65',''));
  GlobalExpressionList.TryAddExp('WM_WINDOWPOSCHANGING',narg('','70',''));
  GlobalExpressionList.TryAddExp('WM_WINDOWPOSCHANGED',narg('','71',''));
  GlobalExpressionList.TryAddExp('WM_POWER',narg('','72',''));
  GlobalExpressionList.TryAddExp('WM_COPYDATA',narg('','74',''));
  GlobalExpressionList.TryAddExp('WM_CANCELJOURNAL',narg('','75',''));
  GlobalExpressionList.TryAddExp('WM_NOTIFY',narg('','78',''));
  GlobalExpressionList.TryAddExp('WM_INPUTLANGCHANGEREQUEST',narg('','80',''));
  GlobalExpressionList.TryAddExp('WM_INPUTLANGCHANGE',narg('','81',''));
  GlobalExpressionList.TryAddExp('WM_TCARD',narg('','82',''));
  GlobalExpressionList.TryAddExp('WM_HELP',narg('','83',''));
  GlobalExpressionList.TryAddExp('WM_USERCHANGED',narg('','84',''));
  GlobalExpressionList.TryAddExp('WM_NOTIFYFORMAT',narg('','85',''));
  GlobalExpressionList.TryAddExp('WM_CONTEXTMENU',narg('','123',''));
  GlobalExpressionList.TryAddExp('WM_STYLECHANGING',narg('','124',''));
  GlobalExpressionList.TryAddExp('WM_STYLECHANGED',narg('','125',''));
  GlobalExpressionList.TryAddExp('WM_DISPLAYCHANGE',narg('','126',''));
  GlobalExpressionList.TryAddExp('WM_GETICON',narg('','127',''));
  GlobalExpressionList.TryAddExp('WM_SETICON',narg('','128',''));
  GlobalExpressionList.TryAddExp('WM_NCCREATE',narg('','129',''));
  GlobalExpressionList.TryAddExp('WM_NCDESTROY',narg('','130',''));
  GlobalExpressionList.TryAddExp('WM_NCCALCSIZE',narg('','131',''));
  GlobalExpressionList.TryAddExp('WM_NCHITTEST',narg('','132',''));
  GlobalExpressionList.TryAddExp('WM_NCPAINT',narg('','133',''));
  GlobalExpressionList.TryAddExp('WM_NCACTIVATE',narg('','134',''));
  GlobalExpressionList.TryAddExp('WM_GETDLGCODE',narg('','135',''));
  GlobalExpressionList.TryAddExp('WM_NCMOUSEMOVE',narg('','160',''));
  GlobalExpressionList.TryAddExp('WM_NCLBUTTONDOWN',narg('','161',''));
  GlobalExpressionList.TryAddExp('WM_NCLBUTTONUP',narg('','162',''));
  GlobalExpressionList.TryAddExp('WM_NCLBUTTONDBLCLK',narg('','163',''));
  GlobalExpressionList.TryAddExp('WM_NCRBUTTONDOWN',narg('','164',''));
  GlobalExpressionList.TryAddExp('WM_NCRBUTTONUP',narg('','165',''));
  GlobalExpressionList.TryAddExp('WM_NCRBUTTONDBLCLK',narg('','166',''));
  GlobalExpressionList.TryAddExp('WM_NCMBUTTONDOWN',narg('','167',''));
  GlobalExpressionList.TryAddExp('WM_NCMBUTTONUP',narg('','168',''));
  GlobalExpressionList.TryAddExp('WM_NCMBUTTONDBLCLK',narg('','169',''));
  GlobalExpressionList.TryAddExp('WM_KEYDOWN',narg('','256',''));
  GlobalExpressionList.TryAddExp('WM_KEYUP',narg('','257',''));
  GlobalExpressionList.TryAddExp('WM_CHAR',narg('','258',''));
  GlobalExpressionList.TryAddExp('WM_DEADCHAR',narg('','259',''));
  GlobalExpressionList.TryAddExp('WM_SYSKEYDOWN',narg('','260',''));
  GlobalExpressionList.TryAddExp('WM_SYSKEYUP',narg('','261',''));
  GlobalExpressionList.TryAddExp('WM_SYSCHAR',narg('','262',''));
  GlobalExpressionList.TryAddExp('WM_SYSDEADCHAR',narg('','263',''));
  GlobalExpressionList.TryAddExp('WM_INITDIALOG',narg('','272',''));
  GlobalExpressionList.TryAddExp('WM_COMMAND',narg('','273',''));
  GlobalExpressionList.TryAddExp('WM_SYSCOMMAND',narg('','274',''));
  GlobalExpressionList.TryAddExp('WM_TIMER',narg('','275',''));
  GlobalExpressionList.TryAddExp('WM_HSCROLL',narg('','276',''));
  GlobalExpressionList.TryAddExp('WM_VSCROLL',narg('','277',''));
  GlobalExpressionList.TryAddExp('WM_INITMENU',narg('','278',''));
  GlobalExpressionList.TryAddExp('WM_INITMENUPOPUP',narg('','279',''));
  GlobalExpressionList.TryAddExp('WM_MENUSELECT',narg('','287',''));
  GlobalExpressionList.TryAddExp('WM_MENUCHAR',narg('','288',''));
  GlobalExpressionList.TryAddExp('WM_ENTERIDLE',narg('','289',''));
  GlobalExpressionList.TryAddExp('WM_CTLCOLORMSGBOX',narg('','306',''));
  GlobalExpressionList.TryAddExp('WM_CTLCOLOREDIT',narg('','307',''));
  GlobalExpressionList.TryAddExp('WM_CTLCOLORLISTBOX',narg('','308',''));
  GlobalExpressionList.TryAddExp('WM_CTLCOLORBTN',narg('','309',''));
  GlobalExpressionList.TryAddExp('WM_CTLCOLORDLG',narg('','310',''));
  GlobalExpressionList.TryAddExp('WM_CTLCOLORSCROLLBAR',narg('','311',''));
  GlobalExpressionList.TryAddExp('WM_CTLCOLORSTATIC',narg('','312',''));
  GlobalExpressionList.TryAddExp('WM_MOUSEMOVE',narg('','512',''));
  GlobalExpressionList.TryAddExp('WM_LBUTTONDOWN',narg('','513',''));
  GlobalExpressionList.TryAddExp('WM_LBUTTONUP',narg('','514',''));
  GlobalExpressionList.TryAddExp('WM_LBUTTONDBLCLK',narg('','515',''));
  GlobalExpressionList.TryAddExp('WM_RBUTTONDOWN',narg('','516',''));
  GlobalExpressionList.TryAddExp('WM_RBUTTONUP',narg('','517',''));
  GlobalExpressionList.TryAddExp('WM_RBUTTONDBLCLK',narg('','518',''));
  GlobalExpressionList.TryAddExp('WM_MBUTTONDOWN',narg('','519',''));
  GlobalExpressionList.TryAddExp('WM_MBUTTONUP',narg('','520',''));
  GlobalExpressionList.TryAddExp('WM_MBUTTONDBLCLK',narg('','521',''));
  GlobalExpressionList.TryAddExp('WM_MOUSEWHEEL',narg('','522',''));
  GlobalExpressionList.TryAddExp('WM_PARENTNOTIFY',narg('','528',''));
  GlobalExpressionList.TryAddExp('WM_ENTERMENULOOP',narg('','529',''));
  GlobalExpressionList.TryAddExp('WM_EXITMENULOOP',narg('','530',''));
  GlobalExpressionList.TryAddExp('WM_SIZING',narg('','532',''));
  GlobalExpressionList.TryAddExp('WM_CAPTURECHANGED',narg('','533',''));
  GlobalExpressionList.TryAddExp('WM_MOVING',narg('','534',''));
  GlobalExpressionList.TryAddExp('WM_POWERBROADCAST',narg('','536',''));
  GlobalExpressionList.TryAddExp('WM_DEVICECHANGE',narg('','537',''));
  GlobalExpressionList.TryAddExp('WM_MDICREATE',narg('','544',''));
  GlobalExpressionList.TryAddExp('WM_MDIDESTROY',narg('','545',''));
  GlobalExpressionList.TryAddExp('WM_MDIACTIVATE',narg('','546',''));
  GlobalExpressionList.TryAddExp('WM_MDIRESTORE',narg('','547',''));
  GlobalExpressionList.TryAddExp('WM_MDINEXT',narg('','548',''));
  GlobalExpressionList.TryAddExp('WM_MDIMAXIMIZE',narg('','549',''));
  GlobalExpressionList.TryAddExp('WM_MDITILE',narg('','550',''));
  GlobalExpressionList.TryAddExp('WM_MDICASCADE',narg('','551',''));
  GlobalExpressionList.TryAddExp('WM_MDIICONARRANGE',narg('','552',''));
  GlobalExpressionList.TryAddExp('WM_MDIGETACTIVE',narg('','553',''));
  GlobalExpressionList.TryAddExp('WM_MDISETMENU',narg('','560',''));
  GlobalExpressionList.TryAddExp('WM_CUT',narg('','768',''));
  GlobalExpressionList.TryAddExp('WM_COPY',narg('','769',''));
  GlobalExpressionList.TryAddExp('WM_PASTE',narg('','770',''));
  GlobalExpressionList.TryAddExp('WM_CLEAR',narg('','771',''));
  GlobalExpressionList.TryAddExp('WM_UNDO',narg('','772',''));
  GlobalExpressionList.TryAddExp('WM_DESTROYCLIPBOARD',narg('','775',''));
  GlobalExpressionList.TryAddExp('WM_DRAWCLIPBOARD',narg('','776',''));
  GlobalExpressionList.TryAddExp('WM_PAINTCLIPBOARD',narg('','777',''));
  GlobalExpressionList.TryAddExp('WM_SIZECLIPBOARD',narg('','779',''));
  GlobalExpressionList.TryAddExp('WM_ASKCBFORMATNAME',narg('','780',''));
  GlobalExpressionList.TryAddExp('WM_CHANGECBCHAIN',narg('','781',''));
  GlobalExpressionList.TryAddExp('WM_HSCROLLCLIPBOARD',narg('','782',''));
  GlobalExpressionList.TryAddExp('WM_QUERYNEWPALETTE',narg('','783',''));
  GlobalExpressionList.TryAddExp('WM_PALETTEISCHANGING',narg('','784',''));
  GlobalExpressionList.TryAddExp('WM_PALETTECHANGED',narg('','785',''));
  GlobalExpressionList.TryAddExp('WM_HOTKEY',narg('','786',''));


  GlobalExpressionList.TryAddExp('k_bksp',narg('','8',''));
  GlobalExpressionList.TryAddExp('k_tab',narg('','9',''));
  GlobalExpressionList.TryAddExp('k_clear',narg('','12',''));
  GlobalExpressionList.TryAddExp('k_enter',narg('','13',''));
  GlobalExpressionList.TryAddExp('k_shift',narg('','16',''));
  GlobalExpressionList.TryAddExp('k_ctrl',narg('','17',''));
  GlobalExpressionList.TryAddExp('k_alt',narg('','18',''));
  GlobalExpressionList.TryAddExp('k_pause',narg('','19',''));
  GlobalExpressionList.TryAddExp('k_capelk',narg('','20',''));
  GlobalExpressionList.TryAddExp('k_esc',narg('','27',''));
  GlobalExpressionList.TryAddExp('k_space',narg('','32',''));
  GlobalExpressionList.TryAddExp('k_pgup',narg('','33',''));
  GlobalExpressionList.TryAddExp('k_pgdn',narg('','34',''));
  GlobalExpressionList.TryAddExp('k_end',narg('','35',''));
  GlobalExpressionList.TryAddExp('k_home',narg('','36',''));
  GlobalExpressionList.TryAddExp('k_left',narg('','37',''));
  GlobalExpressionList.TryAddExp('k_up',narg('','38',''));
  GlobalExpressionList.TryAddExp('k_right',narg('','39',''));
  GlobalExpressionList.TryAddExp('k_down',narg('','40',''));
  GlobalExpressionList.TryAddExp('k_sel',narg('','41',''));
  GlobalExpressionList.TryAddExp('k_print',narg('','42',''));
  GlobalExpressionList.TryAddExp('k_exec',narg('','43',''));
  GlobalExpressionList.TryAddExp('k_snapshot',narg('','44',''));
  GlobalExpressionList.TryAddExp('k_ins',narg('','45',''));
  GlobalExpressionList.TryAddExp('k_del',narg('','46',''));
  GlobalExpressionList.TryAddExp('k_help',narg('','47',''));
  GlobalExpressionList.TryAddExp('k_lwin',narg('','91',''));
  GlobalExpressionList.TryAddExp('k_rwin',narg('','92',''));
  GlobalExpressionList.TryAddExp('k_numlk',narg('','144',''));
  GlobalExpressionList.TryAddExp('k_f1',narg('','112',''));
  GlobalExpressionList.TryAddExp('k_f2',narg('','113',''));
  GlobalExpressionList.TryAddExp('k_f3',narg('','114',''));
  GlobalExpressionList.TryAddExp('k_f4',narg('','115',''));
  GlobalExpressionList.TryAddExp('k_f5',narg('','116',''));
  GlobalExpressionList.TryAddExp('k_f6',narg('','117',''));
  GlobalExpressionList.TryAddExp('k_f7',narg('','118',''));
  GlobalExpressionList.TryAddExp('k_f8',narg('','119',''));
  GlobalExpressionList.TryAddExp('k_f9',narg('','120',''));
  GlobalExpressionList.TryAddExp('k_f10',narg('','121',''));
  GlobalExpressionList.TryAddExp('k_f11',narg('','122',''));
  GlobalExpressionList.TryAddExp('k_f12',narg('','123',''));
end;


{ TTimerLag }

constructor TTimerLag.Create(AOwner:TComponent);
begin
  inherited Create(AOwner);
  Self.OnTimer:=@Self.OnSend;
  Self.waiting:=false;
  Self.Enabled:=false;
end;

procedure TTimerLag.NextMessage(delay,hwnd,msg,wparam,lparam:dword);
begin
  Self.Enabled:=false;
  Self.next_message.hwnd:=hwnd;
  Self.next_message.msg:=msg;
  Self.next_message.wparam:=wparam;
  Self.next_message.lparam:=lparam;
  Self.Interval:=delay;
  Self.Enabled:=true;
  //qk('NextMessage('+IntToStr(delay)+','+IntToStr(hwnd)+','+IntToStr(msg)+','+IntToStr(wparam)+','+IntToStr(lparam)+');');
end;

procedure TTimerLag.OnSend(Sender:TObject);
var tmp:TForm_Routiner;
    tim:TTimerlag;
begin
  tim:=Sender as TTimerLag;
  tmp:=tim.Owner as TForm_Routiner;
  Self.Enabled:=false;
  with tim.next_message do PostMessage(hwnd,msg,wparam,lparam);
  //with tim.next_message do qk('QK:post('+IntToStr(hwnd)+','+IntToStr(msg)+','+IntToStr(wparam)+','+IntToStr(lparam)+');');
end;

{ TWindow }

constructor TWindow.Create(_hd:HWND;_name:utf8string;_Left,_Top,_Width,_Height:word);
begin
  inherited Create;
  info.hd:=_hd;
  info.name:=_name;
  info.Left:=_Left;
  info.Top:=_Top;
  info.Width:=_Width;
  info.Height:=_Height;
  parent:=nil;
  child:=TList.Create;
end;

{ TForm_Routiner }

procedure TForm_Routiner.MouseHook;
begin
  if Self.MouseHookEnabled = true then exit;
  SetCallHandleM(Self.Handle);
  if not StartHookM(WM_USER+100) then
  begin
    ShowMessage('挂钩失败！');
  end else begin
    SetTrackMouseMoveM(1);
    Self.MouseHookEnabled:=true;
  end;
end;
procedure TForm_Routiner.MouseUnHook;
begin
  if Self.MouseHookEnabled = false then exit;
  StopHookM;
  Self.MouseHookEnabled:=false;
end;
procedure TForm_Routiner.KeybdHook;
begin
  if Self.KeybdHookEnabled = true then exit;
  SetCallHandleK(Self.Handle);
  if not StartHookK(WM_USER+100) then
  begin
    ShowMessage('挂钩失败！');
  end else begin
    Self.KeybdHookEnabled:=true;
  end;
end;
procedure TForm_Routiner.KeybdUnHook;
begin
  if Self.KeybdHookEnabled = false then exit;
  StopHookK;
  Self.KeybdHookEnabled:=false;
end;

procedure TForm_Routiner.SaveOption;
var sav:TMemoryStream;
    i,j,fo:byte;
    taddr:int64;
    forms:array[1..6]of TForm;
    stmp:string;
    procedure rec_byte(pos:int64;value:byte);
    begin
      sav.Position:=pos;
      sav.WriteByte(value);
    end;
    procedure rec_long(pos:int64;value:longint);
    begin
      sav.Position:=pos;
      sav.WriteDWord(value);
    end;
    procedure rec_str(pos:int64;str:string);
    begin
      sav.Position:=pos;
      sav.WriteAnsiString(str);
    end;

begin
  sav:=TmemoryStream.Create;
  sav.Size:=$40000;
  sav.Position:=0;
  for taddr:=0 to $3FFFF do sav.WriteByte(0);

  rec_str(0,'Apiglio MR'+version_number);
  rec_byte(24,longint(Self.Layout.LayoutCode));

  rec_byte(12288+0,$80);
  rec_byte(12288+1,$80);
  rec_byte(12288+2,$80);
  rec_byte(12288+3,$80);
  rec_byte(12288+4,$80);
  rec_byte(12288+5,$80);
  rec_long(12288+128+0,Self.Splitter_MainV.Left);
  rec_long(12288+128+4,Self.Splitter_SyncV.Left);
  rec_long(12288+128+8,Self.Splitter_ButtonV.Left);
  rec_long(12288+128+12,Self.Splitter_LeftH.Top);
  rec_long(12288+128+16,Self.Splitter_RightH.Top);
  rec_long(12288+128+20,Self.Splitter_RecH.Top);
  {
  rec_byte(12288+6,$80);
  rec_byte(12288+7,$80);
  rec_long(12288+128+24,预留轴①  );
  rec_long(12288+128+28,预留轴②  );
  }
  rec_long(12288+32+6*4,Self.Layout.customer_layout.Width);
  rec_long(12288+32+7*4,Self.Layout.customer_layout.Height);
  rec_long(12288+32+0*4,Self.Layout.customer_layout.MainV);
  rec_long(12288+32+1*4,Self.Layout.customer_layout.SyncV);
  rec_long(12288+32+2*4,Self.Layout.customer_layout.ButtV);
  rec_long(12288+32+3*4,Self.Layout.customer_layout.LeftH);
  rec_long(12288+32+4*4,Self.Layout.customer_layout.RightH);
  rec_long(12288+32+5*4,Self.Layout.customer_layout.RecH);

  forms[1]:=Self;
  forms[2]:=AufButtonForm;
  forms[3]:=SettingLagForm;
  forms[4]:=ManualForm;
  forms[5]:=FormRunPerformance;
  forms[6]:=Form_HoldButtonSetting;
  FOR fo:=1 TO 6 DO BEGIN
    rec_long(32*fo,forms[fo].Top);
    rec_long(32*fo+4,forms[fo].Left);
    rec_long(32*fo+8,forms[fo].Width);
    rec_long(32*fo+12,forms[fo].Height);
  END;

  for i:=0 to SynCount do
    for j:=0 to ButtonColumn do
      begin
        taddr:=512 + ((i*32)+j)*512;
        rec_str(taddr,Self.AufButtons[i,j].ScriptFile);
        rec_str(taddr+256,Self.AufButtons[i,j].Caption);
        rec_long(taddr+508,Self.AufButtons[i,j].WindowIndex);
        if Self.AufButtons[i,j].WindowChangeable then rec_byte(1,taddr+507)
        else rec_byte(0,taddr+507);
      end;

  for i:=0 to 31 do
    begin
      taddr:=256 + i*8;
      stmp:=utf8towincp(Self.HoldButtons[i].Caption);
      //messagebox(0,PChar(IntToStr(length(stmp))),'E',MB_OK);
      while length(stmp)<4 do stmp:=stmp+#0;
      for j:=0 to 3 do rec_byte(taddr+j,ord(stmp[j+1]));
      for j:=0 to 3 do rec_byte(taddr+4+j,Self.HoldButtons[i].keymessage[j]);
    end;


    rec_byte(12288+8,MouseActSettingToMouseActByte(Self.Setting.AufButtonAct1,Self.Setting.AufButtonAct2));
    rec_byte(12288+9,MouseActSettingToMouseActByte(Self.Setting.AufButtonSetting1,Self.Setting.AufButtonSetting2));
    rec_byte(12288+10,MouseActSettingToMouseActByte(Self.Setting.AufButtonHalt1,Self.Setting.AufButtonHalt2));
    rec_byte(12288+11,MouseActSettingToMouseActByte(Self.Setting.HoldButtonSetting1,Self.Setting.HoldButtonSetting2));


   sav.SaveToFile('option.lay');
   sav.Free;

end;
procedure TForm_Routiner.LoadOption;
var sav:TMemoryStream;
    i,j,fo:byte;
    taddr:int64;
    error_text:string;
    hh,ww:longint;
    stmp:string;
    forms:array[1..6]of TForm;
    function get_byte(pos:int64):byte;
    begin
      sav.Position:=pos;
      result:=sav.ReadByte;
      //MessageBox(0,PChar('get_byte('+IntToStr(pos)+')='+IntToStr(result)),'',MB_OK);
    end;
    function get_long(pos:int64):longint;
    begin
      sav.Position:=pos;
      result:=sav.ReadDWord;
      //MessageBox(0,PChar('get_long('+IntToStr(pos)+')='+IntToStr(result)),'',MB_OK);
    end;
    function get_str(pos:int64):string;
    begin
      sav.Position:=pos;
      result:=sav.ReadAnsiString;
      //MessageBox(0,PChar(result),'',MB_OK);
    end;
begin
  sav:=TmemoryStream.Create;
  forms[1]:=Self;
  forms[2]:=AufButtonForm;
  forms[3]:=SettingLagForm;
  forms[4]:=ManualForm;
  forms[5]:=FormRunPerformance;
  forms[6]:=Form_HoldButtonSetting;
  try
    sav.LoadFromFile('option.lay');
    if sav.Size<$40000 then
      begin
        taddr:=sav.Size;
        sav.size:=$40000;
        while taddr<sav.size do
          begin
            sav.position:=taddr;
            sav.WriteByte(0);
            inc(taddr);
          end;
      end;
    Self.Layout.LayoutCode:=TLayoutSet(get_byte(24));
    FOR fo:=1 TO 6 DO BEGIN
      ww:=get_long(32*fo+8);
      hh:=get_long(32*fo+12);
      if ww*hh<>0 then begin
        forms[fo].Width:=ww;
        forms[fo].Height:=hh;
        forms[fo].Top:=get_long(32*fo);
        forms[fo].Left:=get_long(32*fo+4);
      end;
    END;
    if get_byte(12288+0) and $80 <> 0 then Self.Splitter_MainV.Left:=get_long(12288+128+0);
    if get_byte(12288+3) and $80 <> 0 then Self.Splitter_LeftH.Top:=get_long(12288+128+12);
    if get_byte(12288+4) and $80 <> 0 then Self.Splitter_RightH.Top:=get_long(12288+128+16);
    if get_byte(12288+5) and $80 <> 0 then Self.Splitter_RecH.Top:=get_long(12288+128+20);
    if get_byte(12288+1) and $80 <> 0 then Self.Splitter_SyncV.Left:=get_long(12288+128+4);
    if get_byte(12288+2) and $80 <> 0 then Self.Splitter_ButtonV.Left:=get_long(12288+128+8);
    {
    if get_byte(12288+6) and $80 <> 0 then 预留轴①  :=get_long(12288+128+24);
    if get_byte(12288+7) and $80 <> 0 then 预留轴②  :=get_long(12288+128+28);
    }
    ww:=get_long(12288+32+6*4);
    hh:=get_long(12288+32+7*4);
    if ww*hh<>0 then begin
      Self.Layout.customer_layout.Width:=ww;
      Self.Layout.customer_layout.Height:=hh;
      Self.Layout.customer_layout.MainV:=get_long(12288+32+0*4);
      Self.Layout.customer_layout.SyncV:=get_long(12288+32+1*4);
      Self.Layout.customer_layout.ButtV:=get_long(12288+32+2*4);
      Self.Layout.customer_layout.LeftH:=get_long(12288+32+3*4);
      Self.Layout.customer_layout.RightH:=get_long(12288+32+4*4);
      Self.Layout.customer_layout.RecH:=get_long(12288+32+5*4);
    end;
    for i:=0 to Self.MainMenu.Items[1].Count - 1 do
      Self.MainMenu.Items[1].Items[i].Enabled:=true;
    if Self.Layout.LayoutCode<>Lay_Customer then Self.MainMenu.Items[1].Items[byte(Self.Layout.LayoutCode)].Enabled:=false;

    for i:=0 to 31 do
      begin
        taddr:=256 + i*8;
        stmp:='XXXX';
        for j:=0 to 3 do stmp[j+1]:=chr(get_byte(taddr+j));
        //while stmp[length(stmp)]=#0 do delete(stmp,length(stmp),1);
        Self.HoldButtons[i].Caption:=wincptoutf8(stmp);
        for j:=0 to 3 do Self.HoldButtons[i].keymessage[j]:=get_byte(taddr+4+j);
      end;

    error_text:='';
    for i:=0 to SynCount do
      for j:=0 to ButtonColumn do
        begin
          try
            taddr:=512 + ((i*32)+j)*512;
            Self.AufButtons[i,j].ScriptFile:=get_str(taddr);
            Self.AufButtons[i,j].Caption:=get_str(taddr+256);
            Self.AufButtons[i,j].WindowChangeable:=get_byte(taddr+507)<>0;
            if Self.AufButtons[i,j].WindowChangeable then Self.AufButtons[i,j].WindowIndex:=get_long(taddr+508)
            else Self.AufButtons[i,j].WindowIndex:=i;
          except
            error_text:=error_text+', ['+IntToStr(i)+','+IntToStr(j)+']'
          end;
        end;
    if error_text<>'' then begin
      delete(error_text,1,1);
      MessageBox(0,PChar(utf8towincp('以下面板按键未找到先前的设置：'+#13+#10+error_text)+'.'),'Error',MB_OK);
    end;

    try
      MouseActByteToMouseActSetting(get_byte(12288+8),Self.Setting.AufButtonAct1,Self.Setting.AufButtonAct2);
    except
      MouseActByteToMouseActSetting($07,Self.Setting.AufButtonAct1,Self.Setting.AufButtonAct2);
    end;
    try
      MouseActByteToMouseActSetting(get_byte(12288+9),Self.Setting.AufButtonSetting1,Self.Setting.AufButtonSetting2);
    except
      MouseActByteToMouseActSetting($06,Self.Setting.AufButtonSetting1,Self.Setting.AufButtonSetting2);
    end;
    try
      MouseActByteToMouseActSetting(get_byte(12288+10),Self.Setting.AufButtonHalt1,Self.Setting.AufButtonHalt2);
    except
      MouseActByteToMouseActSetting($05,Self.Setting.AufButtonHalt1,Self.Setting.AufButtonHalt2);
    end;
    try
      MouseActByteToMouseActSetting(get_byte(12288+11),Self.Setting.HoldButtonSetting1,Self.Setting.HoldButtonSetting2);
    except
      MouseActByteToMouseActSetting($06,Self.Setting.HoldButtonSetting1,Self.Setting.HoldButtonSetting2);
    end;

  except
    MessageBox(0,PChar(utf8towincp('布局文件读取失败')),'Error',MB_OK);
    FOR fo:=1 TO 6 DO BEGIN
      forms[fo].Position:=poScreenCenter;
    END;
  end;
  sav.Free;

  for i:=0 to SynCount do
    for j:=0 to ButtonColumn do
      begin
        Self.AufButtons[i,j].RenewCmd;
      end;
  Self.SetLayout(byte(Self.Layout.LayoutCode));

end;

procedure TForm_Routiner.WindowsFilter;
begin
  TreeView_Wnd.items.clear;
  WndFinder(Edit_TreeView.Text);
end;

procedure TForm_Routiner.CurrentAufStrAdd(str:string);inline;
begin
  Self.AufScriptFrames[Self.PageControl.ActivePageIndex].Frame.Memo_cmd.Lines.Add(str);
end;

procedure TForm_Routiner.GetMessageUpdate(var Msg:TMessage);
var x,y:integer;
    i,kx{35转0,37转1}:byte;
    NowTimeNumber,NowTmp:longint;
begin
  x := pMouseHookStruct(Msg.LParam)^.pt.X;
  y := pMouseHookStruct(Msg.LParam)^.pt.Y;
  //Self.AufScriptFrames[Self.PageControl.ActivePageIndex].Frame.Memo_cmd.Lines.Add(IntToStr(Msg.wParam));
  case Msg.wParam of
    WM_KeyUp,WM_KeyDown,WM_Char,WM_SysKeyUp,WM_SysKeyDown,WM_IME_Char:
      begin
        case Msg.wParam of
          WM_KeyDown:
            begin
              case x of
                162,163:Self.Key_State.Ctrl:=true;
                160,161:Self.Key_State.Shift:=true;
                164,165:Self.Key_State.Alt:=true;
                91,92:Self.Key_State.Win:=true;
                49..49+SynCount:Self.Key_State.NumKey[x-49]:=true;
              end;
            end;
          WM_KeyUp:
            begin
              case x of
                162,163:Self.Key_State.Ctrl:=false;
                160,161:Self.Key_State.Shift:=false;
                164,165:Self.Key_State.Alt:=false;
                91,92:Self.Key_State.Win:=false;
                49..49+SynCount:begin Self.Key_State.Number[x-49]:=true;Self.Key_State.NumKey[x-49]:=false;end;
                192:Self.Key_State.Gross:=true;
              end;
            end;
        end;

        if Self.Key_State.ctrl and Self.Key_State.Gross and (Msg.wParam=WM_KeyDown) and (x = 192) and (y = 41) then
          begin
            Self.Button_Wnd_SynthesisClick(Self.Button_Wnd_Synthesis);
            Self.Key_State.Gross:=false;
          end;
        if Self.Key_State.ctrl and (Msg.wParam=WM_KeyDown) and (x in [49..49+SynCount]) then
          begin
            if Self.Key_State.Number[x-49] then Self.CheckBoxs[x-49].Checked:=not Self.CheckBoxs[x-49].Checked;
            Self.Key_State.Number[x-49]:=false;
          end;
        if (x in [33,34]) and (Msg.wParam=WM_KEYDOWN) then begin
          for i:=0 to SynCount do if Self.Key_State.NumKey[i] then
            begin
              NowTmp:=Self.SynSetting[i].adjusting_lag;
              case x of
                33:inc(NowTmp,Self.SynSetting[i].adjusting_step);
                34:dec(NowTmp,Self.SynSetting[i].adjusting_step);
              end;
              if NowTmp>999 then NowTmp:=999;
              if NowTmp<0 then NowTmp:=0;
              SettingLagForm.LagTime[i].Text:=IntToStr(NowTmp);
              Self.SynSetting[i].adjusting_lag:=NowTmp;
            end;
        end;
        if Self.Synthesis_mode then begin
        for i:=0 to SynCount do
          begin
            if Self.CheckBoxs[i].Checked then
              begin
                if (Self.SynSetting[i].mode_lag)
                    and (Self.SynSetting[i].adjusting_lag<>0)
                    and (x in [37,39])
                then begin
                  case x of
                    37:kx:=0;
                    39:kx:=1;
                  end;
                  case Msg.wParam of
                    WM_KeyDown:
                      begin
                        postmessage(Self.Buttons[i].sel_hwnd,Msg.wParam,x,y);
                        if not Self.KeyLag[i,kx].waiting then
                          begin
                            Self.SynSetting[i].keypress_time[kx]:=GetTimeNumber;
                            Self.KeyLag[i,kx].waiting:=true;
                          end;
                      end;
                    WM_KeyUp:
                      begin
                        NowTimeNumber:=GetTimeNumber;
                        if NowTimeNumber<Self.SynSetting[i].keypress_time[kx] then inc(NowTimeNumber,86400000);
                        Self.KeyLag[i,kx].waiting:=false;
                        Self.KeyLag[i,kx].NextMessage(
                          (NowTimeNumber-Self.SynSetting[i].keypress_time[kx])
                            * Self.SynSetting[i].adjusting_lag div 100,
                          Self.Buttons[i].sel_hwnd,
                          Msg.wParam,
                        x,y);
                      end;
                  end;
                end
                else begin
                  postmessage(Self.Buttons[i].sel_hwnd,Msg.wParam,x,y);
                end;
              end;
          end;
        end;

        if Self.Record_Mode and Self.RecKey then begin
          if (Self.LastMessage.msg=Msg.wParam) and (Self.LastMessage.wParam=x) then else begin
              NowTimeNumber:=GetTimeNumber;
              if NowTimeNumber<Self.LastRecTime then inc(NowTimeNumber,86400000);
              IF Self.RecTimeMode=rtmSleep THEN BEGIN
                Self.CurrentAufStrAdd('sleep '+IntToStr(NowTimeNumber-Self.LastRecTime));
              END ELSE BEGIN
                Self.CurrentAufStrAdd('waittimer '+IntToStr(Self.TimeOffset+NowTimeNumber-Self.FirstRecTime));
              END;
              Self.CurrentAufStrAdd('post @win,'+IntToStr(Msg.wParam)+','+IntToStr(x)+','+IntToStr((x shl 16) + 1));
              Self.LastRecTime:=NowTimeNumber;
          end;
        end;

        Self.LastMessage.msg:=Msg.wParam;
        Self.LastMessage.wParam:=x;

      end;
    WM_LButtonDown,WM_MButtonDown,WM_RButtonDown,WM_LButtonDblClk,WM_MButtonDblClk,WM_RButtonDblClk,WM_LButtonUp,WM_MButtonUp,WM_RButtonUp:
      begin
        if (Self.SettingOri)and(Msg.wParam=WM_LButtonUp) then begin
          Self.MouseOri.x:=x;
          Self.MouseOri.y:=y;
          Self.SettingOri:=false;
          Self.Button_MouseOri.Enabled:=true;
          Self.Button_MouseOri.Caption:='('+IntToStr(x)+','+IntToStr(y)+')';
        end;
        if Self.Record_Mode and Self.RecMouse then begin
          NowTimeNumber:=GetTimeNumber;
          if NowTimeNumber<Self.LastRecTime then inc(NowTimeNumber,86400000);
          IF Self.RecTimeMode=rtmSleep THEN BEGIN
            Self.CurrentAufStrAdd('sleep '+IntToStr(NowTimeNumber-Self.LastRecTime));
          END ELSE BEGIN
            Self.CurrentAufStrAdd('waittimer '+IntToStr(Self.TimeOffset+NowTimeNumber-Self.FirstRecTime));
          END;
          Self.CurrentAufStrAdd('post @win,'+IntToStr(Msg.wParam)+',0,'+IntToStr((word(y-Self.MouseOri.y) shl 16) + dword(x-Self.MouseOri.x)));
          Self.LastRecTime:=NowTimeNumber;
        end;
      end
    else ;
  end;

end;

procedure TForm_Routiner.Memo_TmpKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  (Sender as TMemo).clear;
end;

procedure TForm_Routiner.Memo_TmpRecKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  (Sender as TMemo).clear;
end;

procedure TForm_Routiner.MenuItem_ExitClick(Sender: TObject);
begin
  Self.Close;
end;

procedure TForm_Routiner.MenuItem_Func_AufClick(Sender: TObject);
begin
  ManualForm.Show;
  ManualForm.CastHtml('Manual\AufScript.html');
end;

procedure TForm_Routiner.MenuItem_Func_BasicClick(Sender: TObject);
begin
  ManualForm.Show;
  ManualForm.CastHtml('Manual\BasicManual.html');
end;

procedure TForm_Routiner.MenuItem_Func_ButtonsClick(Sender: TObject);
begin
  ManualForm.Show;
  ManualForm.CastHtml('Manual\AufButtons.html');
end;

procedure TForm_Routiner.MenuItem_Func_DiffClick(Sender: TObject);
begin
  ManualForm.Show;
  ManualForm.CastHtml('Manual\Differential.html');
end;

procedure TForm_Routiner.MenuItem_Func_KeyClick(Sender: TObject);
begin
  ManualForm.Show;
  ManualForm.CastHtml('Manual\KeyCoding.html');
end;

procedure TForm_Routiner.MenuItem_Func_RecClick(Sender: TObject);
begin
  ManualForm.Show;
  ManualForm.CastHtml('Manual\KeyRecord.html');
end;

procedure TForm_Routiner.MenuItem_Func_SynClick(Sender: TObject);
begin
  ManualForm.Show;
  ManualForm.CastHtml('Manual\Synchronization.html');
end;

procedure TForm_Routiner.MenuItem_Lay_simpleClick(Sender: TObject);
begin
  Self.SetLayout(byte(Lay_Command));
  Self.FormResize(Self);
end;

procedure TForm_Routiner.MenuItem_Lay_advancedClick(Sender: TObject);
begin
  Self.SetLayout(byte(Lay_Advanced));
  Self.FormResize(Self);
end;

procedure TForm_Routiner.MenuItem_Lay_SynChronicClick(Sender: TObject);
begin
  Self.SetLayout(byte(Lay_Synchronic));
  Self.FormResize(Self);
end;

procedure TForm_Routiner.MenuItem_Lay_ButtonsClick(Sender: TObject);
begin
  Self.SetLayout(byte(Lay_Buttons));
  Self.FormResize(Self);
end;

procedure TForm_Routiner.MenuItem_Lay_Customer_ApplyClick(Sender: TObject);
begin
  Self.SetLayout(byte(Lay_Customer));
  with Self.Layout.customer_layout do
    begin
      Self.Width:=Width;
      Self.Height:=Height;
      Self.Splitter_MainV.Left:=MainV;
      Self.Splitter_SyncV.Left:=SyncV;
      Self.Splitter_ButtonV.Left:=ButtV;
      Self.Splitter_LeftH.Top:=LeftH;
      Self.Splitter_RightH.Top:=RightH;
      Self.Splitter_RecH.Top:=RecH;
    end;
  Self.FormResize(Self);
end;

procedure TForm_Routiner.MenuItem_Lay_Customer_SaveClick(Sender: TObject);
begin
  with Self.Layout.customer_layout do
    begin
      MainV:=Self.Splitter_MainV.Left;
      SyncV:=Self.Splitter_SyncV.Left;
      ButtV:=Self.Splitter_ButtonV.Left;
      LeftH:=Self.Splitter_LeftH.Top;
      RightH:=Self.Splitter_RightH.Top;
      RecH:=Self.Splitter_RecH.Top;
      Width:=Self.Width;
      Height:=Self.Height;
    end;
end;

procedure TForm_Routiner.MenuItem_Lay_RecordClick(Sender: TObject);
begin
  Self.SetLayout(byte(Lay_Recorder));
  Self.FormResize(Self);
end;

procedure TForm_Routiner.MenuItem_Lay_SaveOptionClick(Sender: TObject);
begin
  Self.SaveOption;
end;

procedure TForm_Routiner.MenuItem_Opt_AboutClick(Sender: TObject);
begin
  MessageBox(0,
    'Apiglio Message Routiner'+#13+#10+'- version '+version_number+#13+#10+'- by Apiglio',
    PChar(utf8towincp('版本信息')),
    MB_OK);
end;

procedure TForm_Routiner.MenuItem_Opt_licenceClick(Sender: TObject);
begin
  //
end;

procedure TForm_Routiner.MenuItem_RunPerformanceClick(Sender: TObject);
begin
  FormRunPerformance.Show;
end;

procedure TForm_Routiner.MenuItem_Setting_LagClick(Sender: TObject);
begin
  SettingLagForm.Show;
end;

procedure TForm_Routiner.PageControlChange(Sender: TObject);
begin
  Self.AufScriptFrames[Self.PageControl.ActivePageIndex].Frame.FrameResize(nil);
end;

procedure TForm_Routiner.PageControlResize(Sender: TObject);
var page:integer;
begin
  //(Sender as TPageControl).ActivePage.Color:=clSkyBlue;
  with Sender as TPageControl do if (Width<=150) or (Height<100) then exit;
  for page:=0 to RuleCount do begin
    Self.AufScriptFrames[page].Frame.Width:=PageControl.Width-2*gap;
    Self.AufScriptFrames[page].Frame.Height:=PageControl.Height-25-2*gap;
    Self.AufScriptFrames[page].Frame.Left:=0;
    Self.AufScriptFrames[page].Frame.Top:=0;
  end;
  Self.AufScriptFrames[PageControl.ActivePageIndex].Frame.FrameResize(nil);
end;

procedure TForm_Routiner.RadioGroup_RecHookModeSelectionChanged(Sender: TObject
  );
begin
  (Sender as TRadioGroup).ItemIndex:=0;
end;

procedure TForm_Routiner.RadioGroup_RecSyntaxModeSelectionChanged(
  Sender: TObject);
begin
  (Sender as TRadioGroup).ItemIndex:=0;
end;

procedure TForm_Routiner.ScrollBox_AufButtonResize(Sender: TObject);
var i,j:byte;
    AufButtonW,AufButtonH:longint;
begin
  with Sender as TScrollBox do
    begin
      AufButtonW:=(Width - (ButtonColumn+3)*gap) div (ButtonColumn+1);
      AufButtonH:=(Height- (SynCount+3)*gap) div (SynCount+1);
    end;
  if AufButtonH<SynchronicH then AufButtonH:=SynchronicH;
  if AufButtonW<SynchronicW then AufButtonW:=SynchronicW;

  for i:=0 to SynCount do
    begin
      for j:=0 to ButtonColumn do
        begin
          Self.AufButtons[i,j].Height:=AufButtonH;
          Self.AufButtons[i,j].Width:=AufButtonW;
          Self.AufButtons[i,j].Left:=j*(gap + AufButtonW)+gap;
          Self.AufButtons[i,j].Top:=gap + i*(gap+AufButtonH);
        end;
    end;
end;

procedure TForm_Routiner.ScrollBox_HoldButtonResize(Sender: TObject);
var i:byte;
    HoldButtonW,HoldButtonH:longint;
begin
  with Sender as TScrollBox do
    begin
      HoldButtonW:=(Width - 9*gap)div 8;
      HoldButtonH:=(Height- 5*gap)div 4;
    end;
  if HoldButtonH<SynchronicH then HoldButtonH:=SynchronicH;
  if HoldButtonW<SynchronicW then HoldButtonW:=SynchronicW;
  for i:=0 to 31 do
    begin
      Self.HoldButtons[i].Top:=gap+(i mod 4)*(HoldButtonH+gap);
      Self.HoldButtons[i].Left:=gap+(i div 4)*(HoldBUttonW+gap);
      Self.HoldButtons[i].Width:=HoldButtonW;
      Self.HoldButtons[i].Height:=HoldButtonH;
    end;
end;

procedure TForm_Routiner.ScrollBox_SynchronicResize(Sender: TObject);
var i:byte;
    SyncW,SyncH:longint;
begin
  with Sender as TScrollBox do
    begin
      SyncW:=(Width - 2*gap);
      SyncH:=(Height- 2*gap);
    end;
  for i:=0 to SynCount do
    begin
      Self.Edits[i].Top:=gap+(SynchronicH+gap)*i;
      Self.Edits[i].Width:=60;
      Self.Edits[i].Left:=gap;
      Self.Edits[i].Height:=SynchronicH;

      Self.Buttons[i].Top:=Self.Edits[i].Top;
      Self.Buttons[i].Width:=SyncW-2*gap-166;
      Self.Buttons[i].Left:=Self.Edits[i].Width+2*gap;
      Self.Buttons[i].Height:=SynchronicH;

      Self.CheckBoxs[i].Left:=SyncW-100;
      Self.CheckBoxs[i].Top:=Self.Buttons[i].Top+3;
    end;
end;

procedure TForm_Routiner.ScrollBox_WndListResize(Sender: TObject);
var i:byte;
    TreeViewH,TreeViewW:longint;
begin
  with Sender as TScrollBox do
    begin
      TreeViewW:=(Width - 2*gap);
      TreeViewH:=(Height- 2*gap);
    end;
  TreeView_Wnd.Top:=gap;
  TreeView_Wnd.Height:=TreeViewH - 36 - 2*gap;
  TreeView_Wnd.Left:=gap;
  TreeView_Wnd.Width:=TreeViewW;
  Label_Filter.Top:=TreeView_Wnd.Top+TreeView_Wnd.Height+gap+12;
  Edit_TreeView.Top:=TreeView_Wnd.Top+TreeView_Wnd.Height+gap+4;
  Button_TreeViewFresh.Top:=TreeView_Wnd.Top+TreeView_Wnd.Height+gap+4;
  Edit_TreeView.Width:=TreeView_Wnd.Width - Label_Filter.Width - Button_TreeViewFresh.Width - 4*gap;
  Label_Filter.Left:=TreeView_Wnd.Left;
  Edit_TreeView.Left:=TreeView_Wnd.Left +10 + Label_Filter.Width;
  Button_TreeViewFresh.Left:=TreeView_Wnd.Left +10 + Label_Filter.Width + 10 + Edit_TreeView.Width;
end;

procedure TForm_Routiner.ScrollBox_WndViewResize(Sender: TObject);
var ARVCW:longint;
begin
  with Sender as TScrollBox do
    begin
      ARVCW:=(Width - 2*gap)-24;
    end;
  Button_Wnd_Record.Top:=gap;
  Button_Wnd_Record.Left:=gap;
  Button_Wnd_Record.Height:=SynchronicH;
  Button_Wnd_Record.Width:=ARVCW;

  Button_Wnd_Synthesis.Top:=SynchronicH + 2*gap;
  Button_Wnd_Synthesis.Left:=gap;
  Button_Wnd_Synthesis.Height:=SynchronicH;
  Button_Wnd_Synthesis.Width:=ARVCW;

  Button_excel.Top:=2*SynchronicH+3*gap;
  Button_excel.Left:=gap;
  Button_excel.Height:=SynchronicH;
  Button_excel.Width:=ARVCW;

  WindowPosPad.Top:=3*SynchronicH+4*gap;
  WindowPosPad.Left:=gap;
  WindowPosPad.Width:=ARVCW;
  WindowPosPad.Height:=WindowPosPad.Width*Desktop.Height div Desktop.Width;
  ReDrawWndPos;

  Memo_Tmp.Top:=3*SynchronicH+5*gap+WindowPosPad.Height;
  Memo_Tmp.Left:=gap;
  Memo_Tmp.Width:=ARVCW;
  Memo_Tmp.Height:=(Sender as TScrollBox).Height-Memo_Tmp.Top+SynchronicH;

  with Sender as TScrollBox do
    begin
      if Self.Layout.LayoutCode = Lay_Synchronic then
        VertScrollBar.Position:=VertScrollBar.Range-VertScrollBar.Page
      else
        VertScrollBar.Position:=0;
      if Self.Layout.LayoutCode = Lay_Recorder then
        VertScrollBar.Visible:=false
      else
        VertScrollBar.Visible:=true;
    end;

end;

procedure TForm_Routiner.GroupBox_RecOptionResize(Sender: TObject);
begin
  ////
end;


procedure TForm_Routiner.TreeView_WndChange(Sender: TObject; Node: TTreeNode);
begin
  ReDrawWndPos;
end;

procedure TForm_Routiner.WindowPosPadViceChange(Sender: TObject);
begin
  (Sender as TMemo).Clear;
end;

procedure TForm_Routiner.FormCreate(Sender: TObject);
var i,j:byte;
    page:integer;
    tmp:TTabSheet;
begin

  //Show_Advanced_Seting:=false;
  //Height_Advanced_Seting:=200+72;
  //Left_Column_Width:=300+120;
  Synthesis_mode:=false;
  Record_Mode:=false;
  RecKey:=false;
  RecMouse:=false;
  RecTimeMode:=rtmSleep;
  SettingOri:=false;
  Button_Wnd_Synthesis.ShowHint:=true;
  Button_Wnd_Synthesis.Hint:='按Ctrl+`切换状态';

  for page:=0 to RuleCount do
    begin
      tmp:=PageControl.AddTabSheet;
      Self.AufScriptFrames[page]:=TAufScriptFrame.Create(Self);
      AufScriptFrames[page].Frame:=TFrame_AufScript.Create(AufScriptFrames[page]);
      AufScriptFrames[page].Frame.Parent:=tmp;
      AufScriptFrames[page].Frame.FrameResize(nil);
      tmp.OnResize:=@AufScriptFrames[page].Frame.FrameResize;
      tmp.OnShow:=@AufScriptFrames[page].Frame.FrameResize;
      tmp.Caption:='规则'+Usf.zeroplus(page,2);
      tmp.OnResize(nil);

      GlobalExpressionInitialize;

      with AufScriptFrames[page].Frame do
        begin
          AufGenerator;
          CostumerFuncInitialize(Auf);
          HighLighterReNew;
        end;
    end;

  //默认尺寸状态
  Self.Width:=615;
  Self.Height:=305;

  Self.Position:=poScreenCenter;
  Self.Key_State.Gross:=true;
  for i:=49 to 49+SynCount do Self.Key_State.Number[i-49]:=true;
  for i:=0 to SynCount do
    begin
      SynSetting[i].mode_lag:=false;
      SynSetting[i].adjusting_lag:=0;
    end;

  for i:=0 to 31 do
    begin
      Self.HoldButtons[i]:=THoldButton.Create(Self);
      Self.HoldButtons[i].Parent:=Self.ScrollBox_HoldButton;
    end;
  for i:=0 to SynCount do
    begin

      Self.WinAuf[i]:=TWinAuf.Create(Self);
      Self.WinAuf[i].WindowIndex:=i;
      Self.WinAuf[i].Script.InternalFuncDefine;
      CostumerFuncInitialize(WinAuf[i]);
      with Self.WinAuf[i].Script do
        begin
          IO_fptr.pause:=@de_nil;
          IO_fptr.echo:=@WinAufStr;
          IO_fptr.print:=@WinAufStr;
          IO_fptr.error:=@WinAufStr;
          Func_Process.ending:=@WinAufEnding;
        end;
      for j:=0 to ButtonColumn do
        begin
          Self.AufButtons[i,j]:=TAufButton.Create(Self,Self.WinAuf[i]);
          Self.AufButtons[i,j].Parent:=Self.ScrollBox_AufButton;
          Self.AufButtons[i,j].WindowChangeable:=false;
          Self.AufButtons[i,j].ScriptFile:='scriptfile';
          Self.AufButtons[i,j].WindowIndex:=i;
          Self.AufButtons[i,j].ColumnIndex:=j;
          Self.AufButtons[i,j].Caption:='';
        end;

      Self.Edits[i]:=TARVEdit.Create(Self);
      Self.Buttons[i]:=TARVButton.Create(Self);
      Self.Edits[i].Parent:=Self.ScrollBox_Synchronic;
      Self.Buttons[i].Parent:=Self.ScrollBox_Synchronic;
      Self.Buttons[i].WindowIndex:=i;
      Self.Edits[i].Button:=Self.Buttons[i];
      Self.Buttons[i].Edit:=Self.Edits[i];
      Self.Edits[i].Text:='@win'+IntToStr(i);
      Self.Buttons[i].Text:='单击设置窗口句柄';
      Self.Buttons[i].expression:=Self.Edits[i].Text;
      delete(Self.Buttons[i].expression,1,1);
      GlobalExpressionList.TryAddExp(Self.Buttons[i].expression,narg('','0',''));
      Self.Buttons[i].expression:=Self.Buttons[i].expression;

      Self.CheckBoxs[i]:=TARVCheckBox.Create(Self);
      Self.CheckBoxs[i].Caption:='键盘同步';
      Self.CheckBoxs[i].Font.Bold:=true;
      Self.CheckBoxs[i].Font.Bold:=false;
      Self.CheckBoxs[i].Parent:=Self.ScrollBox_Synchronic;
      Self.CheckBoxs[i].Checked:=false;

      Self.CheckBoxs[i].OnChange:=@Self.CheckBoxs[i].CheckOnChange;

      Self.CheckBoxs[i].ShowHint:=true;
      Self.CheckBoxs[i].Hint:='按Ctrl+'+IntToStr(i+1)+'切换状态';

      Self.SynSetting[i].mode_lag:=true;
      Self.SynSetting[i].adjusting_step:=5;
      Self.SynSetting[i].adjusting_lag:=0;
      Self.KeyLag[i,0]:=TTimerLag.Create(Self);
      Self.KeyLag[i,1]:=TTimerLag.Create(Self);

    end;

  //Self.BorderStyle:=bsSingle;

  WindowsFilter;
  FormResize(nil);

  tim:=TTimer.Create(Self);
  tim.OnTimer:=@Self.TreeViewEditOnChange;

  Self.LastMessage.msg:=0;
  Self.LastMessage.lParam:=0;
  Self.LastMessage.wParam:=0;

  with Self.Layout.customer_layout do
    begin
      Width:=800;
      Height:=600;
      MainV:=500;
      SyncV:=ARVControlW;
      ButtV:=650;
      LeftH:=350;
      RightH:=200;
      RecH:=400;
    end;
  with Self.Setting do
    begin
      AufButtonAct1:=[];
      AufButtonAct2:=mbLeft;
      AufButtonSetting1:=[];
      AufButtonSetting2:=mbRight;
      AufButtonHalt1:=[];
      AufButtonHalt2:=mbMiddle;
      HoldButtonSetting1:=[];
      HoldButtonSetting2:=mbRight;
    end;

  {
  SetCallHandleK(Self.Handle);
  if not StartHookK(WM_USER+100) then
  begin
    ShowMessage('挂钩失败！');
  end;
  SetCallHandleM(Self.Handle);
  if not StartHookM(WM_USER+100) then
  begin
    ShowMessage('挂钩失败！');
  end;
  SetTrackMouseMoveM(1);
  }
  Self.KeybdHookEnabled:=false;
  Self.MouseHookEnabled:=false;
  Self.KeybdHook;
  //Self.MouseHook;//初始不开鼠标钩子

end;

procedure TForm_Routiner.FormResize(Sender: TObject);
  procedure MinSizeCheck(PWidth,PHeight:longint);
  begin
    if Self.Width<PWidth then Self.Width:=PWidth;
    if Self.Height<PHeight then Self.Height:=PHeight;
  end;
begin
  case Self.Layout.LayoutCode of
    Lay_Command:MinSizeCheck(480,300);
    Lay_Advanced:MinSizeCheck(480+WindowsListW,300+(SynCount+1)*(gap+SynchronicH)+gap);
    Lay_Synchronic:MinSizeCheck(ARVControlW+360,(SynCount+2)*(SynchronicH+gap)+gap);
    Lay_Buttons:MinSizeCheck((ButtonColumn+1+8+1)*(gap+SynchronicW)+2*gap,(SynCount+1)*(gap+SynchronicH)+2*gap+MainMenuH);
    Lay_Recorder:MinSizeCheck(480+WindowsListW,300+(SynCount+1)*(gap+SynchronicH)+gap);
  end;
  Self.Splitter_LeftV.Left:=0;
  Self.Splitter_RightV.Left:=Self.Width-sp_thick;
  //if Self.Width<ARVControlW then begin Self.Width:=ARVControlW;exit;end;
  case Self.Layout.LayoutCode of
    Lay_Command:
      begin
        Self.Splitter_MainV.Left:=Self.Width-sp_thick;
        Self.Splitter_SyncV.Left:=Self.Width-sp_thick;
        Self.Splitter_ButtonV.Left:=Self.Width-sp_thick;
        Self.Splitter_LeftH.Top:=Self.Height-sp_thick-MainMenuH;
        Self.Splitter_RightH.Top:=Self.Height-sp_thick-MainMenuH;
        Self.Splitter_RecH.Top:=Self.Height-sp_thick-MainMenuH;
        Self.Button_Wnd_Record.Enabled:=false;
      end;
    Lay_Advanced:
      begin
        Self.Splitter_MainV.Left:=Self.Width-sp_thick-WindowsListW;
        Self.Splitter_SyncV.Left:=ARVControlW;
        Self.Splitter_ButtonV.Left:=Self.Width{-sp_thick}-WindowsListW;
        Self.Splitter_LeftH.Top:=Self.Height-sp_thick-MainMenuH-(1+SynCount)*(gap+SynchronicH)-gap;
        Self.Splitter_RightH.Top:=0;
        Self.Splitter_RecH.Top:=Self.Height-sp_thick-MainMenuH;
        Self.Button_Wnd_Record.Enabled:=true;
      end;
    Lay_Synchronic:
      begin
        Self.Splitter_MainV.Left:=ARVControlW+360;
        Self.Splitter_SyncV.Left:=ARVControlW;
        Self.Splitter_ButtonV.Left:=max(Self.Splitter_MainV.Left+2*sp_thick,Self.Width-sp_thick-8*(gap+SynchronicW)-gap)-sp_thick;
        Self.Splitter_LeftH.Top:=0;
        Self.Splitter_RightH.Top:=(SynCount+1)*(SynchronicH+gap)+gap;
        Self.Splitter_RecH.Top:=Self.Height-sp_thick-MainMenuH;
        Self.Button_Wnd_Record.Enabled:=false;
      end;
    Lay_Buttons:
      begin
        Self.Splitter_MainV.Left:=0;
        Self.Splitter_SyncV.Left:=0;
        Self.Splitter_ButtonV.Left:=(Self.Width-sp_thick)*(ButtonColumn+1)div(ButtonColumn+1+8);
        Self.Splitter_LeftH.Top:=0;
        Self.Splitter_RightH.Top:=Self.Height-sp_thick-MainMenuH;
        Self.Splitter_RecH.Top:=Self.Height-sp_thick-MainMenuH;
        Self.Button_Wnd_Record.Enabled:=false;
      end;
    Lay_Recorder:
      begin
        Self.Splitter_MainV.Left:=Self.Width-sp_thick-WindowsListW;
        Self.Splitter_SyncV.Left:=Self.Width-sp_thick-WindowsListW;
        Self.Splitter_ButtonV.Left:=Self.Width-sp_thick-WindowsListW;
        Self.Splitter_LeftH.Top:=Self.Height-sp_thick-MainMenuH-3*gap-SynchronicH;
        Self.Splitter_RightH.Top:=0;
        Self.Splitter_RecH.Top:=0;
        Self.Button_Wnd_Record.Enabled:=true;
      end;
  end;
  Self.PageControlResize(Self.PageControl);
  Self.ScrollBox_WndViewResize(Self.ScrollBox_WndView);
  Self.ScrollBox_SynchronicResize(Self.ScrollBox_Synchronic);
  Self.ScrollBox_AufButtonResize(Self.ScrollBox_AufButton);
  Self.ScrollBox_HoldButtonResize(Self.ScrollBox_HoldButton);
  Self.ScrollBox_WndListResize(Self.ScrollBox_WndList);
  Self.GroupBox_RecOptionResize(Self.GroupBox_RecOption);
end;

procedure TForm_Routiner.Button_advancedClick(Sender: TObject);
begin
  SetLayout((byte(Self.Layout.LayoutCode)+1) mod 5);
end;

procedure TForm_Routiner.Button_excelClick(Sender: TObject);
var i:byte;
    btn:TButton;
begin
  btn:=Sender as TButton;
  if btn.Caption = '锁定窗口设置' then
    begin
      btn.Caption:='解锁窗口设置';
      for i:=0 to SynCount do Self.Buttons[i].Enabled:=false;
    end
  else
    begin
      btn.Caption:='锁定窗口设置';
      for i:=0 to SynCount do Self.Buttons[i].Enabled:=true;
    end;
end;

procedure TForm_Routiner.Button_excelMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button=mbRight then
    begin
      //MessageBox(0,PChar('pos('+IntToStr(x)+','+IntToStr(y)+')'),'Apiglio',MB_OK);
    end
  else exit;
end;

procedure TForm_Routiner.Button_MouseOriKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin

end;

procedure TForm_Routiner.Button_MouseOriMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  Self.SettingOri:=true;
  with Sender as TButton do
    begin
      Enabled:=false;
      Caption:='单击设置录制原点';
    end;
end;

procedure TForm_Routiner.CheckGroup_KeyMouseItemClick(Sender: TObject;
  Index: integer);
var msgtext:string;
begin
  with Sender as TCheckGroup do
    begin
      Self.RecKey:=Checked[0];
      Self.RecMouse:=Checked[1];
    end;
  msgtext:='';
  if (not Self.MouseHookEnabled) and Self.RecMouse then msgtext:=msgtext + '鼠标钩子未启用，鼠标录制功能无效。'+#13+#10;
  if (not Self.KeybdHookEnabled) and Self.RecKey then msgtext:=msgtext + '键盘钩子未启用，键盘录制功能无效。'+#13+#10;
  if msgtext<>'' then messagebox(0,PChar(utf8towincp(msgtext)),PChar(utf8towincp('钩子未启用')),MB_OK);
end;

procedure TForm_Routiner.RadioGroup_DelayModeClick(Sender: TObject);
begin
  with Sender as TRadioGroup do
    begin
      Self.RecTimeMode:=TRecTimeMode(ItemIndex);
    end;
end;

procedure TForm_Routiner.Button_TreeViewFreshClick(Sender: TObject);
begin
  WindowsFilter;
end;

procedure TForm_Routiner.Button_Wnd_RecordClick(Sender: TObject);
begin
  if not Self.Record_Mode then
    begin
      Self.Record_Mode:=true;
      (Sender as TButton).Caption:='结束录制键盘';
      (Sender as TButton).Font.Bold:=true;
      (Sender as TButton).Font.Color:=clRed;
      Self.LastRecTime:=GetTimeNumber;
      Self.FirstRecTime:=GetTimeNumber;
      Self.TimeOffset:=Usf.to_i(Self.Edit_TimerOffset.Caption);
      if (Self.RecTimeMode=rtmWaittimer) and (Self.TimeOffset=0) then CurrentAufStrAdd('settimer');
    end
  else
    begin
      Self.Record_Mode:=false;
      (Sender as TButton).Caption:='开始录制键盘';
      (Sender as TButton).Font.Bold:=false;
      (Sender as TButton).Font.Color:=clDefault;
    end;
end;

procedure TForm_Routiner.Button_Wnd_SynthesisClick(Sender: TObject);
begin
  if not Self.Synthesis_mode then
    begin
      Self.Synthesis_mode:=true;
      (Sender as TButton).Caption:='结束同步键盘';
      (Sender as TButton).Font.Bold:=true;
    end
  else
    begin
      Self.Synthesis_mode:=false;
      (Sender as TButton).Caption:='开始同步键盘';
      (Sender as TButton).Font.Bold:=false;
    end;
end;

procedure TForm_Routiner.Edit_TreeViewChange(Sender: TObject);
begin
  //Self.Button_TreeViewFresh.OnClick(nil);
  tim.Interval:=50;
  tim.Enabled:=true;
  //这个问题肯定没有结束，目前用50ms以后重新刷新的方法迟早会再暴露出问题
  WindowsFilter;
end;

procedure TForm_Routiner.TreeViewEditOnChange(Sender:TObject);
begin
  WindowsFilter;
  Self.tim.Enabled:=false;
end;

procedure TForm_Routiner.SetLayout(layoutcode:byte);
begin
  Self.MainMenu.Items[1].Items[0].Enabled:=true;
  Self.MainMenu.Items[1].Items[1].Enabled:=true;
  Self.MainMenu.Items[1].Items[2].Enabled:=true;
  Self.MainMenu.Items[1].Items[3].Enabled:=true;
  Self.MainMenu.Items[1].Items[4].Enabled:=true;
  Self.MainMenu.Items[1].Items[5].Enabled:=true;
  case TLayoutSet(layoutcode) of
  Lay_Command:
    begin
      Self.Layout.LayoutCode:=Lay_Command;
      Self.Constraints.MinHeight:=300;
      Self.Constraints.MaxHeight:=0;
      Self.Constraints.MinWidth:=480;
      Self.Constraints.MaxWidth:=0;
      //Self.Width:=WindowsListW + 150;
      //Self.Height:=(SynCount+1)*(gap+SynchronicH) + MainMenuH + 150;
      Self.MainMenu.Items[1].Items[0].Enabled:=false;
    end;
  Lay_advanced:
    begin
      Self.Layout.LayoutCode:=Lay_Advanced;
      Self.Constraints.MinHeight:=300+(SynCount+1)*(gap+SynchronicH)+gap;
      Self.Constraints.MaxHeight:=0;
      Self.Constraints.MinWidth:=480+WindowsListW;
      Self.Constraints.MaxWidth:=0;
      //Self.Width:=WindowsListW + 450;
      //Self.Height:=(SynCount+1)*(gap+SynchronicH) + MainMenuH + 300;
      Self.MainMenu.Items[1].Items[1].Enabled:=false;
    end;
  Lay_SynChronic:
    begin
      Self.Layout.LayoutCode:=Lay_Synchronic;
      Self.Constraints.MinHeight:=(SynCount+2)*(SynchronicH+gap)+gap;
      Self.Constraints.MaxHeight:=0;
      Self.Constraints.MinWidth:=ARVControlW+360;
      Self.Constraints.MaxWidth:=0;
      //Self.Width:=WindowsListW + 150;
      Self.Height:=(SynCount+1)*(gap+SynchronicH) + MainMenuH;
      Self.MainMenu.Items[1].Items[2].Enabled:=false;
    end;
  Lay_Buttons:
    begin
      Self.Layout.LayoutCode:=Lay_Buttons;
      Self.Constraints.MinHeight:=(SynCount+1)*(gap+SynchronicH)+2*gap+MainMenuH;
      Self.Constraints.MaxHeight:=(SynCount+1)*(gap+SynchronicH)+2*gap+MainMenuH;
      Self.Constraints.MinWidth:=(ButtonColumn+1+8+1)*(gap+SynchronicW)+2*gap;
      Self.Constraints.MaxWidth:=0;
      //Self.Width:=WindowsListW + 150;
      Self.Height:=(SynCount+1)*(gap+SynchronicH) + MainMenuH;
      Self.MainMenu.Items[1].Items[3].Enabled:=false;
    end;
  Lay_Recorder:
    begin
      Self.Layout.LayoutCode:=Lay_Recorder;
      Self.Constraints.MinHeight:=300+(SynCount+1)*(gap+SynchronicH)+gap;
      Self.Constraints.MaxHeight:=0;
      Self.Constraints.MinWidth:=480+WindowsListW;
      Self.Constraints.MaxWidth:=0;
      //Self.Width:=WindowsListW + 150;
      //Self.Height:=(SynCount+1)*(gap+SynchronicH) + MainMenuH + 150;
      Self.MainMenu.Items[1].Items[4].Enabled:=false;
    end;
  Lay_Customer:
    begin
      Self.Layout.LayoutCode:=Lay_Customer;
      Self.Constraints.MinHeight:=0;
      Self.Constraints.MaxHeight:=0;
      Self.Constraints.MinWidth:=0;
      Self.Constraints.MaxWidth:=0;
    end;
  end;
  Self.FormResize(nil);
end;

procedure TForm_Routiner.ReDrawWndPos;
var tmp:TTreeNode;
    ww,hh,ll,tt:longint;
begin
  tmp:=Self.TreeView_Wnd.Selected;
  if tmp = nil then begin
    ww:=0;ll:=0;tt:=0;hh:=0;
  end else with TWindow(tmp.Data).info do begin
    ww:=Width;
    hh:=Height;
    ll:=Left;
    tt:=Top;
  end;
  Self.WindowPosPadWind.Top:=Self.WindowPosPad.Top+tt*Self.WindowPosPad.Height div Desktop.Height;
  Self.WindowPosPadWind.Left:=Self.WindowPosPad.Left+ll*Self.WindowPosPad.Width div Desktop.Width;
  Self.WindowPosPadWind.Width:=ww*Self.WindowPosPad.Width div Desktop.Width;
  Self.WindowPosPadWind.Height:=hh*Self.WindowPosPad.Height div Desktop.Height;

end;

procedure TForm_Routiner.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
    SaveOption;
    {
    StopHookM;
    StopHookK;
    }
    Self.MouseUnHook;
    Self.KeybdUnHook;

end;



{ TARVButton & TARVEdit }

constructor TARVButton.Create(AOwner:TComponent);
begin
  inherited Create(AOwner);
  Self.onClick:=@Self.ButtonClick;
  Self.sel_hwnd:=0;
end;

procedure TARVButton.ButtonClick(Sender: TObject);
var wind:TWindow;
    node:TTreeNode;
    str:string;
begin
  node:=Form_Routiner.TreeView_Wnd.selected;
  if node=nil then
    begin
      MessageBox(0,PChar(utf8towincp('错误：不能将nil赋值给变量，请选择一个窗体！')),'Error',MB_OK);
      exit
    end;
  wind:=TWindow(Form_Routiner.TreeView_Wnd.selected.data);
  str:=Self.Edit.Text;
  if length(str)=0 then begin
    MessageBox(0,PChar(utf8towincp('错误：窗体变量为空，请输入一个变量名!')),'Error',MB_OK);
    exit
  end;
  if str[1]<>'@' then begin
    MessageBox(0,PChar(utf8towincp('错误：窗体变量必须以@开头，例如@win1')),'Error',MB_OK);
    exit
  end;
  case str[2] of
    'a'..'z','A'..'Z','_':;
    else begin
      MessageBox(0,PChar(utf8towincp('错误：窗体变量第二位必须是字母或下划线，例如@win1')),'Error',MB_OK);
      exit
    end;
  end;
  delete(str,1,1);
  try
    GlobalExpressionList.TryAddExp(str,narg('',IntToStr(wind.info.hd),''));
  except
    MessageBox(0,PChar(utf8towincp('错误：窗体变量写入失败，请尝试其他变量名称')),'Error',MB_OK);
    exit;
  end;
  (Sender as TARVButton).expression:=str;
  (Sender as TARVButton).Caption:=IntToHex(wind.info.hd,8)+':'+wind.info.name;
  (Sender as TARVButton).hint:=(Sender as TButton).Caption;
  (Sender as TARVButton).ShowHint:=true;
  (Sender as TARVButton).sel_hwnd:=wind.info.hd;
end;

constructor TARVEdit.Create(AOwner:TComponent);
begin
  inherited Create(AOwner);
  Self.onChange:=@Self.EditOnChange;
end;

procedure TARVEdit.EditOnChange(Sender:TObject);
var tmp:TARVEdit;
    str:string;
begin
  tmp:=Sender as TARVEdit;
  str:=tmp.Text;
  if length(str)=0 then exit;
  if str[1]<>'@' then exit;
  if not (str[2] in ['a'..'z','A'..'Z','_']) then exit;
  delete(str,1,1);
  try
    GlobalExpressionList.TryRenameExp((tmp.Button as TARVButton).expression,str);
  except
    exit;
  end;
  (tmp.Button as TARVButton).expression:=str;
  AufButtonForm.ComboBox_Window.Items[(tmp.Button as TARVButton).WindowIndex]:='@'+str;
end;

procedure TARVCheckBox.CheckOnChange(Sender:TObject);
begin
  //with (Sender as TARVCheckBox) do TheLabel.font.bold:=checked
  (Sender as TARVCheckBox).Font.bold:=checked;
end;
{
procedure TARVLabel.LabelOnClick(Sender:TObject);
begin
  with Sender as TARVLabel do CheckBox.Checked:=not CheckBox.Checked;
end;
}
constructor TAufButton.Create(AOwner:TComponent;AWinAuf:TWinAuf);
begin
  inherited Create(AOwner);
  Self.OnMouseUp:=@Self.ButtonMouseUp;
  Self.cmd:=TStringList.Create;
  Self.Auf:=AWinAuf;
  Self.Font.Bold:=true;
  Self.Font.Bold:=false;

end;
procedure TAufButton.ButtonLeftUp;
var i:byte;
begin
  if Self.Font.Bold then
    begin
      Self.AufPause;
      Self.Font.Bold:=false;
    end
  else
    begin
      if Self.Auf.Script.PSW.pause then
        begin
          Self.Font.Bold:=true;
          Self.AufResume;
        end
      else
        begin
          for i:=0 to ButtonColumn do Form_Routiner.AufButtons[Self.WindowIndex,i].Enabled:=false;
          Self.Enabled:=true;
          Self.Font.Bold:=true;
          Self.AufRun;
        end;
    end;
end;
procedure TAufButton.ButtonRightUp;
begin
  AufButtonForm.NowEditing:=Self;
  //AufButtonForm.Edit_Caption.Caption:=Self.Caption;
  //AufButtonForm.ComboBox_Window.ItemIndex:=Self.WindowIndex;
  //AufButtonForm.ComboBox_Window.Enabled:=Self.WindowChangeable;
  //AufButtonForm.ComboBox_Window.ItemIndex:=Self.WindowIndex;
  //AufButtonForm.Button_FileName.Caption:=Self.ScriptFile;
  AufButtonForm.Show;
  AufButtonForm.FormShow(nil);
end;
procedure TAufButton.ButtonMouseUp(Sender: TObject; Button: TMouseButton;
                      Shift: TShiftState; X, Y: Integer);
var frm:TForm_Routiner;
begin
  frm:=Form_Routiner;
  if (Button=frm.Setting.AufButtonSetting2) and (Shift=frm.Setting.AufButtonSetting1) then
    begin ButtonRightUp;exit end;
  if (Button=frm.Setting.AufButtonAct2) and (Shift=frm.Setting.AufButtonAct1) then
    begin ButtonLeftUp;exit end;
  if (Button=frm.Setting.AufButtonHalt2) and (Shift=frm.Setting.AufButtonHalt1) then
    begin AufStop;exit end;

end;
procedure TAufButton.AufRun;
begin
  Self.RenewCmd;
  Self.Auf.Script.command(Self.cmd);
end;
procedure TAufButton.AufPause;
begin
  Self.Auf.Script.Pause;
end;
procedure TAufButton.AufResume;
begin
  Self.Auf.Script.Resume;
end;
procedure TAufButton.AufStop;
begin
  Self.Auf.Script.Stop;
end;
procedure TAufButton.RenewCmd;
begin
  Self.cmd.Clear;
  Self.cmd.add('define win, @'+Form_Routiner.Buttons[Self.WindowIndex].expression);
  //qkm('M-AufButton['+INtToStr(Self.WindowIndex)+','+INtToStr(Self.ColumnIndex)+']');
  Self.cmd.add('load "'+Self.ScriptFile+'"');
  //qkm('E-AufButton['+INtToStr(Self.WindowIndex)+','+INtToStr(Self.ColumnIndex)+']');

end;

procedure THoldButton.HoldMouseDown(Sender: TObject;Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var sync,step:byte;
begin
  if (Button=mbRight) then begin
    exit;
  end;
  for step:=0 to 2 do if Self.keymessage[step]<>0 then BEGIN
    for sync:=0 to SynCount do
      if Form_Routiner.CheckBoxs[sync].Checked then
        postmessage(Form_Routiner.Buttons[sync].sel_hwnd,WM_KEYDOWN,Self.keymessage[step],Self.keymessage[step] shl 32 + 1);
    sleep(Self.keymessage[3]);
  END;
end;
procedure THoldButton.HoldMouseUp(Sender: TObject;Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var sync,step:byte;
    frm:TForm_Routiner;
begin
  frm:=Form_Routiner;
  if (Button=frm.Setting.HoldButtonSetting2) and (Shift=frm.Setting.HoldButtonSetting1) then begin
    Form_HoldButtonSetting.TargetButton:=Self;
    Form_HoldButtonSetting.Show;
    Form_HoldButtonSetting.FormShow(nil);
    exit;
  end;
  for step:=2 downto 0 do if Self.keymessage[step]<>0 then BEGIN
    for sync:=0 to SynCount do
      if Form_Routiner.CheckBoxs[sync].Checked then
        postmessage(Form_Routiner.Buttons[sync].sel_hwnd,WM_KEYUP,Self.keymessage[step],Self.keymessage[step] shl 32 + 1);
    sleep(Self.keymessage[3]);
  END;
end;
constructor THoldButton.Create(AOwner:TComponent);
var step:byte;
begin
  inherited Create(AOwner);
  Self.OnMouseDown:=@Self.HoldMouseDown;
  Self.OnMouseUp:=@Self.HoldMouseUp;
  for step:=0 to 3 do Self.keymessage[step]:=0;
  Self.Caption:='';
end;


end.

