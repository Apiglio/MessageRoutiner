unit form_runperformance;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, EditBtn, ComCtrls, Grids, Windows, form_adapter;

type

  TSCButton=class(TButton)
    public ShortcutIndex:integer;
  end;

  { TFormRunPerformance }

  TFormRunPerformance = class(TForm)
    Button_SCAufClear: TButton;
    Button_AufButtonExtraAct: TButton;
    Button_AufButtonAct: TButton;
    Button_AufButtonSetting: TButton;
    Button_AufButtonHalt: TButton;
    Button_HoldButtonSetting: TButton;
    Button_Okay: TButton;
    Button_Reset: TButton;
    Button_Cancel: TButton;
    CheckGroup_HookEnabled: TCheckGroup;
    Edit_SCM_KEY_DownUp: TEdit;
    Edit_SCM_KEY_Start: TEdit;
    Edit_SCM_KEY_End: TEdit;
    GroupBox_SCM_Threads: TGroupBox;
    GroupBox_SCM_Command: TGroupBox;
    GroupBox_SCM_Key: TGroupBox;
    GroupBox_MouseSetting: TGroupBox;
    Label_SCM_KEY_Start: TLabel;
    Label_AufButtonExtraAct: TLabel;
    Label_AufButtonAct: TLabel;
    Label_HoldButtonSetting: TLabel;
    Label_AufButtonSetting: TLabel;
    Label_AufButtonHalt: TLabel;
    Label_SCM_KEY_End: TLabel;
    Label_SCM_KEY_DownUp: TLabel;
    OpenDialog: TOpenDialog;
    PageControl_RunPorferance: TPageControl;
    ProgressBar_SCAufsThread: TProgressBar;
    RadioGroup_SCM: TRadioGroup;
    ScrollBox_KeyShort: TScrollBox;
    StringGrid_CommandList: TStringGrid;
    TabSheet_HookOpt: TTabSheet;
    TabSheet_ButtonOpt: TTabSheet;
    TabSheet_KeyShortOpt: TTabSheet;
    ToggleBox_SCM_KEY_manual: TToggleBox;
    procedure Button_AufButtonActMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Button_AufButtonExtraActMouseUp(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Button_AufButtonHaltMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Button_AufButtonSettingMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Button_CancelClick(Sender: TObject);
    procedure Button_HoldButtonSettingMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Button_OkayClick(Sender: TObject);
    procedure Button_ResetClick(Sender: TObject);
    procedure Button_SCAufClearClick(Sender: TObject);
    procedure CheckGroup_PerformanceItemClick(Sender: TObject; Index: integer);
    procedure Edit_SCM_KEY_KeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure RadioGroup_SCMClick(Sender: TObject);
    procedure StringGrid_CommandListEditingDone(Sender: TObject);
    //procedure GroupBox_SCM_FilenameResize(Sender: TObject);
    procedure StringGrid_CommandListResize(Sender: TObject);
    procedure StringGrid_CommandListSelectCell(Sender: TObject; aCol,
      aRow: Integer; var CanSelect: Boolean);
  private
    Setting:record
      AufButtonAct1:TShiftState;
      AufButtonAct2:TMouseButton;
      AufButtonExtraAct1:TShiftState;
      AufButtonExtraAct2:TMouseButton;
      AufButtonSetting1:TShiftState;
      AufButtonSetting2:TMouseButton;
      AufButtonHalt1:TShiftState;
      AufButtonHalt2:TMouseButton;
      HoldButtonSetting1:TShiftState;
      HoldButtonSetting2:TMouseButton;
    end;
  public

  end;

var
  FormRunPerformance: TFormRunPerformance;

implementation
uses MessageRoutiner_Unit;

{$R *.lfm}

{ TFormRunPerformance }

function MouseActToStr(shift:TShiftState;button:TMouseButton):string;
begin
  result:='';
  if ssCtrl  in shift then result:=result+'Ctrl+';
  if ssShift in shift then result:=result+'Shift+';
  if ssAlt   in shift then result:=result+'Alt+';
  {
  if ssLeft  in shift then result:=result+'Left+';
  if ssRight in shift then result:=result+'Right+';
  if ssMiddle   in shift then result:=result+'Middle+';
  if ssDouble   in shift then result:=result+'Double+';
  }
  case button of
    mbLeft:result:=result+'鼠标左键';
    mbRight:result:=result+'鼠标右键';
    mbMiddle:result:=result+'鼠标中键';
    mbExtra1:result:=result+'鼠标拓展键1';
    mbExtra2:result:=result+'鼠标拓展键2';
  end;
end;

procedure TFormRunPerformance.FormCreate(Sender: TObject);
var i:integer;
begin
  Self.CheckGroup_HookEnabled.Checked[0]:=Form_Routiner.KeybdHookEnabled;
  Self.CheckGroup_HookEnabled.Checked[1]:=Form_Routiner.MouseHookEnabled;

  Self.CheckGroup_HookEnabled.Height:=56;
  Self.GroupBox_MouseSetting.Height:=200;

  Self.OpenDialog.Title:='选择脚本文件';
  Self.OpenDialog.InitialDir:=ExtractFilePath(Application.ExeName);
  Self.OpenDialog.Filter:='AufScript File(*.auf)|*.auf|TableCalc Script File(*.scpt)|*.scpt|布局脚本文件(*.auf.lay)|*.auf.lay|文本文档(*.txt)|*.txt|全部文件(*.*)|*.*';
  Self.OpenDialog.DefaultExt:='*.auf';

  Self.StringGrid_CommandList.ColCount:=4;
  Self.StringGrid_CommandList.RowCount:=34;
  Self.StringGrid_CommandList.Cells[1,0]:='快捷键';
  Self.StringGrid_CommandList.Cells[2,0]:='执行动作';
  Self.StringGrid_CommandList.Cells[3,0]:='设置';
  Self.StringGrid_CommandListResize(Self.StringGrid_CommandList);

end;

procedure TFormRunPerformance.FormResize(Sender: TObject);
begin
  //
end;

procedure TFormRunPerformance.RadioGroup_SCMClick(Sender: TObject);
begin
  with Sender as TRadioGroup do
    case ItemIndex of
      0,1:;
      2,3:ItemIndex:=1;
    end;
end;

procedure TFormRunPerformance.StringGrid_CommandListEditingDone(Sender: TObject
  );
var tmpSG:TStringGrid;
begin
  tmpSG:=Sender as TStringGrid;
  if tmpSG.Cells[1,tmpSG.RowCount-1]<>'' then tmpSG.RowCount:=tmpSG.RowCount+1;
end;

procedure TFormRunPerformance.StringGrid_CommandListResize(Sender: TObject);
begin
  with Sender as TStringGrid do
    begin
      ColWidths[0]:=30;
      ColWidths[3]:=50;
      ColWidths[1]:=100;
      ColWidths[2]:=Width-220;
    end;
end;

procedure TFormRunPerformance.StringGrid_CommandListSelectCell(Sender: TObject;
  aCol, aRow: Integer; var CanSelect: Boolean);
begin
  if aCol<>3 then exit;
  //为什么会触发两次？
end;

procedure TFormRunPerformance.Button_OkayClick(Sender: TObject);
var pi:integer;
    stmp:TStringList;
    s1,s2:string;
begin
  //按键设置
  with Self.Setting do
    begin
      Form_Routiner.Setting.AufButton.Act1:=AufButtonAct1*[ssAlt,ssShift,ssCtrl];
      Form_Routiner.Setting.AufButton.Act2:=AufButtonAct2;
      Form_Routiner.Setting.AufButton.ExtraAct1:=AufButtonExtraAct1*[ssAlt,ssShift,ssCtrl];
      Form_Routiner.Setting.AufButton.ExtraAct2:=AufButtonExtraAct2;
      Form_Routiner.Setting.AufButton.Setting1:=AufButtonSetting1*[ssAlt,ssShift,ssCtrl];
      Form_Routiner.Setting.AufButton.Setting2:=AufButtonSetting2;
      Form_Routiner.Setting.AufButton.Halt1:=AufButtonHalt1*[ssAlt,ssShift,ssCtrl];
      Form_Routiner.Setting.AufButton.Halt2:=AufButtonHalt2;
      Form_Routiner.Setting.HoldButton.Setting1:=HoldButtonSetting1*[ssAlt,ssShift,ssCtrl];
      Form_Routiner.Setting.HoldButton.Setting2:=HoldButtonSetting2;
    end;

  //消息钩子
  if Self.CheckGroup_HookEnabled.Checked[0] then begin
    Form_Routiner.KeybdHook;
  end else begin
    Form_Routiner.KeybdUnHook;
  end;
  if Self.CheckGroup_HookEnabled.Checked[1] then begin
    Form_Routiner.MouseHook;
  end else begin
    Form_Routiner.MouseUnHook;
  end;

  //键盘快捷键
  case RadioGroup_SCM.ItemIndex of
    0:AdapterForm.Option.Shortcut.Mode:=scmDblCheck;
    1:AdapterForm.Option.Shortcut.Mode:=scmDownUp;
    2:AdapterForm.Option.Shortcut.Mode:=scmLoop;
    3:AdapterForm.Option.Shortcut.Mode:=scmPoly;
  end;

  with AdapterForm.Option.Shortcut.CommandList do
    begin
      while Count>0 do
        begin
          TStringList(Objects[0]).Free;
          Delete(0);
        end;
    end;
  with Self.StringGrid_CommandList do
    begin
      for pi:=1 to RowCount-1 do
        begin
          s1:=Cells[1,pi];
          s2:=Cells[2,pi];
          if (s1<>'') and (s2<>'') then begin
            stmp:=TStringList.Create;
            stmp.Add(s2);
            AdapterForm.Option.Shortcut.CommandList.AddObject(lowercase(s1),TObject(stmp));
          end;
        end;
    end;

  try
    AdapterForm.Option.Shortcut.DownUpKey:=StrToInt(Edit_SCM_KEY_DownUp.Caption);
    AdapterForm.Option.Shortcut.StartKey:=StrToInt(Edit_SCM_KEY_Start.Caption);
    AdapterForm.Option.Shortcut.EndKey:=StrToInt(Edit_SCM_KEY_End.Caption);
  except
    ShowMessage('唤醒键设置无效，请使用数字！');
    exit;
  end;

  //Self.Hide;
  ModalResult:=mrOK;
end;

procedure TFormRunPerformance.Button_ResetClick(Sender: TObject);
begin
  with Self.Setting do
    begin
      Form_Routiner.Setting.AufButton.Act1:=[];
      Form_Routiner.Setting.AufButton.Act2:=mbLeft;
      Form_Routiner.Setting.AufButton.ExtraAct1:=[ssCtrl];
      Form_Routiner.Setting.AufButton.ExtraAct2:=mbLeft;
      Form_Routiner.Setting.AufButton.Setting1:=[];
      Form_Routiner.Setting.AufButton.Setting2:=mbRight;
      Form_Routiner.Setting.AufButton.Halt1:=[];
      Form_Routiner.Setting.AufButton.Halt2:=mbMiddle;
      Form_Routiner.Setting.HoldButton.Setting1:=[];
      Form_Routiner.Setting.HoldButton.Setting2:=mbRight;
    end;
  Self.CheckGroup_HookEnabled.Checked[0]:=true;
  Self.CheckGroup_HookEnabled.Checked[1]:=false;
  Self.FormActivate(Self);
end;

procedure TFormRunPerformance.Button_SCAufClearClick(Sender: TObject);
begin
  Form_Routiner.ShortcutAufClear;
end;



procedure TFormRunPerformance.Button_AufButtonActMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  (Sender as TButton).Caption:=MouseActToStr(shift,button);
  Self.Setting.AufButtonAct1:=shift;
  Self.Setting.AufButtonAct2:=button;
end;

procedure TFormRunPerformance.Button_AufButtonExtraActMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  (Sender as TButton).Caption:=MouseActToStr(shift,button);
  Self.Setting.AufButtonExtraAct1:=shift;
  Self.Setting.AufButtonExtraAct2:=button;
end;

procedure TFormRunPerformance.Button_AufButtonHaltMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  (Sender as TButton).Caption:=MouseActToStr(shift,button);
  Self.Setting.AufButtonHalt1:=shift;
  Self.Setting.AufButtonHalt2:=button;
end;

procedure TFormRunPerformance.Button_AufButtonSettingMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  (Sender as TButton).Caption:=MouseActToStr(shift,button);
  Self.Setting.AufButtonSetting1:=shift;
  Self.Setting.AufButtonSetting2:=button;
end;

procedure TFormRunPerformance.Button_CancelClick(Sender: TObject);
begin
  //Self.Hide;
  ModalResult:=mrCancel;
end;

procedure TFormRunPerformance.Button_HoldButtonSettingMouseDown(
  Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  (Sender as TButton).Caption:=MouseActToStr(shift,button);
  Self.Setting.HoldButtonSetting1:=shift;
  Self.Setting.HoldButtonSetting2:=button;
end;

procedure TFormRunPerformance.CheckGroup_PerformanceItemClick(Sender: TObject;
  Index: integer);
begin

end;

procedure TFormRunPerformance.Edit_SCM_KEY_KeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if Self.ToggleBox_SCM_KEY_manual.Checked then exit;
  (Sender as TEdit).Text:=IntToStr(key);
end;

procedure TFormRunPerformance.FormActivate(Sender: TObject);
var pi:integer;
begin
  with Self.Setting do
    begin
      AufButtonAct1:=Form_Routiner.Setting.AufButton.Act1;
      AufButtonAct2:=Form_Routiner.Setting.AufButton.Act2;
      Self.Button_AufButtonAct.Caption:=MouseActToStr(AufButtonAct1,AufButtonAct2);
      AufButtonExtraAct1:=Form_Routiner.Setting.AufButton.ExtraAct1;
      AufButtonExtraAct2:=Form_Routiner.Setting.AufButton.ExtraAct2;
      Self.Button_AufButtonExtraAct.Caption:=MouseActToStr(AufButtonExtraAct1,AufButtonExtraAct2);
      AufButtonSetting1:=Form_Routiner.Setting.AufButton.Setting1;
      AufButtonSetting2:=Form_Routiner.Setting.AufButton.Setting2;
      Self.Button_AufButtonSetting.Caption:=MouseActToStr(AufButtonSetting1,AufButtonSetting2);
      AufButtonHalt1:=Form_Routiner.Setting.AufButton.Halt1;
      AufButtonHalt2:=Form_Routiner.Setting.AufButton.Halt2;
      Self.Button_AufButtonHalt.Caption:=MouseActToStr(AufButtonHalt1,AufButtonHalt2);
      HoldButtonSetting1:=Form_Routiner.Setting.HoldButton.Setting1;
      HoldButtonSetting2:=Form_Routiner.Setting.HoldButton.Setting2;
      Self.Button_HoldButtonSetting.Caption:=MouseActToStr(HoldButtonSetting1,HoldButtonSetting2);
    end;
  Self.RadioGroup_SCM.ItemIndex:=byte(AdapterForm.Option.Shortcut.Mode);
  Self.Edit_SCM_KEY_Start.Text:=IntToStr(AdapterForm.Option.Shortcut.StartKey);
  Self.Edit_SCM_KEY_End.Text:=IntToStr(AdapterForm.Option.Shortcut.EndKey);
  Self.Edit_SCM_KEY_DownUp.Text:=IntToStr(AdapterForm.Option.Shortcut.DownUpKey);
  with AdapterForm.Option.Shortcut do
    begin
      StringGrid_CommandList.RowCount:=CommandList.Count+2;
      pi:=-1;
      if CommandList.Count>0 then
      for pi:=0 to CommandList.Count-1 do
        begin
          StringGrid_CommandList.Cells[1,pi+1]:=CommandList[pi];
          StringGrid_CommandList.Cells[2,pi+1]:=TStringList(CommandList.Objects[pi])[0];
          //StringGrid_CommandList.Cells[3,pi+1]:='...';
        end;
      inc(pi);
      StringGrid_CommandList.Cells[1,pi+1]:='';
      StringGrid_CommandList.Cells[2,pi+1]:='';
      //StringGrid_CommandList.Cells[3,pi+1]:='...';
    end;
end;

end.

