unit mr_aufbutton;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Apiglio_Useful, mr_misc;

type
  TWinAuf = class(TAuf)
  public
    WindowIndex:byte;
  end;

  TAufButton = class(TButton)
    constructor Create(AOwner:TComponent;AWinAuf:TWinAuf);
    procedure ButtonLeftUp;
    procedure ButtonCtrlLeftUp;
    procedure ButtonRightUp;
    procedure ButtonMouseUp(Sender: TObject; Button: TMouseButton;
                          Shift: TShiftState; X, Y: Integer);

    procedure ButtonMouseEnter(Sender:TObject);
    procedure ButtonMouseLeave(Sender:TObject);

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
    ScriptFile:TStrings;
    ScriptPath:string;
    WindowChangeable:boolean;
    SkipLine:byte;//跳转多少行，默认为1
  end;

implementation
uses MessageRoutiner_Unit, form_aufbutton;


constructor TAufButton.Create(AOwner:TComponent;AWinAuf:TWinAuf);
begin
  inherited Create(AOwner);
  Self.OnMouseUp:=@Self.ButtonMouseUp;
  Self.cmd:=TStringList.Create;
  Self.Auf:=AWinAuf;
  Self.Font.Bold:=true;
  Self.Font.Bold:=false;
  Self.SkipLine:=1;
  Self.ScriptFile:=TStringList.Create;
  Self.OnMouseEnter:=@Self.ButtonMouseEnter;
  Self.OnMouseLeave:=@Self.ButtonMouseLeave;
end;

procedure TAufButton.ButtonMouseEnter(Sender:TObject);
begin
  Form_Routiner.ShowManual('面板按键。用于向窗体执行录制的脚本，请查阅“操作指南”-“预定义面板”。');
end;

procedure TAufButton.ButtonMouseLeave(Sender:TObject);
begin
  Form_Routiner.ShowManual('');
end;

procedure TAufButton.ButtonLeftUp;
var i:byte;
begin
  if Self.Font.Bold then begin
    Self.AufPause;
    Self.Font.Bold:=false;
  end else begin
    if Self.Auf.Script.PSW.pause then begin
      Self.Font.Bold:=true;
      Self.AufResume;
    end else begin
      if Self.Caption='' then exit;//没有显示名的按键不触发（还是触发设置？）
      for i:=0 to ButtonColumn do Form_Routiner.AufButtons[Self.WindowIndex,i].Enabled:=false;
      Self.Enabled:=true;
      Self.Font.Bold:=true;
      Self.SkipLine:=1;
      Self.AufRun;
    end;
  end;
end;

procedure TAufButton.ButtonCtrlLeftUp;
var i:byte;
begin
  if Self.Font.Bold then begin
    Self.AufPause;
    Self.Font.Bold:=false;
  end else begin
    if Self.Auf.Script.PSW.pause then begin
      Self.Font.Bold:=true;
      Self.AufResume;
    end else begin
      if Self.Caption='' then exit;//没有显示名的按键不触发（还是触发设置？）
      Form_Routiner.AufPopupMenu.PopupComponent:=Self;
      Form_Routiner.AufPopupMenu.button:=Self;
      for i:=0 to AufPopupCount do begin
        if Self.ScriptFile.Count>i then begin
          Form_Routiner.AufPopupMenu.Items[i].Caption:=ExtractFileName(Self.ScriptFile[i]);
          Form_Routiner.AufPopupMenu.Items[i].Enabled:=true;
        end else begin
          Form_Routiner.AufPopupMenu.Items[i].Caption:='未定义';
          Form_Routiner.AufPopupMenu.Items[i].Enabled:=false;
        end;
      end;
      Form_Routiner.AufPopupMenu.PopUp;
      Self.SkipLine:=AufPopupCount+2;
      Application.ProcessMessages;
      if (Self.SkipLine>AufPopupCount+1)or(Self.SkipLine=0) then exit;
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
  AufButtonForm.Show;
end;

procedure TAufButton.ButtonMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var frm:TForm_Routiner;
begin
  frm:=Form_Routiner;
  if (Button=frm.Setting.AufButton.Setting2)
  and (Shift=frm.Setting.AufButton.Setting1) then begin
    ButtonRightUp;
    exit;
  end;
  if (Button=frm.Setting.AufButton.ExtraAct2)
  and (Shift=frm.Setting.AufButton.ExtraAct1) then begin
    ButtonCtrlLeftUp;
    exit;
  end;
  if (Button=frm.Setting.AufButton.Act2)
  and (Shift=frm.Setting.AufButton.Act1) then begin
    ButtonLeftUp;
    exit;
  end;
  if (Button=frm.Setting.AufButton.Halt2)
  and (Shift=frm.Setting.AufButton.Halt1) then begin
    AufStop;
    exit;
  end;
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
var str:string;
begin
  Self.cmd.Clear;
  Self.cmd.add('define win, @'+Form_Routiner.Buttons[Self.WindowIndex].expression);
  Self.cmd.add('define idx, '+IntToStr(Self.WindowIndex));
  Self.cmd.add('jmp +'+IntToStr(Self.SkipLine));
  for str in Self.ScriptFile do Self.cmd.Add('load "'+str+'"');
end;

end.

