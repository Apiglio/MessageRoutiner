unit form_scale;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  Windows;

type

  { TFormScale }

  TScaleType = (stUnknown, stForm, stClient);
  TFormScale = class(TForm)
    procedure FormChangeBounds(Sender: TObject);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormPaint(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    FHWND:HWND;
    FType:TScaleType;
  public
    procedure Call(Target:HWND;ScaleType:TScaleType);
  end;

var
  FormScale: TFormScale;

implementation
uses MessageRoutiner_Unit;

{$R *.lfm}

//function GetDPIScaling:double;
//function GetDPI:integer;
//function GetDPIRect(ARect:TRect):TRect;

{ TFormScale }

procedure TFormScale.FormChangeBounds(Sender: TObject);
begin
  FormPaint(Self);
end;

procedure TFormScale.FormMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  ModalResult:=mrOK;
end;

procedure TFormScale.FormPaint(Sender: TObject);
var window_info:TWindowInfo;
    tmpRect:TRect;
    tmpx,tmpy,linex,liney:Integer;
    hth,htw:Integer;
    stmp:string;
    dpi_scaling:double;
begin
  if GetWindowInfo(FHWND,window_info) then begin
    dpi_scaling:=GetDPIScaling;
    case FType of
      stClient:tmpRect:=window_info.rcClient;
      stForm:tmpRect:=window_info.rcWindow;
      else exit;
    end;
    tmpRect.Top:=tmpRect.Top-Top;
    tmpRect.Left:=tmpRect.Left-Left;
    tmpRect.Right:=tmpRect.Right-Left;
    tmpRect.Bottom:=tmpRect.Bottom-Top;
    with Canvas do begin
      Brush.Style:=bsClear;
      Clear;
      Pen.Color:=clBlack;
      Pen.Width:=3;
      Rectangle(tmpRect);
      hth:=TextHeight('8') div 2;
      tmpx:=0;
      Font.Bold:=true;
      while tmpx<tmpRect.Width*dpi_scaling do begin
        linex:=tmpRect.Left+round(tmpx/dpi_scaling);
        if tmpx mod 100 = 0 then begin
          stmp:=IntToStr(tmpx);
          htw:=TextWidth(stmp) div 2;
          TextOut(linex-htw, tmpRect.Top-10-2*hth, stmp);
          TextOut(linex-htw, tmpRect.Bottom+10,    stmp);
          Pen.Width:=2;
        end else begin
          Pen.Width:=1;
        end;
        Line(linex, tmpRect.Top, linex, tmpRect.Bottom);
        inc(tmpx,20);
      end;
      tmpy:=0;
      while tmpy<tmpRect.Height*dpi_scaling do begin
        liney:=tmpRect.Top+round(tmpy/dpi_scaling);
        if tmpy mod 100 = 0 then begin
          stmp:=IntToStr(tmpy);
          htw:=TextWidth(stmp) div 2;
          TextOut(tmpRect.Left-2*htw-10, liney-hth, stmp);
          TextOut(tmpRect.Right+10,      liney-hth, stmp);
          Pen.Width:=2;
        end else begin
          Pen.Width:=1;
        end;
        Line(tmpRect.Left, liney, tmpRect.Right, liney);
        inc(tmpy,20);
      end;
    end;
  end;
end;

procedure TFormScale.FormResize(Sender: TObject);
begin
  FormPaint(Self);
end;

procedure TFormScale.Call(Target:HWND;ScaleType:TScaleType);
begin
  FHWND:=Target;
  FType:=ScaleType;
  ShowModal;
end;

end.

