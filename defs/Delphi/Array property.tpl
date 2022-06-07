#keyfile:keys.txt
#key:delphi.class
#parameter:Class:string
#key:delphi.property.name.singular
#parameter:Singular Name:string
#key:delphi.property.name.plural
#parameter:Plural Name:string
#key:delphi.datatype
#parameter:Data type:string
#parameter:List class:string:TStringList
#key:delphi.indextype
#parameter:Index type:string:Integer
#Parameter:Index name:string:Index
#parameter:Default property:Boolean:false
#code:Getter/Setter (Decl)
    function Get${Singular Name}(const ${Index name}: ${Index type}): ${Data type};
    procedure Set${Singular Name}(const ${Index name}: ${Index type}; const Value: ${Data type});
    function Get${Singular Name}Count: Integer;
#code:Property (Decl)
    property ${Plural Name}[const ${Index name}: ${Index type}]: ${Data type} read Get${Singular Name} write Set${Singular Name};
    property ${Singular Name}Count: Integer read Get${Singular Name}Count;
#code:Methods (Decl)
    procedure Insert${Singular Name}(const ${Index Name}: ${Index type}; const Value: ${Data type});
    function Add(const Value: ${Data type}): Integer;
    function Delete${Singular Name}(const ${Index Name}: ${Index type});
    function IndexOF${Plural Name}(const Value: ${Data type}): ${Index type};
    function Remove${Singular Name}(const Value: ${Data type});
#code:Create/Destroy variable
    F${Plural Name} := ${List class}.Create;
    FreeAndNil(F{${Plural Name});
#code:Getter/Setter (Impl)
function ${Class}.Get${Singular Name}(const ${Index name}: ${Index type}): ${Data type};
begin
  Result := F${Plural Name}[${Index name}];
end;

function ${Class}.Get${Singular Name}Count: Integer;
begin
  Result := F${Plural Name}.Count;
end;

procedure ${Class}.Set${Singular Name}(const ${Index name}: ${Index type}; const Value: ${Data type});
begin
end;

#code:Methods (Impl)
procedure ${Class}.Insert${Singular Name}(const ${Index Name}: ${Index type}; const Value: ${Data type});
begin
  F${Plural Name}.Insert(${Index Name}, Value);
end;

function ${Class}.Add(const Value: ${Data type}): Integer;
begin
  Result := ${Singular Name}Count;
  Insert(Result, Value);
end;

function ${Class}.Delete${Singular Name}(const ${Index Name}: ${Index type});
begin
  F{$Name}.Delete(${Index name});
end;

function ${Class}.IndexOf${Plural Name}(const Value: ${Data type}): ${Index type};
begin
  for Result := 0 to ${Singular Name}Count - 1 do
  begin
    if ${Singular Name}[Result] = Value then
      Exit;
  end;
  Result := -1;
end;

function ${Class}.Remove${Singular Name}(const Value: ${Data type});
var
  ${Index name}: ${Index type};
begin
  ${Index name} := IndexOF${Plural Name}(Value);
  if ${Index name} >= 0 then
    Delete${Singular Name}(${Index name});
end;

