unit form_holdbuttonsetting;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls;

type

  { TFormHoldButtonSetting }

  TFormHoldButtonSetting = class(TForm)
    Button_Okay: TButton;
    Button_Cancel: TButton;
    Button_Reset: TButton;
    LabeledEdit_Caption: TLabeledEdit;
    LabeledEdit_Key1: TLabeledEdit;
    LabeledEdit_Key2: TLabeledEdit;
    LabeledEdit_Key3: TLabeledEdit;
    LabeledEdit_Interval: TLabeledEdit;
    ToggleBox_KeyRead: TToggleBox;
    procedure Button_CancelClick(Sender: TObject);
    procedure Button_OkayClick(Sender: TObject);
    procedure Button_ResetClick(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure LabeledEdit_IntervalKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure LabeledEdit_Key1KeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure LabeledEdit_Key2KeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure LabeledEdit_Key3KeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private

  public
    TargetButton:TButton;
  end;

var
  FormHoldButtonSetting: TFormHoldButtonSetting;

implementation
uses MessageRoutiner_Unit, mr_holdbutton;

{$R *.lfm}

{ TFormHoldButtonSetting }

procedure TFormHoldButtonSetting.Button_OkayClick(Sender: TObject);
var tmp:THoldButton;
begin
  tmp:=TargetButton as THoldButton;
  tmp.Caption:=Self.LabeledEdit_Caption.Text;
  try
    tmp.keymessage[0]:=StrToInt(Self.LabeledEdit_Key1.Text);
  except
    tmp.keymessage[0]:=0;
  end;
  try
    tmp.keymessage[1]:=StrToInt(Self.LabeledEdit_Key2.Text);
  except
    tmp.keymessage[1]:=0;
  end;
  try
    tmp.keymessage[2]:=StrToInt(Self.LabeledEdit_Key3.Text);
  except
    tmp.keymessage[2]:=0;
  end;
  try
    tmp.keymessage[3]:=StrToInt(Self.LabeledEdit_Interval.Text);
  except
    tmp.keymessage[3]:=0;
  end;
  Self.Hide;
end;

procedure TFormHoldButtonSetting.Button_CancelClick(Sender: TObject);
begin
  Self.Hide;
end;

procedure TFormHoldButtonSetting.Button_ResetClick(Sender: TObject);
begin
  Self.LabeledEdit_Caption.Text:='';
  Self.LabeledEdit_Key1.Text:='0';
  Self.LabeledEdit_Key2.Text:='0';
  Self.LabeledEdit_Key3.Text:='0';
  Self.LabeledEdit_Interval.Text:='0';
end;

procedure TFormHoldButtonSetting.FormHide(Sender: TObject);
begin
  //
end;

procedure TFormHoldButtonSetting.FormShow(Sender: TObject);
var tmp:THoldButton;
begin
  tmp:=TargetButton as THoldButton;
  Self.LabeledEdit_Caption.Text:=tmp.Caption;
  Self.LabeledEdit_Key1.Text:=IntToStr(tmp.keymessage[0]);
  Self.LabeledEdit_Key2.Text:=IntToStr(tmp.keymessage[1]);
  Self.LabeledEdit_Key3.Text:=IntToStr(tmp.keymessage[2]);
  Self.LabeledEdit_Interval.Text:=IntToStr(tmp.keymessage[3]);
end;

procedure TFormHoldButtonSetting.LabeledEdit_IntervalKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  //(Sender as TLabeledEdit).Text:=IntToStr(Key mod 256);
end;

procedure TFormHoldButtonSetting.LabeledEdit_Key1KeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if not Self.ToggleBox_KeyRead.Checked then
  (Sender as TLabeledEdit).Text:=IntToStr(Key mod 256);
end;

procedure TForm_HoldButtonSetting.LabeledEdit_Key2KeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if not Self.ToggleBox_KeyRead.Checked then
  (Sender as TLabeledEdit).Text:=IntToStr(Key mod 256);
end;

procedure TForm_HoldButtonSetting.LabeledEdit_Key3KeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if not Self.ToggleBox_KeyRead.Checked then
  (Sender as TLabeledEdit).Text:=IntToStr(Key mod 256);
end;


end.

