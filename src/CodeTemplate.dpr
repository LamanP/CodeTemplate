program CodeTemplate;

uses
  Vcl.Forms,
  uMainForm in 'uMainForm.pas' {MainForm},
  uParameterFrame in 'uParameterFrame.pas' {ParameterFrame: TFrame},
  uTemplateApi in 'uTemplateApi.pas',
  uStringParameterFrame in 'uStringParameterFrame.pas' {StringParameterFrame: TFrame},
  uBooleanParameterFrame in 'uBooleanParameterFrame.pas' {BooleanParameterFrame: TFrame};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
