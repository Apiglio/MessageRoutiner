unit mr_holdbutton;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Windows, mr_misc;

type
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

implementation
uses MessageRoutiner_Unit, form_holdbuttonsetting;


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

end.

