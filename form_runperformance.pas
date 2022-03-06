unit form_runperformance;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, EditBtn, ComCtrls, Windows, form_adapter;

type

  TSCButton=class(TButton)
    public ShortcutIndex:integer;
  end;

  { TFormRunPerformance }

  TFormRunPerformance = class(TForm)
    Button_AufButtonExtraAct: TButton;
    Button_AufButtonAct: TButton;
    Button_AufButtonSetting: TButton;
    Button_AufButtonHalt: TButton;
    Button_HoldButtonSetting: TButton;
    Button_Okay: TButton;
    Button_Reset: TButton;
    Button_Cancel: TButton;
    CheckGroup_HookEnabled: TCheckGroup;
    Edit_SCM_KEY_DownUp: TEdit;
    Edit_SCM_KEY_Start: TEdit;
    Edit_SCM_KEY_End: TEdit;
    GroupBox_SCM_Filename: TGroupBox;
    GroupBox_SCM_Key: TGroupBox;
    GroupBox_MouseSetting: TGroupBox;
    Label_SCM_KEY_Start: TLabel;
    Label_AufButtonExtraAct: TLabel;
    Label_AufButtonAct: TLabel;
    Label_HoldButtonSetting: TLabel;
    Label_AufButtonSetting: TLabel;
    Label_AufButtonHalt: TLabel;
    Label_SCM_KEY_End: TLabel;
    Label_SCM_KEY_DownUp: TLabel;
    OpenDialog: TOpenDialog;
    PageControl_RunPorferance: TPageControl;
    RadioGroup_SCM: TRadioGroup;
    ScrollBox_KeyShort: TScrollBox;
    TabSheet_HookOpt: TTabSheet;
    TabSheet_ButtonOpt: TTabSheet;
    TabSheet_KeyShortOpt: TTabSheet;
    ToggleBox_SCM_KEY_manual: TToggleBox;
    procedure Button_AufButtonActMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Button_AufButtonExtraActMouseUp(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Button_AufButtonHaltMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Button_AufButtonSettingMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Button_CancelClick(Sender: TObject);
    procedure Button_HoldButtonSettingMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Button_OkayClick(Sender: TObject);
    procedure Button_ResetClick(Sender: TObject);
    procedure CheckGroup_PerformanceItemClick(Sender: TObject; Index: integer);
    procedure Edit_SCM_KEY_KeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure GroupBox_SCM_FilenameResize(Sender: TObject);
  private
    procedure CtrlsClick(Sender: TObject);
    procedure ButtonsClick(Sender: TObject);
  public
    FileButtons:array[0..ShortcutCount] of TButton;
    FileCtrls:array[0..ShortcutCount] of TSCButton;
    FileEdits:array[0..SHortcutCount] of TEdit;
  private
    Setting:record
      AufButtonAct1:TShiftState;
      AufButtonAct2:TMouseButton;
      AufButtonExtraAct1:TShiftState;
      AufButtonExtraAct2:TMouseButton;
      AufButtonSetting1:TShiftState;
      AufButtonSetting2:TMouseButton;
      AufButtonHalt1:TShiftState;
      AufButtonHalt2:TMouseButton;
      HoldButtonSetting1:TShiftState;
      HoldButtonSetting2:TMouseButton;
    end;
  public

  end;

var
  FormRunPerformance: TFormRunPerformance;

implementation
uses MessageRoutiner_Unit;

{$R *.lfm}

{ TFormRunPerformance }

function MouseActToStr(shift:TShiftState;button:TMouseButton):string;
begin
  result:='';
  if ssCtrl  in shift then result:=result+'Ctrl+';
  if ssShift in shift then result:=result+'Shift+';
  if ssAlt   in shift then result:=result+'Alt+';
  {
  if ssLeft  in shift then result:=result+'Left+';
  if ssRight in shift then result:=result+'Right+';
  if ssMiddle   in shift then result:=result+'Middle+';
  if ssDouble   in shift then result:=result+'Double+';
  }
  case button of
    mbLeft:result:=result+'鼠标左键';
    mbRight:result:=result+'鼠标右键';
    mbMiddle:result:=result+'鼠标中键';
    mbExtra1:result:=result+'鼠标拓展键1';
    mbExtra2:result:=result+'鼠标拓展键2';
  end;
end;

procedure TFormRunPerformance.FormCreate(Sender: TObject);
var i:integer;
begin
  Self.CheckGroup_HookEnabled.Checked[0]:=Form_Routiner.KeybdHookEnabled;
  Self.CheckGroup_HookEnabled.Checked[1]:=Form_Routiner.MouseHookEnabled;

  for i:=0 to ShortcutCount do
    begin
      FileEdits[i]:=TEdit.Create(Self);
      with FileEdits[i] do
        begin
          Parent:=Self.GroupBox_SCM_Filename;
          Height:=28;
          Width:=100;
          Left:=5;
          Top:=15+i*(28+15);
          Text:='';
        end;
      FileButtons[i]:=TButton.Create(Self);
      with FileButtons[i] do
        begin
          Parent:=Self.GroupBox_SCM_Filename;
          Height:=28;
          Top:=15+i*(28+15);
          Left:=110;
          Caption:='scriptfile';
          onClick:=@ButtonsClick;
          ShowHint:=true;
        end;
      FileCtrls[i]:=TSCButton.Create(Self);
        with FileCtrls[i] do
          begin
            ShortcutIndex:=i;
            Parent:=Self.GroupBox_SCM_Filename;
            Left:=115+FileButtons[i].Width+10;
            Height:=28;
            Width:=45;
            Top:=15+i*(28+15);
            Caption:='中止';
            onClick:=@CtrlsClick;
            Enabled:=false;
          end;

    end;

  Self.CheckGroup_HookEnabled.Height:=56;
  Self.GroupBox_MouseSetting.Height:=200;
  Self.GroupBox_SCM_Filename.Height:=(15+28)*(ShortcutCount+1)+30;
  //Self.GroupBox_ShortcutSetting.Height:=240+Self.GroupBox_SCM_Filename.Height;

  Self.OpenDialog.Title:='选择脚本文件';
  Self.OpenDialog.InitialDir:=ExtractFilePath(Application.ExeName);
  Self.OpenDialog.Filter:='AufScript File(*.auf)|*.auf|TableCalc Script File(*.scpt)|*.scpt|布局脚本文件(*.auf.lay)|*.auf.lay|文本文档(*.txt)|*.txt|全部文件(*.*)|*.*';
  Self.OpenDialog.DefaultExt:='*.auf';

end;

procedure TFormRunPerformance.FormResize(Sender: TObject);
begin
  //
end;

procedure TFormRunPerformance.GroupBox_SCM_FilenameResize(Sender: TObject);
var i:integer;
begin
  for i:=0 to ShortcutCount do
    begin
      with FileButtons[i] do
        begin
          Width:=max(0,Self.GroupBox_SCM_Filename.Width-120-45);
        end;
      with FileCtrls[i] do
        begin
          Left:=115+FileButtons[i].Width;
        end;
    end;
end;

procedure TFormRunPerformance.CtrlsClick(Sender: TObject);
begin
  Form_Routiner.SCAufs[(Sender as TSCButton).ShortcutIndex].Script.Stop;
end;
procedure TFormRunPerformance.ButtonsClick(Sender: TObject);
begin
  if Self.OpenDialog.Execute then
    begin
      (Sender as TButton).Caption:=Self.OpenDialog.FileName;
      (Sender as TButton).Hint:=Self.OpenDialog.FileName;
    end;
end;

procedure TFormRunPerformance.Button_OkayClick(Sender: TObject);
var pi:integer;
begin
  with Self.Setting do
    begin
      Form_Routiner.Setting.AufButton.Act1:=AufButtonAct1*[ssAlt,ssShift,ssCtrl];
      Form_Routiner.Setting.AufButton.Act2:=AufButtonAct2;
      Form_Routiner.Setting.AufButton.ExtraAct1:=AufButtonExtraAct1*[ssAlt,ssShift,ssCtrl];
      Form_Routiner.Setting.AufButton.ExtraAct2:=AufButtonExtraAct2;
      Form_Routiner.Setting.AufButton.Setting1:=AufButtonSetting1*[ssAlt,ssShift,ssCtrl];
      Form_Routiner.Setting.AufButton.Setting2:=AufButtonSetting2;
      Form_Routiner.Setting.AufButton.Halt1:=AufButtonHalt1*[ssAlt,ssShift,ssCtrl];
      Form_Routiner.Setting.AufButton.Halt2:=AufButtonHalt2;
      Form_Routiner.Setting.HoldButton.Setting1:=HoldButtonSetting1*[ssAlt,ssShift,ssCtrl];
      Form_Routiner.Setting.HoldButton.Setting2:=HoldButtonSetting2;
    end;

    if Self.CheckGroup_HookEnabled.Checked[0] then begin
      Form_Routiner.KeybdHook;
    end else begin
      Form_Routiner.KeybdUnHook;
    end;
    if Self.CheckGroup_HookEnabled.Checked[1] then begin
      Form_Routiner.MouseHook;
    end else begin
      Form_Routiner.MouseUnHook;
    end;

  for pi:=0 to ShortcutCount do
    begin
      AdapterForm.Option.Shortcut.ScriptFiles[pi].filename:=Self.FileButtons[pi].Caption;
      AdapterForm.Option.Shortcut.ScriptFiles[pi].command:=lowercase(Self.FileEdits[pi].Text);
    end;

  Self.Hide;
end;

procedure TFormRunPerformance.Button_ResetClick(Sender: TObject);
begin
  with Self.Setting do
    begin
      Form_Routiner.Setting.AufButton.Act1:=[];
      Form_Routiner.Setting.AufButton.Act2:=mbLeft;
      Form_Routiner.Setting.AufButton.ExtraAct1:=[ssCtrl];
      Form_Routiner.Setting.AufButton.ExtraAct2:=mbLeft;
      Form_Routiner.Setting.AufButton.Setting1:=[];
      Form_Routiner.Setting.AufButton.Setting2:=mbRight;
      Form_Routiner.Setting.AufButton.Halt1:=[];
      Form_Routiner.Setting.AufButton.Halt2:=mbMiddle;
      Form_Routiner.Setting.HoldButton.Setting1:=[];
      Form_Routiner.Setting.HoldButton.Setting2:=mbRight;
    end;
  Self.CheckGroup_HookEnabled.Checked[0]:=true;
  Self.CheckGroup_HookEnabled.Checked[1]:=false;
  Self.FormActivate(Self);
end;



procedure TFormRunPerformance.Button_AufButtonActMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  (Sender as TButton).Caption:=MouseActToStr(shift,button);
  Self.Setting.AufButtonAct1:=shift;
  Self.Setting.AufButtonAct2:=button;
end;

procedure TFormRunPerformance.Button_AufButtonExtraActMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  (Sender as TButton).Caption:=MouseActToStr(shift,button);
  Self.Setting.AufButtonExtraAct1:=shift;
  Self.Setting.AufButtonExtraAct2:=button;
end;

procedure TFormRunPerformance.Button_AufButtonHaltMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  (Sender as TButton).Caption:=MouseActToStr(shift,button);
  Self.Setting.AufButtonHalt1:=shift;
  Self.Setting.AufButtonHalt2:=button;
end;

procedure TFormRunPerformance.Button_AufButtonSettingMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  (Sender as TButton).Caption:=MouseActToStr(shift,button);
  Self.Setting.AufButtonSetting1:=shift;
  Self.Setting.AufButtonSetting2:=button;
end;

procedure TFormRunPerformance.Button_CancelClick(Sender: TObject);
begin
  Self.Hide;
end;

procedure TFormRunPerformance.Button_HoldButtonSettingMouseDown(
  Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  (Sender as TButton).Caption:=MouseActToStr(shift,button);
  Self.Setting.HoldButtonSetting1:=shift;
  Self.Setting.HoldButtonSetting2:=button;
end;

procedure TFormRunPerformance.CheckGroup_PerformanceItemClick(Sender: TObject;
  Index: integer);
begin

end;

procedure TFormRunPerformance.Edit_SCM_KEY_KeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if Self.ToggleBox_SCM_KEY_manual.Checked then exit;
  (Sender as TEdit).Text:=IntToStr(key);
end;

procedure TFormRunPerformance.FormActivate(Sender: TObject);
var pi:integer;
begin
  with Self.Setting do
    begin
      AufButtonAct1:=Form_Routiner.Setting.AufButton.Act1;
      AufButtonAct2:=Form_Routiner.Setting.AufButton.Act2;
      Self.Button_AufButtonAct.Caption:=MouseActToStr(AufButtonAct1,AufButtonAct2);
      AufButtonExtraAct1:=Form_Routiner.Setting.AufButton.ExtraAct1;
      AufButtonExtraAct2:=Form_Routiner.Setting.AufButton.ExtraAct2;
      Self.Button_AufButtonExtraAct.Caption:=MouseActToStr(AufButtonExtraAct1,AufButtonExtraAct2);
      AufButtonSetting1:=Form_Routiner.Setting.AufButton.Setting1;
      AufButtonSetting2:=Form_Routiner.Setting.AufButton.Setting2;
      Self.Button_AufButtonSetting.Caption:=MouseActToStr(AufButtonSetting1,AufButtonSetting2);
      AufButtonHalt1:=Form_Routiner.Setting.AufButton.Halt1;
      AufButtonHalt2:=Form_Routiner.Setting.AufButton.Halt2;
      Self.Button_AufButtonHalt.Caption:=MouseActToStr(AufButtonHalt1,AufButtonHalt2);
      HoldButtonSetting1:=Form_Routiner.Setting.HoldButton.Setting1;
      HoldButtonSetting2:=Form_Routiner.Setting.HoldButton.Setting2;
      Self.Button_HoldButtonSetting.Caption:=MouseActToStr(HoldButtonSetting1,HoldButtonSetting2);
    end;
  Self.RadioGroup_SCM.ItemIndex:=byte(AdapterForm.Option.Shortcut.Mode);
  Self.Edit_SCM_KEY_Start.Text:=IntToStr(AdapterForm.Option.Shortcut.StartKey);
  Self.Edit_SCM_KEY_End.Text:=IntToStr(AdapterForm.Option.Shortcut.EndKey);
  Self.Edit_SCM_KEY_DownUp.Text:=IntToStr(AdapterForm.Option.Shortcut.DownUpKey);

  for pi:=0 to ShortcutCount do
    begin
      Self.FileEdits[pi].Text:=AdapterForm.Option.Shortcut.ScriptFiles[pi].command;
      Self.FileButtons[pi].Caption:=AdapterForm.Option.Shortcut.ScriptFiles[pi].filename;
    end;
end;

end.

