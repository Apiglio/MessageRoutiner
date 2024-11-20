unit Form_Manual;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, IpHtml, Ipfilebroker, Forms, Controls, Graphics,
  Dialogs, Windows, LazUTF8;

type

  { TForm_Manual }

  TForm_Manual = class(TForm)
    IpFileDataProvider: TIpFileDataProvider;
    IpHtmlPanel: TIpHtmlPanel;
  private

  public
    procedure CastHtml(str:string);
  end;

var
  ManualForm: TForm_Manual;

implementation

{$R *.lfm}

procedure TForm_Manual.CastHtml(str:string);
var
  fs: TMemoryStream;
  pHTML: TIpHtml;
begin
  try
    fs := TMemoryStream.Create;
    try
      fs.LoadFromFile(str);
    except
      MessageBox(0,PChar(utf8towincp('操作指南文件丢失')),'Error',MB_OK);
      fs.free;
      Self.Hide;
      exit;
    end;
    try
      pHTML:=TIpHtml.Create; // Beware: Will be freed automatically by IpHtmlPanel
      pHTML.LoadFromStream(fs);
    finally
      fs.Free;
    end;
    IpHtmlPanel.SetHtml( pHTML );
  except
    on E: Exception do begin
      MessageDlg( 'Error: '+E.Message, mtError, [mbCancel], 0 );
    end;
  end;
end;

end.

