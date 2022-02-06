unit form_aufbutton;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, SynEdit, Forms, Controls, Graphics, Dialogs,
  StdCtrls, Windows;

type

  { TAufButtonForm }

  TAufButtonForm = class(TForm)
    Button_Apply: TButton;
    Button_ApplyCol: TButton;
    Button_ReEdit: TButton;
    Button_FileName: TButton;
    ComboBox_Window: TComboBox;
    Edit_Caption: TEdit;
    Label_Caption: TLabel;
    Label_FileName: TLabel;
    Label_Window: TLabel;
    Label_Syntax: TLabel;
    Syn_Show: TSynEdit;
    OpenDialog: TOpenDialog;
    procedure Button_ApplyClick(Sender: TObject);
    procedure Button_ApplyColClick(Sender: TObject);
    procedure Button_FileNameClick(Sender: TObject);
    procedure Button_ReEditClick(Sender: TObject);
    procedure ComboBox_WindowChange(Sender: TObject);
    procedure Edit_CaptionChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private

  public
    NowEditing:TButton;//当前修改的按键
  public
    procedure Save;
    procedure SaveCol;
    procedure ReEdit;
    procedure ReNewSyntax;
  end;

var
  AufButtonForm: TAufButtonForm;

implementation
uses MessageRoutiner_Unit;

{$R *.lfm}

{ TAufButtonForm }

procedure TAufButtonForm.Save;
var button:TAufButton;
begin
  button:=NowEditing as TAufButton;
  button.Caption:=Self.Edit_Caption.Caption;
  if button.WindowChangeable then button.WindowIndex:=Self.ComboBox_Window.ItemIndex;
  button.ScriptFile:=Self.Button_FileName.Caption;
  button.cmd.Text:=Self.Syn_Show.Text;
end;
procedure TAufButtonForm.SaveCol;
var button:TAufButton;
    coli,wini:byte;
begin
  button:=NowEditing as TAufButton;
  coli:=button.ColumnIndex;
  for wini:=0 to SynCount do with Form_Routiner.AufButtons[wini,coli] do
    begin
      Caption:=Self.Edit_Caption.Caption;
      if WindowChangeable then WindowIndex:=Self.ComboBox_Window.ItemIndex;
      ScriptFile:=Self.Button_FileName.Caption;
      cmd.Text:=Self.Syn_Show.Text;
    end;
end;
procedure TAufButtonForm.ReEdit;//从AufButton读取数据显示在面板中
var button:TAufButton;
begin
  button:=NowEditing as TAufButton;
  Self.Edit_Caption.Caption:=button.Caption;
  if button.WindowChangeable then Self.ComboBox_Window.ItemIndex:=button.WindowIndex;
  Self.Button_FileName.Caption:=button.ScriptFile;
  Self.Syn_Show.Text:=button.cmd.Text;
  ReNewSyntax;
end;

procedure TAufButtonForm.FormCreate(Sender: TObject);
var i:integer;
begin
  Self.Syn_Show.Lines.Clear;
  Self.Syn_Show.Lines.Add('define win, @win_name');
  Self.Syn_Show.Lines.Add('load "scriptfile"');
  Self.ComboBox_Window.Items.Clear;
  for i:=0 to SynCount do Self.ComboBox_Window.Items.Add(Form_Routiner.Edits[i].Text);
  Self.FormResize(nil);
end;

procedure TAufButtonForm.FormHide(Sender: TObject);
begin
  ////////
end;

procedure TAufButtonForm.FormResize(Sender: TObject);
var tre:longint;
begin
  tre:=(Self.Width-40) div 3;
  Self.Button_FileName.Width:=Self.Width-20;
  Self.ComboBox_Window.Width:=Self.Width-20;
  Self.Syn_Show.Width:=Self.Width-20;
  Self.Edit_Caption.Width:=Self.Width-20;
  Self.Button_Apply.Width:=tre;
  Self.Button_ApplyCol.Width:=tre;
  Self.Button_ReEdit.Width:=tre;
  Self.Button_Apply.Left:=10;
  Self.Button_ApplyCol.Left:=20+tre;
  Self.Button_ReEdit.Left:=30+2*tre;

end;

procedure TAufButtonForm.FormShow(Sender: TObject);
begin
  //Self.Syn_Show.Lines[1]:='load "'+Self.Button_FileName.Caption+'"';
  //Self.ComboBox_Window.ItemIndex:=(Self.NowEditing as TAufButton).WindowIndex;
  //Self.Syn_Show.Lines[0]:='define win, @'+Form_Routiner.Buttons[Self.ComboBox_Window.ItemIndex].expression;
  Self.ReEdit;
end;

procedure TAufButtonForm.Button_FileNameClick(Sender: TObject);
begin
  if Self.OpenDialog.Execute then
    begin
      //Self.Syn_Show.Lines[1]:='load "'+Self.OpenDialog.FileName+'"';
      Self.Button_FileName.Caption:=Self.OpenDialog.FileName;
      //(Self.NowEditing as TAufButton).ScriptFile:=Self.OpenDialog.FileName;
      Self.ReNewSyntax;
    end;
end;

procedure TAufButtonForm.Button_ReEditClick(Sender: TObject);
begin
  Self.ReEdit;
end;

procedure TAufButtonForm.Button_ApplyClick(Sender: TObject);
begin
  Self.Save;
end;

procedure TAufButtonForm.Button_ApplyColClick(Sender: TObject);
begin
  Self.SaveCol;
end;

procedure TAufButtonForm.ReNewSyntax;
begin
  Self.Syn_Show.Clear;
  Self.Syn_Show.Lines.Add('define win, @'+Form_Routiner.Buttons[Self.ComboBox_Window.ItemIndex].expression);
  Self.Syn_Show.Lines.Add('load "'+Self.Button_FileName.Caption+'"');
end;

procedure TAufButtonForm.ComboBox_WindowChange(Sender: TObject);
begin
  Self.ReNewSyntax;
  //Self.Syn_Show.Lines[0]:='define win, '+Self.ComboBox_Window.Items[Self.ComboBox_Window.ItemIndex];
  //(Self.NowEditing as TAufButton).WindowIndex:=Self.ComboBox_Window.ItemIndex;
end;

procedure TAufButtonForm.Edit_CaptionChange(Sender: TObject);
begin
  //Self.NowEditing.Caption:=(Sender as TEdit).Caption;
end;

end.

