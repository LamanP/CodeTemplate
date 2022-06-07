#keyfile:keys.tpk
#key:delphi.class
#parameter:Class:string
#key:delphi.class.parent
#parameter:Parent class:string:TInterfacedObject
#key:delphi.method.args
#parameter:Constructor args:string
#code:Class
type
  ${Class} = class(${Parent class})
  private
  protected
  public
  end;

#code:Con/destructor (Decl)
    constructor Create(${Constructor args}); reintroduce;
    destructor Destroy; override;
#code:Con/destructor (Impl)
constructor ${Class}.Create(${Constructor args});
begin
end;

destructor ${Class}.Destroy;
begin
  inherited;
end;
