program MessageRoutiner;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms,
  { you can add units after this }
  MessageRoutiner_Unit,
  form_settinglag, form_aufbutton, form_manual, form_runperformance,
  form_holdbuttonsetting, form_adapter, form_imagemerger, form_scale,
  unit_bitmapdata, unit_writescreen, mr_messagebox, mr_windowlist, mr_misc;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Initialize;
  Application.CreateForm(TForm_Routiner, Form_Routiner);
  Application.CreateForm(TSettingLagForm, SettingLagForm);
  Application.CreateForm(TAufButtonForm, AufButtonForm);
  Application.CreateForm(TForm_Manual, ManualForm);
  Application.CreateForm(TFormRunPerformance, FormRunPerformance);
  Application.CreateForm(TFormHoldButtonSetting, FormHoldButtonSetting);
  Application.CreateForm(TAdapterForm, AdapterForm);
  Form_Routiner.LoadOption;
  Form_Routiner.FormResize(Form_Routiner);
  Application.CreateForm(TForm_ImgMerger, Form_ImgMerger);
  Application.CreateForm(TFormScale, FormScale);
  Application.Run;
end.

