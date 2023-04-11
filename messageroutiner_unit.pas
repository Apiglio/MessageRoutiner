//{$define insert}

unit MessageRoutiner_Unit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Windows,
  StdCtrls, ComCtrls, ExtCtrls, Menus, Buttons, Spin, Dos, LazUTF8, RegExpr, Clipbrd
  {$ifndef insert},
  Apiglio_Useful, aufscript_frame, auf_ram_var, form_adapter, unit_bitmapdata
  {$endif};

const

  version_number='0.2.9';

  RuleCount      = 9;{不能大于31，否则设置保存会出问题}
  SynCount       = 4;{不能大于9，也不推荐9}
  ButtonColumn   = 9;{不能大于31，否则设置保存会出问题}
  AufPopupCount  = 5;{不能大于254，也不推荐大于5}

  gap=5;
  sp_thick=6;
  WindowsListW=300;
  //ARVControlH=170;
  ARVControlW=150;
  SynchronicH=28;
  SynchronicW=36;
  MainMenuH=24;
  StatusBarH=26;
  MinAufButtonW=450;


type

  TLayoutSet = (Lay_Command=0,Lay_Advanced=1,Lay_Synchronic=2,Lay_Buttons=3,Lay_Recorder=4,Lay_Customer=5,Lay_ImgMerger=6);


  { TWindow }
  TWindow = class(TObject)
  public
    info:record
      hd:HWND;
      name,classname,fullname:string;
      Left,Top,Height,Width:word;
    end;
    child:TList;
    parent:TWindow;
    node:TObject;
    constructor Create(_hd:HWND;_name,_classname:string;_Left,_Top,_Width,_Height:word);
  end;


  { TARVButton & TARVEdit }

  TARVButton = class(TButton)
    published
      Edit:TEdit;
      procedure ButtonClick(Sender:TObject);
      constructor Create(AOwner:TComponent);
      procedure ButtonMouseEnter(Sender:TObject);
      procedure ButtonMouseLeave(Sender:TObject);
    public
      sel_hwnd:hwnd;
      expression:string;
      WindowIndex:byte;
  end;
  TARVEdit = class(TEdit)
    published
      Button:TButton;
      procedure EditOnChange(Sender:TObject);
      procedure EditMouseEnter(Sender:TObject);
      procedure EditMouseLeave(Sender:TObject);
      constructor Create(AOwner:TComponent);
  end;
  TARVCheckBox = class(TCheckBox)
    //public
      procedure CheckOnChange(Sender:TObject);
      procedure CheckBoxMouseEnter(Sender:TObject);
      procedure CheckBoxMouseLeave(Sender:TObject);
      constructor Create(AOwner:TComponent);
  end;

  THoldButton = class(TButton)
  public
    keymessage:array[0..3]of byte;
  private
    procedure HoldMouseDown(Sender: TObject;Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure HoldMouseUp(Sender: TObject;Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ButtonMouseEnter(Sender:TObject);
    procedure ButtonMouseLeave(Sender:TObject);
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
    procedure POnChangeTitle(Sender:TObject;str:string);
  end;

  TWinAuf = class(TAuf)
  public
    WindowIndex:byte;
  end;
  TSCAuf = class(TAuf)
  public
    ShortcutIndex:byte;
  end;

  TAufButton = class(TButton)
    constructor Create(AOwner:TComponent;AWinAuf:TWinAuf);
    procedure ButtonLeftUp;
    procedure ButtonCtrlLeftUp;
    procedure ButtonRightUp;
    procedure ButtonMouseUp(Sender: TObject; Button: TMouseButton;
                          Shift: TShiftState; X, Y: Integer);

    procedure ButtonMouseEnter(Sender:TObject);
    procedure ButtonMouseLeave(Sender:TObject);

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
    ScriptFile:TStrings;
    ScriptPath:string;
    WindowChangeable:boolean;
    SkipLine:byte;//跳转多少行，默认为1
  end;

  TAufMenuItem = class(TMenuItem)
  public
    SkipLine:byte;
    SuperMenu:TPopupMenu;
  end;

  TAufPopupMenu = class(TPopupMenu)
  public
    button:TAufButton;
    //submenu:array[0..AufPopupCount]of TAufMenuItem;
  public
    constructor Create(AOwner:TComponent);
    procedure SubButtonClick(Sender:TObject);
  end;

  { TForm_Routiner }

  TForm_Routiner = class(TForm)
    Button_MergerPath: TButton;
    Button_MergerRollback: TButton;
    Button_MergerAppend: TButton;
    Button_MergerClear: TButton;
    Button_MergerPosition: TButton;
    Button_MergerSave: TButton;
    Button_MergerTarget: TButton;
    Button_MouseOri: TButton;
    Button_excel: TButton;
    Button_TreeViewFresh: TButton;
    Button_Wnd_Record: TButton;
    Button_advanced: TButton;
    Button_Wnd_Synthesis: TButton;
    CheckBox_MergerAutoAppend: TCheckBox;
    CheckBox_MergerPosition: TCheckBox;
    CheckBox_MergerTarget: TCheckBox;
    CheckBox_UseReg: TCheckBox;
    CheckBox_ViewEnabled: TCheckBox;
    CheckGroup_KeyMouse: TCheckGroup;
    Edit_TimerOffset: TEdit;
    Edit_TreeView: TEdit;
    Image_Ram: TImage;
    Label_MergerPixelWidth_Title: TLabel;
    Label_MergerIntervalsEvery: TLabel;
    Label_MergerIntervalsMS: TLabel;
    Label_MergerBackMatch_Title: TLabel;
    Label_WindowPosPadState: TLabel;
    MenuItem_Lay_ImgMerge: TMenuItem;
    GroupBox_OffsetSetting: TGroupBox;
    Panel_ImageMerger: TPanel;
    ScrollBox_ImageView: TPanel;
    ScrollBox_ImageViewScroll: TScrollBox;
    ScrollBox_RecOption: TScrollBox;
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
    SpinEdit_MergerPixelWidth: TSpinEdit;
    SpinEdit_MergerIntervals: TSpinEdit;
    SpinEdit_MergerBackMatch: TSpinEdit;
    Splitter_SyncV: TSplitter;
    Splitter_LeftH: TSplitter;
    Splitter_ButtonV: TSplitter;
    Splitter_RightH: TSplitter;
    Splitter_RecH: TSplitter;
    Splitter_RightV: TSplitter;
    Splitter_MainV: TSplitter;
    Splitter_LeftV: TSplitter;
    StatusBar: TStatusBar;
    WindowPosPad: TShape;
    MenuItem_Opt_Div: TMenuItem;
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
    MenuItem_Opt_Adapter: TMenuItem;
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
    procedure Button_excelMouseEnter(Sender: TObject);
    procedure Button_excelMouseLeave(Sender: TObject);
    procedure Button_excelMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Button_MergerAppendClick(Sender: TObject);
    procedure Button_MergerAppendMouseEnter(Sender: TObject);
    procedure Button_MergerAppendMouseLeave(Sender: TObject);
    procedure Button_MergerClearClick(Sender: TObject);
    procedure Button_MergerClearMouseEnter(Sender: TObject);
    procedure Button_MergerClearMouseLeave(Sender: TObject);
    procedure Button_MergerPathMouseEnter(Sender: TObject);
    procedure Button_MergerPathMouseLeave(Sender: TObject);
    procedure Button_MergerRollbackClick(Sender: TObject);
    procedure Button_MergerPathClick(Sender: TObject);
    procedure Button_MergerPositionClick(Sender: TObject);
    procedure Button_MergerPositionMouseEnter(Sender: TObject);
    procedure Button_MergerPositionMouseLeave(Sender: TObject);
    procedure Button_MergerRollbackMouseEnter(Sender: TObject);
    procedure Button_MergerRollbackMouseLeave(Sender: TObject);
    procedure Button_MergerSaveClick(Sender: TObject);
    procedure Button_MergerSaveMouseEnter(Sender: TObject);
    procedure Button_MergerSaveMouseLeave(Sender: TObject);
    procedure Button_MergerTargetClick(Sender: TObject);
    procedure Button_MergerTargetMouseEnter(Sender: TObject);
    procedure Button_MergerTargetMouseLeave(Sender: TObject);
    procedure Button_MouseOriKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Button_MouseOriMouseEnter(Sender: TObject);
    procedure Button_MouseOriMouseLeave(Sender: TObject);
    procedure Button_MouseOriMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Button_TreeViewFreshMouseEnter(Sender: TObject);
    procedure Button_TreeViewFreshMouseLeave(Sender: TObject);
    procedure Button_Wnd_RecordMouseEnter(Sender: TObject);
    procedure Button_Wnd_RecordMouseLeave(Sender: TObject);
    procedure Button_Wnd_SynthesisMouseEnter(Sender: TObject);
    procedure Button_Wnd_SynthesisMouseLeave(Sender: TObject);
    procedure CheckBox_MergerAutoAppendChange(Sender: TObject);
    procedure CheckBox_MergerAutoAppendMouseEnter(Sender: TObject);
    procedure CheckBox_MergerAutoAppendMouseLeave(Sender: TObject);
    procedure CheckBox_MergerPositionChange(Sender: TObject);
    procedure CheckBox_MergerPositionMouseEnter(Sender: TObject);
    procedure CheckBox_MergerPositionMouseLeave(Sender: TObject);
    procedure CheckBox_MergerTargetChange(Sender: TObject);
    procedure CheckBox_MergerTargetMouseEnter(Sender: TObject);
    procedure CheckBox_MergerTargetMouseLeave(Sender: TObject);
    procedure CheckBox_UseRegMouseEnter(Sender: TObject);
    procedure CheckBox_UseRegMouseLeave(Sender: TObject);
    procedure CheckBox_ViewEnabledChange(Sender: TObject);
    procedure CheckGroup_KeyMouseItemClick(Sender: TObject; Index: integer);
    procedure CheckGroup_KeyMouseMouseEnter(Sender: TObject);
    procedure CheckGroup_KeyMouseMouseLeave(Sender: TObject);
    procedure Edit_TimerOffsetMouseEnter(Sender: TObject);
    procedure Edit_TimerOffsetMouseLeave(Sender: TObject);
    procedure Edit_TreeViewMouseEnter(Sender: TObject);
    procedure Edit_TreeViewMouseLeave(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure Label_WindowPosPadStateMouseEnter(Sender: TObject);
    procedure Label_WindowPosPadStateMouseLeave(Sender: TObject);
    procedure Memo_TmpMouseEnter(Sender: TObject);
    procedure Memo_TmpMouseLeave(Sender: TObject);
    procedure Memo_TmpRecMouseEnter(Sender: TObject);
    procedure Memo_TmpRecMouseLeave(Sender: TObject);
    procedure MenuItem_Lay_ImgMergeClick(Sender: TObject);
    procedure RadioGroup_DelayModeClick(Sender: TObject);
    procedure RadioGroup_DelayModeMouseEnter(Sender: TObject);
    procedure RadioGroup_DelayModeMouseLeave(Sender: TObject);
    procedure RadioGroup_RecSyntaxModeMouseEnter(Sender: TObject);
    procedure RadioGroup_RecSyntaxModeMouseLeave(Sender: TObject);
    procedure SpinEdit_MergerBackMatchChange(Sender: TObject);
    procedure SpinEdit_MergerBackMatchMouseEnter(Sender: TObject);
    procedure SpinEdit_MergerBackMatchMouseLeave(Sender: TObject);
    procedure SpinEdit_MergerIntervalsEditingDone(Sender: TObject);
    procedure SpinEdit_MergerIntervalsMouseEnter(Sender: TObject);
    procedure SpinEdit_MergerIntervalsMouseLeave(Sender: TObject);
    procedure SpinEdit_MergerPixelWidthChange(Sender: TObject);
    procedure SpinEdit_MergerPixelWidthMouseEnter(Sender: TObject);
    procedure SpinEdit_MergerPixelWidthMouseLeave(Sender: TObject);
    procedure TreeViewEditOnChange(Sender:TObject);
    procedure Button_TreeViewFreshClick(Sender: TObject);
    procedure Button_Wnd_RecordClick(Sender: TObject);
    procedure Button_Wnd_SynthesisClick(Sender: TObject);
    procedure Edit_TreeViewChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure ScrollBox_RecOptionResize(Sender: TObject);
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
    procedure MenuItem_Opt_AdapterClick(Sender: TObject);
    procedure MenuItem_RunPerformanceClick(Sender: TObject);
    procedure MenuItem_Setting_LagClick(Sender: TObject);
    procedure PageControlChange(Sender: TObject);
    procedure PageControlResize(Sender: TObject);
    procedure RadioGroup_RecSyntaxModeSelectionChanged(Sender: TObject);
    procedure ScrollBox_AufButtonResize(Sender: TObject);
    procedure ScrollBox_HoldButtonResize(Sender: TObject);
    procedure ScrollBox_SynchronicResize(Sender: TObject);
    procedure ScrollBox_WndListResize(Sender: TObject);
    procedure ScrollBox_WndViewResize(Sender: TObject);
    procedure TreeView_WndChange(Sender: TObject; Node: TTreeNode);
    procedure TreeView_WndMouseEnter(Sender: TObject);
    procedure TreeView_WndMouseLeave(Sender: TObject);
    procedure WindowPosPadMouseEnter(Sender: TObject);
    procedure WindowPosPadMouseLeave(Sender: TObject);
    procedure WindowPosPadViceChange(Sender: TObject);
    procedure WindowPosPadWindMouseEnter(Sender: TObject);
    procedure WindowPosPadWindMouseLeave(Sender: TObject);

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
      AufButton:record //面板操作按键设置
        Act1,ExtraAct1,Setting1,Halt1:TShiftState;
        Act2,ExtraAct2,Setting2,Halt2:TMouseButton;
      end;
      HoldButton:record //鼠标操作代键设置
        Setting1:TShiftState;
        Setting2:TMouseButton;
      end;
      RecOption:record //记录器选项设置
        RecKey,RecMouse:boolean;//是否记录键盘或鼠标消息
        RecTimeMode:TRecTimeMode;
        RecSyntaxMode:TRecSyntaxMode;
      end;
      MergerOption:record//长图截屏选项
        UseWindow:boolean;
        UseRect:boolean;
        UseAuto:boolean;
        Target:HWND;
        Rect:TRect;
        Interval:integer;
        PixelWidth:integer;
        BackMatch:integer;
      end;
      WndListShowingOption:record
        HwndVisible,WndNameVisible,ClassNameVisible,PositionVisible:boolean;
        AlignCell,NameCell:byte;
      end;
    end;
  public
    WinAuf:array[0..SynCount]of TWinAuf;//每个窗口的专用Auf
    SCAufs:array[0..ShortcutCount]of TSCAuf;//每个快捷键的专用Auf
    MergerAuf:TAuf;//用于长图截屏工具
    AufButtons:array[0..SynCount,0..ButtonColumn]of TAufButton;//面板按键
    HoldButtons:array[0..31]of THoldButton;//鼠标代键
    Edits:array[0..SynCount]of TARVEdit;
    Buttons:array[0..SynCount]of TARVButton;
    CheckBoxs:array[0..SynCount]of TARVCheckBox;
    AufScriptFrames:array[0..RuleCount] of TAufScriptFrame;
    AufPopupMenu:TAufPopupMenu;
  public
    procedure ShortcutAufCommand(str:TStrings);//寻找一个没有在运行的SCAuf执行代码
    procedure ShortcutAufClear;//中止所有在运行的SCAuf执行代码

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
    procedure MouseHook;
    procedure MouseUnHook;
    procedure KeybdHook;
    procedure KeybdUnHook;
    procedure KeybdBlockOn;
    procedure KeybdBlockOff;

  public
    procedure Merger_Clear;
    procedure Merger_Save;
    procedure Merger_Append;
    procedure Merger_Rollback;
    procedure Merger_Loop;
    procedure Merger_Stop;

  public
    procedure CurrentAufStrAdd(str:string);inline;
    procedure WindowsFilter;
    procedure SetLayout(layoutcode:byte);
    procedure ReDrawWndPos;
    procedure ShowManual(msg:string);
    function GetSelectedWindow:TWindow;
  end;

var
  Form_Routiner: TForm_Routiner;
  WndRoot:TWindow;
  WndFlat,WndSub,WndTmp:TStringList;
  Desktop:record
    Width,Height:longint;
  end;
  Reg:TRegExpr;

  function GetDPIScaling:double;
  function GetDPI:integer;
  function GetDPIRect(ARect:TRect):TRect;

implementation
uses form_settinglag, form_aufbutton, form_manual, form_runperformance,
     unit_holdbuttonsetting, auf_ram_image, form_imagemerger;

{$R *.lfm}

function StartHookK(MsgID:Word):Bool;stdcall;external 'AufMR_KeyBD.dll' name 'StartHook';
function StopHookK:Bool;stdcall;external 'AufMR_KeyBD.dll' name 'StopHook';
procedure SetCallHandleK(sender:HWND);stdcall;external 'AufMR_KeyBD.dll' name 'SetCallHandle';
procedure BlockMsgOnK;stdcall;external 'AufMR_KeyBD.dll' name 'BlockMsgOn';
procedure BlockMsgOffK;stdcall;external 'AufMR_KeyBD.dll' name 'BlockMsgOff';

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

function GetDPIScaling:double;
var dc:HDC;
begin
  dc:=GetDC(0);
  result:=GetDeviceCaps(dc, DESKTOPHORZRES) / GetDeviceCaps(dc, HORZRES);
  ReleaseDC(0,dc);
end;
function GetDPI:integer;
var dtmp:double;
begin
  dtmp:=GetDPIScaling;
  result:=round(96*dtmp);
end;
function GetDPIRect(ARect:TRect):TRect;
var dpiScaling:double;
begin
  dpiScaling:=GetDPIScaling;
  result:=Classes.Rect(
    round(dpiScaling*ARect.Left),
    round(dpiScaling*ARect.Top),
    round(dpiScaling*ARect.Right),
    round(dpiScaling*ARect.Bottom)
  );
end;

function GetTimeNumber:longint;
var h,m,s,ms:word;
begin
  gettime(h,m,s,ms);
  result:=ms*10+s*1000+m*60000+h*3600000;
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
procedure MouseActCodeToMouseActSetting(MouseActCode:string;var shift:TShiftState;var button:TMouseButton);
begin
  case MouseActCode[1] of
    'L','l':button:=mbLeft;
    'R','r':button:=mbRight;
    'M','m':button:=mbMiddle;
    '1':button:=mbExtra1;
    '2':button:=mbExtra2;
    else raise Exception.Create('Invalid MouseActByte');
  end;
  shift:=[];
  if (pos('C',MouseActCode)>0) or (pos('c',MouseActCode)>0) then shift:=shift+[ssCtrl];
  if (pos('S',MouseActCode)>0) or (pos('s',MouseActCode)>0) then shift:=shift+[ssShift];
  if (pos('A',MouseActCode)>0) or (pos('a',MouseActCode)>0) then shift:=shift+[ssAlt];
end;
function MouseActSettingToMouseActCode(shift:TShiftState;button:TMouseButton):string;
begin
  case button of
    mbLeft:result:='L';
    mbRight:result:='R';
    mbMiddle:result:='M';
    mbExtra1:result:='1';
    mbExtra2:result:='2';
    else result:='U';
  end;
  if ssCtrl  in shift then result:=result+'C';
  if ssShift in shift then result:=result+'S';
  if ssAlt   in shift then result:=result+'A';
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

procedure SCAufBeginning(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TSCAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TSCAuf;
  FormRunPerformance.ProgressBar_SCAufsThread.Position:=FormRunPerformance.ProgressBar_SCAufsThread.Position+1;
end;
procedure SCAufEnding(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TSCAuf;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TSCAuf;
  FormRunPerformance.ProgressBar_SCAufsThread.Position:=FormRunPerformance.ProgressBar_SCAufsThread.Position-1;
end;

procedure WinAufStr(Sender:TObject;str:string);
var tmp:byte;
begin
  if str='' then exit;
  if (Sender as TAufScript).PSW.haltoff then exit;
  tmp:=MessageBox(0,PChar(utf8towincp('是否继续执行？')+#13+#10+utf8towincp('错误信息：'+str)),'WinAuf',MB_RETRYCANCEL);
  if tmp=IDCANCEL then (Sender as TAufScript).Stop;
end;
procedure SCAufStr(Sender:TObject;str:string);
var tmp:byte;
begin
  if str='' then exit;
  tmp:=MessageBox(0,PChar(utf8towincp('是否继续执行？')+#13+#10+utf8towincp('错误信息：'+str)),'SCAuf',MB_RETRYCANCEL);
  if tmp=IDCANCEL then (Sender as TAufScript).Stop;
end;
procedure ImgMergerAufStr(Sender:TObject;str:string);
var count:integer;
    stmp:string;
begin
  count:=Form_Routiner.Memo_Tmp.Lines.Count;
  stmp:=Form_Routiner.Memo_Tmp.Lines[count];
  Form_Routiner.Memo_Tmp.Lines[count]:=stmp+str;
end;
procedure ImgMergerAufStrLn(Sender:TObject;str:string);
begin
  ImgMergerAufStr(Sender,str);
  Form_Routiner.Memo_Tmp.Lines.Add('');
end;
procedure ImgMergerAufStrErr(Sender:TObject;str:string);
begin
  Form_Routiner.Memo_Tmp.Lines.Add(str);
  Form_Routiner.Memo_Tmp.Lines.Add('');
end;

procedure ClearWindows(wnd:TWindow);
begin
  if not assigned(wnd) then exit;
  Application.ProcessMessages;
  while wnd.child.count <> 0 do
    begin
      ClearWindows(TWindow(wnd.child.Extract(wnd.child.first)));
    end;
  wnd.child.free;
  wnd.free;
end;

procedure GetChildWindows(wnd:TWindow;filter:string='';UseReg:boolean=false);
var hd:HWND;
    info:tagWindowInfo;
    w,h:word;
    title,classname,caption:string;
    ttmp,ctmp:{PChar}array[0..199]of char;
    new_wnd:TWindow;
    FilterRes:boolean;
begin
  hd:=GetWindow(wnd.info.hd,GW_CHILD);
  while hd<>0 do
    begin
      GetWindowText(hd,ttmp,200);
      GetClassName(hd,ctmp,200);
      title:=ttmp;
      classname:=ctmp;
      GetWindowInfo(hd,info);
      w:=info.rcWindow.Right-info.rcWindow.Left;
      h:=info.rcWindow.Bottom-info.rcWindow.Top;
      new_wnd:=TWindow.Create(hd,wincptoutf8(title),wincptoutf8(classname),info.rcWindow.Left,info.rcWindow.Top,w,h);
      new_wnd.parent:=Wnd;
      if new_wnd.parent.info.name='WndRoot' then new_wnd.info.fullname:='['+IntToHex(new_wnd.info.hd,8)+']'+new_wnd.info.name
      else new_wnd.info.fullname:=new_wnd.parent.info.fullname+'/['+IntToHex(new_wnd.info.hd,8)+']'+new_wnd.info.name;
      wnd.child.add(new_wnd);
      WndFlat.Objects[WndFlat.Add(new_wnd.info.fullname)]:=new_wnd;
      if title='' then title:=' ';

      if filter='' then FilterRes:=true
      else begin
        if UseReg then begin
          Reg.Expression:=filter;
          try
            FilterRes:=Reg.Exec(title);
            if not FilterRes then FilterRes:=Reg.Exec(classname);
          except
            FilterRes:=true;
          end;
        end else begin
          FilterRes:=(pos(lowercase(filter),lowercase(title))>0) or (pos(lowercase(filter),lowercase(classname))>0)
        end;
      end;

      IF FilterRes THEN
        BEGIN
          with Form_Routiner.Setting.WndListShowingOption do
            begin
              if HwndVisible then caption:='['+IntToHex(hd,8)+']' else caption:='';
              if PositionVisible then caption:=caption+'[W='+Usf.zeroplus(w,5)+' H='+Usf.zeroplus(h,5)+' L='+Usf.zeroplus(info.rcWindow.Left,5)+' T='+Usf.zeroplus(info.rcWindow.Top,5)+']';
              if WndNameVisible then caption:=caption + Usf.left_adjust(title,NameCell,AlignCell);
              if ClassNameVisible then caption:=caption + ' [CLASS]'+classname;
              caption:=wincptoutf8(trim(caption));
            end;
          if (new_wnd.parent.node)=nil then
            begin
              Form_Routiner.TreeView_Wnd.Items.add(nil,caption)
            end
          else
            begin
              Form_Routiner.TreeView_Wnd.Items.addchild((new_wnd.parent.node) as TTreeNode,caption);
            end;
          new_wnd.node:=Form_Routiner.TreeView_Wnd.Items[Form_Routiner.TreeView_Wnd.Items.count-1];
          (new_wnd.node as TTreeNode).data:=new_wnd;
          GetChildWindows(new_wnd);
        END;

      hd:=GetNextWindow(hd,GW_HWNDNEXT);

    end;
end;


procedure WndFinder(filter:string='';UseReg:boolean=false);
var hd:HWND;
    info:tagWindowInfo;
begin
  ClearWindows(WndRoot);
  WndFlat.Clear;
  hd:=GetDesktopWindow;//得到桌面窗口
  GlobalExpressionList.TryAddExp('desktop',narg('',IntToStr(hd),''));
  WndRoot:=TWindow.Create(hd,'WndRoot','',0,0,0,0);
  WndRoot.parent:=nil;
  WndRoot.node:=nil;
  WndFlat.Objects[WndFlat.Add('')]:=nil;

  GetWindowInfo(hd,info);
  Desktop.Width:=info.rcWindow.Right-info.rcWindow.Left;
  Desktop.Height:=info.rcWindow.Bottom-info.rcWindow.Top;

  GetChildWindows(WndRoot,filter,UseReg);
end;


{ COMMAND }

procedure print_version(Sender:TObject);
var AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  AufScpt.writeln('Apiglio Message Routiner');
  AufScpt.writeln('- version '+version_number+' -');
  AufScpt.writeln('- by Apiglio -');
end;

procedure getwind_name_visible(Sender:TObject);
var AAuf:TAuf;
    AufScpt:TAufScript;
    wind_name:string;
    tmp:TAufRamVar;
    hd:hwnd;
    info:tagWindowInfo;
    hidden:boolean=false;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToString(2,wind_name) then exit;
  if not AAuf.TryArgToARV(1,8,High(dword),[ARV_FixNum],tmp) then exit;
  hd:=FindWindow(nil,PChar(utf8towincp(wind_name)));
  while (hd<>0) and hidden do begin
    hidden:=false;
    GetWindowInfo(hd,info);
    if info.rcWindow.Width*info.rcWindow.Height=0 then hidden:=true;
    if (info.rcWindow.Left<-info.rcWindow.Width) or (info.rcWindow.Left>Desktop.Width) then hidden:=true;
    if (info.rcWindow.Top<-info.rcWindow.Height) or (info.rcWindow.Top>Desktop.Height) then hidden:=true;
  end;
  dword_to_arv(hd,tmp);

end;

procedure getwind_top(Sender:TObject);
var AAuf:TAuf;
    AufScpt:TAufScript;
    tmp,name_tmp:TAufRamVar;
    hd:hwnd;
    ntmp:array[0..255]of char;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToARV(1,4,High(dword),[ARV_FixNum],tmp) then exit;
  if AAuf.ArgsCount>2 then begin
    if not AAuf.TryArgToARV(2,4,High(dword),[ARV_FixNum],name_tmp) then exit;
  end else name_tmp.size:=0;
  hd:=GetForegroundWindow;
  dword_to_arv(hd,tmp);
  if name_tmp.size<>0 then
    begin
      GetWindowText(hd,ntmp,min(name_tmp.size,240));
      initiate_arv_str(wincptoutf8(ntmp),name_tmp);
    end;
end;

procedure getwind_size(Sender:TObject);
var AAuf:TAuf;
    AufScpt:TAufScript;
    wind_name:string;
    x,y,w,h:TAufRamVar;
    hd:longint;
    info:tagWindowInfo;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(6) then exit;
  if not AAuf.TryArgToLong(1,hd) then exit;
  if not AAuf.TryArgToARV(2,8,High(dword),[ARV_FixNum],x) then exit;
  if not AAuf.TryArgToARV(3,8,High(dword),[ARV_FixNum],y) then exit;
  if not AAuf.TryArgToARV(4,8,High(dword),[ARV_FixNum],w) then exit;
  if not AAuf.TryArgToARV(5,8,High(dword),[ARV_FixNum],h) then exit;
  if hd<>0 then begin
    GetWindowInfo(hd,info);
    dword_to_arv(info.rcWindow.Top,y);
    dword_to_arv(info.rcWindow.Left,x);
    dword_to_arv(info.rcWindow.Width,w);
    dword_to_arv(info.rcWindow.Height,h);
  end else begin
    dword_to_arv(0,x);
    dword_to_arv(0,y);
    dword_to_arv(Desktop.Width,w);
    dword_to_arv(Desktop.Height,h);
  end;
end;

procedure wndlist_update(Sender:TObject);
var AAuf:TAuf;
    AufScpt:TAufScript;
    filter_str,use_reg_str:string;
    use_reg:boolean=false;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToString(1,filter_str) then exit;
  if AAuf.ArgsCount>=3 then begin
    if not AAuf.TryArgToString(2,use_reg_str) then exit;
  end else use_reg_str:='';
  case lowercase(use_reg_str) of
    'on':use_reg:=true;
    else use_reg:=false;
  end;
  Form_Routiner.TreeView_Wnd.items.clear;
  WndFinder(filter_str,use_reg);
  //Form_Routiner.Memo_Tmp.Clear;
  //for use_reg_str in WndFlat do AufScpt.writeln(use_reg_str);
  WndTmp.Clear;//如果刷新列表之后再wndnew.pop，列表里的TWindow就会出错。
  Application.ProcessMessages;
end;

procedure wndlist_find(Sender:TObject);
var AAuf:TAuf;
    AufScpt:TAufScript;
    filter_str,use_reg_str:string;
    use_reg:boolean=false;
  function CheckWnd(WndName:string):boolean;
  begin
    try
       if use_reg then result:=Reg.Exec(WndName)
       else result:=pos(filter_str,WndName)>0;
    except
      result:=false;
    end;
  end;

begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToString(1,filter_str) then exit;
  if AAuf.ArgsCount>=3 then begin
    AAuf.TryArgToString(2,use_reg_str);
  end else use_reg_str:='';
  case lowercase(use_reg_str) of
    'on':use_reg:=true;
    else use_reg:=false;
  end;
  Reg.Expression:=filter_str;
  for use_reg_str in WndFlat do begin
    if CheckWnd(use_reg_str) then AufScpt.writeln(use_reg_str);
  end;
end;

procedure wndlist_new_init(Sender:TObject);//wndnew.init
var AAuf:TAuf;
    AufScpt:TAufScript;
    stmp:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  WndSub.Clear;
  for stmp in WndFlat do WndSub.Add(stmp);
end;

procedure wndlist_new_update(Sender:TObject);//wndnew.update filter,use_reg[,-show]
var AAuf:TAuf;
    AufScpt:TAufScript;
    filter_str,use_reg_str,show_list_str:string;
    use_reg:boolean;
    pi,useless:integer;
    show_list:boolean;
  function CheckWnd(WndName:string):boolean;
  begin
    try
      if use_reg then result:=Reg.Exec(WndName)
      else result:=pos(filter_str,WndName)>0;
    except
      result:=false;
    end;
  end;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToString(1,filter_str) then exit;
  if AAuf.ArgsCount>=3 then begin
    if not AAuf.TryArgToString(2,use_reg_str) then exit;
  end else use_reg_str:='';
  if AAuf.ArgsCount>=4 then begin
    if not AAuf.TryArgToStrParam(3,['-show','-list','-quiet'],false,show_list_str) then exit;
  end else show_list_str:='-quiet';
  show_list:=not(lowercase(show_list_str)='-quiet');
  case lowercase(use_reg_str) of
    'on':use_reg:=true;
    else use_reg:=false;
  end;
  WndTmp.Clear;
  for pi:=0 to WndFlat.Count-1 do begin
    WndTmp.Add(WndFlat[pi]);
    WndTmp.Objects[pi]:=WndFlat.Objects[pi];
  end;
  pi:=0;
  while pi<WndTmp.Count do begin
    if WndSub.Find(WndTmp[pi],useless) then WndTmp.Delete(pi)
    else begin
      if show_list then AufScpt.writeln(WndTmp[pi]);
      inc(pi);
    end;
  end;
end;

procedure wndlist_new_pop(Sender:TObject);//wndnew.pop @hwnd
var AAuf:TAuf;
    AufScpt:TAufScript;
    tmp:TAufRamVar;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToARV(1,8,High(Dword),[ARV_FixNum],tmp) then exit;
  if WndTmp.Count>0 then begin
    dword_to_arv(TWindow(WndTmp.Objects[0]).info.hd,tmp);
    WndTmp.Delete(0);
  end else begin
    dword_to_arv(0,tmp);
  end;
end;

procedure wndlist_new_empty(Sender:TObject);//wndnew.empty? :label
var AAuf:TAuf;
    AufScpt:TAufScript;
    line:pRam;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToAddr(1,line) then exit;
  if WndTmp.Count<=0 then begin
    AufScpt.jump_addr(line);
  end;
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
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToLong(1,hd) then exit;
  if not AAuf.TryArgToString(2,str) then exit;
  str:=utf8towincp(str);
  for i:=1 to length(str) do sendmessage(hd,WM_CHAR,ord(str[i]),0);
end;

procedure ClipBoardString(Sender:TObject);
var str:string;
    AAuf:TAuf;
    AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToString(1,str) then exit;
  Clipboard.AsText:=str;
end;

procedure SendM(Sender:TObject);
var hd,msg,wparam,lparam:longint;
    AAuf:TAuf;
    AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(5) then exit;
  if not AAuf.TryArgToLong(1,hd) then exit;
  if not AAuf.TryArgToLong(2,msg) then exit;
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
  if not AAuf.CheckArgs(5) then exit;
  if not AAuf.TryArgToLong(1,hd) then exit;
  if not AAuf.TryArgToLong(2,msg) then exit;
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

procedure _Keybd(Sender:TObject);//keybd @w,"D/U",key
var hd,msg,wparam,lparam:longint;
    key:byte;
    str:string;
    AAuf:TAuf;
    AufScpt:TAufScript;
    buttonmode:string;
    alt_offset:byte;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(4) then exit;
  if not AAuf.TryArgToLong(1,hd) then exit;
  if not AAuf.TryArgToStrParam(2,['d','u'],false,buttonmode) then exit;
  case AAuf.nargs[3].pre of
    '"':begin
          if not AAuf.TryArgToString(3,str) then exit;
          if length(str) <> 1 then begin
            AufScpt.send_error('警告：指令第3参数不是字符或数字，代码未执行！');
            exit;
          end;
          key:=form_adapter.SynToKey(str[1]);
        end;
    else if not AAuf.TryArgToByte(3,key) then exit;
  end;

  if key in [18,164,165] then alt_offset:=4
  else alt_offset:=0;
  case buttonmode of
    'd','D':msg:=WM_KeyDown+alt_offset;
    'u','U':msg:=WM_KeyUp+alt_offset;
  end;
  wparam:=key;
  lparam:=(key shl 16) + 1;
  SendMessage(hd,msg,wparam,lparam);
end;

procedure _KeyPress(Sender:TObject);
var hd,key,delay:longint;
    AAuf:TAuf;
    AufScpt:TAufScript;
    alt_offset:byte;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(4) then exit;
  if not AAuf.TryArgToLong(1,hd) then exit;
  case AAuf.nargs[2].pre of
    '"':key:=ord(AAuf.nargs[2].arg[1]);
    else if not AAuf.TryArgToLong(2,key) then exit;
  end;
  if key in [18,164,165] then alt_offset:=4
  else alt_offset:=0;
  if not AAuf.TryArgToLong(3,delay) then exit;
  if delay=0 then delay:=50;
  PostMessage(hd,WM_KeyDown+alt_offset,key,{(key shl 32)+}1);
  process_sleep(delay);
  PostMessage(hd,WM_KeyUp+alt_offset,key,{(key shl 32)+}1);

end;

procedure _Mouse(Sender:TObject);//mouse @w,"L/M/R"+"D/U/B",x,y
var hd,msg,wparam,lparam:longint;
    x,y:dword;
    AAuf:TAuf;
    AufScpt:TAufScript;
    buttonmode:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(5) then exit;
  if not AAuf.TryArgToLong(1,hd) then exit;
  if not AAuf.TryArgToStrParam(2,['ld','md','rd','lu','mu','ru','lb','mb','rb'],false,buttonmode) then exit;
  if not AAuf.TryArgToDWord(3,x) then exit;
  if not AAuf.TryArgToDWord(4,y) then exit;
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
  end;
  wparam:=0;
  lparam:=(y shl 16) + x;
  SendMessage(hd,msg,wparam,lparam);
end;

procedure _MouseClk(Sender:TObject);//mouseclk @w,"L/M/R",x,y,delay
var hd,msg,wparam,lparam:longint;
    x,y,delay:dword;
    AAuf:TAuf;
    AufScpt:TAufScript;
    buttonmode:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(6) then exit;
  if not AAuf.TryArgToLong(1,hd) then exit;
  if not AAuf.TryArgToStrParam(2,['l','m','r'],false,buttonmode) then exit;
  if not AAuf.TryArgToDWord(3,x) then exit;
  if not AAuf.TryArgToDWord(4,y) then exit;
  if not AAuf.TryArgToDWord(5,delay) then exit;
  if delay=0 then delay:=50;
  case lowercase(buttonmode) of
    'l':msg:=WM_LButtonDown;
    'm':msg:=WM_MButtonDown;
    'r':msg:=WM_RButtonDown;
  end;
  wparam:=0;
  lparam:=(y shl 16) + x;
  SendMessage(hd,msg,wparam,lparam);
  process_sleep(delay);
  SendMessage(hd,msg+1,wparam,lparam);

end;

procedure _MouseMov(Sender:TObject);//mousemove @w,"LRCSM12",x,y
var hd,msg,wparam,lparam:longint;
    x,y:dword;
    AAuf:TAuf;
    AufScpt:TAufScript;
    buttonmode:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(5) then exit;
  if not AAuf.TryArgToLong(1,hd) then exit;
  if not AAuf.TryArgToString(2,buttonmode) then exit;
  if not AAuf.TryArgToDWord(3,x) then exit;
  if not AAuf.TryArgToDWord(4,y) then exit;
  buttonmode:=lowercase(buttonmode);
  wparam:=0;
  msg:=WM_MOUSEMOVE;
  if pos('l',buttonmode)>0 then wparam:=wparam or $01;
  if pos('r',buttonmode)>0 then wparam:=wparam or $02;
  if pos('s',buttonmode)>0 then wparam:=wparam or $04;
  if pos('c',buttonmode)>0 then wparam:=wparam or $08;
  if pos('m',buttonmode)>0 then wparam:=wparam or $10;
  if pos('1',buttonmode)>0 then wparam:=wparam or $20;
  if pos('2',buttonmode)>0 then wparam:=wparam or $40;
  lparam:=(y shl 16) + x;
  SendMessage(hd,msg,wparam,lparam);
end;

procedure _MouseWheel(Sender:TObject);//mousewheel @w,wheel_delta,"LRCSM12",x,y
var hd,msg,wparam,lparam,wheeldelta:longint;
    x,y:dword;
    AAuf:TAuf;
    AufScpt:TAufScript;
    buttonmode:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(6) then exit;
  if not AAuf.TryArgToLong(1,hd) then exit;
  if not AAuf.TryArgToLong(2,wheeldelta) then exit;
  if not AAuf.TryArgToString(3,buttonmode) then exit;
  if not AAuf.TryArgToDWord(4,x) then exit;
  if not AAuf.TryArgToDWord(5,y) then exit;
  buttonmode:=lowercase(buttonmode);
  wparam:=0;
  msg:=WM_MOUSEWHEEL;
  if pos('l',buttonmode)>0 then wparam:=wparam or $01;
  if pos('r',buttonmode)>0 then wparam:=wparam or $02;
  if pos('s',buttonmode)>0 then wparam:=wparam or $04;
  if pos('c',buttonmode)>0 then wparam:=wparam or $08;
  if pos('m',buttonmode)>0 then wparam:=wparam or $10;
  if pos('1',buttonmode)>0 then wparam:=wparam or $20;
  if pos('2',buttonmode)>0 then wparam:=wparam or $40;
  wparam:=(wheeldelta mod 65536) shl 16 + wparam;
  lparam:=(y shl 16) + x;
  SendMessage(hd,msg,wparam,lparam);
end;

function FunningColorExchange(ori:dword):dword;//  ABCD -> CBAD
var arr:array[0..3]of byte;
    tmp:byte;
    ptr:pbyte;
begin
  ptr:=@arr;
  pdword(ptr)^:=ori;
  tmp:=arr[2];
  arr[2]:=arr[0];
  arr[0]:=tmp;
  result:=pdword(ptr)^;
end;

procedure _GetPixel(Sender:TObject);//getpixel hwnd,col,row,@var
var hd:longint;
    x,y,res:dword;
    tmp:TAufRamVar;
    AAuf:TAuf;
    AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(5) then exit;
  if not AAuf.TryArgToLong(1,hd) then exit;
  if hd=0 then begin     AufScpt.send_error('警告：窗体句柄无效，代码未执行！');exit end;
  hd:=GetDC(hd);
  if hd=0 then begin     AufScpt.send_error('警告：窗体句柄无对应HDC，代码未执行！');exit end;
  if not AAuf.TryArgToDWord(2,x) then exit;
  if not AAuf.TryArgToDWord(3,y) then exit;
  if not AAuf.TryArgToARV(4,4,High(dword),[ARV_FixNum],tmp) then exit;
  res:=FunningColorExchange(GetPixel(hd,x,y));
  dword_to_arv(res,tmp);
end;

procedure _GetPixelRect(Sender:TObject);//getrect hwnd,x1,x2,y1,y2,@var
var hd:longint;
    x1,x2,y1,y2,x,y,px,py:dword;
    img_size:dword;
    tmp:TAufRamVar;
    AAuf:TAuf;
    AufScpt:TAufScript;
    BDBitmapData:TBDBitmapData;
    tp,mp:dword;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(7) then exit;
  if not AAuf.TryArgToLong(1,hd) then exit;
  if hd=0 then begin     AufScpt.send_error('警告：窗体句柄无效，代码未执行！');exit end;
  if not AAuf.TryArgToDWord(2,x1) then exit;
  if not AAuf.TryArgToDWord(3,x2) then exit;
  if not AAuf.TryArgToDWord(4,y1) then exit;
  if not AAuf.TryArgToDWord(5,y2) then exit;
  if (x2<x1) or (y2<y1) then begin AufScpt.send_error('警告：未选中任何一个像素，代码未执行！');exit end;
  img_size:=(x2-x1+1)*(y2-y1+1);
  if not AAuf.TryArgToARV(6,img_size*4,img_size*4,[ARV_FixNum],tmp) then exit;
  BDBitmapData:=TBDBitmapData.Create;
  try
    BDBitmapData.CopyFormScreen(hd,x1,y1,x2-x1+1,y2-y1+1);
    px:=BDBitmapData.Width;
    py:=BDBitmapData.Height;
    for y:=y1 to y2 do
      for x:=x1 to x2 do
        begin
          tp:=4*((x2-x1+1)*(y-y1)+(x-x1));
          mp:=3*(px*(py-(y-y1)-1)+(x-x1));
          pbyte(tmp.Head+tp)^:=(pbyte(BDBitmapData.Bits+mp))^;
          pbyte(tmp.Head+tp+1)^:=(pbyte(BDBitmapData.Bits+mp+1))^;
          pbyte(tmp.Head+tp+2)^:=(pbyte(BDBitmapData.Bits+mp+2))^;
          pbyte(tmp.Head+tp+3)^:=$ff;
        end;
  finally
    BDBitmapData.Free;
  end;
end;

procedure _RamImage(Sender:TObject);//ramimg col,row,@var
var x,y:dword;
    pos,pot:longint;
    dit:pbyte;
    tmp:TAufRamVar;
    AAuf:TAuf;
    AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(4) then exit;
  if not AAuf.TryArgToDWord(1,x) then exit;
  if not AAuf.TryArgToDWord(2,y) then exit;
  if not AAuf.TryArgToARV(3,x*y*4,x*y*4,[ARV_FixNum,ARV_Float,ARV_Char],tmp) then exit;
  Form_Routiner.Image_Ram.Picture.Free;
  Form_Routiner.Image_Ram.Picture:=TPicture.Create;
  Form_Routiner.Image_Ram.Picture.BitMap.PixelFormat:=pf32bit;
  Form_Routiner.Image_Ram.Picture.Bitmap.SetSize(x,y);
  CopyMemory(Form_Routiner.Image_Ram.Picture.Bitmap.ScanLine[0],tmp.Head,tmp.size);

  Form_Routiner.Image_Ram.Picture.Bitmap.SaveToFile('ram.bmp');
  Form_Routiner.Image_Ram.Refresh;
  Form_Routiner.ScrollBox_SynchronicResize(Form_Routiner.ScrollBox_Synchronic);
  Form_Routiner.ScrollBox_WndListResize(Form_Routiner.ScrollBox_Synchronic);
  Form_Routiner.ScrollBox_WndListResize(Form_Routiner.ScrollBox_WndList);
  Form_Routiner.ScrollBox_RecOptionResize(Form_Routiner.ScrollBox_RecOption);

end;


procedure _ARI_GetRect(Sender:TObject);//ari.get hwnd,@img[,x,y,w,h]
var hd:longint;
    info:tagWINDOWINFO;
    mem:TMemoryStream;
    dpiScaling:double;
    xx,yy,ww,hh:dword;
    tmp:TAufRamVar;
    AAuf:TAuf;
    AufScpt:TAufScript;
    BDBitmapData:TBDBitmapData;
    procedure GetWindowRect;
    begin
      xx:=0;
      yy:=0;
      GetWindowInfo(hd,info);
      ww:=round(info.rcWindow.Width*dpiScaling);
      hh:=round(info.rcWindow.Height*dpiScaling);
    end;

begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToLong(1,hd) then exit;
  if hd=0 then begin AufScpt.send_error('警告：窗体句柄无效，代码未执行！');exit end;
  if not AAuf.TryArgToARV(2,8,8,[ARV_FixNum],tmp) then exit;
  dpiScaling:=GetDPIScaling;
  if AAuf.ArgsCount>3 then begin
    if not AAuf.TryArgToDWord(3,xx) then exit;
    if not AAuf.TryArgToDWord(4,yy) then exit;
    if not AAuf.TryArgToDWord(5,ww) then exit;
    if not AAuf.TryArgToDWord(6,hh) then exit;
    xx:=round(xx*dpiScaling);
    yy:=round(yy*dpiScaling);
    ww:=round(ww*dpiScaling);
    hh:=round(hh*dpiScaling);
    if ww*hh=0 then GetWindowRect;
  end else GetWindowRect;

  BDBitmapData:=TBDBitmapData.Create;
  mem:=TMemoryStream.Create;
  try
    BDBitmapData.CopyFormScreen(hd,xx,yy,ww,hh);
    BDBitmapData.SaveToStream(mem);
    mem.Position:=0;
    (arv_to_obj(tmp) as TARImage).LoadFromStream(mem);
  finally
    BDBitmapData.Free;
    mem.Free;
  end;
end;

procedure _ARI_Display(Sender:TObject);//ari.dsp @img -u/-d
var ww,hh:word;
    tmp:TAufRamVar;
    AAuf:TAuf;
    AufScpt:TAufScript;
    mode:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  AAuf.TryArgToARV(1,8,8,[ARV_FixNum],tmp);
  if not (arv_to_obj(tmp) is TARImage) then begin
    AufScpt.send_error('ARI图像无效。');
    exit;
  end;
  with (arv_to_obj(tmp) as TARImage).FPicture do begin
    ww:=Width;
    hh:=Height;
  end;
  if hh*ww=0 then begin
    AufScpt.send_error('ARI图像为空图。');
    exit;
  end;

  if AAuf.ArgsCount>2 then begin
    if not AAuf.TryArgToStrParam(2,['-d','-u'],false,mode) then exit;
  end else mode:='-u';

  Form_Routiner.Image_Ram.Picture.Free;
  Form_Routiner.Image_Ram.Picture:=TPicture.Create;
  Form_Routiner.Image_Ram.Picture.BitMap.PixelFormat:=pf32bit;
  Form_Routiner.Image_Ram.Picture.Bitmap.SetSize(ww,hh);
  Form_Routiner.Image_Ram.Picture.Bitmap.Assign((arv_to_obj(tmp) as TARImage).FPicture.Bitmap);
  Form_Routiner.Image_Ram.Refresh;
  case lowercase(mode) of
    '-d':with Form_Routiner.ScrollBox_ImageViewScroll.VertScrollBar do Position:=Range-1;
    else ;
  end;
  Form_Routiner.ScrollBox_SynchronicResize(Form_Routiner.ScrollBox_Synchronic);
  Form_Routiner.ScrollBox_WndListResize(Form_Routiner.ScrollBox_Synchronic);
  Form_Routiner.ScrollBox_WndListResize(Form_Routiner.ScrollBox_WndList);
  Form_Routiner.ScrollBox_RecOptionResize(Form_Routiner.ScrollBox_RecOption);

end;

procedure Routiner_Setting(Sender:TObject);
var AufScpt:TAufScript;
    AAuf:TAuf;
    fo,ww,hh,tt,ll:longint;
    s1,s2:string;
    slst:TStringList;
    pf:TForm;
    branch,option:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.TryArgToStrParam(1,
  ['title','version','axis','form','layout','customer_layout','aufbutton',
  'holdbutton','action_setting','wndlist','shortcut','shortcut_command'],
  false,branch) then exit;
  case lowercase(branch) of
    'title':;//do nothing
    'version':;//do nothing
    'axis':
      begin
        if AAuf.ArgsCount<4 then begin
          AufScpt.send_error('set Axis需要3个参数，未成功设置！');exit
        end;
        if not AAuf.TryArgToStrParam(2,['mainv=','syncv=','buttonv=','lefth=','righth=','rech=','codev='],false,option) then exit;
        case lowercase(option) of
          'mainv=':
            begin
              try Form_Routiner.Splitter_MainV.Left:=StrToInt(AAuf.nargs[3].arg);
              except AufScpt.send_error('参数错误，未成功设置！');end;
            end;
          'syncv=':
            begin
              try Form_Routiner.Splitter_SyncV.Left:=StrToInt(AAuf.nargs[3].arg);
              except AufScpt.send_error('参数错误，未成功设置！');end;
            end;
          'buttonv=':
            begin
              try Form_Routiner.Splitter_ButtonV.Left:=StrToInt(AAuf.nargs[3].arg);
              except AufScpt.send_error('参数错误，未成功设置！');end;
            end;
          'lefth=':
            begin
              try Form_Routiner.Splitter_LeftH.Top:=StrToInt(AAuf.nargs[3].arg);
              except AufScpt.send_error('参数错误，未成功设置！');end;
            end;
          'righth=':
            begin
              try Form_Routiner.Splitter_RightH.Top:=StrToInt(AAuf.nargs[3].arg);
              except AufScpt.send_error('参数错误，未成功设置！');end;
            end;
          'rech=':
            begin
              try Form_Routiner.Splitter_RecH.Top:=StrToInt(AAuf.nargs[3].arg);
              except AufScpt.send_error('参数错误，未成功设置！');end;
            end;
          'codev=':
            begin
              try
                if AAuf.ArgsCount<5 then
                  fo:=-1
                else
                  fo:=StrToInt(AAuf.nargs[4].arg);
                if (fo<0) or (fo>RuleCount) then fo:=Form_Routiner.PageControl.PageIndex;
                Form_Routiner.AufScriptFrames[fo].Frame.TrackBar.Position:=StrToInt(AAuf.nargs[3].arg);
              except AufScpt.send_error('参数错误，未成功设置！');end;
            end;
        end;
      end;
    'form':
      begin
        if AAuf.ArgsCount<7 then begin
          AufScpt.send_error('set Form需要6个参数，未成功设置！');exit
        end;
        try
          fo:=StrToInt(AAuf.nargs[2].arg);
          tt:=StrToInt(AAuf.nargs[3].arg);
          ll:=StrToInt(AAuf.nargs[4].arg);
          ww:=StrToInt(AAuf.nargs[5].arg);
          hh:=StrToInt(AAuf.nargs[6].arg);
        except
          AufScpt.send_error('set Form之后的参数需要是数字，未设置成功。');exit
        end;
        case fo of
          1:pf:=Form_Routiner;
          2:pf:=AufButtonForm;
          3:pf:=SettingLagForm;
          4:pf:=ManualForm;
          5:pf:=FormRunPerformance;
          6:pf:=Form_HoldButtonSetting;
          else begin AufScpt.send_error('未找到指定窗口，未设置成功。');exit end;
        end;
        with pf do
          begin
            Top:=tt;
            Left:=ll;
            Width:=ww;
            Height:=hh;
          end;
      end;
    'layout':
      begin
        if AAuf.ArgsCount<3 then begin
          AufScpt.send_error('set Layout需要2个参数，未成功设置！');exit
        end;
        try fo:=StrToInt(AAuf.nargs[2].arg);
        except AufScpt.send_error('set Layout之后的参数需要是数字，未设置成功。');exit end;
        Form_Routiner.Layout.LayoutCode:=TLayoutSet(fo);
        Form_Routiner.SetLayout(byte(Form_Routiner.Layout.LayoutCode));
        Form_Routiner.FormResize(Form_Routiner);
      end;
    'customer_layout':
      begin
        if AAuf.ArgsCount<10 then begin
          AufScpt.send_error('set Customer_Layout需要9个参数，未成功设置！');exit
        end;
        try
          Form_Routiner.Layout.customer_layout.Width:=StrToInt(AAuf.nargs[2].arg);
          Form_Routiner.Layout.customer_layout.Height:=StrToInt(AAuf.nargs[3].arg);
          Form_Routiner.Layout.customer_layout.MainV:=StrToInt(AAuf.nargs[4].arg);
          Form_Routiner.Layout.customer_layout.SyncV:=StrToInt(AAuf.nargs[5].arg);
          Form_Routiner.Layout.customer_layout.ButtV:=StrToInt(AAuf.nargs[6].arg);
          Form_Routiner.Layout.customer_layout.LeftH:=StrToInt(AAuf.nargs[7].arg);
          Form_Routiner.Layout.customer_layout.RightH:=StrToInt(AAuf.nargs[8].arg);
          Form_Routiner.Layout.customer_layout.RecH:=StrToInt(AAuf.nargs[9].arg);
        except
          AufScpt.send_error('参数存在错误，未完全完成设置！')
        end;
      end;
    'aufbutton':
      begin
        if AAuf.ArgsCount<7 then begin
          AufScpt.send_error('set AufButton需要6个参数，未成功设置！');exit
        end;
        try
          {winID}ww:=StrToInt(AAuf.nargs[2].arg);
          {colID}hh:=StrToInt(AAuf.nargs[3].arg);
          {winIndex}ll:=StrToInt(AAuf.nargs[5].arg);
          if (ww>SynCount) or (ww<0) then raise Exception.Create('SynCount');
          if (ll>SynCount) or (ll<0) then raise Exception.Create('WinIndex');
          if (hh>ButtonColumn) or (hh<0) then raise Exception.Create('ButtonColumn');
        except
          AufScpt.send_error('参数存在错误，未完成设置！');exit
        end;
        Form_Routiner.AufButtons[ww,hh].Caption:=AAuf.nargs[4].arg;
        Form_Routiner.AufButtons[ww,hh].ScriptFile.CommaText:=AAuf.nargs[6].arg;
        Form_Routiner.AufButtons[ww,hh].WindowIndex:=ll;
      end;
    'holdbutton':
      begin
        if AAuf.ArgsCount<8 then begin
          AufScpt.send_error('set HoldButton需要7个参数，未成功设置！');exit
        end;
        try
          {ID}fo:=StrToInt(AAuf.nargs[2].arg);
          {key1}tt:=StrToInt(AAuf.nargs[4].arg);
          {key2}ll:=StrToInt(AAuf.nargs[5].arg);
          {key3}ww:=StrToInt(AAuf.nargs[6].arg);
          {last}hh:=StrToInt(AAuf.nargs[7].arg);
          if (fo>31) or (fo<0) then raise Exception.Create('HoldButton');
          if (tt>255) or (tt<0) then raise Exception.Create('key1');
          if (ll>255) or (ll<0) then raise Exception.Create('key2');
          if (ww>255) or (ww<0) then raise Exception.Create('key3');
          if (hh>255) or (hh<0) then raise Exception.Create('last');
        except
          AufScpt.send_error('参数存在错误，未完成设置！');exit
        end;
        Form_Routiner.HoldButtons[fo].Caption:=AAuf.nargs[3].arg;
        Form_Routiner.HoldButtons[fo].keymessage[0]:=tt;
        Form_Routiner.HoldButtons[fo].keymessage[1]:=ll;
        Form_Routiner.HoldButtons[fo].keymessage[2]:=ww;
        Form_Routiner.HoldButtons[fo].keymessage[3]:=hh;
      end;
    'action_setting':
      begin
        if AAuf.ArgsCount<4 then begin
          AufScpt.send_error('set Action_Setting需要3个参数，未成功设置！');exit
        end;
        if not AAuf.TryArgToStrParam(2,['ab_act=','ab_adv=','ab_halt=','ab_opt=','hb_opt='],false,option) then exit;
        try
          case lowercase(option) of
            'ab_act=':MouseActCodeToMouseActSetting(AAuf.nargs[3].arg,Form_Routiner.Setting.AufButton.Act1,Form_Routiner.Setting.AufButton.Act2);
            'ab_adv=':MouseActCodeToMouseActSetting(AAuf.nargs[3].arg,Form_Routiner.Setting.AufButton.ExtraAct1,Form_Routiner.Setting.AufButton.ExtraAct2);
            'ab_halt=':MouseActCodeToMouseActSetting(AAuf.nargs[3].arg,Form_Routiner.Setting.AufButton.Halt1,Form_Routiner.Setting.AufButton.Halt2);
            'ab_opt=':MouseActCodeToMouseActSetting(AAuf.nargs[3].arg,Form_Routiner.Setting.AufButton.Setting1,Form_Routiner.Setting.AufButton.Setting2);
            'hb_opt=':MouseActCodeToMouseActSetting(AAuf.nargs[3].arg,Form_Routiner.Setting.HoldButton.Setting1,Form_Routiner.Setting.HoldButton.Setting2);
          end;
        except
          AufScpt.send_error('参数只能包含LMR12CSA几个字符，未完成设置！');exit
        end;
      end;
    'wndlist':
      begin
        if AAuf.ArgsCount<4 then begin
          AufScpt.send_error('set Wndlist需要3个参数，未成功设置！');exit
        end;
        if not AAuf.TryArgToStrParam(2,['pos=','hwnd=','name=','class=','namecell=','aligncell='],false,option) then exit;
        try
          with Form_Routiner.Setting.WndListShowingOption do begin
            case lowercase(AAuf.nargs[2].arg) of
              'pos=':case lowercase(AAuf.nargs[3].arg) of 'true','t','on','y','yes':PositionVisible:=true; else PositionVisible:=false;end;
              'hwnd=':case lowercase(AAuf.nargs[3].arg) of 'true','t','on','y','yes':HwndVisible:=true; else HwndVisible:=false;end;
              'name=':case lowercase(AAuf.nargs[3].arg) of 'true','t','on','y','yes':WndNameVisible:=true; else WndNameVisible:=false;end;
              'class=':case lowercase(AAuf.nargs[3].arg) of 'true','t','on','y','yes':ClassNameVisible:=true; else ClassNameVisible:=false;end;
              'namecell=':try NameCell:=StrToInt(AAuf.nargs[3].arg) mod 256 except AufScpt.send_error('namecell 需要数字参数') end;
              'aligncell=':try AlignCell:=StrToInt(AAuf.nargs[3].arg) mod 256 except AufScpt.send_error('aligncell 需要数字参数') end;
            end;
          end;
        except
          AufScpt.send_error('参数只能包含LMR12CSA几个字符，未完成设置！');exit
        end;
      end;
    'shortcut':
      begin
        if AAuf.ArgsCount<4 then begin
          AufScpt.send_error('set Shortcut需要3个参数，未成功设置！');exit
        end;
        try fo:=AufScpt.TryToDWord(AAuf.nargs[3]);
        except AufScpt.send_error('第2个参数需要是整数，未成功设置！');exit;end;
        if not AAuf.TryArgToStrParam(2,['mode=','startkey=','endkey=','downupkey='],false,option) then exit;
        case lowercase(option) of
          'mode=':
            if (fo<0) or (fo>3) then AufScpt.send_error('第3个参数无效，未成功设置！')
            else AdapterForm.Option.Shortcut.Mode:=TShortcutMode(fo);
          'startkey=':
            if (fo<0) or (fo>255) then AufScpt.send_error('第3个参数无效，未成功设置！')
            else AdapterForm.Option.Shortcut.StartKey:=fo;
          'endkey=':
            if (fo<0) or (fo>255) then AufScpt.send_error('第3个参数无效，未成功设置！')
            else AdapterForm.Option.Shortcut.EndKey:=fo;
          'downupkey=':
            if (fo<0) or (fo>255) then AufScpt.send_error('第3个参数无效，未成功设置！')
            else AdapterForm.Option.Shortcut.DownUpKey:=fo;
          else AufScpt.send_error('Action_Setting之后需要使用Mode=,StartKey=,EndKey=,DownUpKey=进行设置。');exit    ;
        end
      end;
    'shortcut_command':
      begin
        if AAuf.ArgsCount<5 then begin AufScpt.send_error('set Shortcut_Command需要4个参数，未成功设置！');exit;end;
        try
          fo:=AufScpt.TryToDWord(AAuf.nargs[2]);
          if (fo<0) or (fo>ShortcutCount) then raise Exception.Create('');
        except
          AufScpt.send_error('第2个参数需要在0-'+IntToStr(ShortcutCount)+'范围内，未成功设置！');
          exit;
        end;

        try s1:=AufScpt.TryToString(AAuf.nargs[3]);
        except AufScpt.send_error('第3个参数转换为字符串失败，未成功设置！');exit
        end;

        try s2:=AufScpt.TryToString(AAuf.nargs[4]);
        except AufScpt.send_error('第4个参数转换为字符串失败，未成功设置！');exit
        end;

        s2:=StringReplace(s2,'%Q','"',[rfReplaceAll]);
        //AdapterForm.Option.Shortcut.ScriptFiles[fo].command:=s1;
        //AdapterForm.Option.Shortcut.ScriptFiles[fo].filename:=s2;
        if (s1<>'') and (s2<>'') then begin
          slst:=TStringList.Create;
          slst.Add(s2);
          AdapterForm.Option.Shortcut.CommandList.AddObject(s1,TObject(slst));
        end;
      end;
    //
    else AufScpt.send_error('未知的命令行设置项，未成功设置！');
  end;
end;

procedure CostumerFuncInitialize(AAuf:TAuf);
begin
  AAuf.Script.add_func('about,软件信息',@print_version,'','版本信息');
  AAuf.Script.add_func('string,发送字符串',@SendString,'hwnd,str','向窗口输入字符串');
  AAuf.Script.add_func('clipbd,修改剪贴板',@ClipBoardString,'hwnd,str','向窗口输入字符串');
  AAuf.Script.add_func('keybd,键盘动作',@_KeyBd,'hwnd,"U/D",key|"char"','向hwnd窗口发送一个键盘消息');
  AAuf.Script.add_func('mouse,鼠标动作',@_Mouse,'hwnd,"L/M/R"+"U/D/B",x,y','向hwnd窗口发送一个鼠标消息');
  AAuf.Script.add_func('keypress,键盘按键',@_KeyPress,'hwnd,key|"char",deley','向hwnd窗口发送一对间隔delay毫秒的按键消息');
  AAuf.Script.add_func('mouseclk,鼠标按键',@_MouseClk,'hwnd,"L/M/R",x,y,delay','向hwnd窗口发送一对间隔delay毫秒的鼠标消息');
  AAuf.Script.add_func('mousemov,鼠标移动',@_MouseMov,'hwnd,"LRSCM12",x,y','向hwnd窗口发送鼠标坐标更新的消息');
  AAuf.Script.add_func('mousewhl,鼠标滚轮',@_MouseWheel,'hwnd,delta,"LRSCM12",x,y','向hwnd窗口发送鼠标滚轮的消息，delta推荐值为±120');
  AAuf.Script.add_func('post,发送消息',@PostM,'hwnd,msg,w,l','调用Postmessage');
  AAuf.Script.add_func('send,发送消息并等待处理',@SendM,'hwnd,msg,w,l','调用Sendmessage');

  AAuf.Script.add_func('getwnd_v,按名称返回句柄',@getwind_name_visible,'@hwnd,wnd_name','查找名称为wnd_name且可见的窗体句柄');
  AAuf.Script.add_func('getwnd_t,返回置顶窗体',@getwind_top,'@hwnd','返回当前置顶窗体句柄');
  AAuf.Script.add_func('getwnd_s,窗体尺寸信息',@getwind_size,'hwnd,@x,@y,@w,@h','返回指定窗体的尺寸信息');
  AAuf.Script.add_func('wndlist.update,刷新窗体列表',@wndlist_update,'filter,"on/off"','刷新窗体列表，filter为筛选字符串，第2参数规定是否使用正则表达式');
  AAuf.Script.add_func('wndlist.find,递归新窗体查找',@wndlist_find,'filter,"on/off"','查找符合条件的递归窗体，filter为筛选字符串，第2参数规定是否使用正则表达式');

  AAuf.Script.add_func('wndnew.init,查找新窗体初始化',@wndlist_new_init,'','将当前WndList保存用于新窗体查找');
  AAuf.Script.add_func('wndnew.update,计算新窗体',@wndlist_new_update,'hwnd,filter,"on/off"[,-show]','获取新窗体列表，filter为筛选字符串，第2参数规定是否使用正则表达式。带-show参数时打印符合要求的窗体');
  AAuf.Script.add_func('wndnew.pop,获取新窗体',@wndlist_new_pop,'@hwnd','从新窗体列表中获取一个句柄并删除');
  AAuf.Script.add_func('wndnew.empty?,判断是否没有新窗体',@wndlist_new_empty,':label','从新窗体列表中获取一个句柄并删除');

  AAuf.Script.add_func('getpixel,获取像素点',@_GetPixel,'hwnd,x,y,out_var','返回窗体指定像素点颜色');
  AAuf.Script.add_func('getrect,获取画面',@_GetPixelRect,'hwnd,x1,x2,y1,y2,out_var','返回窗体指定矩形范围内像素点颜色');
  AAuf.Script.add_func('ramimg,显示画面',@_RamImage,'col,row,in_var','根据内存变量显示图片');
  AAuf.Script.add_func('ari.get,获取画面ARI',@_ARI_GetRect,'hwnd,@img[,x,y,w,h]','读取窗体画面并保存到ARI图像中');
  AAuf.Script.add_func('ari.dsp,显示画面ARI',@_ARI_Display,'@img','从ARI图像中显示图片');

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
  GlobalExpressionList.TryAddExp('k_numlk',narg('','144',''));
  GlobalExpressionList.TryAddExp('k_lshift',narg('','160',''));
  GlobalExpressionList.TryAddExp('k_rshift',narg('','161',''));
  GlobalExpressionList.TryAddExp('k_lctrl',narg('','162',''));
  GlobalExpressionList.TryAddExp('k_rctrl',narg('','163',''));
  GlobalExpressionList.TryAddExp('k_lalt',narg('','164',''));
  GlobalExpressionList.TryAddExp('k_ralt',narg('','165',''));
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
end;

procedure TTimerLag.OnSend(Sender:TObject);
var tim:TTimerlag;
begin
  tim:=Sender as TTimerLag;
  Self.Enabled:=false;
  with tim.next_message do PostMessage(hwnd,msg,wparam,lparam);
end;

procedure TAufScriptFrame.POnChangeTitle(Sender:TObject;str:string);
begin
  (Self.Frame.Parent as TTabSheet).Caption:=str;
  Application.ProcessMessages;
end;

{ TWindow }

constructor TWindow.Create(_hd:HWND;_name,_classname:string;_Left,_Top,_Width,_Height:word);
begin
  inherited Create;
  info.hd:=_hd;
  info.name:=_name;
  info.classname:=_classname;
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
  SetCallHandleM(AdapterForm.Handle);
  if not StartHookM(WM_USER+MessageOffset) then
  begin
    ShowMessage('挂钩失败！');
  end else begin
    SetTrackMouseMoveM(1);
    Self.MouseHookEnabled:=true;
    Self.StatusBar.Panels.Items[2].Text:='鼠标';
    FormRunPerformance.CheckGroup_HookEnabled.Checked[1]:=true;
  end;
end;
procedure TForm_Routiner.MouseUnHook;
begin
  if Self.MouseHookEnabled = false then exit;
  StopHookM;
  Self.MouseHookEnabled:=false;
  Self.StatusBar.Panels.Items[2].Text:='';
  FormRunPerformance.CheckGroup_HookEnabled.Checked[1]:=false;
end;
procedure TForm_Routiner.KeybdHook;
begin
  if Self.KeybdHookEnabled = true then exit;
  SetCallHandleK(AdapterForm.Handle);
  if not StartHookK(WM_USER+MessageOffset) then
  begin
    ShowMessage('挂钩失败！');
  end else begin
    Self.KeybdHookEnabled:=true;
    Self.StatusBar.Panels.Items[1].Text:='键盘';
    FormRunPerformance.CheckGroup_HookEnabled.Checked[0]:=true;
  end;
end;
procedure TForm_Routiner.KeybdUnHook;
begin
  if Self.KeybdHookEnabled = false then exit;
  StopHookK;
  Self.KeybdHookEnabled:=false;
  Self.StatusBar.Panels.Items[1].Text:='';
  FormRunPerformance.CheckGroup_HookEnabled.Checked[0]:=false;
end;
procedure TForm_Routiner.KeybdBlockOn;
begin
  BlockMsgOnK;
end;
procedure TForm_Routiner.KeybdBlockOff;
begin
  BlockMsgOffK;
end;

procedure TForm_Routiner.ShortcutAufCommand(str:TStrings);
var pi:integer;
begin
  pi:=0;
  while pi<=ShortcutCount do
    begin
      if Self.SCAufs[pi].Script.PSW.haltoff then
        begin
          Self.SCAufs[pi].Script.command(str);
          exit;
        end;
      inc(pi);
    end;
  ShowMessage('快捷键线程池已满(>'+IntToStr(ShortcutCount+1)+')，新动作未开始执行。');
end;

procedure TForm_Routiner.ShortcutAufClear;
var pi:integer;
begin
  for pi:=0 to ShortcutCount do
    if not Self.SCAufs[pi].Script.PSW.haltoff then
        Self.SCAufs[pi].Script.Stop;
end;

{$define ByteModeRec}
{$define CodeModeRec}

procedure TForm_Routiner.SaveOption;
var sav:TMemoryStream;
    sat:text;
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
  {$ifdef ByteModeRec}
  sav:=TmemoryStream.Create;
  sav.Size:=$40000;
  sav.Position:=0;
  for taddr:=0 to $3FFFF do sav.WriteByte(0);
  {$endif}
  {$ifdef CodeModeRec}
  assignfile(sat,'option.auf.lay');
  rewrite(sat);
  {$endif}

  {$ifdef ByteModeRec}
  rec_str(0,'Apiglio MR'+version_number);
  rec_byte(24,longint(Self.Layout.LayoutCode));
  rec_byte(12288+0,$80);
  rec_byte(12288+1,$80);
  rec_byte(12288+2,$80);
  rec_byte(12288+3,$80);
  rec_byte(12288+4,$80);
  rec_byte(12288+5,$80);
  {$endif}
  {$ifdef CodeModeRec}
  writeln(sat,'set Title '+'"Apiglio MR"');
  writeln(sat,'set Version '+'"'+version_number+'"');
  writeln(sat,'set Layout '+IntToStr(longint(Self.Layout.LayoutCode)));
  {$endif}

  forms[1]:=Self;
  forms[2]:=AufButtonForm;
  forms[3]:=SettingLagForm;
  forms[4]:=ManualForm;
  forms[5]:=FormRunPerformance;
  forms[6]:=Form_HoldButtonSetting;
  FOR fo:=1 TO 6 DO BEGIN
    {$ifdef ByteModeRec}
    rec_long(32*fo,forms[fo].Top);
    rec_long(32*fo+4,forms[fo].Left);
    rec_long(32*fo+8,forms[fo].Width);
    rec_long(32*fo+12,forms[fo].Height);
    {$endif}
    {$ifdef CodeModeRec}
    writeln(sat,'set Form '+IntToStr(fo)
    +' '+IntToStr(forms[fo].Top)
    +','+IntToStr(forms[fo].Left)
    +','+IntToStr(forms[fo].Width)
    +','+IntToStr(forms[fo].Height)
    );
    {$endif}
  END;

  {$ifdef ByteModeRec}
  rec_long(12288+128+0,Self.Splitter_MainV.Left);
  rec_long(12288+128+4,Self.Splitter_SyncV.Left);
  rec_long(12288+128+8,Self.Splitter_ButtonV.Left);
  rec_long(12288+128+12,Self.Splitter_LeftH.Top);
  rec_long(12288+128+16,Self.Splitter_RightH.Top);
  rec_long(12288+128+20,Self.Splitter_RecH.Top);
  rec_long(12288+32+6*4,Self.Layout.customer_layout.Width);
  rec_long(12288+32+7*4,Self.Layout.customer_layout.Height);
  rec_long(12288+32+0*4,Self.Layout.customer_layout.MainV);
  rec_long(12288+32+1*4,Self.Layout.customer_layout.SyncV);
  rec_long(12288+32+2*4,Self.Layout.customer_layout.ButtV);
  rec_long(12288+32+3*4,Self.Layout.customer_layout.LeftH);
  rec_long(12288+32+4*4,Self.Layout.customer_layout.RightH);
  rec_long(12288+32+5*4,Self.Layout.customer_layout.RecH);
  {$endif}
  {$ifdef CodeModeRec}
  writeln(sat,'set Axis '+'MainV= '+IntToStr(Self.Splitter_MainV.Left));
  writeln(sat,'set Axis '+'SyncV= '+IntToStr(Self.Splitter_SyncV.Left));
  writeln(sat,'set Axis '+'ButtonV= '+IntToStr(Self.Splitter_ButtonV.Left));
  writeln(sat,'set Axis '+'LeftH= '+IntToStr(Self.Splitter_LeftH.Top));
  writeln(sat,'set Axis '+'RightH= '+IntToStr(Self.Splitter_RightH.Top));
  writeln(sat,'set Axis '+'RecH= '+IntToStr(Self.Splitter_RecH.Top));
  writeln(sat,'set Customer_Layout '+IntToStr(Self.Layout.customer_layout.Width)
  +','+IntToStr(Self.Layout.customer_layout.Height)
  +','+IntToStr(Self.Layout.customer_layout.MainV)
  +','+IntToStr(Self.Layout.customer_layout.SyncV)
  +','+IntToStr(Self.Layout.customer_layout.ButtV)
  +','+IntToStr(Self.Layout.customer_layout.LeftH)
  +','+IntToStr(Self.Layout.customer_layout.RightH)
  +','+IntToStr(Self.Layout.customer_layout.RecH));

  {$endif}

  //窗口尺寸原本在这里

  for i:=0 to SynCount do
    for j:=0 to ButtonColumn do
      begin
        {$ifdef ByteModeRec}
        taddr:=512 + ((i*32)+j)*512;
        rec_str(taddr,Self.AufButtons[i,j].ScriptFile.CommaText);
        rec_str(taddr+256,Self.AufButtons[i,j].Caption);
        rec_long(taddr+508,Self.AufButtons[i,j].WindowIndex);
        if Self.AufButtons[i,j].WindowChangeable then rec_byte(1,taddr+507)
        else rec_byte(0,taddr+507);
        {$endif}
        {$ifdef CodeModeRec}
        writeln(sat,'set AufButton '+IntToStr(i)+','+IntToStr(j)+' "'
        +Self.AufButtons[i,j].Caption+'" '
        +IntToStr(Self.AufButtons[i,j].WindowIndex)
        +' "'+Self.AufButtons[i,j].ScriptFile.CommaText+'"');
        {$endif}
      end;

  for i:=0 to 31 do
    begin
      {$ifdef ByteModeRec}
      taddr:=256 + i*8;
      stmp:=utf8towincp(Self.HoldButtons[i].Caption);
      //messagebox(0,PChar(IntToStr(length(stmp))),'E',MB_OK);
      while length(stmp)<4 do stmp:=stmp+#0;
      for j:=0 to 3 do rec_byte(taddr+j,ord(stmp[j+1]));
      for j:=0 to 3 do rec_byte(taddr+4+j,Self.HoldButtons[i].keymessage[j]);
      {$endif}
      {$ifdef CodeModeRec}
      writeln(sat,'set HoldButton '+IntToStr(i)+' "'
      +{utf8towincp}PChar(Self.HoldButtons[i].Caption)+'"'
      +' '+IntToStr(Self.HoldButtons[i].keymessage[0])
      +','+IntToStr(Self.HoldButtons[i].keymessage[1])
      +','+IntToStr(Self.HoldButtons[i].keymessage[2])
      +' '+IntToStr(Self.HoldButtons[i].keymessage[3]));
      {$endif}
    end;

    {$ifdef ByteModeRec}
    rec_byte(12288+8,MouseActSettingToMouseActByte(Self.Setting.AufButton.Act1,Self.Setting.AufButton.Act2));
    rec_byte(12288+9,MouseActSettingToMouseActByte(Self.Setting.AufButton.Setting1,Self.Setting.AufButton.Setting2));
    rec_byte(12288+10,MouseActSettingToMouseActByte(Self.Setting.AufButton.Halt1,Self.Setting.AufButton.Halt2));
    rec_byte(12288+11,MouseActSettingToMouseActByte(Self.Setting.HoldButton.Setting1,Self.Setting.HoldButton.Setting2));
    rec_byte(12288+12,MouseActSettingToMouseActByte(Self.Setting.AufButton.ExtraAct1,Self.Setting.AufButton.ExtraAct2));
    {$endif}
    {$ifdef CodeModeRec}
    writeln(sat,'set Action_Setting '+'AB_act= "'+(MouseActSettingToMouseActCode(Self.Setting.AufButton.Act1,Self.Setting.AufButton.Act2))+'"');
    writeln(sat,'set Action_Setting '+'AB_adv= "'+(MouseActSettingToMouseActCode(Self.Setting.AufButton.ExtraAct1,Self.Setting.AufButton.ExtraAct2))+'"');
    writeln(sat,'set Action_Setting '+'AB_halt= "'+(MouseActSettingToMouseActCode(Self.Setting.AufButton.Halt1,Self.Setting.AufButton.Halt2))+'"');
    writeln(sat,'set Action_Setting '+'AB_opt= "'+(MouseActSettingToMouseActCode(Self.Setting.AufButton.Setting1,Self.Setting.AufButton.Setting2))+'"');
    writeln(sat,'set Action_Setting '+'HB_opt= "'+(MouseActSettingToMouseActCode(Self.Setting.HoldButton.Setting1,Self.Setting.HoldButton.Setting2))+'"');
    {$endif}


    {$ifdef CodeModeRec}
    with AdapterForm.Option.Shortcut do
      begin
        writeln(sat,'set Shortcut '+'Mode= '+IntToStr(byte(Mode)));
        writeln(sat,'set Shortcut '+'StartKey= '+IntToStr(byte(StartKey)));
        writeln(sat,'set Shortcut '+'EndKey= '+IntToStr(byte(EndKey)));
        writeln(sat,'set Shortcut '+'DownUpKey= '+IntToStr(byte(DownUpKey)));
        {
        for i:=0 to ShortcutCount do
          writeln(sat,'set Shortcut_Command '+IntToStr(i)+',"'
                     +ScriptFiles[i].command+'","'+ScriptFiles[i].filename+'"');
        }
        if CommandList.Count>0 then
        for i:=0 to CommandList.Count-1 do
          writeln(sat,'set Shortcut_Command '+IntToStr(i)+',"'
                     +CommandList[i]+'","'+StringReplace(TStringList(CommandList.Objects[i])[0],'"','%Q',[rfReplaceAll])+'"');
      end;
    {$endif}

    {$ifdef ByteModeRec}
    sav.SaveToFile('option.lay');
    sav.Free;
    {$endif}
    {$ifdef CodeModeRec}
    closefile(sat);
    {$endif}

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
    end;
    function get_long(pos:int64):longint;
    begin
      sav.Position:=pos;
      result:=sav.ReadDWord;
    end;
    function get_str(pos:int64):string;
    begin
      sav.Position:=pos;
      result:=sav.ReadAnsiString;
    end;
begin

  IF FileExists('option.auf.lay') THEN
    Self.AufScriptFrames[RuleCount].Frame.Auf.Script.command('load "option.auf.lay"')
  ELSE BEGIN
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
          Self.HoldButtons[i].Caption:=wincptoutf8(stmp);
          for j:=0 to 3 do Self.HoldButtons[i].keymessage[j]:=get_byte(taddr+4+j);
        end;

      error_text:='';
      for i:=0 to SynCount do
        for j:=0 to ButtonColumn do
          begin
            try
              taddr:=512 + ((i*32)+j)*512;
              Self.AufButtons[i,j].ScriptFile.CommaText:=get_str(taddr);
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

      try MouseActByteToMouseActSetting(get_byte(12288+8),Self.Setting.AufButton.Act1,Self.Setting.AufButton.Act2);
        except MouseActByteToMouseActSetting($07,Self.Setting.AufButton.Act1,Self.Setting.AufButton.Act2);
      end;
      try MouseActByteToMouseActSetting(get_byte(12288+9),Self.Setting.AufButton.Setting1,Self.Setting.AufButton.Setting2);
        except MouseActByteToMouseActSetting($06,Self.Setting.AufButton.Setting1,Self.Setting.AufButton.Setting2);
      end;
      try MouseActByteToMouseActSetting(get_byte(12288+10),Self.Setting.AufButton.Halt1,Self.Setting.AufButton.Halt2);
        except MouseActByteToMouseActSetting($05,Self.Setting.AufButton.Halt1,Self.Setting.AufButton.Halt2);
      end;
      try MouseActByteToMouseActSetting(get_byte(12288+11),Self.Setting.HoldButton.Setting1,Self.Setting.HoldButton.Setting2);
        except MouseActByteToMouseActSetting($06,Self.Setting.HoldButton.Setting1,Self.Setting.HoldButton.Setting2);
      end;
      try MouseActByteToMouseActSetting(get_byte(12288+12),Self.Setting.AufButton.ExtraAct1,Self.Setting.AufButton.ExtraAct2);
        except MouseActByteToMouseActSetting($87,Self.Setting.AufButton.ExtraAct1,Self.Setting.AufButton.ExtraAct2);
      end;

    except
      if FileExists('option.lay') then
        MessageBox(0,PChar(utf8towincp('布局文件读取失败')),'Error',MB_OK);
      FOR fo:=1 TO 6 DO BEGIN
        forms[fo].Position:=poScreenCenter;
      END;
    end;
    sav.Free;
  END;

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
  WndFinder(utf8towincp(Edit_TreeView.Text),CheckBox_UseReg.Checked);
end;

procedure TForm_Routiner.CurrentAufStrAdd(str:string);inline;
begin
  Self.AufScriptFrames[Self.PageControl.ActivePageIndex].Frame.Memo_cmd.Lines.Add(str);
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
  ManualForm.CastHtml('Manual\AufScript.html');
  ManualForm.ShowModal;
end;

procedure TForm_Routiner.MenuItem_Func_BasicClick(Sender: TObject);
begin
  ManualForm.CastHtml('Manual\BasicManual.html');
  ManualForm.ShowModal;
end;

procedure TForm_Routiner.MenuItem_Func_ButtonsClick(Sender: TObject);
begin
  ManualForm.CastHtml('Manual\AufButtons.html');
  ManualForm.ShowModal;
end;

procedure TForm_Routiner.MenuItem_Func_DiffClick(Sender: TObject);
begin
  ManualForm.CastHtml('Manual\Differential.html');
  ManualForm.ShowModal;
end;

procedure TForm_Routiner.MenuItem_Func_KeyClick(Sender: TObject);
begin
  ManualForm.CastHtml('Manual\KeyCoding.html');
  ManualForm.ShowModal;
end;

procedure TForm_Routiner.MenuItem_Func_RecClick(Sender: TObject);
begin
  ManualForm.CastHtml('Manual\KeyRecord.html');
  ManualForm.ShowModal;
end;

procedure TForm_Routiner.MenuItem_Func_SynClick(Sender: TObject);
begin
  ManualForm.CastHtml('Manual\Synchronization.html');
  ManualForm.ShowModal;
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

procedure TForm_Routiner.MenuItem_Lay_ImgMergeClick(Sender: TObject);
begin
  Self.SetLayout(byte(Lay_ImgMerger));
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

procedure TForm_Routiner.MenuItem_Opt_AdapterClick(Sender: TObject);
begin
  AdapterForm.Show;
end;

procedure TForm_Routiner.MenuItem_RunPerformanceClick(Sender: TObject);
begin
  FormRunPerformance.ShowModal;
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

procedure TForm_Routiner.RadioGroup_RecSyntaxModeSelectionChanged(
  Sender: TObject);
var radiogroup:TRadioGroup;
begin
  radiogroup:=Sender as TRadioGroup;
  with radiogroup do if ItemIndex=2 then ItemIndex:=0;
  case radiogroup.ItemIndex of
    0:AdapterForm.Option.Rec.SyntaxMode:=smRapid;
    1:AdapterForm.Option.Rec.SyntaxMode:=smChar;
    2:AdapterForm.Option.Rec.SyntaxMode:=smMono;
  end;
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
    SyncW{,SyncH},PentaW:longint;
begin
  with Sender as TScrollBox do
    begin
      SyncW:=(Width - 2*gap);
      //SyncH:=(Height- 2*gap);
      PentaW:=(Width - 6*gap) div 5;
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
  if Layout.LayoutCode=Lay_ImgMerger then
    Self.ScrollBox_ImageView.Top:=gap
  else
    Self.ScrollBox_ImageView.Top:=Self.CheckBoxs[SynCount].Top+Self.CheckBoxs[SynCount].Height+gap;
  Self.ScrollBox_ImageView.Height:=Self.ScrollBox_Synchronic.Height-Self.ScrollBox_ImageView.Top-gap;
  if Self.ScrollBox_ImageView.Height<48 then Self.CheckBox_ViewEnabled.Visible:=false
  else Self.CheckBox_ViewEnabled.Visible:=true;
  if Layout.LayoutCode=Lay_ImgMerger then begin
    Self.Image_Ram.Width:=(Sender as TScrollBox).Width-2*gap;
    Self.Image_Ram.Height:=Self.Image_Ram.Width * Self.Image_Ram.Picture.Height div Self.Image_Ram.Picture.Width;
  end else begin
    Self.Image_Ram.Height:=max(0,Self.ScrollBox_ImageView.Height-48);
    with Self.Image_Ram do Width:=Height * Picture.Bitmap.Width div Picture.Bitmap.Height;
    if Self.Image_Ram.Width+2*gap>(Sender as TScrollBox).Width then
      begin
        Self.Image_Ram.Width:=(Sender as TScrollBox).Width-2*gap;
        with Self.Image_Ram do Height:=Width * Picture.Bitmap.Height div Picture.Bitmap.Width;
      end;
  end;
  Button_MergerPosition.Height:=SynchronicH;
  Button_MergerTarget.Height:=SynchronicH;
  SpinEdit_MergerIntervals.Height:=SynchronicH;
  SpinEdit_MergerPixelWidth.Height:=SynchronicH;
  SpinEdit_MergerBackMatch.Height:=SynchronicH;
  Button_MergerSave.Height:=SynchronicH;
  Button_MergerClear.Height:=SynchronicH;
  Button_MergerAppend.Height:=SynchronicH;
  Button_MergerRollback.Height:=SynchronicH;
  Button_MergerPath.Height:=SynchronicH;
  Button_MergerSave.Width:=PentaW;
  Button_MergerClear.Width:=PentaW;
  Button_MergerAppend.Width:=PentaW;
  Button_MergerRollback.Width:=PentaW;
  Button_MergerPath.Width:=PentaW;
  Panel_ImageMerger.Height:=5*SynchronicH+6*Gap;
end;

procedure TForm_Routiner.ScrollBox_WndListResize(Sender: TObject);
begin
  TreeView_Wnd.Width:=(Sender as TScrollBox).Width - 2*gap;
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

procedure TForm_Routiner.ScrollBox_RecOptionResize(Sender: TObject);
begin

end;


procedure TForm_Routiner.TreeView_WndChange(Sender: TObject; Node: TTreeNode);
begin
  ReDrawWndPos;
end;

procedure TForm_Routiner.TreeView_WndMouseEnter(Sender: TObject);
begin
  Self.ShowManual('窗体列表。选择具体项后可单击左侧按键设置为监听窗体，进一步用于同步器、面板按键和代码执行。');
end;

procedure TForm_Routiner.TreeView_WndMouseLeave(Sender: TObject);
begin
  Self.ShowManual('');
end;

procedure TForm_Routiner.WindowPosPadMouseEnter(Sender: TObject);
begin
  Self.ShowManual('窗体列表中选中窗体在屏幕中的位置预览。');
end;

procedure TForm_Routiner.WindowPosPadMouseLeave(Sender: TObject);
begin
  Self.ShowManual('');
end;

procedure TForm_Routiner.WindowPosPadViceChange(Sender: TObject);
begin
  (Sender as TMemo).Clear;
end;

procedure TForm_Routiner.WindowPosPadWindMouseEnter(Sender: TObject);
begin
  Self.ShowManual('窗体列表中选中窗体在屏幕中的位置预览。');
end;

procedure TForm_Routiner.WindowPosPadWindMouseLeave(Sender: TObject);
begin
  Self.ShowManual('');
end;

procedure TForm_Routiner.FormCreate(Sender: TObject);
var i,j:byte;
    page:integer;
    tmp:TTabSheet;
begin

  Synthesis_mode:=false;
  Record_Mode:=false;
  Setting.RecOption.RecKey:=false;
  Setting.RecOption.RecMouse:=false;
  Setting.RecOption.RecTimeMode:=rtmSleep;
  Setting.RecOption.RecSyntaxMode:=smRapid;
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

      with AufScriptFrames[page] do
        begin
          Frame.AufGenerator;
          Frame.Auf.Script.Func_process.Setting:=@Routiner_Setting;
          CostumerFuncInitialize(Frame.Auf);
          Frame.HighLighterReNew;
          Frame.onHelper:=@Self.ShowManual;
          Frame.OnChangeTitle:=@POnChangeTitle;
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
          Self.AufButtons[i,j].ScriptPath:='';
          Self.AufButtons[i,j].ScriptFile.Add('scriptfile');
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

  for i:=0 to ShortcutCount do
    begin
      Self.SCAufs[i]:=TSCAuf.Create(Self);
      Self.SCAufs[i].ShortcutIndex:=i;
      Self.SCAufs[i].Script.InternalFuncDefine;
      CostumerFuncInitialize(SCAufs[i]);
      with Self.SCAufs[i].Script do
        begin
          IO_fptr.pause:=nil;
          IO_fptr.echo:=nil;
          IO_fptr.print:=nil;
          IO_fptr.error:=@SCAufStr;
          Func_Process.beginning:=@SCAufBeginning;
          Func_Process.ending:=@SCAufEnding;
          Func_process.Setting:=@Routiner_Setting;
        end;
    end;

  Self.AufPopupMenu:=TAufPopupMenu.Create(Self);

  //Self.BorderStyle:=bsSingle;

  WindowsFilter;

  MergerAuf:=TAuf.Create(Self);
  MergerAuf.Script.Func_process.Setting:=@Routiner_Setting;//不一定用得到，还是加上吧
  MergerAuf.Script.InternalFuncDefine;
  CostumerFuncInitialize(MergerAuf);
  MergerAuf.Script.IO_fptr.echo:=@ImgMergerAufStrLn;
  MergerAuf.Script.IO_fptr.print:=@ImgMergerAufStr;
  MergerAuf.Script.IO_fptr.error:=@ImgMergerAufStrErr;
  MergerAuf.Script.IO_fptr.pause:=nil;
  MergerAuf.Script.Expression.Local.TryAddExp('hwnd',narg('',IntToStr(WndRoot.info.hd),''));
  MergerAuf.Script.Expression.Local.TryAddExp('pw',narg('','120',''));
  MergerAuf.Script.Expression.Local.TryAddExp('bm',narg('','12',''));
  MergerAuf.Script.Expression.Local.TryAddExp('x',narg('','0',''));
  MergerAuf.Script.Expression.Local.TryAddExp('y',narg('','0',''));
  MergerAuf.Script.Expression.Local.TryAddExp('w',narg('','0',''));
  MergerAuf.Script.Expression.Local.TryAddExp('h',narg('','0',''));
  MergerAuf.Script.Expression.Local.TryAddExp('i',narg('','500',''));
  MergerAuf.Script.Expression.Local.TryAddExp('im',narg('$"','@@@@@@@@|@@@@@@@H','"'));//define im,$8[0]
  MergerAuf.Script.Expression.Local.TryAddExp('in',narg('$"','@@@@@@@H|@@@@@@@H','"'));//define in,$8[8]
  MergerAuf.Script.Expression.Local.TryAddExp('fn',narg('#"','@@@@@@A@|@@@@@@C@','"'));//define fn,#48[16]
  Merger_Clear;

  ScrollBox_ImageView.BringToFront;//LAY_ImgMerger时，遮盖ARV
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
      AufButton.Act1:=[];
      AufButton.Act2:=mbLeft;
      AufButton.ExtraAct1:=[ssCtrl];
      AufButton.ExtraAct2:=mbLeft;
      AufButton.Setting1:=[];
      AufButton.Setting2:=mbRight;
      AufButton.Halt1:=[];
      AufButton.Halt2:=mbMiddle;
      HoldButton.Setting1:=[];
      HoldButton.Setting2:=mbRight;
      with WndListShowingOption do begin
        AlignCell:=16;
        NameCell:=32;
        HwndVisible:=true;
        WndNameVisible:=true;
        ClassNameVisible:=false;
        PositionVisible:=false;
      end;
      with MergerOption do begin
        Rect:=Classes.Rect(0,0,0,0);
        Interval:=500;
        BackMatch:=12;
        Target:=0;
      end;

    end;
  //AdapterForm.Show;

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
    Lay_Synchronic:MinSizeCheck(ARVControlW+360,(SynCount+2)*(SynchronicH+gap)+gap+StatusBarH);
    Lay_Buttons:MinSizeCheck((ButtonColumn+1+8+1)*(gap+SynchronicW)+2*gap,(SynCount+1)*(gap+SynchronicH)+2*gap+MainMenuH+StatusBarH);
    Lay_Recorder:MinSizeCheck(480+WindowsListW,300+(SynCount+1)*(gap+SynchronicH)+gap);
    Lay_ImgMerger:MinSizeCheck(300+WindowsListW,300+StatusBarH);
  end;
  Self.Splitter_LeftV.Left:=0;
  Self.Splitter_RightV.Left:=Self.Width-sp_thick;
  Self.StatusBar.Panels.Items[0].Width:=max(0,Self.Width-240);
  //if Self.Width<ARVControlW then begin Self.Width:=ARVControlW;exit;end;
  case Self.Layout.LayoutCode of
    Lay_Command:
      begin
        Self.Splitter_MainV.Left:=Self.Width-sp_thick;
        Self.Splitter_SyncV.Left:=Self.Width-sp_thick;
        Self.Splitter_ButtonV.Left:=Self.Width-sp_thick;
        Self.Splitter_LeftH.Top:=Self.Height-sp_thick-MainMenuH-StatusBarH;
        Self.Splitter_RightH.Top:=Self.Height-sp_thick-MainMenuH-StatusBarH;
        Self.Splitter_RecH.Top:=Self.Height-sp_thick-MainMenuH-StatusBarH;
        Self.Button_Wnd_Record.Enabled:=false;
      end;
    Lay_Advanced:
      begin
        Self.Splitter_MainV.Left:=Self.Width-sp_thick-WindowsListW;
        Self.Splitter_SyncV.Left:=ARVControlW;
        Self.Splitter_ButtonV.Left:=Self.Width{-sp_thick}-WindowsListW;
        Self.Splitter_LeftH.Top:=Self.Height-sp_thick-MainMenuH-(1+SynCount)*(gap+SynchronicH)-gap-StatusBarH;
        Self.Splitter_RightH.Top:=0;
        Self.Splitter_RecH.Top:=Self.Height-sp_thick-MainMenuH-StatusBarH;
        Self.Button_Wnd_Record.Enabled:=true;
      end;
    Lay_Synchronic:
      begin
        Self.Splitter_MainV.Left:=ARVControlW+360;
        Self.Splitter_SyncV.Left:=ARVControlW;
        Self.Splitter_ButtonV.Left:=max(Self.Splitter_MainV.Left+2*sp_thick,Self.Width-sp_thick-8*(gap+SynchronicW)-gap)-sp_thick;
        Self.Splitter_LeftH.Top:=0;
        Self.Splitter_RightH.Top:=(SynCount+1)*(SynchronicH+gap)+gap;
        Self.Splitter_RecH.Top:=Self.Height-sp_thick-MainMenuH-StatusBarH;
        Self.Button_Wnd_Record.Enabled:=false;
      end;
    Lay_Buttons:
      begin
        Self.Splitter_MainV.Left:=0;
        Self.Splitter_SyncV.Left:=0;
        Self.Splitter_ButtonV.Left:=(Self.Width-sp_thick)*(ButtonColumn+1)div(ButtonColumn+1+8);
        Self.Splitter_LeftH.Top:=0;
        Self.Splitter_RightH.Top:=Self.Height-sp_thick-MainMenuH-StatusBarH;
        Self.Splitter_RecH.Top:=Self.Height-sp_thick-MainMenuH-StatusBarH;
        Self.Button_Wnd_Record.Enabled:=false;
      end;
    Lay_Recorder:
      begin
        Self.Splitter_MainV.Left:=Self.Width-sp_thick-WindowsListW;
        Self.Splitter_SyncV.Left:=Self.Width-sp_thick-WindowsListW;
        Self.Splitter_ButtonV.Left:=Self.Width-sp_thick-WindowsListW;
        Self.Splitter_LeftH.Top:=Self.Height-sp_thick-MainMenuH-3*gap-SynchronicH-StatusBarH;
        Self.Splitter_RightH.Top:=0;
        Self.Splitter_RecH.Top:=0;
        Self.Button_Wnd_Record.Enabled:=true;
      end;
    Lay_ImgMerger:
      begin
        Self.Splitter_MainV.Left:=Self.Width-WindowsListW;
        Self.Splitter_SyncV.Left:=0;
        Self.Splitter_ButtonV.Left:=max(Self.Splitter_MainV.Left+2*sp_thick,Self.Width-sp_thick-8*(gap+SynchronicW)-gap)-sp_thick;
        Self.Splitter_LeftH.Top:=0;
        Self.Splitter_RightH.Top:=0;
        Self.Splitter_RecH.Top:=Self.Height-sp_thick-MainMenuH-StatusBarH;
        Self.Button_Wnd_Record.Enabled:=false;
      end;
    Lay_Customer:
      begin
        Self.Button_Wnd_Record.Enabled:=true;
      end;
  end;
  Self.PageControlResize(Self.PageControl);
  Self.ScrollBox_WndViewResize(Self.ScrollBox_WndView);
  Self.ScrollBox_SynchronicResize(Self.ScrollBox_Synchronic);
  Self.ScrollBox_AufButtonResize(Self.ScrollBox_AufButton);
  Self.ScrollBox_HoldButtonResize(Self.ScrollBox_HoldButton);
  Self.ScrollBox_WndListResize(Self.ScrollBox_WndList);
  Self.ScrollBox_RecOptionResize(Self.ScrollBox_RecOption);
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

procedure TForm_Routiner.Button_excelMouseEnter(Sender: TObject);
begin
  if (Sender as TButton).Caption='锁定窗口设置' then Self.ShowManual('单击锁定窗体句柄设置。')
  else Self.ShowManual('单击解锁窗体句柄设置。');
end;

procedure TForm_Routiner.Button_excelMouseLeave(Sender: TObject);
begin
  Self.ShowManual('');
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

procedure TForm_Routiner.Button_MergerAppendClick(Sender: TObject);
begin
  Merger_Append;
end;

procedure TForm_Routiner.Button_MergerAppendMouseEnter(Sender: TObject);
begin
  Self.ShowManual('手动截取新的画面并尝试拼接，自动拼接模式下不可用。');
end;

procedure TForm_Routiner.Button_MergerAppendMouseLeave(Sender: TObject);
begin
  Self.ShowManual('');
end;

procedure TForm_Routiner.Button_MergerClearClick(Sender: TObject);
begin
  Merger_Clear;
end;

procedure TForm_Routiner.Button_MergerClearMouseEnter(Sender: TObject);
begin
  Self.ShowManual('开始新的拼接，原有图片将被清除。');
end;

procedure TForm_Routiner.Button_MergerClearMouseLeave(Sender: TObject);
begin
  Self.ShowManual('');
end;

procedure TForm_Routiner.Button_MergerPathMouseEnter(Sender: TObject);
begin
  Self.ShowManual('打开截取画面的保存路径。');
end;

procedure TForm_Routiner.Button_MergerPathMouseLeave(Sender: TObject);
begin
  Self.ShowManual('');
end;

procedure TForm_Routiner.Button_MergerRollbackClick(Sender: TObject);
begin
  Merger_Rollback;
end;

procedure TForm_Routiner.Button_MergerPathClick(Sender: TObject);
begin
  ShellExecute(0,'open','explorer.exe','".\ScreenShot"',nil,SW_NORMAL);
end;

procedure TForm_Routiner.Button_MergerPositionClick(Sender: TObject);
var tmpRect:TRect;
begin
  tmpRect:=Form_ImgMerger.Call(Setting.MergerOption.Target);
  if tmpRect.Height*tmpRect.Width>0 then Setting.MergerOption.Rect:=tmpRect;
  with Setting.MergerOption.Rect do begin
    Button_MergerPosition.Caption:='X:'+IntToStr(Left)+' Y:'+IntToStr(Top)
                                  +' W:'+IntToStr(Width)+' H:'+IntToStr(Height);
    MergerAuf.Script.Expression.Local.TryAddExp('x',narg('',IntToStr(Left),''));
    MergerAuf.Script.Expression.Local.TryAddExp('y',narg('',IntToStr(Top),''));
    MergerAuf.Script.Expression.Local.TryAddExp('w',narg('',IntToStr(Width),''));
    MergerAuf.Script.Expression.Local.TryAddExp('h',narg('',IntToStr(Height),''));
    Setting.MergerOption.PixelWidth:=Height div 4;
    SpinEdit_MergerPixelWidth.Value:=Setting.MergerOption.PixelWidth;
    MergerAuf.Script.Expression.Local.TryAddExp('pw',narg('',IntToStr(Setting.MergerOption.PixelWidth),''));
    MergerAuf.Script.Expression.Local.TryAddExp('bm',narg('',IntToStr(Setting.MergerOption.BackMatch),''));
  end;
  SetFocus;
end;

procedure TForm_Routiner.Button_MergerPositionMouseEnter(Sender: TObject);
begin
  Self.ShowManual('点击设置画面截取的自定义范围。');
end;

procedure TForm_Routiner.Button_MergerPositionMouseLeave(Sender: TObject);
begin
  Self.ShowManual('');
end;

procedure TForm_Routiner.Button_MergerRollbackMouseEnter(Sender: TObject);
begin
  Self.ShowManual('裁去当前截取结果最底部一段画面，自动拼接模式下不可用。');
end;

procedure TForm_Routiner.Button_MergerRollbackMouseLeave(Sender: TObject);
begin
  Self.ShowManual('');
end;

procedure TForm_Routiner.Button_MergerSaveClick(Sender: TObject);
begin
  if Setting.MergerOption.UseAuto then begin
    CheckBox_MergerAutoAppend.Checked:=false;
    Application.ProcessMessages;
  end;
  Merger_Save;
  ShowMessage('保存成功，点击目录按钮查看文件。');
end;

procedure TForm_Routiner.Button_MergerSaveMouseEnter(Sender: TObject);
begin
  Self.ShowManual('开始新的拼接，原有图片将被保存。');
end;

procedure TForm_Routiner.Button_MergerSaveMouseLeave(Sender: TObject);
begin
  Self.ShowManual('');
end;

procedure TForm_Routiner.Button_MergerTargetClick(Sender: TObject);
var wind:TWindow;
begin
  wind:=GetSelectedWindow;
  if wind=nil then exit;
  (Sender as TButton).caption:=IntToHex(wind.info.hd,8)+':'+wind.info.name;
  Setting.MergerOption.Target:=wind.info.hd;
  MergerAuf.Script.Expression.Local.TryAddExp('hwnd',narg('',IntToStr(wind.info.hd),''));
  Setting.MergerOption.Rect:=Classes.Rect(0,0,0,0);
  Button_MergerPosition.Caption:='X:0 Y:0 W:0 H:0';
end;

procedure TForm_Routiner.Button_MergerTargetMouseEnter(Sender: TObject);
begin
  Self.ShowManual('在窗体列表中选择要截取的窗体后点击此处设置画面截取对象。');
end;

procedure TForm_Routiner.Button_MergerTargetMouseLeave(Sender: TObject);
begin
  Self.ShowManual('');
end;

procedure TForm_Routiner.Button_MouseOriKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin

end;

procedure TForm_Routiner.Button_MouseOriMouseEnter(Sender: TObject);
begin
  if Self.MouseHookEnabled then Self.ShowManual('点击按键后单击屏幕任意一处设置为鼠标录制原点。')
  else Self.ShowManual('若需要设置鼠标录制原点，请先打开鼠标钩子。');
end;

procedure TForm_Routiner.Button_MouseOriMouseLeave(Sender: TObject);
begin
  Self.ShowManual('');
end;

procedure TForm_Routiner.Button_MouseOriMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if not Self.MouseHookEnabled then exit;
  AdapterForm.SetMouseOriMode:=true;
  with Sender as TButton do
    begin
      Enabled:=false;
      Caption:='单击设置录制原点';
    end;
end;

procedure TForm_Routiner.Button_TreeViewFreshMouseEnter(Sender: TObject);
begin
  Self.ShowManual('点击手动刷新窗体列表及其位置信息。');
end;

procedure TForm_Routiner.Button_TreeViewFreshMouseLeave(Sender: TObject);
begin
  Self.ShowManual('');
end;

procedure TForm_Routiner.Button_Wnd_RecordMouseEnter(Sender: TObject);
begin
  if Self.Record_Mode then Self.ShowManual('单击结束录制。')
  else Self.ShowManual('单击开始录制，录制的代码会记录在当前代码标签页中。');
end;

procedure TForm_Routiner.Button_Wnd_RecordMouseLeave(Sender: TObject);
begin
  Self.ShowManual('');
end;

procedure TForm_Routiner.Button_Wnd_SynthesisMouseEnter(Sender: TObject);
var button:TButton;
begin
  button:=Sender as TButton;
  if Self.Synthesis_mode then Self.ShowManual('单击结束同步，'+button.Hint+'。')
  else Self.ShowManual('单击开始同步，'+button.Hint+'。');
end;

procedure TForm_Routiner.Button_Wnd_SynthesisMouseLeave(Sender: TObject);
begin
  Self.ShowManual('');
end;

procedure TForm_Routiner.CheckBox_MergerAutoAppendChange(Sender: TObject);
begin
  SpinEdit_MergerIntervals.Enabled:=(Sender as TCheckBox).Checked;
  Button_MergerAppend.Enabled:=not (Sender as TCheckBox).Checked;
  Button_MergerRollback.Enabled:=not (Sender as TCheckBox).Checked;
  Setting.MergerOption.UseAuto:=(Sender as TCheckBox).Checked;
  if Setting.MergerOption.UseAuto then
    Merger_Loop
  else
    Merger_Stop;
end;

procedure TForm_Routiner.CheckBox_MergerAutoAppendMouseEnter(Sender: TObject);
begin
  Self.ShowManual('勾选时以特定间隔时间自动截屏，并尝试拼接到已有画面。');
end;

procedure TForm_Routiner.CheckBox_MergerAutoAppendMouseLeave(Sender: TObject);
begin
  Self.ShowManual('');
end;

procedure TForm_Routiner.CheckBox_MergerPositionChange(Sender: TObject);
begin
  Button_MergerPosition.Enabled:=(Sender as TCheckBox).Checked;
  Setting.MergerOption.UseRect:=(Sender as TCheckBox).Checked;
  if not Setting.MergerOption.UseRect then begin
    Button_MergerPosition.Caption:='X:0 Y:0 W:0 H:0';
    Setting.MergerOption.Rect:=Classes.Rect(0,0,0,0);
  end;
end;

procedure TForm_Routiner.CheckBox_MergerPositionMouseEnter(Sender: TObject);
begin
  Self.ShowManual('未勾选时截取整个画面，勾选后点击右侧按钮设置截取范围。');
end;

procedure TForm_Routiner.CheckBox_MergerPositionMouseLeave(Sender: TObject);
begin
  Self.ShowManual('');
end;

procedure TForm_Routiner.CheckBox_MergerTargetChange(Sender: TObject);
begin
  Button_MergerTarget.Enabled:=(Sender as TCheckBox).Checked;
  Setting.MergerOption.UseWindow:=(Sender as TCheckBox).Checked;
  if not Setting.MergerOption.UseWindow then begin
    Button_MergerPosition.Caption:='X:0 Y:0 W:0 H:0';
    Setting.MergerOption.Rect:=Classes.Rect(0,0,0,0);
    MergerAuf.Script.Expression.Local.TryAddExp('hwnd',narg('',IntToStr(WndRoot.info.hd),''));
  end;
end;

procedure TForm_Routiner.CheckBox_MergerTargetMouseEnter(Sender: TObject);
begin
  Self.ShowManual('未勾选时截取整个屏幕，勾选后选择窗体进行画面截取。');
end;

procedure TForm_Routiner.CheckBox_MergerTargetMouseLeave(Sender: TObject);
begin
  Self.ShowManual('');
end;

procedure TForm_Routiner.CheckBox_UseRegMouseEnter(Sender: TObject);
begin
  Self.ShowManual('勾选时使用正则表达式搜索窗体。');
end;

procedure TForm_Routiner.CheckBox_UseRegMouseLeave(Sender: TObject);
begin
  Self.ShowManual('');
end;

procedure TForm_Routiner.CheckBox_ViewEnabledChange(Sender: TObject);
begin
  Self.Image_Ram.Visible:=(Sender as TCheckBox).Checked;
end;

procedure TForm_Routiner.CheckGroup_KeyMouseItemClick(Sender: TObject;
  Index: integer);
var msgtext:string;
begin
  with Sender as TCheckGroup do
    begin
      AdapterForm.Option.Rec.BKeybd:=Checked[0];
      AdapterForm.Option.Rec.BMouse:=Checked[1];
    end;
  msgtext:='';
  if (not Self.MouseHookEnabled) and Self.Setting.RecOption.RecMouse then msgtext:=msgtext + '鼠标钩子未启用，鼠标录制功能无效。'+#13+#10;
  if (not Self.KeybdHookEnabled) and Self.Setting.RecOption.RecKey then msgtext:=msgtext + '键盘钩子未启用，键盘录制功能无效。'+#13+#10;
  if msgtext<>'' then messagebox(0,PChar(utf8towincp(msgtext)),PChar(utf8towincp('钩子未启用')),MB_OK);
end;

procedure TForm_Routiner.CheckGroup_KeyMouseMouseEnter(Sender: TObject);
begin
  Self.ShowManual('勾选需要录制的消息，若勾选部分的消息钩子未打开则不会记录。');
end;

procedure TForm_Routiner.CheckGroup_KeyMouseMouseLeave(Sender: TObject);
begin
  Self.ShowManual('');
end;

procedure TForm_Routiner.Edit_TimerOffsetMouseEnter(Sender: TObject);
begin
  Self.ShowManual('起始累计时间，当前版本不再支持。');
end;

procedure TForm_Routiner.Edit_TimerOffsetMouseLeave(Sender: TObject);
begin
  Self.ShowManual('');
end;

procedure TForm_Routiner.Edit_TreeViewMouseEnter(Sender: TObject);
begin
  Self.ShowManual('查找名称或类型符合输入字符串的窗体。');
end;

procedure TForm_Routiner.Edit_TreeViewMouseLeave(Sender: TObject);
begin
  Self.ShowManual('');
end;

procedure TForm_Routiner.FormActivate(Sender: TObject);
begin
  if assigned(SettingLagForm) then SettingLagForm.Hide;
  if assigned(AufButtonForm) then AufButtonForm.Hide;
  if assigned(ManualForm) then ManualForm.Hide;
  if assigned(FormRunPerformance) then FormRunPerformance.Hide;
  if assigned(Form_HoldButtonSetting) then Form_HoldButtonSetting.Hide;
end;

procedure TForm_Routiner.Label_WindowPosPadStateMouseEnter(Sender: TObject);
begin
  Self.ShowManual('窗体列表中选中窗体在屏幕中的位置预览。');
end;

procedure TForm_Routiner.Label_WindowPosPadStateMouseLeave(Sender: TObject);
begin
  Self.ShowManual('');
end;

procedure TForm_Routiner.Memo_TmpMouseEnter(Sender: TObject);
begin
  Self.ShowManual('同步器模式下推荐将此文本框设置为焦点，写入的内容会自动删除。');
end;

procedure TForm_Routiner.Memo_TmpMouseLeave(Sender: TObject);
begin
  Self.ShowManual('');
end;

procedure TForm_Routiner.Memo_TmpRecMouseEnter(Sender: TObject);
begin
  Self.ShowManual('录制模式下推荐将此文本框设置为焦点，写入的内容会自动删除。');
end;

procedure TForm_Routiner.Memo_TmpRecMouseLeave(Sender: TObject);
begin
  Self.ShowManual('');
end;

procedure TForm_Routiner.RadioGroup_DelayModeClick(Sender: TObject);
begin
  with Sender as TRadioGroup do
    begin
      AdapterForm.Option.Rec.TimeMode:=TRecTimeMode(ItemIndex);
    end;
end;

procedure TForm_Routiner.RadioGroup_DelayModeMouseEnter(Sender: TObject);
begin
  Self.ShowManual('累计模式：使用连续的计时系统，控制总过程时间；独立模式：使用分步独立计时系统，保证每一步都有足够的等待时间。');
end;

procedure TForm_Routiner.RadioGroup_DelayModeMouseLeave(Sender: TObject);
begin
  Self.ShowManual('');
end;

procedure TForm_Routiner.RadioGroup_RecSyntaxModeMouseEnter(Sender: TObject);
begin
  Self.ShowManual('快速模式：直接记录消息参数；明文模式：尽可能转译每一个消息使之具有可读性；单键模式：录制成不能多键同时按下的简易代码。');
end;

procedure TForm_Routiner.RadioGroup_RecSyntaxModeMouseLeave(Sender: TObject);
begin
  Self.ShowManual('');
end;

procedure TForm_Routiner.SpinEdit_MergerBackMatchChange(Sender: TObject);
begin
  Setting.MergerOption.BackMatch:=(Sender as TSpinEdit).Value;
end;

procedure TForm_Routiner.SpinEdit_MergerBackMatchMouseEnter(Sender: TObject);
begin
  Self.ShowManual('设置拼接长图时的回溯次数上限，较大的值适合画面下部存在未加载的情况，同时运算耗时增大。');
end;

procedure TForm_Routiner.SpinEdit_MergerBackMatchMouseLeave(Sender: TObject);
begin
  Self.ShowManual('');
end;

procedure TForm_Routiner.SpinEdit_MergerIntervalsEditingDone(Sender: TObject);
begin
  Setting.MergerOption.Interval:=(Sender as TSpinEdit).Value;
  MergerAuf.Script.Expression.Local.TryAddExp('i',narg('',IntToStr(Setting.MergerOption.Interval),''));
end;

procedure TForm_Routiner.SpinEdit_MergerIntervalsMouseEnter(Sender: TObject);
begin
  Self.ShowManual('自动拼接时间间隔，最大间隔为一分钟。');
end;

procedure TForm_Routiner.SpinEdit_MergerIntervalsMouseLeave(Sender: TObject);
begin
  Self.ShowManual('');
end;

procedure TForm_Routiner.SpinEdit_MergerPixelWidthChange(Sender: TObject);
begin
  Setting.MergerOption.PixelWidth:=(Sender as TSpinEdit).Value;
end;

procedure TForm_Routiner.SpinEdit_MergerPixelWidthMouseEnter(Sender: TObject);
begin
  Self.ShowManual('设置拼接长图时的像素匹配区域高度，值越大计算时间越长，过小的值可能造成拼接错误。');
end;

procedure TForm_Routiner.SpinEdit_MergerPixelWidthMouseLeave(Sender: TObject);
begin
  Self.ShowManual('');
end;

procedure TForm_Routiner.Button_TreeViewFreshClick(Sender: TObject);
begin
  WindowsFilter;
end;

procedure TForm_Routiner.Button_Wnd_RecordClick(Sender: TObject);
begin
  if not AdapterForm.RecordMode then
    begin
      (Sender as TButton).Caption:='结束录制键盘';
      (Sender as TButton).Font.Bold:=true;
      (Sender as TButton).Font.Color:=clRed;
      Self.StatusBar.Panels.Items[5].Text:='录制';
      AdapterForm.StartRecord;
    end
  else
    begin
      (Sender as TButton).Caption:='开始录制键盘';
      (Sender as TButton).Font.Bold:=false;
      (Sender as TButton).Font.Color:=clDefault;
      Self.StatusBar.Panels.Items[5].Text:='';
      AdapterForm.EndRecord;
    end;
end;

procedure TForm_Routiner.Button_Wnd_SynthesisClick(Sender: TObject);
begin
  if not AdapterForm.SynchronicMode then
    begin
      (Sender as TButton).Caption:='结束同步键盘';
      (Sender as TButton).Font.Bold:=true;
      Self.StatusBar.Panels.Items[3].Text:='同步';
      AdapterForm.SynchronicMode:=true;
    end
  else
    begin
      (Sender as TButton).Caption:='开始同步键盘';
      (Sender as TButton).Font.Bold:=false;
      Self.StatusBar.Panels.Items[3].Text:='';
      AdapterForm.SynchronicMode:=false;
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
  Self.MainMenu.Items[1].Items[6].Enabled:=true;
  case TLayoutSet(layoutcode) of
  Lay_Command:
    begin
      Self.Layout.LayoutCode:=Lay_Command;
      Self.Constraints.MinHeight:=300+StatusBarH;
      Self.Constraints.MaxHeight:=0;
      Self.Constraints.MinWidth:=480;
      Self.Constraints.MaxWidth:=0;
      Self.MainMenu.Items[1].Items[0].Enabled:=false;
    end;
  Lay_advanced:
    begin
      Self.Layout.LayoutCode:=Lay_Advanced;
      Self.Constraints.MinHeight:=300+(SynCount+1)*(gap+SynchronicH)+gap+StatusBarH;
      Self.Constraints.MaxHeight:=0;
      Self.Constraints.MinWidth:=480+WindowsListW;
      Self.Constraints.MaxWidth:=0;
      Self.MainMenu.Items[1].Items[1].Enabled:=false;
    end;
  Lay_SynChronic:
    begin
      Self.Layout.LayoutCode:=Lay_Synchronic;
      Self.Constraints.MinHeight:=(SynCount+2)*(SynchronicH+gap)+gap+StatusBarH;
      Self.Constraints.MaxHeight:=0;
      Self.Constraints.MinWidth:=ARVControlW+360;
      Self.Constraints.MaxWidth:=0;
      Self.Height:=(SynCount+1)*(gap+SynchronicH) + MainMenuH;
      Self.MainMenu.Items[1].Items[2].Enabled:=false;
    end;
  Lay_Buttons:
    begin
      Self.Layout.LayoutCode:=Lay_Buttons;
      Self.Constraints.MinHeight:=(SynCount+1)*(gap+SynchronicH)+2*gap+MainMenuH+StatusBarH;
      Self.Constraints.MaxHeight:=(SynCount+1)*(gap+SynchronicH)+2*gap+MainMenuH+StatusBarH;
      Self.Constraints.MinWidth:=(ButtonColumn+1+8+1)*(gap+SynchronicW)+2*gap;
      Self.Constraints.MaxWidth:=0;
      Self.Height:=(SynCount+1)*(gap+SynchronicH) + MainMenuH;
      Self.MainMenu.Items[1].Items[3].Enabled:=false;
    end;
  Lay_Recorder:
    begin
      Self.Layout.LayoutCode:=Lay_Recorder;
      Self.Constraints.MinHeight:=300+(SynCount+1)*(gap+SynchronicH)+gap+StatusBarH;
      Self.Constraints.MaxHeight:=0;
      Self.Constraints.MinWidth:=480+WindowsListW;
      Self.Constraints.MaxWidth:=0;
      Self.MainMenu.Items[1].Items[4].Enabled:=false;
    end;
  Lay_ImgMerger:
    begin
      Self.Layout.LayoutCode:=Lay_ImgMerger;
      Self.Constraints.MinHeight:=300+StatusBarH;
      Self.Constraints.MaxHeight:=0;
      Self.Constraints.MinWidth:=300+WindowsListW;
      Self.Constraints.MaxWidth:=0;
      Self.MainMenu.Items[1].Items[5].Enabled:=false;
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
    Label_WindowPosPadState.Caption:='无句柄';
  end else with TWindow(tmp.Data).info do begin
    ww:=Width;
    hh:=Height;
    ll:=Left;
    tt:=Top;
    if ww*hh<=16 then Label_WindowPosPadState.Caption:='窗体过小'
    else if ((ll+ww<0) or (ll>Desktop.Width)) and ((tt+hh<0) or (tt>Desktop.Height)) then Label_WindowPosPadState.Caption:='屏幕外'
    else Label_WindowPosPadState.Caption:='';
  end;
  Self.WindowPosPadWind.Top:=Self.WindowPosPad.Top+tt*Self.WindowPosPad.Height div Desktop.Height;
  Self.WindowPosPadWind.Left:=Self.WindowPosPad.Left+ll*Self.WindowPosPad.Width div Desktop.Width;
  Self.WindowPosPadWind.Width:=ww*Self.WindowPosPad.Width div Desktop.Width;
  Self.WindowPosPadWind.Height:=hh*Self.WindowPosPad.Height div Desktop.Height;
  if Label_WindowPosPadState.Caption<>'' then WindowPosPad.Brush.Color:=clSilver
  else WindowPosPad.Brush.Color:=clWhite;
end;

procedure TForm_Routiner.ShowManual(msg:string);
begin
  Self.StatusBar.Panels.Items[0].Text:=msg;
end;

function TForm_Routiner.GetSelectedWindow:TWindow;
var node:TTreeNode;
begin
  result:=nil;
  node:=TreeView_Wnd.selected;
  if node=nil then begin
    MessageBox(0,PChar(utf8towincp('错误：请先选择一个窗体！')),'Error',MB_OK);
    exit
  end;
  result:=TWindow(Form_Routiner.TreeView_Wnd.selected.data);
end;

procedure TForm_Routiner.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  SaveOption;
  Self.MouseUnHook;
  Self.KeybdUnHook;
end;

procedure TForm_Routiner.Merger_Clear;
var str:TStringList;
begin
  if not MergerAuf.Script.PSW.haltoff then MergerAuf.Script.Stop;
  str:=TStringList.Create;
  try
    str.Add('img.freeall');
    str.Add('img.new @im');
    str.Add('img.new @in');
    str.Add('ari.get @hwnd,@im,@x,@y,@w,@h');
    str.Add('ari.dsp @im,-u');
    MergerAuf.Script.command(str);
  finally
    str.Clear;
  end;
end;
procedure TForm_Routiner.Merger_Save;
var str:TStringList;
begin
  if not MergerAuf.Script.PSW.haltoff then MergerAuf.Script.Stop;
  str:=TStringList.Create;
  try
    str.Add('gettimestr @fn,-F');
    str.Add('cat @fn,".png"');
    str.Add('cat @fn,"ScreenShot\",-r');
    str.Add('img.save @im,@fn,-r');
    //str.Add('ari.get @hwnd,@im,@x,@y,@w,@h');
    //str.Add('ari.dsp @im,-u');
    MergerAuf.Script.command(str);
  finally
    str.Clear;
  end;
end;
procedure TForm_Routiner.Merger_Append;
var str:TStringList;
begin
  if not MergerAuf.Script.PSW.haltoff then MergerAuf.Script.Stop;
  str:=TStringList.Create;
  try
    str.Add('echoln @hwnd,@in,@x,@y,@w,@h');
    str.Add('ari.get @hwnd,@in,@x,@y,@w,@h');
    str.Add('img.addln @im,@in,@pw,@bm');
    str.Add('ari.dsp @im,-d');
    MergerAuf.Script.command(str);
  finally
    str.Clear;
  end;
end;
procedure TForm_Routiner.Merger_Rollback;
var str:TStringList;
begin
  if not MergerAuf.Script.PSW.haltoff then MergerAuf.Script.Stop;
  str:=TStringList.Create;
  try
    str.Add('img.trmb @im,@pw,-sub');
    str.Add('ari.dsp @im,-d');
    str.Add('echoln rollback @pw');
    MergerAuf.Script.command(str);
  finally
    str.Clear;
  end;
end;
procedure TForm_Routiner.Merger_Loop;
var str:TStringList;
begin
  if not MergerAuf.Script.PSW.haltoff then MergerAuf.Script.Stop;
  str:=TStringList.Create;
  try
    str.Add('auto_loop:');
    str.Add('sleep @i');
    str.Add('call :merger_append');
    str.Add('jmp :auto_loop');
    str.Add('merger_append:');
    str.Add('ari.get @hwnd,@in,@x,@y,@w,@h');
    str.Add('img.addln @im,@in,@pw,@bm');
    str.Add('ari.dsp @im,-d');
    str.Add('ret');
    MergerAuf.Script.command(str);
  finally
    str.Clear;
  end;
end;
procedure TForm_Routiner.Merger_Stop;
begin
  if not MergerAuf.Script.PSW.haltoff then MergerAuf.Script.Stop;
end;


{ TARVButton & TARVEdit }

constructor TARVButton.Create(AOwner:TComponent);
begin
  inherited Create(AOwner);
  Self.onClick:=@Self.ButtonClick;
  Self.sel_hwnd:=0;
  Self.OnMouseEnter:=@Self.ButtonMouseEnter;
  Self.OnMouseLeave:=@Self.ButtonMouseLeave;
end;

procedure TARVButton.ButtonMouseEnter(Sender:TObject);
begin
  if Form_Routiner.TreeView_Wnd.Selected=nil then Form_Routiner.ShowManual('请先在右侧窗体列表中选择具体一个窗体后再单击确认。')
  else Form_Routiner.ShowManual('在窗体列表中选择窗体后单击确认，此步骤为同步器和其他脚本操作的前提设置。');
end;
procedure TARVButton.ButtonMouseLeave(Sender:TObject);
begin
  Form_Routiner.ShowManual('');
end;

procedure TARVButton.ButtonClick(Sender: TObject);
var wind:TWindow;
    str:string;
begin
  wind:=Form_Routiner.GetSelectedWindow;
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

procedure TARVEdit.EditMouseEnter(Sender:TObject);
begin
  Form_Routiner.ShowManual('给选定的窗体句柄命名，以便于在代码或预定义面板中使用。必须以@+字母开头。');
end;
procedure TARVEdit.EditMouseLeave(Sender:TObject);
begin
  Form_Routiner.ShowManual('');
end;




constructor TARVEdit.Create(AOwner:TComponent);
begin
  inherited Create(AOwner);
  Self.onChange:=@Self.EditOnChange;
  Self.OnMouseLeave:=@Self.EditMouseLeave;
  Self.OnMouseEnter:=@SElf.EditMouseEnter;
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
end;

procedure TARVCheckBox.CheckOnChange(Sender:TObject);
begin
  (Sender as TARVCheckBox).Font.bold:=checked;
end;

procedure TARVCheckBox.CheckBoxMouseEnter(Sender:TObject);
var str:string;
    checkbox:TARVCheckBox;
begin
  checkbox:=Sender as TARVCheckBox;
  if checkbox.checked then str:='停用'
  else str:='启用';
  str:='单击'+str+'此窗体的同步状态，';
  Form_Routiner.ShowManual(str+checkbox.Hint+'。');
end;
procedure TARVCheckBox.CheckBoxMouseLeave(Sender:TObject);
begin
  Form_Routiner.ShowManual('');
end;
constructor TARVCheckBox.Create(AOwner:TComponent);
begin
  inherited Create(AOwner);
  Self.OnMouseEnter:=@Self.CheckBoxMouseEnter;
  Self.OnMouseLeave:=@Self.CheckBoxMouseLeave;
end;

constructor TAufButton.Create(AOwner:TComponent;AWinAuf:TWinAuf);
begin
  inherited Create(AOwner);
  Self.OnMouseUp:=@Self.ButtonMouseUp;
  Self.cmd:=TStringList.Create;
  Self.Auf:=AWinAuf;
  Self.Font.Bold:=true;
  Self.Font.Bold:=false;
  Self.SkipLine:=1;
  Self.ScriptFile:=TStringList.Create;
  Self.OnMouseEnter:=@Self.ButtonMouseEnter;
  Self.OnMouseLeave:=@Self.ButtonMouseLeave;
end;
procedure TAufButton.ButtonMouseEnter(Sender:TObject);
begin
  Form_Routiner.ShowManual('面板按键。用于向窗体执行录制的脚本，请查阅“操作指南”-“预定义面板”。');
end;
procedure TAufButton.ButtonMouseLeave(Sender:TObject);
begin
  Form_Routiner.ShowManual('');
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
          Self.SkipLine:=1;
          Self.AufRun;
        end;
    end;
end;
procedure TAufButton.ButtonCtrlLeftUp;
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
          Form_Routiner.AufPopupMenu.PopupComponent:=Self;
          Form_Routiner.AufPopupMenu.button:=Self;
          for i:=0 to AufPopupCount do begin
            if Self.ScriptFile.Count>i then begin
              Form_Routiner.AufPopupMenu.Items[i].Caption:=ExtractFileName(Self.ScriptFile[i]);
              Form_Routiner.AufPopupMenu.Items[i].Enabled:=true;
            end else begin
              Form_Routiner.AufPopupMenu.Items[i].Caption:='未定义';
              Form_Routiner.AufPopupMenu.Items[i].Enabled:=false;
            end;
          end;
          Form_Routiner.AufPopupMenu.PopUp;
          Self.SkipLine:=AufPopupCount+2;
          Application.ProcessMessages;
          if (Self.SkipLine>AufPopupCount+1)or(Self.SkipLine=0) then exit;
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
  AufButtonForm.Show;
end;

procedure TAufButton.ButtonMouseUp(Sender: TObject; Button: TMouseButton;
                      Shift: TShiftState; X, Y: Integer);
var frm:TForm_Routiner;
begin
  frm:=Form_Routiner;
  if (Button=frm.Setting.AufButton.Setting2) and (Shift=frm.Setting.AufButton.Setting1) then
    begin ButtonRightUp;exit end;
  if (Button=frm.Setting.AufButton.ExtraAct2) and (Shift=frm.Setting.AufButton.ExtraAct1) then
    begin ButtonCtrlLeftUp;exit end;
  if (Button=frm.Setting.AufButton.Act2) and (Shift=frm.Setting.AufButton.Act1) then
    begin ButtonLeftUp;exit end;
  if (Button=frm.Setting.AufButton.Halt2) and (Shift=frm.Setting.AufButton.Halt1) then
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
var str:string;
begin
  Self.cmd.Clear;
  Self.cmd.add('define win, @'+Form_Routiner.Buttons[Self.WindowIndex].expression);
  Self.cmd.add('jmp +'+IntToStr(Self.SkipLine));
  for str in Self.ScriptFile do Self.cmd.Add('load "'+str+'"');

end;

constructor TAufPopupMenu.Create(AOwner:TComponent);
var i:byte;
begin
  inherited Create(AOwner);
  for i:=0 to AufPopupCount do
    begin
      Self.items.Add(TAufMenuItem.Create(Self));
      Self.items[i].OnClick:=@Self.SubButtonClick;
      Self.items[i].Caption:=IntToStr(i+1);
      (Self.items[i] as TAufMenuItem).SkipLine:=i+1;
      (Self.items[i] as TAufMenuItem).SuperMenu:=Self;
    end;
end;

procedure TAufPopupMenu.SubButtonClick(Sender: TObject);
var aufbutton:TAufButton;
begin
  aufbutton:=((Sender as TAufMenuItem).Supermenu as TAufPopupMenu).button;
  aufbutton.SkipLine:=(Sender as TAufMenuItem).SkipLine;
end;

procedure THoldButton.ButtonMouseEnter(Sender:TObject);
begin
  Form_Routiner.ShowManual('鼠标代键。使用鼠标模拟一个组合键的按下，群发给所有同步器启用下的窗体，无论同步器是否打开。');
end;
procedure THoldButton.ButtonMouseLeave(Sender:TObject);
begin
  Form_Routiner.ShowManual('');
end;

procedure THoldButton.HoldMouseDown(Sender: TObject;Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var sync,step:byte;
    alt_offset:byte;
begin
  if (Button<>mbLeft) then begin
    exit;
  end;
  for step:=0 to 2 do if Self.keymessage[step]<>0 then BEGIN
    for sync:=0 to SynCount do
      if Form_Routiner.CheckBoxs[sync].Checked then
        begin
          if Self.keymessage[step] in [18,164,165] then alt_offset:=4
          else alt_offset:=0;
          postmessage(Form_Routiner.Buttons[sync].sel_hwnd,WM_KEYDOWN+alt_offset,Self.keymessage[step],Self.keymessage[step] shl 32 + 1);
        end;
    process_sleep(Self.keymessage[3]);
  END;
end;
procedure THoldButton.HoldMouseUp(Sender: TObject;Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var sync,step:byte;
    frm:TForm_Routiner;
    alt_offset:byte;
begin
  frm:=Form_Routiner;
  if (Button=frm.Setting.HoldButton.Setting2) and (Shift=frm.Setting.HoldButton.Setting1) then begin
    Form_HoldButtonSetting.TargetButton:=Self;
    Form_HoldButtonSetting.Show;
    Form_HoldButtonSetting.FormShow(nil);
    exit;
  end;
  for step:=2 downto 0 do if Self.keymessage[step]<>0 then BEGIN
    for sync:=0 to SynCount do
      if Form_Routiner.CheckBoxs[sync].Checked then
        begin
          if Self.keymessage[step] in [18,164,165] then alt_offset:=4
          else alt_offset:=0;
          postmessage(Form_Routiner.Buttons[sync].sel_hwnd,WM_KEYUP+alt_offset,Self.keymessage[step],Self.keymessage[step] shl 32 + 1);
        end;
    process_sleep(Self.keymessage[3]);
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
  Self.OnMouseEnter:=@Self.ButtonMouseEnter;
  Self.OnMouseLeave:=@Self.ButtonMouseLeave;
end;


initialization
  Reg:=TRegExpr.Create;
  WndFlat:=TStringList.Create;
  WndFlat.Sorted:=true;
  WndSub:=TStringList.Create;
  WndSub.Sorted:=true;
  WndTmp:=TStringList.Create;

finalization
  Reg.Free;
  WndFlat.Free;
  WndSub.Free;
  WndTmp.Free;
end.

