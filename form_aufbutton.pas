//{$define OldButtFiles}
//0.1.6及以前版本的旧方法，只能接受相对根目录的脚本文件，伺机删除



unit form_aufbutton;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, SynEdit, SynHighlighterHTML, SynHighlighterPas,
  Forms, Controls, Graphics, Dialogs, StdCtrls, Windows, SynHighlighterAuf;

type

  { TAufButtonForm }

  TAufButtonForm = class(TForm)
    Button_Stop: TButton;
    Button_Apply: TButton;
    Button_ApplyCol: TButton;
    Button_ReEdit: TButton;
    Button_FileName: TButton;
    ComboBox_Window: TComboBox;
    Edit_Caption: TEdit;
    Label_Caption: TLabel;
    Label_FileView: TLabel;
    Label_FileName: TLabel;
    Label_Window: TLabel;
    Label_Syntax: TLabel;
    SynEdit_FileView: TSynEdit;
    Syn_Show: TSynEdit;
    OpenDialog: TOpenDialog;
    procedure Button_ApplyClick(Sender: TObject);
    procedure Button_ApplyColClick(Sender: TObject);
    procedure Button_FileNameClick(Sender: TObject);
    procedure Button_ReEditClick(Sender: TObject);
    procedure Button_StopClick(Sender: TObject);
    procedure ComboBox_WindowChange(Sender: TObject);
    procedure Edit_CaptionChange(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private

  public
    NowEditing:TButton;//当前修改的按键
    MultiFile:TStrings;
    FilePath:string;
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
  button.ScriptFile:=Self.MultiFile;
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
      ScriptFile:=Self.MultiFile;
      cmd.Text:=Self.Syn_Show.Text;
    end;
end;
procedure TAufButtonForm.ReEdit;//从AufButton读取数据显示在面板中
var button:TAufButton;
    i:integer;
begin
  button:=NowEditing as TAufButton;
  Self.Edit_Caption.Caption:=button.Caption;

  for i:=0 to SynCount do
    begin
      Self.ComboBox_Window.Items[i]:='@'+Form_Routiner.Buttons[i].expression;
    end;
  if button.WindowChangeable then Self.ComboBox_Window.ItemIndex:=button.WindowIndex
  else Self.ComboBox_Window.ItemIndex:=button.WindowIndex;
  //上面这里定义上没有很好地区分固有行号和实际窗体行号
  //所以以上表述不适用于WindowChangeable=true的状况
  Self.Button_FileName.Caption:=button.ScriptFile.CommaText;
  Self.MultiFile:=button.ScriptFile;
  Self.Syn_Show.Text:=button.cmd.Text;
  Self.ComboBox_Window.Enabled:=button.WindowChangeable;
  ReNewSyntax;
end;

procedure TAufButtonForm.FormCreate(Sender: TObject);
var i:integer;
    str,path,tmppath:string;
begin
  //Self.SynAufSyn:=TSynAufSyn.Create(Self);
  //Self.SynEdit_FileView.Highlighter:=Self.;
  Self.MultiFile:=TStringList.Create;
  Self.MultiFile.Add('scriptfile');
  //Self.Syn_Show.Highlighter:=Self.SynAufSyn;
  Self.Syn_Show.Lines.Clear;
  Self.Syn_Show.Lines.Add('define win, @win_name');
  Self.Syn_Show.Lines.Add('jmp +1');
  path:='';
  for str in Self.MultiFile do
    begin
      tmppath:=ExtractFilePath(str);
      if tmppath<>'' then path:=tmppath;
      if pos(':',str)>0 then
        Self.Syn_Show.Lines.Add('load "'+str+'"')
      else
        Self.Syn_Show.Lines.Add('load "'+path+ExtractFileName(str)+'"');
    end;

  Self.Syn_Show.Lines.Add('end');
  Self.Syn_Show.Lines.Add('');
  //Self.Syn_Show.Lines.Add('load "scriptfile"');
  Self.ComboBox_Window.Items.Clear;
  for i:=0 to SynCount do Self.ComboBox_Window.Items.Add(Form_Routiner.Edits[i].Text);

  Self.OpenDialog.Title:='选择脚本文件';
  Self.OpenDialog.InitialDir:=ExtractFilePath(Application.ExeName);
  Self.OpenDialog.Filter:='AufScript File(*.auf)|*.auf|TableCalc Script File(*.scpt)|*.scpt|布局脚本文件(*.auf.lay)|*.auf.lay|文本文档(*.txt)|*.txt|全部文件(*.*)|*.*';
  Self.OpenDialog.DefaultExt:='*.auf';
  Self.OpenDialog.Options:=[ofAllowMultiSelect,ofFileMustExist,ofEnableSizing,ofViewDetail];

  Self.FormResize(nil);
end;

procedure TAufButtonForm.FormHide(Sender: TObject);
begin
  Self.Button_ReEditClick(Self.Button_ReEdit);
end;

procedure TAufButtonForm.FormResize(Sender: TObject);
var tre:longint;
begin
  tre:=(Self.Width-50) div 4;
  Self.Button_Apply.Width:=tre;
  Self.Button_ApplyCol.Width:=tre;
  Self.Button_ReEdit.Width:=tre;
  Self.Button_Stop.Width:=tre;
end;

procedure TAufButtonForm.FormShow(Sender: TObject);
begin

  Self.ReEdit;
  Self.ReNewSyntax;
  {
  Self.Syn_Show.Highlighter:=(Self.NowEditing as TAufButton).Auf.Script.SynAufSyn;
  Self.SynEdit_FileView.Highlighter:=(Self.NowEditing as TAufButton).Auf.Script.SynAufSyn;
  }
end;

procedure TAufButtonForm.Button_FileNameClick(Sender: TObject);
var i:byte;
begin
  if Self.OpenDialog.Execute then
    begin
      Self.Button_FileName.Caption:=Self.OpenDialog.Files.CommaText;
      Self.MultiFile.CommaText:=Self.OpenDialog.Files.CommaText;
      {$ifdef OldButtFiles}
      for i:=1 to Self.MultiFile.Count-1 do Self.MultiFile[i]:=ExtractFileName(Self.MultiFile[i]);
      {$else}
      for i:=0 to Self.MultiFile.Count-1 do Self.MultiFile[i]:={Self.OpenDialog.InitialDir+}Self.MultiFile[i];
      {$endif}
      //Self.Button_FileName.Caption:=Self.OpenDialog.FileName;
      Self.ReNewSyntax;
    end;
end;

procedure TAufButtonForm.Button_ReEditClick(Sender: TObject);
begin
  Self.ReEdit;
end;

procedure TAufButtonForm.Button_StopClick(Sender: TObject);
begin
  //(Self.NowEditing as TAufButton).Perform(WM_MButtonUp,0,$0808);
  (Self.NowEditing as TAufButton).AufStop;
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
var str,stmp:string;
    path,tmppath:string;
    tmpStr:TStrings;
begin
  tmpStr:=TStringList.Create;
  tmpStr.Clear;
  Self.Syn_Show.Clear;
  Self.Syn_Show.Lines.Add('define win, @'+Form_Routiner.Buttons[Self.ComboBox_Window.ItemIndex].expression);
  Self.Syn_Show.Lines.Add('jmp +'+IntToStr((Self.NowEditing as TAufButton).SkipLine));
  //Self.Syn_Show.Lines.Add('load "'+Self.Button_FileName.Caption+'"');
  path:='';
  for str in Self.MultiFile do
    begin
      tmppath:=ExtractFilePath(str);
      if tmppath<>'' then path:=tmppath;
      if pos(':',str)>0 then
        Self.Syn_Show.Lines.Add('load "'+str+'"')
      else
        Self.Syn_Show.Lines.Add('load "'+path+ExtractFileName(str)+'"');
      try
        tmpStr.add('');
        tmpStr.add('//文件 "'+ExtractFileName(str)+'":');
        Application.ProcessMessages;
        if pos(':',str)>0 then
          Self.SynEdit_FileView.Lines.LoadFromFile(str)
        else
          Self.SynEdit_FileView.Lines.LoadFromFile(path+ExtractFileName(str));
        for stmp in Self.SynEdit_FileView.Lines do tmpStr.Add(stmp);
      except
        tmpStr.Add('//文件未正确打开');
      end;
    end;
  Self.SynEdit_FileView.Lines.Clear;
  for stmp in tmpStr do Self.SynEdit_FileView.Lines.Add(stmp);
  tmpStr.Free;
  Self.Syn_Show.Lines.Add('end');
  Self.Syn_Show.Lines.Add('');
end;

procedure TAufButtonForm.ComboBox_WindowChange(Sender: TObject);
begin
  Self.ReNewSyntax;
end;

procedure TAufButtonForm.Edit_CaptionChange(Sender: TObject);
begin
  //Self.NowEditing.Caption:=(Sender as TEdit).Caption;
end;

procedure TAufButtonForm.FormActivate(Sender: TObject);
begin
  Self.ReEdit;
  Self.Syn_Show.Highlighter:=(Self.NowEditing as TAufButton).Auf.Script.SynAufSyn;
  Self.SynEdit_FileView.Highlighter:=(Self.NowEditing as TAufButton).Auf.Script.SynAufSyn;
end;

end.

