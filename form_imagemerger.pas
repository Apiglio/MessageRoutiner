unit form_imagemerger;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls, Windows;

type

  TMouseState = (msNone, msMove, msTop, msLeft, msRight, msButtom, msLT, msRT, msLB, msRB);

  { TForm_ImgMerger }

  TForm_ImgMerger = class(TForm)
    Button_RESET: TButton;
    Button_OK: TButton;
    Button_ESC: TButton;
    Label_size: TLabel;
    procedure Button_RESETClick(Sender: TObject);
    procedure Button_OKClick(Sender: TObject);
    procedure Button_ESCClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormPaint(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    FMouseState:TMouseState;
    FMouseDown:boolean;
    FPoint:TPoint;
    FHWND:HWND;
    FRect:TRect;
  public
    function Call(Target:HWND):TRect;
  end;

var
  Form_ImgMerger: TForm_ImgMerger;

implementation
uses MessageRoutiner_Unit;

{$R *.lfm}

{ TForm_ImgMerger }

procedure TForm_ImgMerger.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  FPoint:=Classes.Point(X,Y);
  FMouseDown:=true;
end;

procedure TForm_ImgMerger.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  {
  case Key of
    13:Button_OKClick(Button_OK);
    27:Button_ESCClick(Button_ESC);
    83,114:Button_RESETClick(Button_RESET);
  end;
  }
end;

procedure TForm_ImgMerger.Button_OKClick(Sender: TObject);
begin
  FRect:=BoundsRect;
end;

procedure TForm_ImgMerger.Button_ESCClick(Sender: TObject);
begin

end;

procedure TForm_ImgMerger.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    13:Button_OKClick(Button_OK);
    27:Button_ESCClick(Button_ESC);
    83,114:Button_RESETClick(Button_RESET);
  end;
end;

procedure TForm_ImgMerger.Button_RESETClick(Sender: TObject);
begin
  Self.Top:=FRect.Top;
  Self.Left:=FRect.Left;
  Self.Width:=FRect.Width;
  Self.Height:=FRect.Height;
end;

procedure TForm_ImgMerger.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
const bound = 16;
begin
  if FMouseDown then begin
    Self.BeginFormUpdate;
    case FMouseState of
      msMove:   Self.ChangeBounds(Left-FPoint.X+X,Top-FPoint.Y+Y,Width,Height,true);
      msTop:    Self.ChangeBounds(Left,Top-FPoint.Y+Y,Width,Height+FPoint.Y-Y,true);
      msLeft:   Self.ChangeBounds(Left-FPoint.X+X,Top,Width+FPoint.X-X,Height,true);
      msRight:  Self.ChangeBounds(Left,Top,Width-FPoint.X+X,Height,true);
      msButtom: Self.ChangeBounds(Left,Top,Width,Height-FPoint.Y+Y,true);
      msLT:     Self.ChangeBounds(Left-FPoint.X+X,Top-FPoint.Y+Y,Width+FPoint.X-X,Height+FPoint.Y-Y,true);
      msLB:     Self.ChangeBounds(Left-FPoint.X+X,Top,Width+FPoint.X-X,Height-FPoint.Y+Y,true);
      msRT:     Self.ChangeBounds(Left,Top-FPoint.Y+Y,Width-FPoint.X+X,Height+FPoint.Y-Y,true);
      msRB:     Self.ChangeBounds(Left,Top,Width-FPoint.X+X,Height-FPoint.Y+Y,true);
    end;
    Self.EndFormUpdate;
    case FMouseState of msRight, msRT,msRB:FPoint.X:=X; end;
    case FMouseState of msButtom,msLB,msRB:FPoint.Y:=Y; end;
  end else begin
    if X<bound then begin
      if Y<bound then FMouseState:=msLT  else if Y>=Height-bound then FMouseState:=msLB else FMouseState:=msLeft;
    end else if X>=Width-bound then begin
      if Y<bound then FMouseState:=msRT  else if Y>=Height-bound then FMouseState:=msRB else FMouseState:=msRight;
    end else begin
      if Y<bound then FMouseState:=msTop else if Y>=Height-bound then FMouseState:=msButtom else FMouseState:=msMove;
    end;
    case FMouseState of
      msTop,msButtom:Cursor:=crSizeNS;
      msLeft,msRight:Cursor:=crSizeWE;
      msLT,msRB:Cursor:=crSizeNWSE;
      msRT,msLB:Cursor:=crSizeNESW;
      msMove:Cursor:=crSize;
    end;
  end;

end;

procedure TForm_ImgMerger.FormMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  FMouseDown:=false;
end;

procedure TForm_ImgMerger.FormPaint(Sender: TObject);
begin
  Canvas.Pen.Style:=psSolid;
  Canvas.Pen.Color:=clRed;
  Canvas.Pen.Width:=2;
  Canvas.Brush.Style:=bsClear;
  Canvas.Brush.Color:=clWhite;
  Canvas.Rectangle(1,1,Width,Height);
end;

procedure TForm_ImgMerger.FormResize(Sender: TObject);
var rs:TRect;
begin
  rs:=GetDPIRect(BoundsRect);
  Label_size.Caption:=IntToStr(rs.Width)+'x'+IntToStr(rs.Height);

end;

function window_visible(ARect:TRect):boolean;
const min_size = 32;
begin
  result:=false;
  if ARect.Right<min_size then exit;
  if ARect.Bottom<min_size then exit;
  if ARect.Left>Screen.Width-min_size then exit;
  if ARect.Top>Screen.Height-min_size then exit;
  if ARect.Height<min_size then exit;
  if ARect.Width<min_size then exit;
  result:=true;
end;

function rect_valid(ARect:TRect):boolean;
begin
  result:=false;
  if ARect.Height<=0 then exit;
  if ARect.Width<=0 then exit;
  result:=true;
end;

function TForm_ImgMerger.Call(Target:HWND):TRect;
var info:tagWINDOWINFO;
    wndRect,frmRect:TRect;
begin
  GetWindowInfo(Target,info);
  wndRect:=info.rcWindow;
  WITH Form_Routiner.Setting.MergerOption DO BEGIN
    if UseWindow then begin
      if rect_valid(Rect) then begin
        FRect:=Classes.Rect(
          wndRect.Left + Rect.Left,
          wndRect.Top  + Rect.Top,
          wndRect.Left + Rect.Right,
          wndRect.Top  + Rect.Bottom
        );
      end else begin
        if not window_visible(FRect) then
          FRect:=Classes.Rect(
            Screen.Width  div 2 - 320,
            Screen.Height div 2 - 240,
            Screen.Width  div 2 + 320,
            Screen.Height div 2 + 240
          );
      end;
    end else begin
      if rect_valid(Rect) then begin
        FRect:=Rect;
      end else begin
        FRect:=Classes.Rect(0,0,Desktop.Width,Desktop.Height);
      end;
    end;
    Button_RESETClick(Button_RESET);
    if ShowModal=mrOK then begin
      frmRect:=BoundsRect;
      if UseWindow then begin
        result:=Classes.Rect(frmRect.Left  -wndRect.Left, frmRect.Top    -wndRect.Top,
                             frmRect.Right -wndRect.Left, frmRect.Bottom -wndRect.Top);
      end else begin
        result:=frmRect;
      end;
    end else result:=Classes.Rect(0,0,0,0);
  END;
end;

end.

