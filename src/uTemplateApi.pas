unit uTemplateApi;

interface

uses
  SysUtils, Classes;

type
  IKeySet = interface;
  IKey = interface;
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
    function GetKey: IKey;

    property Name: string read GetName;
    property DataType: string read GetDataType;
    property DefaultString: string read GetDefaultString;
    property Value: string read GetValue write SetValue;
    property Key: IKey read GetKey;
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
    function GetKeySet: IKeySet;

    property ParameterCount: Integer read GetParameterCount;
    property Parameters[Index: Integer]: IParameter read GetParameters;

    property CodeSectionCount: Integer read GetCodeSectionCount;
    property CodeSections[Index: Integer]: ICodeSection read GetCodeSections;
    property KeySet: IKeySet read GetKeySet;
  end;

  // Persistence
  IKey = interface(IUnknown)
    ['{9F66E5C9-D845-4C20-9F09-3A218897DC2B}']
    function GetName: string;
    function GetRecentItem(const Idx: Integer): string;
    function GetRecentItemCount: Integer;

    function AddRecentItem(const Value: string): Integer;

    property Name: string read GetName;
    property RecentItems[const Idx: Integer]: string read GetRecentItem; default;
    property RecentItemCount: Integer read GetRecentItemCount;
  end;

  IKeySet = interface(IUnknown)
    ['{67893800-8669-479A-8EE9-BC123510D2A6}']
    function GetMaxHistory: Integer;
    function GetKey(const Idx: Integer): IKey;
    function GetKeyCount: Integer;

    function FindKey(const KeyName: string): IKey;

    property Keys[const Idx: Integer]: IKey read GetKey; default;
    property KeyCount: Integer read GetKeyCount;
    property MaxHistory: Integer read GetMaxHistory;
  end;

  IKeyHistoryWriter = interface(IUnknown)
    ['{B1DAD4F7-F6D8-4074-A8E2-6AC7C46D09D1}']
    procedure Write(Template: ICodeTemplate);
  end;

  IKeyHistoryReader = interface(IUnknown)
    ['{B64E9C61-D9F0-4733-9E3D-62CBFC4FFF6B}']
    procedure Read(Template: ICodeTemplate);
  end;

function ParseCodeTemplate(const Template: TStrings; const FileName: string): ICodeTemplate;
function CreateKeyHistoryFileWriter(const FileName: string): IKeyHistoryWriter;
function CreateKeyHistoryFileReader(const FileName: string): IKeyHistoryReader;

implementation

uses System.RegularExpressions;

const
  MaxSectionDataLength = 10;

type
  TCodeTemplate = class;
  TKeySet = class;

  TSectionData = record
    Count: Integer;
    SectionArgs: array of string;
  end;

  // Internal access to IKey
  IKeyInternal = interface(IKey)
    ['{F16185F2-101F-4E5E-A0BE-728040F1DA5B}']
    procedure ClearHistory;
  end;

  TParameter = class(TContainedObject, IParameter)
  private
    FCodeTemplate: TCodeTemplate;
    FName: string;
    FDataType: string;
    FDefaultString: string;
    FValue: string;
    FKey: IKey;
  protected
    function GetName: string;
    function GetDataType: string;
    function GetDefaultString: string;
    function GetValue: string;
    function GetKey: IKey;
    procedure SetValue(const Value: string);
  public
    constructor Create(CodeTemplate: TCodeTemplate; const Name: string;
      const DataType: string; const DefaultString: string;
      const Key: IKey); reintroduce;
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
    FKey: IKey;
    FParameters: TList;
    FCodeSections: TList;
    FKeySet: TKeySet;
    FFileName: string;
    procedure DestroyList(var List: TList);
    procedure LoadKeys(FileName: string; const DefaultFolder: string);
  protected
    function GetParameterCount: Integer;
    function GetParameters(Index: Integer): IParameter;
    function GetCodeSectionCount: Integer;
    function GetCodeSections(Index: Integer): ICodeSection;
    function GetKeySet: IKeySet;
  public
    constructor Create(const FileName: string); reintroduce;
    destructor Destroy; override;
    procedure Parse(const Template: TStrings);
    function FindParameter(const Name: string): TParameter;
  end;

  TKey = class(TContainedObject, IKey)
  private
    FKeySet: TKeySet;
    FName: string;
    FRecentItems: TStringList;
    procedure PruneRecentItems;
  protected
    function GetName: string;
    procedure SetName(const Value: string);
    function GetRecentItem(const Idx: Integer): string;
    function GetRecentItemCount: Integer;
    function AddRecentItem(const Value: string): Integer;
  public
    constructor Create(const KeySet: TKeySet; const Name: string);
    destructor Destroy; override;
  end;

  TKeySet = class(TContainedObject, IKeySet)
  private
    FKeys: TStringList;
    FMaxHistory: Integer;
  protected
    function GetKey(const Idx: Integer): IKey;
    function GetKeyCount: Integer;
    function GetMaxHistory: Integer;
    function AddKey(const KeyName: string): IKey;
    function FindKey(const KeyName: string): IKey;
  public
    constructor Create(Controller: IUnknown); reintroduce;
    destructor Destroy; override;
  end;

  TKeyHistoryFileWriter = class(TInterfacedObject, IKeyHistoryWriter)
  private
    FFileName: string;
  protected
    procedure Write(Template: ICodeTemplate);
  public
    constructor Create(const FileName: string); reintroduce;
  end;

  TKeyHistoryFileReader = class(TInterfacedObject, IKeyHistoryReader)
  private
    FFileName: string;
  protected
    procedure Read(Template: ICodeTemplate);
  public
    constructor Create(const FileName: string); reintroduce;
  end;

function ParseCodeTemplate(const Template: TStrings; const FileName: string): ICodeTemplate;
var
  Tpl: TCodeTemplate;
begin
  Tpl := TCodeTemplate.Create(FileName);
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

function CreateKeyHistoryFileWriter(const FileName: string): IKeyHistoryWriter;
begin
  Result := TKeyHistoryFileWriter.Create(FileName);
end;

function CreateKeyHistoryFileReader(const FileName: string): IKeyHistoryReader;
begin
  Result := TKeyHistoryFileReader.Create(FileName);
end;

{ TParameter }

constructor TParameter.Create(CodeTemplate: TCodeTemplate; const Name: string;
  const DataType: string; const DefaultString: string; const Key: IKey);
begin
  inherited Create(CodeTemplate);
  FCodeTemplate := CodeTemplate;
  FName := Name;
  FDataType := DataType;
  FDefaultString := DefaultString;
  FValue := DefaultString;
  FKey := Key;
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

function TParameter.GetKey: IKey;
begin
  Result := FKey;
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

constructor TCodeTemplate.Create(const FileName: string);
begin
  inherited Create;
  FFileName := FileName;
  FParameters := TList.Create;
  FCodeSections := TList.Create;
  FKeySet := TKeySet.Create(Self);
end;

destructor TCodeTemplate.Destroy;
begin
  DestroyList(FParameters);
  DestroyList(FCodeSections);
  FreeAndNil(FKeySet);
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

function TCodeTemplate.GetKeySet: IKeySet;
begin
  Result := FKeySet;
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
  SKeyNameMissing = 'Key name missing';
  SKeyFileNameMissing = 'Key file name missing';
  SUndefinedKey = 'Key "%s" in the reference key file, or no key file has been referenced';
  SDefaultParameterType = 'string';
var
  I: Integer;
  Line: string;
  SectionData: TSectionData;

  procedure ParseParameter;
  resourcestring
    SParameterNameMissing = 'Parameter name missing';
  var
    ParamName,
    ParamType,
    ParamDefault: string;
  begin
    if SectionData.Count < 2 then
      raise ETemplateSyntaxError.Create(SParameterNameMissing, I);
    ParamName := SectionData.SectionArgs[1];
    if SectionData.Count < 3 then
      ParamType := SDefaultParameterType
    else
      ParamType := SectionData.SectionArgs[2];
    if SectionData.Count > 3 then
      ParamDefault := SectionData.SectionArgs[3]
    else
      ParamDefault := '';
    FParameters.Add(TParameter.Create(Self, ParamName, ParamType, ParamDefault, FKey));
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
   // We must load a key file before loading parameters. So, first see if there
   // is a keyfile declared.
   for I := 0 to Template.Count - 1 do
   begin
     Line := Template[I];
     if SameText(Copy(Line, 1, 9), '#keyfile:') then
     begin
       SplitSectionData(Copy(Line, 2, Length(Line)), SectionData);
       if Length(SectionData.SectionArgs) < 2 then
         raise ETemplateSyntaxError.Create(SKeyFileNameMissing, I);
       LoadKeys(SectionData.SectionArgs[1], ExtractFilePath(FFileName));
       Break;
     end;
   end;

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
           begin
             ParseCodeSection;
             FKey := nil;
           end
         else if SameText(SectionData.SectionArgs[0], 'key') then
           begin
             if Length(SectionData.SectionArgs) < 2 then
               raise ETemplateSyntaxError.Create(SKeyNameMissing, I);
             FKey := FKeySet.FindKey(SectionData.SectionArgs[1]);
             if not Assigned(FKey) then
               raise ETemplateSyntaxError.Create(SUndefinedKey, I, [SectionData.SectionArgs[1]]);
           end
         else if SameText(SectionData.SectionArgs[0], 'keyfile') then
           // Ignore, because we already loaded the key file
         else
           raise ETemplateSyntaxError.Create(SUnsupportedSectionId, I, [SectionData.SectionArgs[0]]);
     end;
     Inc(I);
   end;
end;

procedure TCodeTemplate.LoadKeys(FileName: string; const DefaultFolder: string);
resourcestring
  SNoSuchKeyFile = 'Keyfile ''%s''does not exist';
  SMaxHistoryMissing = 'Max. history missing from keys file';
  SKeyMissing = 'Key name missing from keys file';
  SMaxHistoryNotInteger = 'Max. history must be an integer in keys file';
  SDupKey = 'Duplicate key name "%s" in key file';
  SSectionStartError = 'A section must be identified by an "#" as the first character on the line';
  SNoSuchSectionName = 'Section "%s" is undefined for a keys file';
var
  Data: TStringList;
  Line: string;
  I, MaxHistory: Integer;
  Sections: TSectionData;
  SectionName: string;
begin
  Data := TStringList.Create;
  try
    if Length(ExtractFilePath(FileName)) = 0 then
      FileName := IncludeTrailingPathDelimiter(DefaultFolder) + FileName;
    if not FileExists(FileName) then
      raise ETemplateSyntaxError.Create(SNoSuchKeyFile, I, [FileName]);
    Data.LoadFromFile(FileName);
    for I := 0 to Data.Count - 1 do
    begin
      Line := Data[I];
      if Length(Line) > 0 then
      begin
        SplitSectionData(Line, Sections);
        if Sections.Count = 0 then
          SectionName := ''
        else if (Length(Sections.SectionArgs[0]) > 0) and
                (Sections.SectionArgs[0][1] = '#')
        then
          SectionName := Copy(Sections.SectionArgs[0], 2, MaxInt)
        else
          raise ETemplateSyntaxError.Create(SSectionStartError, I);
        if SameText(SectionName, 'maxhistory') then
          begin
            if Sections.Count < 2 then
              raise ETemplateSyntaxError.Create(SMaxHistoryMissing, I);
            if not TryStrToInt(Sections.SectionArgs[1], MaxHistory) then
              raise ETemplateSyntaxError.Create(SMaxHistoryNotInteger, I);
            FKeySet.FMaxHistory := MaxHistory;
          end
        else if SameText(SectionName, 'key') then
          begin
            if Sections.Count < 2 then
              raise ETemplateSyntaxError.Create(SKeyMissing, I);
            if Assigned(FKeySet.FindKey(Sections.SectionArgs[1])) then
              raise ETemplateSyntaxError.Create(SDupKey, I, [Sections.SectionArgs[1]]);
            FKeyset.AddKey(Sections.SectionArgs[1]);
          end
        else
          raise ETemplateSyntaxError.Create(SNoSuchSectionName, I, [SectionName]);
      end;
    end;
  finally
    Data.Free;
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

{ TKeySet }

function TKeySet.AddKey(const KeyName: string): IKey;
var
  Key: TKey;
begin
  Key := TKey.Create(Self, KeyName);
  try
    FKeys.AddObject(KeyName, Key);
  except
    Key.Free;
    raise;
  end;
  Result := Key;
end;

constructor TKeySet.Create(Controller: IUnknown);
begin
  inherited Create(Controller);
  FKeys := TStringList.Create;
  FKeys.Sorted := True;
end;

destructor TKeySet.Destroy;
begin
  FreeAndNil(FKeys);
  inherited;
end;

function TKeySet.FindKey(const KeyName: string): IKey;
var
  I: Integer;
begin
  I := FKeys.IndexOf(KeyName);
  if I < 0 then
    Result := nil
  else
    Result := TKey(FKeys.Objects[I]);
end;

function TKeySet.GetMaxHistory: Integer;
begin
  Result := FMaxHistory;
end;

function TKeySet.GetKey(const Idx: Integer): IKey;
begin
  Result := TKey(FKeys.Objects[Idx]);
end;

function TKeySet.GetKeyCount: Integer;
begin
  Result := FKeys.Count;
end;

{ TKey }

constructor TKey.Create(const KeySet: TKeySet; const Name: string);
begin
  inherited Create(KeySet);
  FKeySet := KeySet;
  FName := Name;
  FRecentItems := TStringList.Create;
end;

destructor TKey.Destroy;
begin
  FreeAndNil(FRecentItems);
  inherited;
end;

function TKey.GetName: string;
begin
  Result := FName;
end;

function TKey.GetRecentItem(const Idx: Integer): string;
begin
   Result := FRecentItems[Idx];
end;

function TKey.GetRecentItemCount: Integer;
begin
  Result := FRecentItems.Count;
end;

procedure TKey.PruneRecentItems;
var
  Cnt: Integer;
begin
  Cnt := FRecentItems.Count;
  while Cnt > FKeySet.FMaxHistory do
  begin
    Dec(Cnt);
    FRecentItems.Delete(Cnt);
  end;
end;

procedure TKey.SetName(const Value: string);
begin

end;

function TKey.AddRecentItem(const Value: string): Integer;
begin
  Result := FRecentItems.IndexOf(Value);
  if Result < 0 then
    begin
      FRecentItems.Insert(0, Value);
      PruneRecentItems;
      Result := 0;
    end
  else if Result <> 0 then
    FRecentItems.Move(Result, 0);
end;

{ TKeyHistoryFileWriter }

constructor TKeyHistoryFileWriter.Create(const FileName: string);
begin
  inherited Create;
  FFileName := FileName;
end;

procedure TKeyHistoryFileWriter.Write(Template: ICodeTemplate);
var
  Data: TStringList;
  I, J: Integer;
  KeySet: IKeySet;
  Key: IKey;
begin //Write
  Data := TStringList.Create;
  try
    KeySet := Template.KeySet;
    for I := 0 to KeySet.KeyCount - 1 do
    begin
      Key := KeySet[I];
      Data.Add(Key.Name);
      for J := 0 to Key.RecentItemCount - 1 do
        Data.Add('#'+Key[J]);
    end;
    Data.SaveToFile(FFileName);
  finally
    Data.Free;
  end;
end;

{ TKeyHistoryFileReader }

constructor TKeyHistoryFileReader.Create(const FileName: string);
begin
  inherited Create;
  FFileName := FileName;
end;

procedure TKeyHistoryFileReader.Read(Template: ICodeTemplate);
var
  Data: TStringList;
  Line: string;
  I: Integer;
  KeySet: IKeySet;
  Key: IKey;
begin
  Data := TStringList.Create;
  try
    Data.LoadFromFile(FFileName);
    KeySet := Template.KeySet;
    Key := nil;
    for I := 0 to Data.Count -1 do
    begin
      Line := Data[I];
      if Length(Line) > 0 then
      begin
        if Line[1] = '#' then // It's a recent file
          begin
            if Assigned(Key) then
              Key.AddRecentItem(Copy(Line, 2, Length(Line) - 1))
          end
        else
          Key := KeySet.FindKey(Line);
      end;
    end;
  finally
    Data.Free;
  end;
end;

end.
