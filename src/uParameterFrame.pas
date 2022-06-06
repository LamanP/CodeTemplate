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
    procedure GetHistoryFromKey;
  protected
    procedure ControlToParameter(const Value: string);
    procedure ParameterToControl(const Value: string); virtual; abstract;
    procedure ValueChange; virtual;
    procedure LoadHistory(const History: TStrings); dynamic;
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
  GetHistoryFromKey;
  LabelCaption.Caption := Parameter.Name;
end;

procedure TParameterFrame.GetHistoryFromKey;
var
  History: TStringList;
  Key: IKey;
  Cnt, I: Integer;
begin
  Key := FParameter.Key;
  Cnt := Key.RecentItemCount;
  if Cnt = 0 then
    Exit;
  History := TStringList.Create;
  try
    for I := Cnt - 1 downto 0 do
      History.Add(Key[I]);
    LoadHistory(History);
    ParameterToControl(History[0]);
  finally
    History.Free;
  end;
end;

procedure TParameterFrame.LoadHistory(const History: TStrings);
begin
  // To be overridden
end;

procedure TParameterFrame.ControlToParameter(const Value: string);
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
