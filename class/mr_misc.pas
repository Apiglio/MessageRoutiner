unit mr_misc;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Windows;

function GetDPIScaling:double;
function GetDPI:integer;
function GetDPIRect(ARect:TRect):TRect;
procedure process_sleep(n:longint);
//function GetTimeNumber:longint;
//procedure process_sleep(n:longint);

implementation

{
procedure qk(str:string);deprecated;
begin
  Form_Routiner.AufScriptFrames[Form_Routiner.PageControl.ActivePageIndex].Frame.Auf.Script.writeln(str);
end;

procedure qkm(str:string);deprecated;
begin
  MessageBox(0,PChar(str),'Error',MB_OK);
end;
}

function GetDPIScaling:double;
var dc:HDC;
begin
  dc:=GetDC(0);
  result:=GetDeviceCaps(dc, DESKTOPHORZRES) / GetDeviceCaps(dc, HORZRES);
  ReleaseDC(0,dc);
end;

function GetDPI:integer;
var dtmp:double;
begin
  dtmp:=GetDPIScaling;
  result:=round(96*dtmp);
end;

function GetDPIRect(ARect:TRect):TRect;
var dpiScaling:double;
begin
  dpiScaling:=GetDPIScaling;
  result:=Classes.Rect(
    round(dpiScaling*ARect.Left),
    round(dpiScaling*ARect.Top),
    round(dpiScaling*ARect.Right),
    round(dpiScaling*ARect.Bottom)
  );
end;

procedure process_sleep(n:longint);
var t0,t1,t2:TDateTime;
begin
  t0:=Now;
  t2:=t0+n/86400000;
  repeat
    t1:=Now;
    Application.ProcessMessages;
  until t1>=t2;
end;

end.

