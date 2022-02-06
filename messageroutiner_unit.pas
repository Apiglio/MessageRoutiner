//{$define insert}

unit MessageRoutiner_Unit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Messages,
  Windows, StdCtrls, ComCtrls, ExtCtrls, Menus, Buttons, CheckLst, Dos,
  LazUTF8{$ifndef insert}, Apiglio_Useful, aufscript_frame{$endif};

const

  version_number='0.1.0-pre2';

  RuleCount = 9;
  SynCount = 4;{不能大于9，也不推荐9}
  ButtonColumn = 9;{不能大于31，否则设置保存会出问题}

  gap=5;
  WindowsListW=300;
  //ARVControlH=170;
  ARVControlW=150;
  SynchronicH=28;
  MainMenuH=24;

  {


  +-------------+-----+
  |             |     |
  |             |     |
  |             |     |
  +---+---------+     |
  |   |         |     |
  +---+---------+-----+



  }


type

  TLayoutSet = (Lay_Command=0,Lay_Advanced=1,Lay_Synchronic=2,Lay_Buttons=3,Lay_Recorder=4);

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
    published
      TheLabel:TLabel;
    public
      procedure CheckOnChange(Sender:TObject);
  end;
  TARVLabel = class(TLabel)
  published
    CheckBox:TCheckBox;
  public
    procedure LabelOnClick(Sender:TObject);
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
    Button_excel: TButton;
    Button_TreeViewFresh: TButton;
    Button_Wnd_Record: TButton;
    Button_advanced: TButton;
    Button_Wnd_Synthesis: TButton;
    Edit_TreeView: TEdit;
    GroupBox_RecOption: TScrollBox;
    Label_filter: TLabel;
    MainMenu: TMainMenu;
    Memo_tmp: TMemo;
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
    MenuItem_Opt_divide: TMenuItem;
    MenuItem_Layout: TMenuItem;
    MenuItem_Option: TMenuItem;
    MenuItem_Func_Auf: TMenuItem;
    MenuItem_Func_Key: TMenuItem;
    MenuItem_Func_Syn: TMenuItem;
    MenuItem_Lay_simple: TMenuItem;
    MenuItem_Lay_advanced: TMenuItem;
    MenuItem_Opt_setting: TMenuItem;
    PageControl: TPageControl;
    RadioGroup_RecHookMode: TRadioGroup;
    RadioGroup_RecSyntaxMode: TRadioGroup;
    TreeView_Wnd: TTreeView;
    {
    procedure Button_endClick(Sender: TObject);
    procedure Button_runClick(Sender: TObject);
    }
    procedure Button_advancedClick(Sender: TObject);
    procedure Button_excelClick(Sender: TObject);
    procedure Button_excelMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Button_TreeViewFreshClick(Sender: TObject);
    procedure Button_Wnd_RecordClick(Sender: TObject);
    procedure Button_Wnd_SynthesisClick(Sender: TObject);
    procedure Edit_TreeViewChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure Memo_cmdEditingDone(Sender: TObject);
    procedure Memo_cmdKeyPress(Sender: TObject; var Key: char);

    procedure GetMessageUpdate(var Msg:TMessage);message WM_USER+100;
    procedure MenuItem_Func_AufClick(Sender: TObject);
    procedure MenuItem_Func_ButtonsClick(Sender: TObject);
    procedure MenuItem_Func_DiffClick(Sender: TObject);
    procedure MenuItem_Func_KeyClick(Sender: TObject);
    procedure MenuItem_Func_RecClick(Sender: TObject);
    procedure MenuItem_Func_SynClick(Sender: TObject);
    procedure MenuItem_Lay_advancedClick(Sender: TObject);
    procedure MenuItem_Lay_ButtonsClick(Sender: TObject);
    procedure MenuItem_Lay_RecordClick(Sender: TObject);
    procedure MenuItem_Lay_simpleClick(Sender: TObject);
    procedure MenuItem_Lay_SynChronicClick(Sender: TObject);
    procedure MenuItem_Opt_AboutClick(Sender: TObject);
    procedure MenuItem_Opt_licenceClick(Sender: TObject);
    procedure MenuItem_Setting_LagClick(Sender: TObject);
    procedure PageControlChange(Sender: TObject);
    procedure PageControlResize(Sender: TObject);
    procedure RadioGroup_RecHookModeSelectionChanged(Sender: TObject);
    procedure RadioGroup_RecSyntaxModeSelectionChanged(Sender: TObject);
    procedure WindowsFilter;

  private
    { private declarations }
    InitialLayout:TLayoutSet;//布局类型
    //Show_Advanced_Seting:boolean;//是否显示高级设置
    //Height_Advanced_Seting:word;//高级设置高度
    //Left_Column_Width:word;//左边栏的宽度
  public
    { public declarations }
    WinAuf:array[0..SynCount]of TWinAuf;//每个窗口的专用Auf
    AufButtons:array[0..SynCount,0..ButtonColumn]of TAufButton;//面板按键

    Edits:array[0..SynCount]of TARVEdit;
    Buttons:array[0..SynCount]of TARVButton;
    Labels:array[0..SynCount]of TARVLabel;
    CheckBoxs:array[0..SynCount]of TARVCheckBox;
    AufScriptFrames:array[0..RuleCount] of TAufScriptFrame;
    Synthesis_mode:boolean;//为真时向所有选中的TARVButton.sel_hwnd窗体广播
    Record_mode:boolean;//为真时向当前标签页记录键盘消息
    LastRecTime:longint;//录制过程中表示上一个记录时间，作差用来确定sleep的参数
    LastMessage:TMessage;
    State:record
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

    Tim:TTimer;//因为不知道怎么处理汉字输入法造成连续的OnChange事件，迫不得已采用延时50ms检测连续输入的办法。
    procedure TreeViewEditOnChange(Sender:TObject);
    procedure SaveOption;
    procedure LoadOption;
    procedure SetLayout(layout:byte);
  end;

var
  Form_Routiner: TForm_Routiner;
  WndRoot:TWindow;

implementation
uses form_settinglag, form_aufbutton, form_manual;

{$R *.lfm}

function StartHookK(MsgID:Word):Bool;stdcall;external 'DesktopCommander_keyboard_dll.dll' name 'StartHook';
function StopHookK:Bool;stdcall;external 'DesktopCommander_keyboard_dll.dll' name 'StopHook';
procedure SetCallHandleK(sender:HWND);stdcall;external 'DesktopCommander_keyboard_dll.dll' name 'SetCallHandle';

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
    title:PChar;
    new_wnd:TWindow;
begin
  hd:=GetWindow(wnd.info.hd,GW_CHILD);
  //renew_writeln('First='+IntToHex(hd,8)+title);
  //Application.ProcessMessages;

  while hd<>0 do
    begin
      getmem(title,200);
      GetWindowText(hd,title,200);
      title:=Usf.ExPChar(wincptoutf8(title));
      GetWindowInfo(hd,info);
      w:=info.rcWindow.Right-info.rcWindow.Left;
      h:=info.rcWindow.Bottom-info.rcWindow.Top;
      new_wnd:=TWindow.Create(hd,title,info.rcWindow.Left,info.rcWindow.Top,w,h);
      new_wnd.parent:=Wnd;
      wnd.child.add(new_wnd);

      IF (filter='') or (pos(lowercase(filter),lowercase(title))>0) THEN BEGIN

      if (new_wnd.parent.node)=nil then
        Form_Routiner.TreeView_Wnd.Items.add(nil,'['+IntToHex(hd,8)+']'+title)
      else
        Form_Routiner.TreeView_Wnd.Items.addchild((new_wnd.parent.node) as TTreeNode,'['+IntToHex(hd,8)+']'+title);
      new_wnd.node:=Form_Routiner.TreeView_Wnd.Items[Form_Routiner.TreeView_Wnd.Items.count-1];
      (new_wnd.node as TTreeNode).data:=new_wnd;


      GetChildWindows(new_wnd);

      END;

      hd:=GetNextWindow(hd,GW_HWNDNEXT);

    end;
end;


procedure WndFinder(filter:string='');
var hd:HWND;
begin
  ClearWindows(WndRoot);
  hd:=GetDesktopWindow;//得到桌面窗口
  WndRoot:=TWindow.Create(hd,'WndRoot',0,0,0,0);
  WndRoot.parent:=nil;
  WndRoot.node:=nil;

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



procedure CostumerFuncInitialize(AAuf:TAuf);
begin
  AAuf.Script.add_func('resize',@_resize,'w,h','修改当前窗口尺寸');
  AAuf.Script.add_func('about',@print_version,'','版本信息');
  //AAuf.Script.add_func('now',@_gettime,'','当前时间');
  AAuf.Script.add_func('string',@SendString,'hwnd,str','向窗口输入字符串');
  AAuf.Script.add_func('widestring',@SendWideString,'hwnd,str','向窗口输入汉字字符串');
  AAuf.Script.add_func('keypress',@KeyPress_Event,'hwnd,key,deley','调用KeyPress_Event');
  AAuf.Script.add_func('post',@PostM,'hwnd,msg,w,l','调用Postmessage');
  AAuf.Script.add_func('send',@SendM,'hwnd,msg,w,l','调用Sendmessage');
end;
procedure GlobalExpressionInitialize;
begin
  GlobalExpressionList.TryAddExp('WM_KEYDOWN',narg('','256',''));
  GlobalExpressionList.TryAddExp('WM_KEYUP',narg('','257',''));
  GlobalExpressionList.TryAddExp('WM_CHAR',narg('','258',''));
  GlobalExpressionList.TryAddExp('WM_DEADCHAR',narg('','259',''));
  GlobalExpressionList.TryAddExp('WM_SYSKEYDOWN',narg('','260',''));
  GlobalExpressionList.TryAddExp('WM_SYSKEYUP',narg('','261',''));
  GlobalExpressionList.TryAddExp('WM_SYSKEYCHAR',narg('','262',''));
  GlobalExpressionList.TryAddExp('WM_SYSDEADCHAR',narg('','263',''));

  GlobalExpressionList.TryAddExp('WM_COMMAND',narg('','265',''));
  GlobalExpressionList.TryAddExp('WM_SYSCOMMAND',narg('','266',''));

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

procedure TForm_Routiner.SaveOption;
var sav:TMemoryStream;
    i,j,tmpb:byte;
    taddr:int64;
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
  sav.Size:=$2FFFF;
  sav.Position:=0;
  for taddr:=0 to $2FFFF do sav.WriteByte(0);

  rec_str(0,'Apiglio MR'+version_number);
  rec_long(24,longint(Self.InitialLayout));
  rec_long(32,Self.Top);
  rec_long(32+4,Self.Left);
  rec_long(32+8,Self.Width);
  rec_long(32+12,Self.Height);
  rec_long(64,AufButtonForm.Top);
  rec_long(64+4,AufButtonForm.Left);
  rec_long(64+8,AufButtonForm.Width);
  rec_long(64+12,AufButtonForm.Height);
  rec_long(96,SettingLagForm.Top);
  rec_long(96+4,SettingLagForm.Left);
  rec_long(96+8,SettingLagForm.Width);
  rec_long(96+12,SettingLagForm.Height);
  rec_long(128,ManualForm.Top);
  rec_long(128+4,ManualForm.Left);
  rec_long(128+8,ManualForm.Width);
  rec_long(128+12,ManualForm.Height);

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

   sav.SaveToFile('option.lay');
   sav.Free;

end;
procedure TForm_Routiner.LoadOption;
var sav:TMemoryStream;
    i,j,tmpb:byte;
    taddr:int64;
    error_text:string;
    function get_byte(pos:int64):byte;
    begin
      sav.Position:=pos;
      result:=sav.ReadByte;
      //MessageBox(0,PChar(IntToStr(result)),'',MB_OK);
    end;
    function get_long(pos:int64):longint;
    begin
      sav.Position:=pos;
      result:=sav.ReadDWord;
      //MessageBox(0,PChar(IntToStr(result)),'',MB_OK);
    end;
    function get_str(pos:int64):string;
    begin
      sav.Position:=pos;
      result:=sav.ReadAnsiString;
      //MessageBox(0,PChar(result),'',MB_OK);
    end;
begin
  try
    sav:=TmemoryStream.Create;
    sav.LoadFromFile('option.lay');

    Self.InitialLayout:=TLayoutSet(get_long(24));
    for i:=0 to Self.MainMenu.Items[1].Count - 1 do
      Self.MainMenu.Items[1].Items[i].Enabled:=true;
    Self.MainMenu.Items[1].Items[byte(Self.InitialLayout)].Enabled:=false;

    Self.Top:=get_long(32);
    Self.Left:=get_long(32+4);
    Self.Width:=get_long(32+8);
    Self.Height:=get_long(32+12);
    AufButtonForm.Top:=get_long(64);
    AufButtonForm.Left:=get_long(64+4);
    AufButtonForm.Width:=get_long(64+8);
    AufButtonForm.Height:=get_long(64+12);
    SettingLagForm.Top:=get_long(96);
    SettingLagForm.Left:=get_long(96+4);
    SettingLagForm.Width:=get_long(96+8);
    SettingLagForm.Height:=get_long(96+12);
    ManualForm.Top:=get_long(128);
    ManualForm.Left:=get_long(128+4);
    ManualForm.Width:=get_long(128+8);
    ManualForm.Height:=get_long(128+12);

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
      MessageBox(0,PChar(utf8towincp('以下面板按键未找到先前的设置：'+#13+#10+error_text)+'.'),'Error',MB_OK)
    end;
    sav.Free;
  except
    MessageBox(0,PChar(utf8towincp('布局文件读取失败')),'Error',MB_OK);
  end;
  //{
  for i:=0 to SynCount do
    for j:=0 to ButtonColumn do
      begin
        Self.AufButtons[i,j].RenewCmd;
        //qkm('AufButton['+INtToStr(i)+','+INtToStr(j)+']');
      end;
  //}

end;

procedure TForm_Routiner.WindowsFilter;
begin
  TreeView_Wnd.items.clear;
  WndFinder(Edit_TreeView.Text);
end;

procedure TForm_Routiner.GetMessageUpdate(var Msg:TMessage);
var x,y:integer;
    i,kx{35转0,37转1}:byte;
    NowTimeNumber,NowTmp:longint;
begin
  x := pMouseHookStruct(Msg.LParam)^.pt.X;
  y := pMouseHookStruct(Msg.LParam)^.pt.Y;

  //if Trace then Self.Memo_cmd.lines.add('更新消息：n='+IntToStr(Msg.WParam)+' x='+IntToStr(x)+' y='+IntToStr(y));
  //AufScriptFrames[PageControl.ActivePageIndex].Frame.Auf.Script.IO_fptr.echo(AufScriptFrames[PageControl.ActivePageIndex].Frame,'更新消息：n='+IntToStr(Msg.WParam)+' x='+IntToStr(x)+' y='+IntToStr(y));

  {
  lctrl=162,29
  rctrl=163,29
  lshift=160,42
  rshift=161,54
  lalt=164,56
  ralt=165,56
  }

  case Msg.wParam of
    WM_KeyUp,WM_KeyDown,WM_Char,WM_SysKeyUp,WM_SysKeyDown,WM_IME_Char:
      begin
        case Msg.wParam of
          WM_KeyDown:
            begin
              case x of
                162,163:Self.State.Ctrl:=true;
                160,161:Self.State.Shift:=true;
                164,165:Self.State.Alt:=true;
                91,92:Self.State.Win:=true;
                49..49+SynCount:Self.State.NumKey[x-49]:=true;
              end;
            end;
          WM_KeyUp:
            begin
              case x of
                162,163:Self.State.Ctrl:=false;
                160,161:Self.State.Shift:=false;
                164,165:Self.State.Alt:=false;
                91,92:Self.State.Win:=false;
                49..49+SynCount:begin Self.State.Number[x-49]:=true;Self.State.NumKey[x-49]:=false;end;
                192:Self.State.Gross:=true;
              end;
            end;
        end;

        if Self.State.ctrl and Self.State.Gross and (Msg.wParam=WM_KeyDown) and (x = 192) and (y = 41) then
          begin
            Self.Button_Wnd_SynthesisClick(Self.Button_Wnd_Synthesis);
            Self.State.Gross:=false;
          end;
        if Self.State.ctrl and (Msg.wParam=WM_KeyDown) and (x in [49..49+SynCount]) then
          begin
            if Self.State.Number[x-49] then Self.CheckBoxs[x-49].Checked:=not Self.CheckBoxs[x-49].Checked;
            Self.State.Number[x-49]:=false;
          end;
        if (x in [33,34]) and (Msg.wParam=WM_KEYDOWN) then begin
          for i:=0 to SynCount do if Self.State.NumKey[i] then
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

        if Self.Record_mode then begin
          if (Self.LastMessage.msg=Msg.wParam) and (Self.LastMessage.wParam=x) then else begin
              NowTimeNumber:=GetTimeNumber;
              if NowTimeNumber<Self.LastRecTime then inc(NowTimeNumber,86400000);
              Self.AufScriptFrames[Self.PageControl.ActivePageIndex].Frame.Memo_cmd.Lines.Add('sleep '+IntToStr(NowTimeNumber-Self.LastRecTime));
              Self.AufScriptFrames[Self.PageControl.ActivePageIndex].Frame.Memo_cmd.Lines.Add('post @win,'+IntToStr(Msg.wParam)+','+IntToStr(x)+','+IntToStr((x shl 16) + 1));
              Self.LastRecTime:=NowTimeNumber;
          end;
        end;

        Self.LastMessage.msg:=Msg.wParam;
        Self.LastMessage.wParam:=x;

      end;
    else ;
  end;

end;

procedure TForm_Routiner.MenuItem_Func_AufClick(Sender: TObject);
begin
  ManualForm.Show;
  ManualForm.CastHtml('Manual\AufScript.html');
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
  SetLayout(byte(Lay_Command));
end;

procedure TForm_Routiner.MenuItem_Lay_advancedClick(Sender: TObject);
begin
  SetLayout(byte(Lay_Advanced));
end;

procedure TForm_Routiner.MenuItem_Lay_SynChronicClick(Sender: TObject);
begin
  SetLayout(byte(Lay_Synchronic));
end;

procedure TForm_Routiner.MenuItem_Lay_ButtonsClick(Sender: TObject);
begin
  SetLayout(byte(Lay_Buttons));
end;

procedure TForm_Routiner.MenuItem_Lay_RecordClick(Sender: TObject);
begin
  SetLayout(byte(Lay_Recorder));
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
  (Sender as TPageControl).ActivePage.Color:=clSkyBlue;
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

procedure TForm_Routiner.FormCreate(Sender: TObject);
var i,j:byte;
    page:integer;
    tmp:TTabSheet;
begin

  //Show_Advanced_Seting:=false;
  //Height_Advanced_Seting:=200+72;
  //Left_Column_Width:=300+120;
  Synthesis_mode:=false;
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

        end;
    end;

  //默认尺寸状态
  Self.Width:=615;
  Self.Height:=305;

  Self.Position:=poScreenCenter;
  Self.State.Gross:=true;
  for i:=49 to 49+SynCount do Self.State.Number[i-49]:=true;
  for i:=0 to SynCount do
    begin
      SynSetting[i].mode_lag:=false;
      SynSetting[i].adjusting_lag:=0;
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
          Self.AufButtons[i,j].Parent:=Self;
          Self.AufButtons[i,j].WindowChangeable:=false;
          Self.AufButtons[i,j].ScriptFile:='scriptfile';
          Self.AufButtons[i,j].WindowIndex:=i;
          Self.AufButtons[i,j].ColumnIndex:=j;
          Self.AufButtons[i,j].Caption:='';
        end;

      Self.Edits[i]:=TARVEdit.Create(Self);
      Self.Buttons[i]:=TARVButton.Create(Self);
      Self.Edits[i].Parent:=Self;
      Self.Buttons[i].Parent:=Self;
      Self.Buttons[i].WindowIndex:=i;
      Self.Edits[i].Button:=Self.Buttons[i];
      Self.Buttons[i].Edit:=Self.Edits[i];
      Self.Edits[i].Text:='@win'+IntToStr(i);
      Self.Buttons[i].Text:='<<窗体句柄';
      Self.Buttons[i].expression:=Self.Edits[i].Text;
      delete(Self.Buttons[i].expression,1,1);
      GlobalExpressionList.TryAddExp(Self.Buttons[i].expression,narg('','0',''));
      Self.Buttons[i].expression:=Self.Buttons[i].expression;

      Self.Labels[i]:=TARVLabel.Create(Self);
      Self.Labels[i].Parent:=Self;
      Self.Labels[i].Caption:='键盘同步';
      Self.CheckBoxs[i]:=TARVCheckBox.Create(Self);
      Self.CheckBoxs[i].Parent:=Self;
      Self.CheckBoxs[i].Checked:=false;

      Self.CheckBoxs[i].TheLabel:=Self.Labels[i];
      Self.CheckBoxs[i].OnChange:=@Self.CheckBoxs[i].CheckOnChange;

      Self.Labels[i].CheckBox:=Self.CheckBoxs[i];
      Self.Labels[i].OnClick:=@Self.Labels[i].LabelOnClick;

      Self.CheckBoxs[i].ShowHint:=true;
      Self.CheckBoxs[i].Hint:='按Ctrl+'+IntToStr(i+1)+'切换状态';
      Self.Labels[i].ShowHint:=true;
      Self.Labels[i].Hint:='按Ctrl+'+IntToStr(i+1)+'切换状态';
      Self.Labels[i].Color:=clForm;

      Self.SynSetting[i].mode_lag:=true;
      Self.SynSetting[i].adjusting_step:=5;
      Self.SynSetting[i].adjusting_lag:=0;
      Self.KeyLag[i,0]:=TTimerLag.Create(Self);
      Self.KeyLag[i,1]:=TTimerLag.Create(Self);

    end;

  //Self.BorderStyle:=bsSingle;


  FormResize(nil);

  tim:=TTimer.Create(Self);
  tim.OnTimer:=@Self.TreeViewEditOnChange;

  Self.LastMessage.msg:=0;
  Self.LastMessage.lParam:=0;
  Self.LastMessage.wParam:=0;

  SetCallHandleK(Self.Handle);
  if not StartHookK(WM_USER+100) then
  begin
    ShowMessage('挂钩失败！');
  end;


end;

procedure TForm_Routiner.FormResize(Sender: TObject);
var i,j:byte;
    divi_vertical,divi_horizontal,ARVControlH,ButtonsTop,TreeViewTop,RecorderTop,AufButtonW,AufButtonH:longint;
    page:integer;
begin
  ARVControlH:=(SynCount+1)*(gap+SynchronicH);
  case Self.InitialLayout of
    Lay_Command:
      begin
        divi_vertical:=Self.Width;
        divi_horizontal:=Self.Height;
        ButtonsTop:=Self.Height;
        RecorderTop:=divi_horizontal + ARVControlH;
        TreeViewTop:=0;
        Self.PageControl.Show;
        Self.Button_Wnd_Record.Enabled:=false;
      end;
    Lay_Advanced:
      begin
        divi_vertical:=Self.Width - WindowsListW;
        divi_horizontal:=Self.Height - ARVControlH;
        ButtonsTop:=Self.Height;
        RecorderTop:=divi_horizontal + ARVControlH;
        TreeViewTop:=0;
        Self.PageControl.Show;
        Self.Button_Wnd_Record.Enabled:=true;
      end;
    Lay_Synchronic:
      begin
        divi_vertical:=Self.Width;
        divi_horizontal:=MainMenuH;
        ButtonsTop:=Self.Height;
        RecorderTop:=divi_horizontal + ARVControlH;
        TreeViewTop:=0;
        Self.PageControl.Hide;
        Self.Button_Wnd_Record.Enabled:=false;
      end;
    Lay_Buttons:
      begin
        divi_vertical:=Self.Width;
        divi_horizontal:=Self.Height;
        ButtonsTop:=0;
        RecorderTop:=divi_horizontal + ARVControlH;
        TreeViewTop:=0;
        Self.PageControl.Hide;
        Self.Button_Wnd_Record.Enabled:=false;
      end;
    Lay_Recorder:
      begin
        divi_vertical:=Self.Width - WindowsListW;
        divi_horizontal:=Self.Height;
        ButtonsTop:=Self.Height;
        RecorderTop:=0;
        TreeViewTop:=ButtonsTop;
        Self.PageControl.Show;
        Self.Button_Wnd_Record.Enabled:=true;
      end;
  end;
  if Self.Width < WindowsListW + 150 then begin
    Self.Width:=WindowsListW + 150;
    exit;
  end;
  if (Self.InitialLayout in [Lay_Advanced,Lay_Recorder])and(Self.Width < WindowsListW + 450) then begin
    Self.Width:=WindowsListW + 450;
    exit;
  end;
  if (Self.InitialLayout in [Lay_Buttons])and(Self.Width < ButtonColumn * 36 +10) then begin
    Self.Width:=ButtonColumn * 36+10;
    exit;
  end;
  if (Self.InitialLayout in [Lay_Buttons])and(Self.Height < gap + (SynCount+1) * 38) then begin
    Self.Height := gap + (SynCount+1) * 38;
    exit;
  end;
  if Self.Height < ARVControlH + MainMenuH then begin
    Self.Height:=ARVControlH + MainMenuH;
    exit;
  end;

  PageControl.Width:=divi_vertical - 2*gap;
  PageControl.Height:=divi_horizontal- 3 * gap - 24;
  PageControl.Left:=gap;
  PageControl.Top:=gap;

  for page:=0 to RuleCount do begin
    Self.AufScriptFrames[page].Frame.Width:=PageControl.Width-2*gap;
    Self.AufScriptFrames[page].Frame.Height:=PageControl.Height-25-2*gap;
    Self.AufScriptFrames[page].Frame.Left:=0;
    Self.AufScriptFrames[page].Frame.Top:=0;
  end;
  Self.AufScriptFrames[PageControl.ActivePageIndex].Frame.FrameResize(nil);


  if Self.InitialLayout = Lay_Buttons then Button_advanced.Left:=divi_vertical + gap
  else Button_advanced.Left:=gap;
  Button_advanced.Top:=divi_horizontal - 24 - gap - MainMenuH;
  Button_advanced.Width:=divi_vertical - 2 * gap - 2;
  Button_advanced.Height:=24;

  IF Self.InitialLayout = Lay_Recorder THEN BEGIN
    Button_Wnd_Record.Top:=gap;
    Button_Wnd_Record.Left:=divi_vertical + gap;
    Button_Wnd_Record.Height:=28;
    Button_Wnd_Record.Width:=(WindowsListW - 3*gap)div 2;

    Button_Wnd_Synthesis.Top:=gap;
    Button_Wnd_Synthesis.Left:=divi_vertical + 2*gap + Button_Wnd_Record.Width;
    Button_Wnd_Synthesis.Height:=28;
    Button_Wnd_Synthesis.Width:=WindowsListW - 3*gap - Button_Wnd_Record.Width-2;
  END ELSE BEGIN
    Button_Wnd_Record.Top:=divi_horizontal - MainMenuH;
    Button_Wnd_Record.Left:=gap;
    Button_Wnd_Record.Height:=28;
    Button_Wnd_Record.Width:=ARVControlW;

    Button_Wnd_Synthesis.Top:=divi_horizontal + 28 + gap - MainMenuH;
    Button_Wnd_Synthesis.Left:=gap;
    Button_Wnd_Synthesis.Height:=28;
    Button_Wnd_Synthesis.Width:=ARVControlW;
  END;

  Button_excel.Top:=divi_horizontal+2*28+2*gap - MainMenuH;
  Button_excel.Left:=gap;
  Button_excel.Height:=28;
  Button_excel.Width:=ARVControlW;

  Memo_tmp.Top:=divi_horizontal + 3 * 28 + 3 * gap - MainMenuH;
  Memo_tmp.Left:=gap;
  Memo_tmp.Height:=Self.Height - gap - Memo_tmp.Top - MainMenuH;
  Memo_tmp.Width:=ARVControlW;

  TreeView_Wnd.Top:=TreeViewTop + gap;
  TreeView_Wnd.Height:=Self.Height - 36 - 2 * gap- MainMenuH;
  TreeView_Wnd.Left:=divi_vertical + gap;
  TreeView_Wnd.Width:=WindowsListW - 2 * gap;

  Label_Filter.Top:=TreeViewTop + Self.Height - 28 - MainMenuH;
  Edit_TreeView.Top:=TreeViewTop + Self.Height - 34 - MainMenuH;
  Button_TreeViewFresh.Top:=TreeViewTop + Self.Height - 34 - MainMenuH;

  //Label_Filter.Width:=45;
  Edit_TreeView.Width:=TreeView_Wnd.Width - Label_Filter.Width - Button_TreeViewFresh.Width - 4*gap;
  //Button_TreeViewFresh.Width:=72;

  Label_Filter.Left:=TreeView_Wnd.Left;
  Edit_TreeView.Left:=TreeView_Wnd.Left +10 + Label_Filter.Width;
  Button_TreeViewFresh.Left:=TreeView_Wnd.Left +10 + Label_Filter.Width + 10 + Edit_TreeView.Width;

  GroupBox_RecOption.Top:=RecorderTop + 2*gap + 28;
  GroupBox_RecOption.Left:=TreeView_Wnd.Left;
  GroupBox_RecOption.Width:=TreeView_Wnd.Width - gap;
  GroupBox_RecOption.Height:=PageControl.Height - gap - 28;

  AufButtonW:=(Self.Width - (ButtonColumn + 2 )*gap) div (ButtonColumn+1);
  AufButtonH:=(Self.Height - (SynCount + 2 )*gap - MainMenuH) div (SYnCount+1);

  for i:=0 to SynCount do
    begin
      Self.Edits[i].Top:=divi_horizontal+(28+gap)*i-MainMenuH;
      Self.Edits[i].Width:=60;
      Self.Edits[i].Left:=ARVControlW+2*gap;
      Self.Edits[i].Height:=28;

      Self.Buttons[i].Top:=Self.Edits[i].Top;
      Self.Buttons[i].Width:=divi_vertical-ARVControlW-2*gap-160;
      Self.Buttons[i].Left:=Self.Edits[i].Left+Self.Edits[i].Width+gap;
      Self.Buttons[i].Height:=28;

      Self.CheckBoxs[i].Left:=divi_vertical-90;
      Self.CheckBoxs[i].Top:=Self.Buttons[i].Top+3;

      Self.Labels[i].Left:=divi_vertical-70;
      Self.Labels[i].Top:=Self.Buttons[i].Top+5;


      for j:=0 to ButtonColumn do
        begin
          Self.AufButtons[i,j].Width:=AufButtonW;
          Self.AufButtons[i,j].Left:=j*(gap + AufButtonW)+gap;
          Self.AufButtons[i,j].Height:=AufButtonH;
          Self.AufButtons[i,j].Top:=ButtonsTop + gap + i*(gap+AufButtonH);
        end;

    end;

end;

procedure TForm_Routiner.Memo_cmdEditingDone(Sender: TObject);
begin
  //
end;

procedure TForm_Routiner.Memo_cmdKeyPress(Sender: TObject; var Key: char);
begin
  //
end;
procedure TForm_Routiner.Button_advancedClick(Sender: TObject);
begin
  SetLayout((byte(Self.InitialLayout)+1) mod 5);
end;

procedure TForm_Routiner.Button_excelClick(Sender: TObject);
begin
  SettingLagForm.Show;
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

procedure TForm_Routiner.Button_TreeViewFreshClick(Sender: TObject);
begin
  WindowsFilter;
end;

procedure TForm_Routiner.Button_Wnd_RecordClick(Sender: TObject);
begin
  if not Self.Record_mode then
    begin
      Self.Record_mode:=true;
      (Sender as TButton).Caption:='结束录制键盘消息';
      (Sender as TButton).Font.Bold:=true;
      (Sender as TButton).Font.Color:=clRed;
      Self.LastRecTime:=GetTimeNumber;
    end
  else
    begin
      Self.Record_mode:=false;
      (Sender as TButton).Caption:='开始录制键盘消息';
      (Sender as TButton).Font.Bold:=false;
      (Sender as TButton).Font.Color:=clDefault;
    end;
end;

procedure TForm_Routiner.Button_Wnd_SynthesisClick(Sender: TObject);
begin
  if not Self.Synthesis_mode then
    begin
      Self.Synthesis_mode:=true;
      (Sender as TButton).Caption:='结束同步键盘消息';
      (Sender as TButton).Font.Bold:=true;
    end
  else
    begin
      Self.Synthesis_mode:=false;
      (Sender as TButton).Caption:='开始同步键盘消息';
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

procedure TForm_Routiner.SetLayout(layout:byte);
begin
  Self.MainMenu.Items[1].Items[0].Enabled:=true;
  Self.MainMenu.Items[1].Items[1].Enabled:=true;
  Self.MainMenu.Items[1].Items[2].Enabled:=true;
  Self.MainMenu.Items[1].Items[3].Enabled:=true;
  Self.MainMenu.Items[1].Items[4].Enabled:=true;
  case TLayoutSet(layout) of
  Lay_Command:
    begin
    Self.InitialLayout:=Lay_Command;
    Self.Width:=WindowsListW + 150;
    Self.Height:=(SynCount+1)*(gap+SynchronicH) + MainMenuH + 150;
    Self.MainMenu.Items[1].Items[0].Enabled:=false;
    end;
  Lay_advanced:
    begin
    Self.InitialLayout:=Lay_Advanced;
    Self.Width:=WindowsListW + 450;
    Self.Height:=(SynCount+1)*(gap+SynchronicH) + MainMenuH + 300;
    Self.MainMenu.Items[1].Items[1].Enabled:=false;
    end;
  Lay_SynChronic:
    begin
    Self.InitialLayout:=Lay_Synchronic;
    Self.Width:=WindowsListW + 150;
    Self.Height:=(SynCount+1)*(gap+SynchronicH) + MainMenuH;
    Self.MainMenu.Items[1].Items[2].Enabled:=false;
    end;
  Lay_Buttons:
    begin
    Self.InitialLayout:=Lay_Buttons;
    Self.Width:=WindowsListW + 150;
    Self.Height:=(SynCount+1)*(gap+SynchronicH) + MainMenuH;
    Self.MainMenu.Items[1].Items[3].Enabled:=false;
    end;
  Lay_Recorder:
    begin
    Self.InitialLayout:=Lay_Recorder;
    Self.Width:=WindowsListW + 150;
    Self.Height:=(SynCount+1)*(gap+SynchronicH) + MainMenuH + 150;
    Self.MainMenu.Items[1].Items[4].Enabled:=false;
    end;
  end;
  Self.FormResize(nil);
end;

procedure TForm_Routiner.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
    SaveOption;
    StopHookK;
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
  with (Sender as TARVCheckBox) do TheLabel.font.bold:=checked
end;

procedure TARVLabel.LabelOnClick(Sender:TObject);
begin
  with Sender as TARVLabel do CheckBox.Checked:=not CheckBox.Checked;
end;

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
  AufButtonForm.Edit_Caption.Caption:=Self.Caption;
  AufButtonForm.ComboBox_Window.ItemIndex:=Self.WindowIndex;
  AufButtonForm.ComboBox_Window.Enabled:=Self.WindowChangeable;
  AufButtonForm.ComboBox_Window.ItemIndex:=Self.WindowIndex;
  AufButtonForm.Button_FileName.Caption:=Self.ScriptFile;
  AufButtonForm.Show;
  AufButtonForm.FormShow(nil);
end;
procedure TAufButton.ButtonMouseUp(Sender: TObject; Button: TMouseButton;
                      Shift: TShiftState; X, Y: Integer);
begin
  if Button=mbRight then begin ButtonRightUp;exit end;
  if Button=mbLeft then begin ButtonLeftUp;exit end;
  if Button=mbMiddle then begin AufStop;exit end;

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

end.

