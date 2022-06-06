unit uStringParameterFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, uParameterFrame, Vcl.StdCtrls,
  uTemplateApi;

type
  TStringParameterFrame = class(TParameterFrame)
    ComboValue: TComboBox;
    procedure ComboValueChange(Sender: TObject);
  protected
    procedure LoadHistory(const History: TStrings); override;
    procedure ParameterToControl(const Value: string); override;
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
  ComboValue.Text := Parameter.DefaultString;
end;

procedure TStringParameterFrame.ComboValueChange(Sender: TObject);
begin
  inherited;
  ControlToParameter(ComboValue.Text);
end;

procedure TStringParameterFrame.LoadHistory(const History: TStrings);
begin
  ComboValue.items.Assign(History);
end;

procedure TStringParameterFrame.ParameterToControl(const Value: string);
var
  I: Integer;
begin
  I := ComboValue.Items.IndexOf(Value);
  if I < 0 then
    ComboValue.Text := Value
  else
    ComboValue.ItemIndex := I;
  ComboValue.SelLength := 0;
  ControlToParameter(Value);
end;

end.
