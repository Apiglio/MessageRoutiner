unit form_runperformance;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, EditBtn, Windows;

type

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
    GroupBox_MouseSetting: TGroupBox;
    Label_AufButtonExtraAct: TLabel;
    Label_AufButtonAct: TLabel;
    Label_HoldButtonSetting: TLabel;
    Label_AufButtonSetting: TLabel;
    Label_AufButtonHalt: TLabel;
    ScrollBox: TScrollBox;
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
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
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
begin
  FormRunPerformance.CheckGroup_HookEnabled.Checked[0]:=Form_Routiner.KeybdHookEnabled;
  FormRunPerformance.CheckGroup_HookEnabled.Checked[1]:=Form_Routiner.MouseHookEnabled;
end;

procedure TFormRunPerformance.Button_OkayClick(Sender: TObject);
begin
  with Self.Setting do
    begin
      Form_Routiner.Setting.AufButtonAct1:=AufButtonAct1*[ssAlt,ssShift,ssCtrl];
      Form_Routiner.Setting.AufButtonAct2:=AufButtonAct2;
      Form_Routiner.Setting.AufButtonExtraAct1:=AufButtonExtraAct1*[ssAlt,ssShift,ssCtrl];
      Form_Routiner.Setting.AufButtonExtraAct2:=AufButtonExtraAct2;
      Form_Routiner.Setting.AufButtonSetting1:=AufButtonSetting1*[ssAlt,ssShift,ssCtrl];
      Form_Routiner.Setting.AufButtonSetting2:=AufButtonSetting2;
      Form_Routiner.Setting.AufButtonHalt1:=AufButtonHalt1*[ssAlt,ssShift,ssCtrl];
      Form_Routiner.Setting.AufButtonHalt2:=AufButtonHalt2;
      Form_Routiner.Setting.HoldButtonSetting1:=HoldButtonSetting1*[ssAlt,ssShift,ssCtrl];
      Form_Routiner.Setting.HoldButtonSetting2:=HoldButtonSetting2;
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

  Self.Hide;
end;

procedure TFormRunPerformance.Button_ResetClick(Sender: TObject);
begin
  with Self.Setting do
    begin
      Form_Routiner.Setting.AufButtonAct1:=[];
      Form_Routiner.Setting.AufButtonAct2:=mbLeft;
      Form_Routiner.Setting.AufButtonExtraAct1:=[ssCtrl];
      Form_Routiner.Setting.AufButtonExtraAct2:=mbLeft;
      Form_Routiner.Setting.AufButtonSetting1:=[];
      Form_Routiner.Setting.AufButtonSetting2:=mbRight;
      Form_Routiner.Setting.AufButtonHalt1:=[];
      Form_Routiner.Setting.AufButtonHalt2:=mbMiddle;
      Form_Routiner.Setting.HoldButtonSetting1:=[];
      Form_Routiner.Setting.HoldButtonSetting2:=mbRight;
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

procedure TFormRunPerformance.FormActivate(Sender: TObject);
begin
  with Self.Setting do
    begin
      AufButtonAct1:=Form_Routiner.Setting.AufButtonAct1;
      AufButtonAct2:=Form_Routiner.Setting.AufButtonAct2;
      Self.Button_AufButtonAct.Caption:=MouseActToStr(AufButtonAct1,AufButtonAct2);
      AufButtonExtraAct1:=Form_Routiner.Setting.AufButtonExtraAct1;
      AufButtonExtraAct2:=Form_Routiner.Setting.AufButtonExtraAct2;
      Self.Button_AufButtonExtraAct.Caption:=MouseActToStr(AufButtonExtraAct1,AufButtonExtraAct2);
      AufButtonSetting1:=Form_Routiner.Setting.AufButtonSetting1;
      AufButtonSetting2:=Form_Routiner.Setting.AufButtonSetting2;
      Self.Button_AufButtonSetting.Caption:=MouseActToStr(AufButtonSetting1,AufButtonSetting2);
      AufButtonHalt1:=Form_Routiner.Setting.AufButtonHalt1;
      AufButtonHalt2:=Form_Routiner.Setting.AufButtonHalt2;
      Self.Button_AufButtonHalt.Caption:=MouseActToStr(AufButtonHalt1,AufButtonHalt2);
      HoldButtonSetting1:=Form_Routiner.Setting.HoldButtonSetting1;
      HoldButtonSetting2:=Form_Routiner.Setting.HoldButtonSetting2;
      Self.Button_HoldButtonSetting.Caption:=MouseActToStr(HoldButtonSetting1,HoldButtonSetting2);
    end;
end;

end.

