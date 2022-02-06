//{$define insert}

unit MessageRoutiner_Unit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Messages,
  Windows, StdCtrls, ComCtrls, ExtCtrls, Menus, LazUTF8{$ifndef insert}, Apiglio_Useful, aufscript_frame{$endif};

const

  version_number='0.0.6';

  RuleCount = 9;
  SynCount = 4;{不能大于9，也不推荐9}
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

  TAufScriptFrame = class(TComponent)
  public
     Frame:TFrame_AufScript;
  end;

  { TForm_Routiner }

  TForm_Routiner = class(TForm)
    Button_excel: TButton;
    Button_TreeViewFresh: TButton;
    Button_Wnd_Fresh: TButton;
    Button_advanced: TButton;
    Button_Wnd_Synthesis: TButton;
    Edit_TreeView: TEdit;
    Label_filter: TLabel;
    MainMenu: TMainMenu;
    Memo_tmp: TMemo;
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
    TreeView_Wnd: TTreeView;
    {
    procedure Button_endClick(Sender: TObject);
    procedure Button_runClick(Sender: TObject);
    }
    procedure Button_advancedClick(Sender: TObject);
    procedure Button_excelClick(Sender: TObject);
    procedure Button_TreeViewFreshClick(Sender: TObject);
    procedure Button_Wnd_FreshClick(Sender: TObject);
    procedure Button_Wnd_SynthesisClick(Sender: TObject);
    procedure Edit_TreeViewChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure Memo_cmdEditingDone(Sender: TObject);
    procedure Memo_cmdKeyPress(Sender: TObject; var Key: char);

    procedure GetMessageUpdate(var Msg:TMessage);message WM_USER+100;
    procedure MenuItem_Lay_advancedClick(Sender: TObject);
    procedure MenuItem_Lay_simpleClick(Sender: TObject);
    procedure MenuItem_Opt_AboutClick(Sender: TObject);
    procedure PageControlChange(Sender: TObject);
    procedure PageControlResize(Sender: TObject);
    procedure WindowsFilter;
  private
    { private declarations }
    Show_Advanced_Seting:boolean;//是否显示高级设置
    Height_Advanced_Seting:word;//高级设置高度
    Left_Column_Width:word;//左边栏的宽度
  public
    { public declarations }
    Edits:array[0..SynCount]of TARVEdit;
    Buttons:array[0..SynCount]of TARVButton;
    Labels:array[0..SynCount]of TARVLabel;
    CheckBoxs:array[0..SynCount]of TARVCheckBox;
    AufScriptFrames:array[0..RuleCount] of TAufScriptFrame;
    Synthesis_mode:boolean;//为真时向所有选中的TARVButton.sel_hwnd窗体广播
    State:record
      ctrl,alt,shift,win:boolean;
      Number:array[0..SynCount]of boolean;//是否抬起，用于放置一次按下触发多次事件
      Gross:boolean;//总闸是否抬起，用于放置一次按下触发多次事件
    end;

    //Timer_Auf:TTimer;//Auf中的SynMoTimer
    Tim:TTimer;//因为不知道怎么处理汉字输入法造成连续的OnChange事件，迫不得已采用延时50ms检测连续输入的办法。
    procedure TreeViewEditOnChange(Sender:TObject);

  end;

var
  Form_Routiner: TForm_Routiner;
  WndRoot:TWindow;
  shutup:boolean;

implementation

{$R *.lfm}

function StartHookK(MsgID:Word):Bool;stdcall;external 'DesktopCommander_keyboard_dll.dll' name 'StartHook';
function StopHookK:Bool;stdcall;external 'DesktopCommander_keyboard_dll.dll' name 'StopHook';
procedure SetCallHandleK(sender:HWND);stdcall;external 'DesktopCommander_keyboard_dll.dll' name 'SetCallHandle';

procedure _shutup(Sender:TObject);
begin
  shutup:=true;
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

procedure layout_to_simple;
var ARVControlH:word;
begin
  ARVControlH:=(SynCount+1)*(gap+SynchronicH);
  Form_Routiner.Show_Advanced_Seting:=false;
  Form_Routiner.Height:=Form_Routiner.Height-ARVControlH;
  Form_Routiner.Width:=Form_Routiner.Width-WindowsListW;
  Form_Routiner.MainMenu.Items[1].Items[1].Enabled:=true;
  Form_Routiner.MainMenu.Items[1].Items[0].Enabled:=false;
  Form_Routiner.FormResize(nil);
end;

procedure layout_to_advanced;
var ARVControlH:word;
begin
  ARVControlH:=(SynCount+1)*(gap+SynchronicH);
  Form_Routiner.Show_Advanced_Seting:=true;
  Form_Routiner.Height:=Form_Routiner.Height+ARVControlH;
  Form_Routiner.Width:=Form_Routiner.Width+WindowsListW;
  Form_Routiner.MainMenu.Items[1].Items[0].Enabled:=true;
  Form_Routiner.MainMenu.Items[1].Items[1].Enabled:=false;
  Form_Routiner.FormResize(nil);
end;








{ COMMAND }

procedure print_version(Sender:TObject);
var AAuf:TAuf;
    AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  AufScpt.IO_fptr.echo(AAuf.Owner,'Apiglio Message Routiner');
  AufScpt.IO_fptr.echo(AAuf.Owner,'- version '+version_number+' -');
  AufScpt.IO_fptr.echo(AAuf.Owner,'- by Apiglio -');
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
  wparam:=Round(AufScpt.to_double(AAuf.nargs[3].pre,AAuf.nargs[3].arg));
  lparam:=Round(AufScpt.to_double(AAuf.nargs[4].pre,AAuf.nargs[4].arg));
  //Auf.Script.IO_fptr.echo(AAuf.Owner,IntToStr(hd)+', '+IntToStr(msg)+', '+IntToStr(wparam)+', '+IntToStr(lparam));
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
  wparam:=Round(AufScpt.to_double(AAuf.nargs[3].pre,AAuf.nargs[3].arg));
  lparam:=Round(AufScpt.to_double(AAuf.nargs[4].pre,AAuf.nargs[4].arg));
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
  key:=Round(AufScpt.to_double(AAuf.nargs[2].pre,AAuf.nargs[2].arg));
  delay:=Round(AufScpt.to_double(AAuf.nargs[3].pre,AAuf.nargs[3].arg));
  if delay=0 then delay:=50;
  PostMessage(hd,WM_KeyDown,key,(key shl 32)+1);
  sleep(delay);//改成防止假死的
  PostMessage(hd,WM_KeyUp,key,(key shl 32)+1);

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

procedure TForm_Routiner.WindowsFilter;
begin
  //Auf.Script.IO_fptr.echo(AAuf.Owner,Edit_TreeView.Text);
  TreeView_Wnd.items.clear;
  WndFinder(Edit_TreeView.Text);
end;

procedure TForm_Routiner.GetMessageUpdate(var Msg:TMessage);
var x,y:integer;
    i:byte;
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
              end;
            end;
          WM_KeyUp:
            begin
              case x of
                162,163:Self.State.Ctrl:=false;
                160,161:Self.State.Shift:=false;
                164,165:Self.State.Alt:=false;
                91,92:Self.State.Win:=false;
                49..49+SynCount:Self.State.Number[x-49]:=true;
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

        if Self.Synthesis_mode then begin
        for i:=0 to SynCount do
          begin
            if Self.CheckBoxs[i].Checked then postmessage(Self.Buttons[i].sel_hwnd,Msg.wParam,x,y);
          end;
        end;
      end;
    else ;
  end;

end;

procedure TForm_Routiner.MenuItem_Lay_advancedClick(Sender: TObject);
var ARVControlH:word;
begin
  layout_to_advanced;
end;

procedure TForm_Routiner.MenuItem_Lay_simpleClick(Sender: TObject);
var ARVControlH:word;
begin
  layout_to_simple;
end;

procedure TForm_Routiner.MenuItem_Opt_AboutClick(Sender: TObject);
begin
  MessageBox(0,
    'Apiglio Message Routiner'+#13+#10+'- version '+version_number+#13+#10+'- by Apiglio',
    PChar(utf8towincp('版本信息')),
    MB_OK);
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

procedure TForm_Routiner.FormCreate(Sender: TObject);
var i:byte;
    page:integer;
    tmp:TTabSheet;
begin

  Show_Advanced_Seting:=false;
  Height_Advanced_Seting:=200+72;
  Left_Column_Width:=300+120;
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
      with AufScriptFrames[page].Frame do
        begin
          AufGenerator;
          Auf.Script.add_func('shutup',@_shutup,'关闭左下角弹窗提示');
          Auf.Script.add_func('resize',@_resize,'w,h 修改当前窗口尺寸');
          Auf.Script.add_func('version',@print_version,'版本信息');
          Auf.Script.add_func('about',@print_version,'版本信息');
          Auf.Script.add_func('post',@PostM,'调用Postmessage(hwnd,msg,wparam,lparam)');
          Auf.Script.add_func('send',@SendM,'调用Sendmessage(hwnd,msg,wparam,lparam)');
          Auf.Script.add_func('keypress',@KeyPress_Event,'调用KeyPress_Event(hwnd,key,deley)');
          Auf.Script.add_func('string',@SendString,'向窗口输入字符串');
          Auf.Script.add_func('widestring',@SendWideString,'向窗口输入汉字字符串');
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
      Self.Edits[i]:=TARVEdit.Create(Self);
      Self.Buttons[i]:=TARVButton.Create(Self);
      Self.Edits[i].Parent:=Self;
      Self.Buttons[i].Parent:=Self;
      Self.Edits[i].Button:=Self.Buttons[i];
      Self.Buttons[i].Edit:=Self.Edits[i];
      Self.Edits[i].Text:='@win'+IntToStr(i);
      Self.Buttons[i].Text:='<<窗体句柄';

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
    end;

  Self.BorderStyle:=bsSingle;
  FormResize(nil);

  tim:=TTimer.Create(Self);
  tim.OnTimer:=@Self.TreeViewEditOnChange;

  SetCallHandleK(Self.Handle);
  if not StartHookK(WM_USER+100) then
  begin
    ShowMessage('挂钩失败！');
  end;


end;

procedure TForm_Routiner.FormResize(Sender: TObject);
var i:byte;
    divi_vertical,divi_horizontal,ARVControlH:word;
    page:integer;
begin
  ARVControlH:=(SynCount+1)*(gap+SynchronicH);
  if Show_Advanced_Seting then
    begin
      divi_vertical:=Self.Width - WindowsListW;
      divi_horizontal:=Self.Height - ARVControlH;
      //Self.Width:=max(Self.Width,615+WindowsListW);
      //Self.Height:=max(Self.Height,305+ARVControlH);
      //if Self.Width<615+WindowsListW then Self.BorderStyle:=bsSingle;
      //if Self.Height<305+ARVControlH then Self.BorderStyle:=bsSingle;
      //我tm一定想办法找到怎么解决
    end
  else
    begin
      divi_vertical:=Self.Width;
      divi_horizontal:=Self.Height;
      //Self.Width:=max(Self.Width,615);
      //Self.Height:=max(Self.Height,305);
      //Self.BorderStyle:=bsSizeable;
    end;

  PageControl.Width:=max(divi_vertical - 2*gap,0);
  PageControl.Height:=max(divi_horizontal- 3 * gap - 24,0);
  PageControl.Left:=gap;
  PageControl.Top:=gap;

  for page:=0 to RuleCount do begin
    Self.AufScriptFrames[page].Frame.Width:=max(PageControl.Width-2*gap,0);
    Self.AufScriptFrames[page].Frame.Height:=max(PageControl.Height-25-2*gap,0);
    Self.AufScriptFrames[page].Frame.Left:=0;
    Self.AufScriptFrames[page].Frame.Top:=0;
  end;
  Self.AufScriptFrames[PageControl.ActivePageIndex].Frame.FrameResize(nil);


  Button_advanced.Left:=gap;
  Button_advanced.Top:=max(divi_horizontal - 24 - gap,0)-MainMenuH;
  Button_advanced.Width:=max(divi_vertical-2*gap-2,0);
  Button_advanced.Height:=24;

  Button_Wnd_Fresh.Top:=max(divi_horizontal,0)-MainMenuH;
  Button_Wnd_Fresh.Left:=gap;
  Button_Wnd_Fresh.Height:=28;
  Button_Wnd_Fresh.Width:=ARVControlW;

  Button_Wnd_Synthesis.Top:=max(divi_horizontal+28+gap,0)-MainMenuH;
  Button_Wnd_Synthesis.Left:=gap;
  Button_Wnd_Synthesis.Height:=28;
  Button_Wnd_Synthesis.Width:=ARVControlW;

  Button_excel.Top:=max(divi_horizontal+2*28+2*gap,0)-MainMenuH;
  Button_excel.Left:=gap;
  Button_excel.Height:=28;
  Button_excel.Width:=ARVControlW;

  Memo_tmp.Top:=max(divi_horizontal+3*28+3*gap,0)-MainMenuH;
  Memo_tmp.Left:=gap;
  Memo_tmp.Height:=Self.Height - gap - Memo_tmp.Top -MainMenuH;
  Memo_tmp.Width:=ARVControlW;

  TreeView_Wnd.Top:=gap;
  TreeView_Wnd.Height:=Self.Height-28-2*gap-MainMenuH;
  TreeView_Wnd.Left:=divi_vertical + gap;
  TreeView_Wnd.Width:=WindowsListW-2*gap;

  Label_Filter.Top:=Self.Height-28-MainMenuH;
  Edit_TreeView.Top:=Self.Height-34-MainMenuH;
  Button_TreeViewFresh.Top:=Self.Height-34-MainMenuH;

  //Label_Filter.Width:=45;
  Edit_TreeView.Width:=TreeView_Wnd.Width - Label_Filter.Width - Button_TreeViewFresh.Width - 4*gap;
  //Button_TreeViewFresh.Width:=72;

  Label_Filter.Left:=TreeView_Wnd.Left;
  Edit_TreeView.Left:=TreeView_Wnd.Left +10 + Label_Filter.Width;
  Button_TreeViewFresh.Left:=TreeView_Wnd.Left +10 + Label_Filter.Width + 10 + Edit_TreeView.Width;

  for i:=0 to SynCount do
    begin
      Self.Edits[i].Top:=max(divi_horizontal+(28+gap)*i-MainMenuH,0);
      Self.Edits[i].Width:=60;
      Self.Edits[i].Left:=ARVControlW+2*gap;
      Self.Edits[i].Height:=28;

      Self.Buttons[i].Top:=Self.Edits[i].Top;
      Self.Buttons[i].Width:=max(divi_vertical-ARVControlW-2*gap-160,0);
      Self.Buttons[i].Left:=Self.Edits[i].Left+Self.Edits[i].Width+gap;
      Self.Buttons[i].Height:=28;

      Self.CheckBoxs[i].Left:=divi_vertical-90;
      Self.CheckBoxs[i].Top:=Self.Buttons[i].Top+3;

      Self.Labels[i].Left:=divi_vertical-70;
      Self.Labels[i].Top:=Self.Buttons[i].Top+5;

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
var ARVControlH:word;
begin
  ARVControlH:=(SynCount+1)*(gap+SynchronicH);
  if Show_Advanced_Seting then
    begin
      (Sender as TButton).Caption:='展开高级设置';   {
      Show_Advanced_Seting:=false;
      Self.Height:=Self.Height-ARVControlH;
      Self.Width:=Self.Width-WindowsListW;
      FormResize(nil);                               }
      layout_to_simple;
    end
  else
    begin
      (Sender as TButton).Caption:='收起高级设置';   {
      Show_Advanced_Seting:=true;
      Self.Height:=Self.Height+ARVControlH;
      Self.Width:=Self.Width+WindowsListW;
      FormResize(nil);                                }
      layout_to_advanced;
    end;
end;

procedure TForm_Routiner.Button_excelClick(Sender: TObject);
begin
  if not shutup then MessageBox(0,PChar(utf8towincp('由于存在一个尚未解决的漏洞，窗体大小只能通过指令调整。'+#13+#10+'设置宽度和高度使用“resize”指令'+#13+#10+'若需要关闭这个弹窗提示在任何一个规则中输入“shutup”后执行')),'Error',MB_OK);
end;

procedure TForm_Routiner.Button_TreeViewFreshClick(Sender: TObject);
begin
  WindowsFilter;
end;

procedure TForm_Routiner.Button_Wnd_FreshClick(Sender: TObject);
begin
  //TreeView_Wnd.items.clear;
  //WndFinder(Edit_TreeView.Text);
  WindowsFilter;
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

procedure TForm_Routiner.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
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
  GlobalExpressionList.TryAddExp(str,narg('',IntToStr(wind.info.hd),''));
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
begin
  //
end;

procedure TARVCheckBox.CheckOnChange(Sender:TObject);
begin
  with (Sender as TARVCheckBox) do TheLabel.font.bold:=checked
end;

procedure TARVLabel.LabelOnClick(Sender:TObject);
begin
  with Sender as TARVLabel do CheckBox.Checked:=not CheckBox.Checked;
end;

end.

