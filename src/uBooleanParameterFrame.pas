unit uBooleanParameterFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, uParameterFrame, Vcl.StdCtrls,
  uTemplateApi;

type
  TBooleanParameterFrame = class(TParameterFrame)
    CBValue: TCheckBox;
    procedure CBValueClick(Sender: TObject);
  protected
    procedure ParameterToControl(const Value: string); override;
  public
    constructor Create(Parameter: IParameter); override;
  end;

var
  BooleanParameterFrame: TBooleanParameterFrame;

implementation

{$R *.dfm}

{ TBooleanParameterFrame }

procedure TBooleanParameterFrame.CBValueClick(Sender: TObject);
begin
  inherited;
  ControlToParameter(BoolToStr(CBValue.Checked));
end;

constructor TBooleanParameterFrame.Create(Parameter: IParameter);
begin
  inherited;
  CBValue.Checked := SameText(Parameter.DefaultString, 'true');
  CBValue.Caption := Parameter.Name;
end;

procedure TBooleanParameterFrame.ParameterToControl(const Value: string);
begin
  inherited;
  CBValue.Checked := SameText(Value, 'True');
end;

end.
