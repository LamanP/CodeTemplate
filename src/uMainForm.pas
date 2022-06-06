unit uMainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.Actions, Vcl.ActnList,
  Vcl.StdCtrls, Vcl.ExtCtrls, uTemplateApi, System.Generics.Collections,
  uParameterFrame, Vcl.ComCtrls;

type
  TCodeTabSheet = class(TTabSheet)
  private
    FCodeSec: ICodeSection;
    FRichEdit: TRichEdit;
    procedure CopyToClipboard(Sender: TObject);
  public
    constructor Create(PageControl: TPageControl; CodeSec: ICodeSection); reintroduce;
    procedure Resolve;
  end;

  TMainForm = class(TForm)
    Panel1: TPanel;
    Button1: TButton;
    ActionList: TActionList;
    ActionOpenTemplate: TAction;
    OpenDialogTemplate: TOpenDialog;
    ScrollBoxParameters: TScrollBox;
    Splitter1: TSplitter;
    PageControlTemplate: TPageControl;
    TabSheetTemplate: TTabSheet;
    RETemplate: TRichEdit;
    ActionSaveTemplate: TAction;
    Panel2: TPanel;
    Button2: TButton;
    SaveDialogTemplate: TSaveDialog;
    TimerSyntaxHighlight: TTimer;
    LabelModified: TLabel;
    LabelTemplateFileName: TLabel;
    procedure ActionOpenTemplateExecute(Sender: TObject);
    procedure ActionSaveTemplateExecute(Sender: TObject);
    procedure ActionSaveTemplateUpdate(Sender: TObject);
    procedure RETemplateChange(Sender: TObject);
    procedure TimerSyntaxHighlightTimer(Sender: TObject);
    procedure TabSheetTemplateShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    FLoadingTemplate:Byte;
    FTemplate: ICodeTemplate;
    FParameterFrames: TObjectList<TParameterFrame>;
    FCodeSecSheets: TObjectList<TCodeTabSheet>;
    FTemplateModified: Boolean;
    procedure ApplicationDeactivate(Sender: TObject);
    procedure LoadTemplateFile(const FileName: string);
    procedure DisplayTemplate(Text: string);
    procedure SyntaxHighlight(const Pattern: string; const Color: TColor);
    procedure SyntaxHighlights;
    procedure DisplayCodeSections;
    procedure DisplayParameters;
    procedure ParameterValueChange(Sender: TObject);
    procedure SetTemplateModified(const Value: Boolean);
    procedure ResolveAll;
    procedure LoadTemplate(const TemplateSource: TStrings);
    procedure SaveParameterHistory;
    function GetParameterHistoryFileName(const CreateFolder: Boolean): string;
    procedure LoadParameterHistory;
    property TemplateModified: Boolean read FTemplateModified write SetTemplateModified;
  public
    constructor Create(Owner: TComponent); override;
    destructor Destroy; override;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses uBooleanParameterFrame, uStringParameterFrame, System.RegularExpressions, WinApi.RichEdit, Clipbrd;

type
  IDontModify = interface(IUnknown)
    ['{AD5523CD-9DB0-40ED-8CBB-F7AABA5B0452}']
  end;

  TDontModify = class(TInterfacedObject, IDontModify)
  private
    FMainForm: TMainForm;
    FSavedModified: Boolean;
  public
    constructor Create(const AMainForm: TMainForm); reintroduce;
    destructor Destroy; override;
  end;

{ TDontModify }

constructor TDontModify.Create(const AMainForm: TMainForm);
begin
  inherited Create;
  FMainForm := AMainForm;
  FSavedModified := FMainForm.TemplateModified;
end;

destructor TDontModify.Destroy;
begin
  FMainForm.TemplateModified := FSavedModified;
  inherited;
end;

{ TCodeTabSheet }

procedure TCodeTabSheet.CopyToClipboard(Sender: TObject);
begin
  Clipboard.AsText := FRichEdit.Text + #13#10;
end;

constructor TCodeTabSheet.Create(PageControl: TPageControl; CodeSec: ICodeSection);
resourcestring
  SCopyToClipboard = 'Copy';
var
  Panel: TPanel;
  Button: TButton;
begin
  inherited Create(PageControl);
  FCodeSec := CodeSec;
  Self.PageControl := PageControl;
  PageIndex := PageControl.PageCount - 2;
  Caption := CodeSec.Name;
  FRichEdit := TRichEdit.Create(Self);
  FRichEdit.Parent := Self;
  FRichEdit.Align := alClient;
  FRichEdit.Font.Name := 'Courier New';
  FRichEdit.ReadOnly := True;
  FRichEdit.PlainText := True;
  FRichEdit.ScrollBars := TScrollStyle.ssBoth;
  FRichEdit.Text := CodeSec.Resolve;

  Panel := TPanel.Create(Self);
  Panel.Parent := Self;
  Panel.Align := alBottom;
  Button := TButton.Create(Self);
  Button.Parent := Panel;
  Button.Anchors := [TAnchorKind.akRight];
  Panel.Height := Button.Height + 8;
  Button.Top := 4;
  Button.Left := Panel.ClientWidth - 4 - Button.Width;
  Button.Caption := SCopyToClipboard;
  Button.OnClick := CopyToClipboard;
end;

procedure TCodeTabSheet.Resolve;
begin
  FRichEdit.Text := FCodeSec.Resolve;
end;

{ TMainForm }

procedure TMainForm.ActionSaveTemplateExecute(Sender: TObject);
var
  PlainText: TStringList;
begin
  SaveDialogTemplate.FileName := OpenDialogTemplate.FileName;
  if SaveDialogTemplate.Execute then
  begin
    PlainText := TStringList.Create;
    try
      PlainText.Assign(RETemplate.Lines);
      PlainText.SaveToFile(SaveDialogTemplate.FileName);
    finally
      PlainText.Free;
    end;
    TemplateModified := False;
    LabelModified.Hide;
  end;
end;

procedure TMainForm.ActionSaveTemplateUpdate(Sender: TObject);
begin
  ActionSaveTemplate.Enabled := TemplateModified;
end;

procedure TMainForm.ActionOpenTemplateExecute(Sender: TObject);
begin
  if OpenDialogTemplate.Execute then
    LoadTemplateFile(OpenDialogTemplate.FileName);
end;

constructor TMainForm.Create(Owner: TComponent);
begin
  inherited;
  FParameterFrames := TObjectList<TParameterFrame>.Create(True);
  FCodeSecSheets := TObjectList<TCodeTabSheet>.Create(True);
  Application.OnDeactivate := ApplicationDeactivate;
end;

destructor TMainForm.Destroy;
begin
  FreeAndNil(FCodeSecSheets);
  FreeAndNil(FParameterFrames);
  inherited;
end;

procedure TMainForm.SyntaxHighlights;
var
  DontModify: IDontModify;
begin
  DontModify := TDontModify.Create(Self);
  SyntaxHighlight('\#[\w0-9 ]+\:', clGreen);
  SyntaxHighlight('\$\{[\w0-9 ]+\}', clBlue);
end;

procedure TMainForm.SetTemplateModified(const Value: Boolean);
begin
  FTemplateModified := Value;
  if PageControlTemplate.ActivePage = TabSheetTemplate then
    LabelModified.Visible := Value;
  RETemplate.Modified := Value;
end;

procedure TMainForm.SyntaxHighlight(const Pattern: string; const Color: TColor);
var
  Match: TMatch;
  SavSelStart, SavSelLength: Integer;
begin
  RETemplate.Perform(WM_SETREDRAW, 0, 0);
  try
    SavSelStart := RETemplate.SelStart;
    SavSelLength := RETemplate.SelLength;
    Match := TRegEx.Match(StringReplace(RETemplate.Text, #13#10, #10, [rfReplaceAll]), Pattern, [roMultiLine]);
    while Match.Success do
    begin
      RETemplate.SelStart := Match.Groups[0].Index - 1;
      RETemplate.SelLength := Match.Groups[0].Length;
      RETemplate.SelAttributes.Color := Color;
      Match := Match.NextMatch;
    end;
    RETemplate.SelStart := SavSelStart;
    RETemplate.SelLength := SavSelLength;
  finally
    RETemplate.Perform(WM_SETREDRAW, 1, 0);
    RedrawWindow(RETemplate.Handle, nil, 0, RDW_ERASE or RDW_FRAME or RDW_INVALIDATE or RDW_ALLCHILDREN);
  end;
end;

procedure TMainForm.TabSheetTemplateShow(Sender: TObject);
begin
  LabelModified.Visible := TemplateModified;
end;

procedure TMainForm.TimerSyntaxHighlightTimer(Sender: TObject);
var
  PageIndex: Integer;
  DontModify: IDontModify;
begin
  DontModify := TDontModify.Create(Self);
  SyntaxHighlights;
  PageIndex := PageControlTemplate.ActivePageIndex;
  LoadTemplate(RETemplate.Lines);
  PageControlTemplate.ActivePageIndex := PageIndex;
  TimerSyntaxHighlight.Enabled := False;
end;

procedure TMainForm.DisplayTemplate(Text: string);
begin
  RETemplate.Text := Text;
  SyntaxHighlights;
  TemplateModified := False;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
resourcestring
  STemplateChanged = 'Template %s has changed. Do you wish to close the app and lose your changes?';
begin
  CanClose := not TemplateModified or
    (MessageDlg(Format(STemplateChanged, [OpenDialogTemplate.FileName]), mtWarning, [mbYes, mbNo], 0, mbNo) = mrYes);
end;

procedure TMainForm.LoadTemplateFile(const FileName: string);
var
  TemplateSource: TStringList;
begin
  TemplateSource := TStringList.Create;
  try
    TemplateSource.LoadFromFile(FileName);
    LoadTemplate(TemplateSource);
    LabelTemplateFileName.Caption := FileName;
    TemplateModified := False;
  finally
    TemplateSource.Free;
  end;
end;

procedure TMainForm.LoadTemplate(const TemplateSource: TStrings);
begin
  Inc(FLoadingTemplate);
  try
    LabelTemplateFileName.Caption := '';
    FTemplate := ParseCodeTemplate(TemplateSource, OpenDialogTemplate.FileName);
    DisplayTemplate(TemplateSource.Text);
    LoadParameterHistory;
    DisplayParameters;
    DisplayCodeSections;
  finally
    Dec(FLoadingTemplate);
  end;
end;

procedure TMainForm.ParameterValueChange(Sender: TObject);
begin
  ResolveAll;
end;

procedure TMainForm.ResolveAll;
var
  I: Integer;
begin
  for I := 0 to FCodeSecSheets.Count - 1 do
    FCodeSecSheets[I].Resolve;
end;

procedure TMainForm.DisplayParameters;
var
  I: Integer;
  Param: IParameter;
  Frame: TParameterFrame;
begin
  ScrollBoxParameters.DisableAlign;
  try
    FParameterFrames.Clear;
    for I := 0 to FTemplate.ParameterCount - 1 do
    begin
      Param := FTemplate.Parameters[I];
      if SameText(Param.DataType, 'boolean') then
        Frame := TBooleanParameterFrame.Create(Param)
      else
        Frame := TStringParameterFrame.Create(Param);
      Frame.Parent := ScrollBoxParameters;
      Frame.Align := alTop;
      Frame.Top := I * Frame.Height;
      Frame.OnValueChange := ParameterValueChange;
      if I = 0 then
        ActiveControl := Frame;
      FParameterFrames.Add(Frame);
    end;
  finally
    ScrollBoxParameters.EnableAlign;
  end;
  if Assigned(Frame) then
    begin
      ScrollBoxParameters.VertScrollBar.Range := Frame.BoundsRect.Bottom;
      ScrollBoxParameters.VertScrollBar.Increment := Frame.Height;
      ScrollBoxParameters.VertScrollBar.Position := 0;
    end
  else
    ScrollBoxParameters.VertScrollBar.Range := 0;
end;

procedure TMainForm.DisplayCodeSections;
var
  I: Integer;
begin
  FCodeSecSheets.clear;
  for I := 0 to FTemplate.CodeSectionCount - 1 do
    FCodeSecSheets.Add(TCodeTabSheet.Create(PageControlTemplate, FTemplate.CodeSections[I]));
  if FCodeSecSheets.Count > 0 then
    PageControlTemplate.ActivePageIndex := 0;
end;

procedure TMainForm.RETemplateChange(Sender: TObject);
begin
  if FLoadingTemplate = 0 then
  begin
    TimerSyntaxHighlight.Enabled := True;
    TemplateModified := True;
  end;
end;

procedure TMainForm.ApplicationDeactivate(Sender: TObject);
begin
  SaveParameterHistory;
end;

function TMainForm.GetParameterHistoryFileName(const CreateFolder: Boolean): string;
var
  HistoryFolder: string;
begin
  HistoryFolder := GetEnvironmentVariable('APPDATA') +
    '\Competer\CodeTemplates\History\' +
    StringReplace(ExtractFilePath(OpenDialogTemplate.FileName), ':','', [rfReplaceAll]);
  ForceDirectories(ExtractFilePath(HistoryFolder));
  Result := ExcludeTrailingPathDelimiter(HistoryFolder) + '.hist';
end;

procedure TMainForm.SaveParameterHistory;
var
  I: Integer;
  Param: IParameter;
  KeySet: IKeySet;
  Key: IKey;
  Writer: IKeyHistoryWriter;
begin
  if not Assigned(FTemplate) then Exit;

  KeySet := FTemplate.KeySet;
  for I := 0 to FParameterFrames.Count - 1 do
  begin
    Param := FParameterFrames[I].Parameter;
    Key := Param.Key;
    if Assigned(Key) and (Length(Param.Value) > 0) then
      Key.AddRecentItem(Param.Value);
  end;

  // Determine history file name
  Writer := CreateKeyHistoryFileWriter(GetParameterHistoryFileName(True));
  Writer.Write(FTemplate);
end;

procedure TMainForm.LoadParameterHistory;
var
  HistFileName: string;
  Reader: IKeyHistoryReader;
begin
  HistFileName := GetParameterHistoryFileName(False);
  if not FileExists(HistFileName) then
    Exit;
  Reader := CreateKeyHistoryFileReader(HistFileName);
  Reader.Read(FTemplate);
end;

end.
