program MessageRoutiner;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, aufscript_frame,
  { you can add units after this }
  MessageRoutiner_Unit, form_settinglag, form_aufbutton, form_manual,
  form_runperformance, unit_holdbuttonsetting, form_adapter, unit_bitmapdata,
  unit_writescreen;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Initialize;
  Application.CreateForm(TForm_Routiner, Form_Routiner);
  Application.CreateForm(TSettingLagForm, SettingLagForm);
  Application.CreateForm(TAufButtonForm, AufButtonForm);
  Application.CreateForm(TForm_Manual, ManualForm);
  Application.CreateForm(TFormRunPerformance, FormRunPerformance);
  Application.CreateForm(TForm_HoldButtonSetting, Form_HoldButtonSetting);
  Application.CreateForm(TAdapterForm, AdapterForm);
  Form_Routiner.LoadOption;
  Form_Routiner.FormResize(Form_Routiner);
  Application.Run;
end.

