unit form_runperformance;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls;

type

  { TFormRunPerformance }

  TFormRunPerformance = class(TForm)
    Button_Okay: TButton;
    CheckGroup_Performance: TCheckGroup;
    procedure Button_OkayClick(Sender: TObject);
    procedure CheckGroup_PerformanceItemClick(Sender: TObject; Index: integer);
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  FormRunPerformance: TFormRunPerformance;

implementation

{$R *.lfm}

{ TFormRunPerformance }

procedure TFormRunPerformance.FormCreate(Sender: TObject);
begin
  Self.CheckGroup_Performance.Checked[0]:=true;
  Self.CheckGroup_Performance.Checked[1]:=false;
  Self.CheckGroup_Performance.Checked[2]:=true;
  Self.CheckGroup_Performance.Checked[3]:=false;
end;

procedure TFormRunPerformance.Button_OkayClick(Sender: TObject);
begin
  Self.Hide;
end;

procedure TFormRunPerformance.CheckGroup_PerformanceItemClick(Sender: TObject;
  Index: integer);
begin
  Self.CheckGroup_Performance.Checked[0]:=true;
  Self.CheckGroup_Performance.Checked[1]:=false;
  Self.CheckGroup_Performance.Checked[2]:=true;
  Self.CheckGroup_Performance.Checked[3]:=false;
end;

end.

