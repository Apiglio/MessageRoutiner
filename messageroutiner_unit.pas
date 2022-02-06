//{$define insert}

unit MessageRoutiner_Unit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Messages,
  Windows, StdCtrls, ComCtrls, LazUTF8{$ifndef insert}, Apiglio_Useful{$endif};

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


  { TForm_Routiner }

  TForm_Routiner = class(TForm)
    Button_Wnd_Def_4: TButton;
    Button_Wnd_Def_3: TButton;
    Button_Wnd_Def_2: TButton;
    Button_Wnd_Def_1: TButton;
    Button_Wnd_Fresh: TButton;
    Button_advanced: TButton;
    Button_end: TButton;
    Button_run: TButton;
    Edit_Wnd_Def_4: TEdit;
    Edit_Wnd_Def_3: TEdit;
    Edit_Wnd_Def_2: TEdit;
    Edit_Wnd_Def_1: TEdit;
    Memo_output: TMemo;
    Memo_cmd: TMemo;
    TreeView_Wnd: TTreeView;
    procedure Button_endClick(Sender: TObject);
    procedure Button_runClick(Sender: TObject);
    procedure Button_advancedClick(Sender: TObject);
    procedure Button_Wnd_Def_1Click(Sender: TObject);
    procedure Button_Wnd_Def_2Click(Sender: TObject);
    procedure Button_Wnd_Def_3Click(Sender: TObject);
    procedure Button_Wnd_Def_4Click(Sender: TObject);
    procedure Button_Wnd_FreshClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure Memo_cmdEditingDone(Sender: TObject);
    procedure Memo_cmdKeyPress(Sender: TObject; var Key: char);
  private
    { private declarations }
    Show_Advanced_Seting:boolean;//是否显示高级设置
    Height_Advanced_Seting:word;//高级设置高度
  public
    { public declarations }
  end;

var
  Form_Routiner: TForm_Routiner;
  WndRoot:TWindow;

implementation

{$R *.lfm}

procedure renew_pre;
begin
  //
end;

procedure renew_post;
begin
  Application.ProcessMessages;
end;

procedure renew_beginning;
begin
  //
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
  renew_writeln('- version 0.0.1 -');
  renew_writeln('- by Apiglio -');

end;

procedure SendM;
var hd,msg,wparam,lparam:longint;
begin
  hd:=Round(Auf.Script.to_double(Auf.nargs[1].pre,Auf.nargs[1].arg));
  msg:=Round(Auf.Script.to_double(Auf.nargs[2].pre,Auf.nargs[2].arg));
  wparam:=Round(Auf.Script.to_double(Auf.nargs[3].pre,Auf.nargs[3].arg));
  lparam:=Round(Auf.Script.to_double(Auf.nargs[4].pre,Auf.nargs[4].arg));
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

procedure TForm_Routiner.FormCreate(Sender: TObject);
begin

  Show_Advanced_Seting:=false;
  Height_Advanced_Seting:=200;

  Self.Position:=poScreenCenter;
  Auf.Script.Func_Process.pre:=@renew_pre;
  Auf.Script.Func_Process.post:=@renew_post;
  Auf.Script.Func_Process.beginning:=@renew_beginning;
  Auf.Script.Func_Process.ending:=@renew_ending;
  Auf.Script.IO_fptr.error:=@renew_writeln;
  Auf.Script.IO_fptr.print:=@renew_write;
  Auf.Script.IO_fptr.echo:=@renew_writeln;
  //Auf.Script.IO_fptr.readln:=@;

  Auf.Script.add_func('version',@print_version,'版本信息');
  Auf.Script.add_func('about',@print_version,'版本信息');
  Auf.Script.add_func('post',@PostM,'调用postmessage');
  Auf.Script.add_func('send',@SendM,'调用sendmessage');

  WndFinder;

end;

procedure TForm_Routiner.FormResize(Sender: TObject);
begin

  IF Show_Advanced_Seting THEN
    BEGIN

      if Self.Width<622 then Self.Width:=622;
      if Self.Height<300+Height_Advanced_Seting then Self.Height:=300+Height_Advanced_Seting;

      Memo_cmd.Left:=10;
      Memo_cmd.Width:=300;
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


      Button_Wnd_Def_1.Top:=Memo_cmd.Height+10+10;
      Button_Wnd_Def_2.Top:=Memo_cmd.Height+10+10+36;
      Button_Wnd_Def_3.Top:=Memo_cmd.Height+10+10+72;
      Button_Wnd_Def_4.Top:=Memo_cmd.Height+10+10+108;
      Button_Wnd_Def_1.Width:=Memo_cmd.Width-10-60;
      Button_Wnd_Def_2.Width:=Memo_cmd.Width-10-60;
      Button_Wnd_Def_3.Width:=Memo_cmd.Width-10-60;
      Button_Wnd_Def_4.Width:=Memo_cmd.Width-10-60;
      Button_Wnd_Def_1.Left:=60+20;
      Button_Wnd_Def_2.Left:=60+20;
      Button_Wnd_Def_3.Left:=60+20;
      Button_Wnd_Def_4.Left:=60+20;

      Edit_Wnd_Def_1.Top:=Memo_cmd.Height+10+10;
      Edit_Wnd_Def_2.Top:=Memo_cmd.Height+10+10+36;
      Edit_Wnd_Def_3.Top:=Memo_cmd.Height+10+10+72;
      Edit_Wnd_Def_4.Top:=Memo_cmd.Height+10+10+108;
      Edit_Wnd_Def_1.Width:=60;
      Edit_Wnd_Def_2.Width:=60;
      Edit_Wnd_Def_3.Width:=60;
      Edit_Wnd_Def_4.Width:=60;
      Edit_Wnd_Def_1.Left:=10;
      Edit_Wnd_Def_2.Left:=10;
      Edit_Wnd_Def_3.Left:=10;
      Edit_Wnd_Def_4.Left:=10;

      Button_Wnd_Fresh.Top:=Memo_cmd.Height+10+10+144;
      Button_Wnd_Fresh.Left:=10;
      Button_Wnd_Fresh.Height:=36;
      Button_Wnd_Fresh.Width:=Memo_cmd.Width;

      TreeView_Wnd.Top:=Memo_output.Height+10+10+50;
      TreeView_Wnd.Height:=Height_Advanced_Seting-20+trunc(0.4*Self.Height);
      TreeView_Wnd.Left:=20+Memo_cmd.Width;
      TreeView_Wnd.Width:=Self.Width-30-Memo_cmd.Width;

    END
  ELSE
    BEGIN

      if Self.Width<622 then Self.Width:=622;
      if Self.Height<300 then Self.Height:=300;

      Memo_cmd.Left:=10;
      Memo_cmd.Width:=300;
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

      Button_Wnd_Def_1.Top:=Memo_cmd.Height+10+10;
      Button_Wnd_Def_2.Top:=Memo_cmd.Height+10+10+36;
      Button_Wnd_Def_3.Top:=Memo_cmd.Height+10+10+72;
      Button_Wnd_Def_4.Top:=Memo_cmd.Height+10+10+108;
      Button_Wnd_Def_1.Width:=Memo_cmd.Width-10-60;
      Button_Wnd_Def_2.Width:=Memo_cmd.Width-10-60;
      Button_Wnd_Def_3.Width:=Memo_cmd.Width-10-60;
      Button_Wnd_Def_4.Width:=Memo_cmd.Width-10-60;
      Button_Wnd_Def_1.Left:=60+20;
      Button_Wnd_Def_2.Left:=60+20;
      Button_Wnd_Def_3.Left:=60+20;
      Button_Wnd_Def_4.Left:=60+20;

      Edit_Wnd_Def_1.Top:=Memo_cmd.Height+10+10;
      Edit_Wnd_Def_2.Top:=Memo_cmd.Height+10+10+36;
      Edit_Wnd_Def_3.Top:=Memo_cmd.Height+10+10+72;
      Edit_Wnd_Def_4.Top:=Memo_cmd.Height+10+10+108;
      Edit_Wnd_Def_1.Width:=60;
      Edit_Wnd_Def_2.Width:=60;
      Edit_Wnd_Def_3.Width:=60;
      Edit_Wnd_Def_4.Width:=60;
      Edit_Wnd_Def_1.Left:=10;
      Edit_Wnd_Def_2.Left:=10;
      Edit_Wnd_Def_3.Left:=10;
      Edit_Wnd_Def_4.Left:=10;

      Button_Wnd_Fresh.Top:=Memo_output.Height+10+10+50+144+Height_Advanced_Seting;
      Button_Wnd_Fresh.Left:=10;
      Button_Wnd_Fresh.Height:=36;
      Button_Wnd_Fresh.Width:=Memo_cmd.Width;



      TreeView_Wnd.Top:=Memo_output.Height+10+10+50+Height_Advanced_Seting;
      TreeView_Wnd.Height:=Height_Advanced_Seting-20;
      TreeView_Wnd.Left:=20+Memo_cmd.Width;
      TreeView_Wnd.Width:=Self.Width-30-Memo_cmd.Width;

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

procedure TForm_Routiner.Button_Wnd_Def_1Click(Sender: TObject);
begin
  Auf.ReadArgs(Edit_Wnd_Def_1.Text);
  case Auf.nargs[0].pre of
    '@':pLongint(Auf.Script.pointer(Auf.nargs[0].pre,StrToInt(Auf.nargs[0].arg)))^:=TWindow(TreeView_Wnd.selected.data).info.hd;
    '~':pDouble(Auf.Script.pointer(Auf.nargs[0].pre,StrToInt(Auf.nargs[0].arg)))^:=TWindow(TreeView_Wnd.selected.data).info.hd;
    else begin renew_writeln('错误：无效的变量名，需要长整型或浮点型！');exit end;
  end;
  (Sender as TButton).Caption:=IntToHex(TWindow(TreeView_Wnd.selected.data).info.hd,8)+':'+TWindow(TreeView_Wnd.selected.data).info.name;
  (Sender as TButton).hint:=(Sender as TButton).Caption;
  (Sender as TButton).ShowHint:=true

end;

procedure TForm_Routiner.Button_Wnd_Def_2Click(Sender: TObject);
begin
  Auf.ReadArgs(Edit_Wnd_Def_2.Text);
  case Auf.nargs[0].pre of
    '@':pLongint(Auf.Script.pointer(Auf.nargs[0].pre,StrToInt(Auf.nargs[0].arg)))^:=TWindow(TreeView_Wnd.selected.data).info.hd;
    '~':pDouble(Auf.Script.pointer(Auf.nargs[0].pre,StrToInt(Auf.nargs[0].arg)))^:=TWindow(TreeView_Wnd.selected.data).info.hd;
    else begin renew_writeln('错误：无效的变量名，需要长整型或浮点型！');exit end;
  end;
  (Sender as TButton).Caption:=IntToHex(TWindow(TreeView_Wnd.selected.data).info.hd,8)+':'+TWindow(TreeView_Wnd.selected.data).info.name;
  (Sender as TButton).hint:=(Sender as TButton).Caption;
  (Sender as TButton).ShowHint:=true
end;

procedure TForm_Routiner.Button_Wnd_Def_3Click(Sender: TObject);
begin
  Auf.ReadArgs(Edit_Wnd_Def_3.Text);
  case Auf.nargs[0].pre of
    '@':pLongint(Auf.Script.pointer(Auf.nargs[0].pre,StrToInt(Auf.nargs[0].arg)))^:=TWindow(TreeView_Wnd.selected.data).info.hd;
    '~':pDouble(Auf.Script.pointer(Auf.nargs[0].pre,StrToInt(Auf.nargs[0].arg)))^:=TWindow(TreeView_Wnd.selected.data).info.hd;
    else begin renew_writeln('错误：无效的变量名，需要长整型或浮点型！');exit end;
  end;
  (Sender as TButton).Caption:=IntToHex(TWindow(TreeView_Wnd.selected.data).info.hd,8)+':'+TWindow(TreeView_Wnd.selected.data).info.name;
  (Sender as TButton).hint:=(Sender as TButton).Caption;
  (Sender as TButton).ShowHint:=true
end;

procedure TForm_Routiner.Button_Wnd_Def_4Click(Sender: TObject);
begin
  Auf.ReadArgs(Edit_Wnd_Def_4.Text);
  case Auf.nargs[0].pre of
    '@':pLongint(Auf.Script.pointer(Auf.nargs[0].pre,StrToInt(Auf.nargs[0].arg)))^:=TWindow(TreeView_Wnd.selected.data).info.hd;
    '~':pDouble(Auf.Script.pointer(Auf.nargs[0].pre,StrToInt(Auf.nargs[0].arg)))^:=TWindow(TreeView_Wnd.selected.data).info.hd;
    else begin renew_writeln('错误：无效的变量名，需要长整型或浮点型！');exit end;
  end;
  (Sender as TButton).Caption:=IntToHex(TWindow(TreeView_Wnd.selected.data).info.hd,8)+':'+TWindow(TreeView_Wnd.selected.data).info.name;
  (Sender as TButton).hint:=(Sender as TButton).Caption;
  (Sender as TButton).ShowHint:=true
end;

procedure TForm_Routiner.Button_Wnd_FreshClick(Sender: TObject);
begin
  TreeView_Wnd.items.clear;
  //TreeView_Wnd.items.addfirst(nil,'sss');
  //TreeView_Wnd.items.addfirst(nil,'ddd');
  WndFinder;
end;



end.
