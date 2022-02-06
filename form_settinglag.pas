unit form_settinglag;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TEditCount }
  TEditCount = class(TEdit)
    constructor Create(AOwner:TComponent;ACount:integer);
  public
    Count:integer;
  end;

  { TSettingLagForm }

  TSettingLagForm = class(TForm)
    ScrollBox: TScrollBox;
    procedure FormCreate(Sender: TObject);
  private

  public
    Title1,Title2,Title3:array[0..9] of TLabel;
    LagTime,LagAdjust:array[0..9] of TEditCount;
  public
    procedure LagOnChange(Sender:TObject);
    procedure StepOnChange(Sender:TObject);


  end;

var
  SettingLagForm: TSettingLagForm;

implementation
uses messageroutiner_unit, apiglio_useful;

{$R *.lfm}

function max(a,b:integer):integer;inline;
begin
  if a>b then result:=a
  else result:=b;
end;
function min(a,b:integer):integer;inline;
begin
  if a<b then result:=a
  else result:=b;
end;

constructor TEditCount.Create(AOwner:TComponent;ACount:integer);
begin
  inherited Create(AOwner);
  Self.Count:=ACount;
end;

{ TSettingLagForm }

procedure TSettingLagForm.LagOnChange(Sender:TObject);
var tmp:TEditCount;
    lag:integer;
begin
  tmp:=(Sender as TEditCount);
  lag:=Usf.to_i(tmp.Text);
  lag:=max(0,lag);
  lag:=min(999,lag);
  tmp.Text:=IntToStr(lag);
  Form_Routiner.SynSetting[tmp.Count].adjusting_lag:=lag;
end;

procedure TSettingLagForm.StepOnChange(Sender:TObject);
var tmp:TEditCount;
    lag:integer;
begin
  tmp:=(Sender as TEditCount);
  lag:=Usf.to_i(tmp.Text);
  lag:=max(0,lag);
  lag:=min(999,lag);
  tmp.Text:=IntToStr(lag);
  Form_Routiner.SynSetting[tmp.Count].adjusting_step:=lag;
end;

procedure TSettingLagForm.FormCreate(Sender: TObject);
var i:integer;
begin
  Self.ScrollBox.Width:=Self.Width;
  Self.ScrollBox.Height:=Self.Height;
  Self.ScrollBox.Top:=0;
  Self.ScrollBox.Left:=0;
  Self.Position:=poScreenCenter;
  for i:= 0 to SynCount do
    begin
      Self.Title1[i]:=TLabel.Create(Self);
      Self.Title2[i]:=TLabel.Create(Self);
      Self.Title3[i]:=TLabel.Create(Self);
      Self.Title1[i].Caption:='窗口'+IntToStr(i)+'：延长移动';
      Self.Title2[i].Caption:='%，单步调整幅度为';
      Self.Title3[i].Caption:='%。';
      Self.Title1[i].Hint:='数字键'+IntToStr(i)+'+PageUp/PageDn调整';
      Self.Title2[i].Hint:='数字键'+IntToStr(i)+'+PageUp/PageDn调整';
      Self.Title3[i].Hint:='数字键'+IntToStr(i)+'+PageUp/PageDn调整';
      Self.Title1[i].ShowHint:=true;
      Self.Title2[i].ShowHint:=true;
      Self.Title3[i].ShowHint:=true;
      Self.Title1[i].Parent:=Self.ScrollBox;
      Self.Title2[i].Parent:=Self.ScrollBox;
      Self.Title3[i].Parent:=Self.ScrollBox;
      Self.Title1[i].Top:=12+i*48+6;
      Self.Title2[i].Top:=12+i*48+6;
      Self.Title3[i].Top:=12+i*48+6;
      Self.Title1[i].Left:=5;
      Self.Title2[i].Left:=165;
      Self.Title3[i].Left:=345;
      Self.LagTime[i]:=TEditCount.Create(Self,i);
      Self.LagAdjust[i]:=TEditCount.Create(Self,i);
      Self.LagTime[i].Text:='0';
      Self.LagAdjust[i].Text:='5';
      Self.LagTime[i].Parent:=Self.ScrollBox;
      Self.LagAdjust[i].Parent:=Self.ScrollBox;
      Self.LagTime[i].Top:=12+i*48;
      Self.LagAdjust[i].Top:=12+i*48;
      Self.LagTime[i].Left:=120;
      Self.LagAdjust[i].Left:=300;
      Self.LagTime[i].Width:=40;
      Self.LagAdjust[i].Width:=40;
      Self.LagTime[i].OnChange:=@Self.LagOnChange;
      Self.LagAdjust[i].OnChange:=@Self.StepOnChange;

    end;

end;

end.

