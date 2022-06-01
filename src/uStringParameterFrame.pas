unit uStringParameterFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, uParameterFrame, Vcl.StdCtrls,
  uTemplateApi;

type
  TStringParameterFrame = class(TParameterFrame)
    EditValue: TEdit;
    procedure EditValueChange(Sender: TObject);
  public
    constructor Create(Parameter: IParameter); override;
  end;

var
  StringParameterFrame: TStringParameterFrame;

implementation

{$R *.dfm}

{ TTStringParameterFrame }

constructor TStringParameterFrame.Create(Parameter: IParameter);
begin
  inherited;
  EditValue.Text := Parameter.DefaultString;
end;

procedure TStringParameterFrame.EditValueChange(Sender: TObject);
begin
  inherited;
  SetValue(EditValue.Text);
end;

end.
