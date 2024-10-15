unit mr_messagebox;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls;

type
  TMROptionForm = class(TForm)
    Prompt:TLabel;
    ListBox: TListBox;
    ButtonOK: TButton;
    ButtonCancel: TButton;
  public
    function Execute(Options:TStrings):string;
  public
    constructor Create(theOwner:TComponent; aCaption, aPrompt: String); reintroduce;
    destructor Destroy; override;
  end;

implementation



{ TMROptionForm }

constructor TMROptionForm.Create(theOwner:TComponent; aCaption, aPrompt: String);
begin
  Inherited CreateNew(theOwner);
  Constraints.MinWidth:=150;
  Constraints.MinHeight:=100;

  Prompt:=TLabel.Create(Self);
  with Prompt do begin
    Parent:=Self;
    Text:=aPrompt;
    Anchors:=[akTop, akLeft];
    AutoSize:=true;
    AnchorSideTop.Control:=Self;
    AnchorSideTop.Side:=asrTop;
    AnchorSideLeft.Control:=Self;
    AnchorSideLeft.Side:=asrLeft;
    BorderSpacing.Top:=8;
    BorderSpacing.Left:=8;
  end;
  ButtonCancel:=TButton.Create(Self);
  with ButtonCancel do begin
    Parent:=Self;
    Caption:='取消';
    Anchors:=[akRight, akBottom];
    Width:=40;
    Height:=24;
    AnchorSideRight.Control:=Self;
    AnchorSideRight.Side:=asrRight;
    AnchorSideBottom.Control:=Self;
    AnchorSideBottom.Side:=asrBottom;
    BorderSpacing.Right:=8;
    BorderSpacing.Bottom:=8;
    ModalResult:=mrCancel;
  end;
  ButtonOK:=TButton.Create(Self);
  with ButtonOK do begin
    Parent:=Self;
    Caption:='确定';
    Anchors:=[akRight, akBottom];
    Width:=40;
    Height:=24;
    AnchorSideRight.Control:=ButtonCancel;
    AnchorSideRight.Side:=asrLeft;
    AnchorSideBottom.Control:=Self;
    AnchorSideBottom.Side:=asrBottom;
    BorderSpacing.Right:=8;
    BorderSpacing.Bottom:=8;
    ModalResult:=mrOK;
  end;
  ListBox:=TListBox.Create(Self);
  with ListBox do begin
    Parent:=Self;
    Anchors:=[akTop, akLeft, akRight, akBottom];
    AnchorSideTop.Control:=Prompt;
    AnchorSideTop.Side:=asrBottom;
    AnchorSideLeft.Control:=Self;
    AnchorSideLeft.Side:=asrLeft;
    AnchorSideRight.Control:=Self;
    AnchorSideRight.Side:=asrRight;
    AnchorSideBottom.Control:=ButtonCancel;
    AnchorSideBottom.Side:=asrTop;
    BorderSpacing.Top:=8;
    BorderSpacing.Left:=8;
    BorderSpacing.Right:=8;
    BorderSpacing.Bottom:=8;
  end;

  Position:=poScreenCenter;
  Caption:=aCaption;
end;

destructor TMROptionForm.Destroy;
begin
  ListBox.Clear;
  inherited Destroy;
end;

function TMROptionForm.Execute(Options:TStrings):string;
var tmpIndex:integer;
begin
  ListBox.Items.Assign(Options);
  case ShowModal of
    mrOK:tmpIndex:=ListBox.ItemIndex;
    else tmpIndex:=-1;
  end;
  if tmpIndex>=0 then result:=Options[tmpIndex] else result:='';
end;

end.

