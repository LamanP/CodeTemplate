#keyfile:keys.txt
#key:delphi.class
#parameter:Class:string
#key:delphi.var.name
#parameter:Name:string
#code:try/finally
try
  ${Name} := ${Class}.Create;
finally
  ${Name}.Free;
end;
