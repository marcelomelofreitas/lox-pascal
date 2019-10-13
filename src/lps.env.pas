// Marcello Mello
// 02/10/2019

unit lps.env;

interface

uses
  SysUtils,
  Classes,
  Generics.Collections,
  lps.types;

type

  TEnvironment = class
  private
    FValues: TDictionary<string, TSSLangValue>;
    FEnclosing: TEnvironment;
  public
    constructor Create(Enclosing: TEnvironment = nil);
    destructor Destroy; override;
    procedure Define(const Name: string; Value: TSSLangValue);
    function Ancestor(Distance: Integer): TEnvironment;
    function GetAt(Distance: Integer; Name: string): TSSLangValue;
    procedure AssignAt(Distance: Integer; Name: TToken; Value: TSSLangValue);
    function Get(Name: TToken): TSSLangValue;
    procedure Assign(Name: TToken; Value: TSSLangValue);
    property Enclosing: TEnvironment read FEnclosing;
  end;

implementation

{ TEnvironment }

destructor TEnvironment.Destroy;
begin
  FValues.Free();
  inherited;
end;

constructor TEnvironment.Create(Enclosing: TEnvironment = nil);
begin
  FEnclosing := Enclosing;
  FValues := TDictionary<string, TSSLangValue>.Create();
end;

procedure TEnvironment.Define(const Name: string; Value: TSSLangValue);
begin
  FValues.AddOrSetValue(Name, Value);
end;

function TEnvironment.Ancestor(Distance: Integer): TEnvironment;
var
  Environment: TEnvironment;
  i: Integer;
begin
  Environment := Self;

  for i := 0 to Distance - 1 do
    Environment := Environment.FEnclosing;

  Result := Environment;
end;

function TEnvironment.GetAt(Distance: Integer; Name: string): TSSLangValue;
begin
  Result := Ancestor(distance).FValues[Name];
end;

procedure TEnvironment.AssignAt(Distance: Integer; Name: TToken; Value: TSSLangValue);
begin
  Ancestor(distance).FValues[Name.lexeme] := Value;
end;

function TEnvironment.Get(Name: TToken): TSSLangValue;
begin

  if FValues.ContainsKey(Name.Lexeme) then
    Result := FValues[Name.Lexeme]
  else if not (FEnclosing = nil) then
    Result := FEnclosing.Get(Name)
  else
    raise ERuntimeError.Create(Name, 'Variável indefinida "' + Name.Lexeme + '".');

end;

procedure TEnvironment.Assign(Name: TToken; Value: TSSLangValue);
begin

  if (FValues.ContainsKey(Name.Lexeme)) then
    FValues.AddOrSetValue(Name.lexeme, Value)
  else if Assigned(FEnclosing) then
    FEnclosing.Assign(Name, Value)
  else
    raise ERuntimeError.Create(Name, 'Variável indefinida "' + name.lexeme + '".');

end;

end.
