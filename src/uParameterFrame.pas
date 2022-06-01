unit uParameterFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, uTemplateApi, Vcl.StdCtrls;

type
  TParameterFrame = class(TFrame)
    LabelCaption: TLabel;
  private
    FParameter: IParameter;
    FOnValueChange: TNotifyEvent;
  protected
    procedure SetValue(const Value: string);
    procedure ValueChange; virtual;
  public
    constructor Create(Parameter: IParameter); reintroduce; virtual;
    property Parameter: IParameter read FParameter;
    property OnValueChange: TNotifyEvent read FOnValueChange write FOnValueChange;
  end;

implementation

{$R *.dfm}

{ TParameterFrame }

constructor TParameterFrame.Create(Parameter: IParameter);
begin
  inherited Create(nil);
  Name := '';
  FParameter := Parameter;
  LabelCaption.Caption := Parameter.Name;
end;

procedure TParameterFrame.SetValue(const Value: string);
begin
  FParameter.Value := Value;
  ValueChange;
end;

procedure TParameterFrame.ValueChange;
begin
  if Assigned(FOnValueChange) then
    FOnValueChange(Self);
end;

end.
