#keyfile:keys.txt
#key:delphi.class
#parameter:Class:string

#key:delphi.method.name
#parameter:Name:string

#key:delphi.method.args
#parameter:Arguments

#key:delphi.method.resultType
#parameter:Result type

#code:Function
    function ${Name}(${Arguments}): ${Result type};

function ${Class}.${Name}(${Arguments}): ${Result type};
begin
  Result := ?;
end;

#code:Procedure
    procedure ${Name}(${Arguments});

procedure ${Class}.${Name}(${Arguments});
begin
end;
