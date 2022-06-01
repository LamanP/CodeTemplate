unit uTemplateApi;

interface

uses
  SysUtils, Classes;

type
  ETemplateSyntaxError = class(Exception)
  public
    constructor Create(const Fmt: string; const LineIndex: Integer; const Args: array of const); overload;
    constructor Create(const Fmt: string; const LineIndex: Integer); overload;
  end;

  IParameter = interface(IUnknown)
    ['{9DA21B97-3C30-4652-A6F2-D98DEA18C852}']
    function GetName: string;
    function GetDataType: string;
    function GetDefaultString: string;
    function GetValue: string;
    procedure SetValue(const Value: string);

    property Name: string read GetName;
    property DataType: string read GetDataType;
    property DefaultString: string read GetDefaultString;
    property Value: string read GetValue write SetValue;
  end;

  ICodeSection = interface(IUnknown)
    ['{6AAD9702-F897-46B1-94AE-18CB24DB5CA2}']
    function GetName: string;
    function GetCode: string;
    function Resolve: string;

    property Name: string read GetName;
    property Code: string read GetCode;
  end;

  ICodeTemplate = interface(IUnknown)
    ['{D00BA69D-6DA0-47A3-A966-F705F0F43F54}']
    function GetParameterCount: Integer;
    function GetParameters(Index: Integer): IParameter;
    function GetCodeSectionCount: Integer;
    function GetCodeSections(Index: Integer): ICodeSection;

    property ParameterCount: Integer read GetParameterCount;
    property Parameters[Index: Integer]: IParameter read GetParameters;

    property CodeSectionCount: Integer read GetCodeSectionCount;
    property CodeSections[Index: Integer]: ICodeSection read GetCodeSections;
  end;

function ParseCodeTemplate(const Template: TStrings): ICodeTemplate;

implementation

uses System.RegularExpressions;

const
  MaxSectionDataLength = 10;

type
  TCodeTemplate = class;
  TSectionData = record
    Count: Integer;
    SectionArgs: array of string;
  end;

  TParameter = class(TContainedObject, IParameter)
  private
    FName: string;
    FDataType: string;
    FDefaultString: string;
    FValue: string;
  protected
    function GetName: string;
    function GetDataType: string;
    function GetDefaultString: string;
    function GetValue: string;
    procedure SetValue(const Value: string);
  public
    constructor Create(Controller: IUnknown; const Name: string;
      const DataType: string; const DefaultString: string); reintroduce;
    destructor Destroy; override;
  end;

  TCodeSection = class(TContainedObject, ICodeSection)
  private
    FName: string;
    FCode: string;
    FTemplate: TCodeTemplate;
  protected
    function GetName: string;
    function GetCode: string;
    function Resolve: string;
  public
    constructor Create(Template: TCodeTemplate; const Name: string;
      const Code: string); reintroduce;
  end;

  TCodeTemplate = class(TInterfacedObject, ICodeTemplate)
  private
    FParameters: TList;
    FCodeSections: TList;
    procedure DestroyList(var List: TList);
  protected
    function GetParameterCount: Integer;
    function GetParameters(Index: Integer): IParameter;
    function GetCodeSectionCount: Integer;
    function GetCodeSections(Index: Integer): ICodeSection;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;
    procedure Parse(const Template: TStrings);
    function FindParameter(const Name: string): TParameter;
  end;

function ParseCodeTemplate(const Template: TStrings): ICodeTemplate;
var
  Tpl: TCodeTemplate;
begin
  Tpl := TCodeTemplate.Create;
  Result := Tpl;
  Tpl.Parse(Template);
end;

procedure SplitSectionData(const Line: string; var Sections: TSectionData);
var
  I, J, L: Integer;
begin
  L := Length(Line);
  I := 1;
  SetLength(Sections.SectionArgs, MaxSectionDataLength);
  Sections.Count := 0;
  while (I <= L) and (Sections.Count < MaxSectionDataLength) do
  begin
    J := I;
    while (I <= L) and (Line[I] <> ':') do Inc(I);
    Sections.SectionArgs[Sections.Count] := Copy(Line, J, I - J);
    Inc(Sections.Count);
    Inc(I);
  end;
end;

{ TParameter }

constructor TParameter.Create(Controller: IUnknown; const Name: string;
  const DataType: string; const DefaultString: string);
begin
  inherited Create(Controller);
    FName := Name;
    FDataType := DataType;
    FDefaultString := DefaultString;
    FValue := DefaultString;
end;

destructor TParameter.Destroy;
begin
  inherited;
end;

function TParameter.GetDataType: string;
begin
  Result := FDataType;
end;

function TParameter.GetDefaultString: string;
begin
  Result := FDefaultString;
end;

function TParameter.GetName: string;
begin
  Result := FName;
end;

function TParameter.GetValue: string;
begin
  Result := FValue;
end;

procedure TParameter.SetValue(const Value: string);
begin
  FValue := Value;
end;

{ TCodeTemplate }

constructor TCodeTemplate.Create;
begin
  inherited;
  FParameters := TList.Create;
  FCodeSections := TList.Create;
end;

destructor TCodeTemplate.Destroy;
begin
  DestroyList(FParameters);
  DestroyList(FCodeSections);
  inherited;
end;

procedure TCodeTemplate.DestroyList(var List: TList);
var
  I: Integer;
begin
  I := List.Count;
  while I > 0 do
  begin
    Dec(I);
    TObject(List[I]).Free;
  end;
  FreeAndNil(List);
end;

function TCodeTemplate.FindParameter(const Name: string): TParameter;
var
  I: Integer;
begin
  for I := 0 to FParameters.Count - 1 do
  begin
    Result := FParameters[I];
    if SameText(Result.FName, Name) then
      Exit;
  end;
  Result := nil;
end;

function TCodeTemplate.GetCodeSectionCount: Integer;
begin
  Result := FCodeSections.Count;
end;

function TCodeTemplate.GetCodeSections(Index: Integer): ICodeSection;
begin
  Result := TCodeSection(FCodeSections[Index]);
end;

function TCodeTemplate.GetParameterCount: Integer;
begin
  Result := FParameters.Count;
end;

function TCodeTemplate.GetParameters(Index: Integer): IParameter;
begin
  Result := TParameter(FParameters[Index]);
end;

procedure TCodeTemplate.Parse(const Template: TStrings);
resourcestring
  SSectionMustStartHash = 'A section must start with ''#''';
  SSectionNameMissing = 'Section name missing';
  SUnsupportedSectionId = 'Unsupported section ID: ''%s''';
  SParameterNameMissing = 'Parameter name missing';
var
  I: Integer;
  Line: string;
  SectionData: TSectionData;

  procedure ParseParameter;
  resourcestring
    SParameterNameMissing = 'Parameter name missing';
    SParameterTypeMissing = 'Parameter type missing';
  var
    ParamName,
    ParamType,
    ParamDefault: string;
  begin
    if SectionData.Count < 2 then
      raise ETemplateSyntaxError.Create(SParameterNameMissing, I);
    ParamName := SectionData.SectionArgs[1];
    if SectionData.Count < 3 then
      raise ETemplateSyntaxError.Create(SParameterTypeMissing, I);
    ParamType := SectionData.SectionArgs[2];
    if SectionData.Count > 3 then
      ParamDefault := SectionData.SectionArgs[3]
    else
      ParamDefault := '';
    FParameters.Add(TParameter.Create(Self, ParamName, ParamType, ParamDefault));
  end;

  procedure ParseCodeSection;
  resourcestring
    SDefaultSectionName = 'Code section';
  var
    SectionName: string;
    SectionBuilder: TStringBuilder;
    FirstLine: Boolean;
    Line: string;
  begin
    if SectionData.Count > 1 then
      SectionName := SectionData.SectionArgs[1]
    else
      SectionName := SDefaultSectionName;
    Inc(I);
    FirstLine := True;
    SectionBuilder := TStringBuilder.Create;
    try
      while (I < Template.Count) do
      begin
        Line := Template[I];
        if (Length(Line) > 0) and (Line[1] = '#') then
        begin
          Dec(I);
          Break;
        end;
        if FirstLine then
          FirstLine := False
        else
          SectionBuilder.Append(#13#10);
        SectionBuilder.Append(Line);
        Inc(I);
      end;
      FCodeSections.Add(TCodeSection.Create(Self, SectionName, SectionBuilder.ToString));
    finally
      SectionBuilder.Free;
    end;
  end;

begin // Parse
   I := 0;
   while I < Template.Count do
   begin
     Line := Template[I];
     if Length(Line) > 0 then
     begin
       if Line[1] <> '#' then
         raise ETemplateSyntaxError.Create(SSectionMustStartHash, I);
       SplitSectionData(Copy(Line, 2, Length(Line)), SectionData);
       if SectionData.Count = 0 then
         raise ETemplateSyntaxError.Create(SSectionNameMissing, I);

         // See what we have here
         if SameText(SectionData.SectionArgs[0], 'parameter') then
           ParseParameter
         else if SameText(SectionData.SectionArgs[0], 'code') then
           ParseCodeSection
         else
           raise ETemplateSyntaxError.Create(SUnsupportedSectionId, I, [SectionData.SectionArgs[0]]);
     end;
     Inc(I);
   end;
end;

{ ETemplateSyntaxError }

constructor ETemplateSyntaxError.Create(const Fmt: string;
  const LineIndex: Integer);
begin
  Create(Fmt, LineIndex, [nil]);
end;

constructor ETemplateSyntaxError.Create(const Fmt: string;
  const LineIndex: Integer; const Args: array of const);
resourcestring
  SMsgWithLine = '%s at line %d';
begin
  inherited CreateFmt(SMsgWithLine, [Format(Fmt, Args), LineIndex + 1]);
end;

{ TCodeSection }

constructor TCodeSection.Create(Template: TCodeTemplate; const Name, Code: string);
begin
  inherited Create(Template);
  FTemplate := Template;
  FName := Name;
  FCode := Code;
end;

function TCodeSection.GetCode: string;
begin
  Result := FCode;
end;

function TCodeSection.GetName: string;
begin
  Result := FName;
end;

function TCodeSection.Resolve: string;
var
  Param: TParameter;
  Match: TMatch;
  Delta: Integer;
  GroupIndex, GroupLength: Integer;
begin
  Result := StringReplace(FCode, #13#10, #10, [rfReplaceAll]);
  Match := TRegEx.Match(Result, '\$\{([\w0-9 ]+)\}', [roMultiLine]);
  Delta := 0;
  while Match.Success do
  begin
    Param := FTemplate.FindParameter(Match.Groups[1].Value);
    if Assigned(Param) and (Length(Param.FValue) > 0) then
    begin
      GroupIndex := Match.Groups[0].Index;
      GroupLength := Match.Groups[0].Length;
      Result := Copy(Result, 1, GroupIndex - 1 + Delta) +
        Param.FValue + Copy(Result, GroupIndex + GroupLength + Delta, MaxInt);
      Delta := Delta - Match.Groups[0].Length + Length(Param.FValue);
    end;
    Match := Match.NextMatch;
  end;
end;

end.
