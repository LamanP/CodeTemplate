#persist:Delphi
#parameter:Class:string
#parameter:Name:string
#parameter:Data type:string
#code:Field var/Getter/Setter (Decl)
    F${Name}: ${Data type};
    function Get${Name}: ${Data type};
    procedure Set${Name}(const Value: ${Data type});
#code:property decl (Field var only)
    property ${Name}: ${Data type} read F${Name} write F${Name};
#code:property decl (Field var/setter)
    property ${Name}: ${Data type} read F${Name} write Set${Name};
#code:property decl (Field getter/setter)
    property ${Name}: ${Data type} read Get${Name} write Set${Name};
#code:Getter/Setter (Impl)
function ${Class}.Get${Name}: ${Data type};
begin
  Result := F${Name};
end;

procedure ${Class}.Set${Name}(const Value: ${Data type});
begin
  if Value <> F${Name} then
  begin
    F${Name} := Value;
  end;
end;