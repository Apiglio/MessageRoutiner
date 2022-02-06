//{$define insert}

unit MessageRoutiner_Unit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Messages,
  Windows, StdCtrls, ComCtrls, ExtCtrls, Menus, LazUTF8, Apiglio_Useful;

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


  { TForm_Routiner }

  TForm_Routiner = class(TForm)
    Button_Wnd_Fresh: TButton;
    Button_advanced: TButton;
    Button_end: TButton;
    Button_run: TButton;
    Button_Wnd_Synthesis: TButton;
    Memo_output: TMemo;
    Memo_cmd: TMemo;
    TreeView_Wnd: TTreeView;
    procedure Button_endClick(Sender: TObject);
    procedure Button_runClick(Sender: TObject);
    procedure Button_advancedClick(Sender: TObject);
    procedure Button_Wnd_FreshClick(Sender: TObject);
    procedure Button_Wnd_SynthesisClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure Memo_cmdEditingDone(Sender: TObject);
    procedure Memo_cmdKeyPress(Sender: TObject; var Key: char);

    procedure GetMessageUpdate(var Msg:TMessage);message WM_USER+100;
  private
    { private declarations }
    Show_Advanced_Seting:boolean;//是否显示高级设置
    Height_Advanced_Seting:word;//高级设置高度
    Left_Column_Width:word;//左边栏的宽度
  public
    { public declarations }
    Edits:array[0..4]of TARVEdit;
    Buttons:array[0..4]of TARVButton;
    Labels:array[0..4]of TARVLabel;
    CheckBoxs:array[0..4]of TARVCheckBox;
    Synthesis_mode:boolean;//为真时向所有选中的TARVButton.sel_hwnd窗体广播
    State:record
      ctrl,alt,shift,win:boolean;
    end;
  end;

var
  Form_Routiner: TForm_Routiner;
  WndRoot:TWindow;

implementation

{$R *.lfm}

function StartHookK(MsgID:Word):Bool;stdcall;external 'DesktopCommander_keyboard_dll.dll' name 'StartHook';
function StopHookK:Bool;stdcall;external 'DesktopCommander_keyboard_dll.dll' name 'StopHook';
procedure SetCallHandleK(sender:HWND);stdcall;external 'DesktopCommander_keyboard_dll.dll' name 'SetCallHandle';




procedure command_decoder(var str:string);
begin
  str:=utf8towincp(str);
end;

procedure renew_pre;
begin

  Form_Routiner.Memo_output.SelStart:=SendMessage(Form_Routiner.Memo_output.Handle, EM_LINEINDEX, Auf.Script.currentline - 1, 0);
  Form_Routiner.Memo_output.SelLength:=Length(Form_Routiner.Memo_output.Lines[Auf.Script.currentline]);
  Application.ProcessMessages;

end;

procedure renew_post;
begin
  Application.ProcessMessages;
end;

procedure renew_mid;
begin
  Application.ProcessMessages;
end;

procedure renew_beginning;
begin
  Form_Routiner.Memo_output.Clear;
end;

procedure renew_ending;
begin
  Form_Routiner.Button_run.Enabled:=true;
  Form_Routiner.Button_end.Enabled:=false;
  Form_Routiner.Memo_cmd.ReadOnly:=false;
end;



procedure renew_writeln(str:string);
begin
  Form_Routiner.Memo_output.lines.add(ansitoutf8(str));
end;

procedure renew_write(str:string);
begin
  Form_Routiner.Memo_output.lines[Form_Routiner.Memo_output.Lines.Count-1]:=
  Form_Routiner.Memo_output.lines[Form_Routiner.Memo_output.Lines.Count-1]+
  ansitoutf8(str);
end;

procedure PrintWindows(wnd:TWindow);
var i:integer;

begin

  renew_writeln(inttohex(wnd.info.hd,8)+':'+wnd.info.name);
  Application.ProcessMessages;

  renew_writeln('{');
  Application.ProcessMessages;


  for i:=0 to wnd.child.count-1 do
    begin
      PrintWindows(TWindow(wnd.child[i]));
    end;

  renew_writeln('}');
  Application.ProcessMessages;

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

procedure GetChildWindows(wnd:TWindow);
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

      if (new_wnd.parent.node)=nil then
        Form_Routiner.TreeView_Wnd.Items.add(nil,'['+IntToHex(hd,8)+']'+title)
      else
        Form_Routiner.TreeView_Wnd.Items.addchild((new_wnd.parent.node) as TTreeNode,'['+IntToHex(hd,8)+']'+title);
      new_wnd.node:=Form_Routiner.TreeView_Wnd.Items[Form_Routiner.TreeView_Wnd.Items.count-1];
      (new_wnd.node as TTreeNode).data:=new_wnd;


      GetChildWindows(new_wnd);

      hd:=GetNextWindow(hd,GW_HWNDNEXT);

    end;
end;


procedure WndFinder;
var hd:HWND;
begin

  //Form_Routiner.TreeView_Wnd.Items.add(nil,'sss');
  //Form_Routiner.TreeView_Wnd.Items.addchild(Form_Routiner.TreeView_Wnd.Items[0],'saa');

  ClearWindows(WndRoot);
  hd:=GetDesktopWindow;//得到桌面窗口
  WndRoot:=TWindow.Create(hd,'WndRoot',0,0,0,0);
  WndRoot.parent:=nil;
  WndRoot.node:=nil;

  GetChildWindows(WndRoot);

  //PrintWindows(WndRoot);

end;

{ COMMAND }

procedure print_version;
begin
  renew_writeln('Apiglio Message Routiner');
  renew_writeln('- version 0.0.3 -');
  renew_writeln('- by Apiglio -');

end;

procedure SendString;
var hd:longint;
    str:string;
    i:integer;
begin
  hd:=Round(Auf.Script.to_double(Auf.nargs[1].pre,Auf.nargs[1].arg));
  str:=Auf.nargs[2].arg;
  for i:=1 to length(str) do
    begin
      sendmessage(hd,WM_CHAR,ord(str[i]),0);
    end;
end;

procedure SendWideString;
var hd:longint;
    str:string;
    i:integer;
begin
  hd:=Round(Auf.Script.to_double(Auf.nargs[1].pre,Auf.nargs[1].arg));
  str:=Auf.nargs[2].arg;
  if odd(length(str)) then begin Auf.Script.IO_fptr.echo('错误：widestring长度为奇数');exit end;
  for i:=2 to length(str) div 2 do
    begin
      sendmessage(hd,WM_IME_CHAR,(ord(str[i-1]) shl 8) + ord(str[i]),0);
    end;
end;

procedure SendM;
var hd,msg,wparam,lparam:longint;
begin
  hd:=Round(Auf.Script.to_double(Auf.nargs[1].pre,Auf.nargs[1].arg));
  msg:=Round(Auf.Script.to_double(Auf.nargs[2].pre,Auf.nargs[2].arg));
  wparam:=Round(Auf.Script.to_double(Auf.nargs[3].pre,Auf.nargs[3].arg));
  lparam:=Round(Auf.Script.to_double(Auf.nargs[4].pre,Auf.nargs[4].arg));
  //Auf.Script.IO_fptr.echo(IntToStr(hd)+', '+IntToStr(msg)+', '+IntToStr(wparam)+', '+IntToStr(lparam));
  SendMessage(hd,msg,wparam,lparam);
end;

procedure PostM;
var hd,msg,wparam,lparam:longint;
begin
  hd:=Round(Auf.Script.to_double(Auf.nargs[1].pre,Auf.nargs[1].arg));
  msg:=Round(Auf.Script.to_double(Auf.nargs[2].pre,Auf.nargs[2].arg));
  wparam:=Round(Auf.Script.to_double(Auf.nargs[3].pre,Auf.nargs[3].arg));
  lparam:=Round(Auf.Script.to_double(Auf.nargs[4].pre,Auf.nargs[4].arg));
  PostMessage(hd,msg,wparam,lparam);
end;

procedure KeyPress_Event;
var hd,key,delay:longint;
begin
  hd:=Round(Auf.Script.to_double(Auf.nargs[1].pre,Auf.nargs[1].arg));
  key:=Round(Auf.Script.to_double(Auf.nargs[2].pre,Auf.nargs[2].arg));
  delay:=Round(Auf.Script.to_double(Auf.nargs[3].pre,Auf.nargs[3].arg));
  if delay=0 then delay:=50;
  PostMessage(hd,WM_KeyDown,key,(key shl 32)+1);
  sleep(delay);
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

procedure TForm_Routiner.GetMessageUpdate(var Msg:TMessage);
var x,y:integer;
    i:byte;
begin
  x := pMouseHookStruct(Msg.LParam)^.pt.X;
  y := pMouseHookStruct(Msg.LParam)^.pt.Y;

  //if Trace then Self.Memo_cmd.lines.add('更新消息：n='+IntToStr(Msg.WParam)+' x='+IntToStr(x)+' y='+IntToStr(y));

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
              end;
            end;
        end;

        if Self.State.ctrl and (Msg.wParam=WM_KeyUp) and (x = 192) then Self.Button_Wnd_SynthesisClick(Self.Button_Wnd_Synthesis);
        if Self.State.ctrl and (Msg.wParam=WM_KeyUp) and (x in [49..53]) then Self.CheckBoxs[x-49].Checked:=not Self.CheckBoxs[x-49].Checked;

        if Self.Synthesis_mode then begin
        for i:=0 to 4 do
          begin
            if Self.CheckBoxs[i].Checked then postmessage(Self.Buttons[i].sel_hwnd,Msg.wParam,x,y);
          end;
        end;
      end;
    else ;
  end;

end;
//{$ifdef AISUID23dED}
procedure TForm_Routiner.FormCreate(Sender: TObject);
var i:byte;
begin

  Show_Advanced_Seting:=false;
  Height_Advanced_Seting:=200+72;
  Left_Column_Width:=300+120;
  Synthesis_mode:=false;
  Button_Wnd_Synthesis.ShowHint:=true;
  Button_Wnd_Synthesis.Hint:='按Ctrl+`切换状态';

  //默认尺寸状态
  Self.Width:=615;
  Self.Height:=305;

  Self.Position:=poScreenCenter;

  for i:=0 to 4 do
    begin
      Self.Edits[i]:=TARVEdit.Create(Self);
      Self.Buttons[i]:=TARVButton.Create(Self);
      Self.Edits[i].Parent:=Self;
      Self.Buttons[i].Parent:=Self;
      Self.Edits[i].Button:=Self.Buttons[i];
      Self.Buttons[i].Edit:=Self.Edits[i];
      Self.Edits[i].Text:='@'+IntToStr(i*8);
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

  Auf.Script.Func_Process.pre:=@renew_pre;
  Auf.Script.Func_Process.post:=@renew_post;
  Auf.Script.Func_Process.mid:=@renew_mid;
  Auf.Script.Func_Process.beginning:=@renew_beginning;
  Auf.Script.Func_Process.ending:=@renew_ending;
  Auf.Script.IO_fptr.error:=@renew_writeln;
  Auf.Script.IO_fptr.print:=@renew_write;
  Auf.Script.IO_fptr.echo:=@renew_writeln;
  //Auf.Script.IO_fptr.readln:=@;
  Auf.Script.IO_fptr.command_decode:=@command_decoder;

  Auf.Script.add_func('version',@print_version,'版本信息');
  Auf.Script.add_func('about',@print_version,'版本信息');
  Auf.Script.add_func('post',@PostM,'调用Postmessage(hwnd,msg,wparam,lparam)');
  Auf.Script.add_func('send',@SendM,'调用Sendmessage(hwnd,msg,wparam,lparam)');
  Auf.Script.add_func('keypress',@KeyPress_Event,'调用KeyPress_Event(hwnd,key,deley)');
  Auf.Script.add_func('string',@SendString,'向窗口输入字符串');
  Auf.Script.add_func('widestring',@SendWideString,'向窗口输入汉字字符串');

  WndFinder;
  FormResize(nil);

  SetCallHandleK(Self.Handle);
  if not StartHookK(WM_USER+100) then
  begin
    ShowMessage('挂钩失败！');
  end;


end;

procedure TForm_Routiner.FormResize(Sender: TObject);
var i:byte;
begin

  IF Show_Advanced_Seting THEN
    BEGIN

      if Self.Width<Left_Column_Width+322 then Self.Width:=Left_Column_Width+322;
      if Self.Height<360+Height_Advanced_Seting then Self.Height:=360+Height_Advanced_Seting;

      Memo_cmd.Left:=10;
      Memo_cmd.Width:=Left_Column_Width;
      Memo_cmd.Top:=10;
      Memo_cmd.Height:=Self.Height-20-Height_Advanced_Seting;
      Memo_output.Top:=10;
      Memo_output.Left:=20+Memo_cmd.Width;
      Memo_output.Width:=Self.Width-30-Memo_cmd.Width;
      Memo_output.Height:=Self.Height-30-30-Height_Advanced_Seting-trunc(0.4*Self.Height);

      Button_end.Left:=Memo_output.Left;
      Button_end.Top:=Memo_output.Height+10+10;
      Button_end.Width:=90;
      Button_end.Height:=30;

      Button_run.Left:=Memo_output.Left+5+Button_end.Width;
      Button_run.Top:=Memo_output.Height+10+10;
      Button_run.Width:=90;
      Button_run.Height:=30;

      Button_advanced.Left:=Memo_output.Left+5+Button_end.Width+5+Button_run.Width;
      Button_advanced.Top:=Memo_output.Height+10+10;
      Button_advanced.Width:=Self.Width-(Memo_cmd.Width+10+Button_end.Width+10+Button_run.Width+10+10);
      Button_advanced.Height:=30;

      Button_Wnd_Fresh.Top:=Memo_cmd.Height+10+10+144+36;
      Button_Wnd_Fresh.Left:=10;
      Button_Wnd_Fresh.Height:=36;
      Button_Wnd_Fresh.Width:=Memo_cmd.Width;

      Button_Wnd_Synthesis.Top:=Memo_cmd.Height+10+10+144+44+36;
      Button_Wnd_Synthesis.Left:=10;
      Button_Wnd_Synthesis.Height:=36;
      Button_Wnd_Synthesis.Width:=Memo_cmd.Width;

      TreeView_Wnd.Top:=Memo_output.Height+10+10+50;
      TreeView_Wnd.Height:=Height_Advanced_Seting-20+trunc(0.4*Self.Height);
      TreeView_Wnd.Left:=20+Memo_cmd.Width;
      TreeView_Wnd.Width:=Self.Width-30-Memo_cmd.Width;

      for i:=0 to 4 do
        begin
          Self.Buttons[i].Top:=Memo_cmd.Height+10+10+36*i;
          Self.Buttons[i].Width:=Memo_cmd.Width-10-60-90;
          Self.Buttons[i].Left:=60+20;
          Self.Buttons[i].Height:=28;

          Self.Edits[i].Top:=Self.Buttons[i].Top;
          Self.Edits[i].Width:=60;
          Self.Edits[i].Left:=10;
          Self.Edits[i].Height:=28;

          Self.CheckBoxs[i].Left:=10+Self.Edits[i].Width+10+Self.Buttons[i].Width+10;
          Self.CheckBoxs[i].Top:=Self.Buttons[i].Top+3;
          Self.Labels[i].Left:=10+Self.Edits[i].Width+10+Self.Buttons[i].Width+10+10+10;
          Self.Labels[i].Top:=Self.Buttons[i].Top+5;

        end;

    END
  ELSE
    BEGIN

      if Self.Width<Left_Column_Width+322 then Self.Width:=Left_Column_Width+322;
      if Self.Height<360 then Self.Height:=360;

      Memo_cmd.Left:=10;
      Memo_cmd.Width:=Left_Column_Width;
      Memo_cmd.Top:=10;
      Memo_cmd.Height:=Self.Height-20;
      Memo_output.Left:=20+Memo_cmd.Width;
      Memo_output.Top:=10;
      Memo_output.Width:=Self.Width-30-Memo_cmd.Width;
      Memo_output.Height:=Self.Height-30-30;

      Button_end.Left:=Memo_output.Left;
      Button_end.Top:=Memo_output.Height+10+10;
      Button_end.Width:=90;
      Button_end.Height:=30;

      Button_run.Left:=Memo_output.Left+5+Button_end.Width;
      Button_run.Top:=Memo_output.Height+10+10;
      Button_run.Width:=90;
      Button_run.Height:=30;

      Button_advanced.Left:=Memo_output.Left+5+Button_end.Width+5+Button_run.Width;
      Button_advanced.Top:=Memo_output.Height+10+10;
      Button_advanced.Width:=Self.Width-(Memo_cmd.Width+10+Button_end.Width+10+Button_run.Width+10+10);
      Button_advanced.Height:=30;

      Button_Wnd_Fresh.Top:=Memo_output.Height+10+10+50+144+36+Height_Advanced_Seting;
      Button_Wnd_Fresh.Left:=10;
      Button_Wnd_Fresh.Height:=36;
      Button_Wnd_Fresh.Width:=Memo_cmd.Width;

      Button_Wnd_Synthesis.Top:=Memo_output.Height+10+10+50+144+36+44+Height_Advanced_Seting;
      Button_Wnd_Synthesis.Left:=10;
      Button_Wnd_Synthesis.Height:=36;
      Button_Wnd_Synthesis.Width:=Memo_cmd.Width;

      TreeView_Wnd.Top:=Memo_output.Height+10+10+50+Height_Advanced_Seting;
      TreeView_Wnd.Height:=Height_Advanced_Seting-20;
      TreeView_Wnd.Left:=20+Memo_cmd.Width;
      TreeView_Wnd.Width:=Self.Width-30-Memo_cmd.Width;

      for i:=0 to 4 do
        begin
          Self.Buttons[i].Top:=Memo_cmd.Height+10+10+36*i;
          Self.Buttons[i].Width:=Memo_cmd.Width-10-60;
          Self.Buttons[i].Left:=60+20;
          Self.Buttons[i].Height:=28;

          Self.Edits[i].Top:=Memo_cmd.Height+10+10+36*i;
          Self.Edits[i].Width:=60;
          Self.Edits[i].Left:=10;
          Self.Edits[i].Height:=28;

          Self.CheckBoxs[i].Left:=10+Self.Edits[i].Width+10+Self.Buttons[i].Width+10;
          Self.CheckBoxs[i].Top:=Self.Buttons[i].Top+3;
          Self.Labels[i].Left:=10+Self.Edits[i].Width+10+Self.Buttons[i].Width+10+10+10;
          Self.Labels[i].Top:=Self.Buttons[i].Top+5;

        end;

    END;

end;

procedure TForm_Routiner.Memo_cmdEditingDone(Sender: TObject);
begin
  //
end;

procedure TForm_Routiner.Memo_cmdKeyPress(Sender: TObject; var Key: char);
begin
  {if Key=#13 then
    begin

    end;}
end;

procedure TForm_Routiner.Button_runClick(Sender: TObject);
begin
  Memo_cmd.ReadOnly:=true;
  Button_run.Enabled:=not Button_run.Enabled;
  Button_end.Enabled:=not Button_end.Enabled;
  Auf.Script.command(Memo_cmd.Lines);
end;

procedure TForm_Routiner.Button_advancedClick(Sender: TObject);
begin
  if Show_Advanced_Seting then
    begin
      (Sender as TButton).Caption:='展开高级设置';
      Show_Advanced_Seting:=false;
      Self.Height:=Self.Height-Height_Advanced_Seting;
      FormResize(nil);
    end
  else
    begin
      (Sender as TButton).Caption:='收起高级设置';
      Show_Advanced_Seting:=true;
      Self.Height:=Self.Height+Height_Advanced_Seting;
      FormResize(nil);
    end;
end;



procedure TForm_Routiner.Button_endClick(Sender: TObject);
begin
  Memo_cmd.ReadOnly:=false;
  Auf.Script.HaltOff;
  Button_run.Enabled:=not Button_run.Enabled;
  Button_end.Enabled:=not Button_end.Enabled;
end;

procedure TForm_Routiner.Button_Wnd_FreshClick(Sender: TObject);
begin
  TreeView_Wnd.items.clear;
  //TreeView_Wnd.items.addfirst(nil,'sss');
  //TreeView_Wnd.items.addfirst(nil,'ddd');
  WndFinder;
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
begin
  node:=Form_Routiner.TreeView_Wnd.selected;
  if node=nil then
    begin
      renew_writeln('错误：不能将nil赋值给变量，请选择一个窗体！');
      exit
    end;
  wind:=TWindow(Form_Routiner.TreeView_Wnd.selected.data);
  Auf.ReadArgs(Self.Edit.Text);
  case Auf.nargs[0].pre of
    '@':pLongint(Auf.Script.pointer(Auf.nargs[0].pre,StrToInt(Auf.nargs[0].arg)))^:=wind.info.hd;
    '~':pDouble(Auf.Script.pointer(Auf.nargs[0].pre,StrToInt(Auf.nargs[0].arg)))^:=wind.info.hd;
    else begin renew_writeln('错误：无效的变量名，需要长整型或浮点型！');exit end;
  end;
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

