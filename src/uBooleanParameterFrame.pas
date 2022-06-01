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
  SetValue(BoolToStr(CBValue.Checked));
end;

constructor TBooleanParameterFrame.Create(Parameter: IParameter);
begin
  inherited;
  CBValue.Checked := SameText(Parameter.DefaultString, 'true');
  CBValue.Caption := Parameter.Name;
end;

end.
