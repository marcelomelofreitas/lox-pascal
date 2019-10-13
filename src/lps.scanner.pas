// Marcello Mello
// 28/09/2019

unit lps.scanner;

interface

uses
  SysUtils,
  Math,
  StrUtils,
  Generics.Collections,
  lps.types;

{$SCOPEDENUMS ON}

type

  TOnScannerErrorEvent = procedure (LineNro: Integer; Msg: string) of object;

  TScanner = class
  private
    FSource: string;
    FTokens: TObjectList<TToken>;
    FStart: Integer;
    FCurrent: Integer;
    FLineNro: Integer;
    FOnError: TOnScannerErrorEvent;
    function IsAtEnd: Boolean;
    function Advance: Char;
    procedure ScanToken;
    procedure AddToken(TokenType: TTokenType); overload;
    procedure AddToken(TokenType: TTokenType; Literal: TSSLangValue); overload;
    procedure Error(Line: Integer; Msg: string);
    function Match(Expected: Char): Boolean;
    function Peek: Char;
    procedure ScanString;
    procedure ScanNumber;
    function IsDigit(c: Char): Boolean;
    function PeekNext: Char;
    function IsAlpha(c: Char): Boolean;
    function IsAlphaNumeric(c: Char): Boolean;
    procedure ScanIdentifier;
  public
    constructor Create(Source: string);
    function ScanTokens: TObjectList<TToken>;
    destructor Destroy; override;
    property OnError: TOnScannerErrorEvent read FOnError write FOnError;
  end;

implementation

uses
  lps.utils;

{ TScanner }

constructor TScanner.Create(Source: string);
begin
  FTokens := TObjectList<TToken>.Create();
  FSource := Source;
  FStart := 1;
  Fcurrent := 1;
  FLineNro := 1;
end;

destructor TScanner.Destroy;
begin
  FTokens.Free();
  inherited;
end;

function TScanner.IsAtEnd(): Boolean;
begin
  Result := FCurrent > FSource.Length;
end;

function TScanner.Advance(): Char;
begin
  Inc(FCurrent);
  Result := FSource[FCurrent-1];
end;

procedure TScanner.AddToken(TokenType: TTokenType);
var
  NullValue: TSSLangValue;
begin
  NullValue := Default(TSSLangValue);
  NullValue.ValueType := TSSLangValueType.IS_NULL;
  AddToken(TokenType, NullValue);
end;

procedure TScanner.AddToken(TokenType: TTokenType; Literal: TSSLangValue);
var
  Text: string;
begin
  Text := Copy(FSource, FStart, FCurrent - FStart);
  FTokens.Add(TToken.Create(TokenType, Text, Literal, FLineNro));
end;

procedure TScanner.ScanToken();
var
  c: Char;
begin
  c := Advance();

  case (c) of
    '(': AddToken(TTokenType.LEFT_PAREN);
    ')': AddToken(TTokenType.RIGHT_PAREN);
    '{': AddToken(TTokenType.LEFT_BRACE);
    '}': AddToken(TTokenType.RIGHT_BRACE);
    ',': AddToken(TTokenType.COMMA);
    '.': AddToken(TTokenType.DOT);
    '-': AddToken(TTokenType.MINUS);
    '+': AddToken(TTokenType.PLUS);
    ';': AddToken(TTokenType.SEMICOLON);
    '*': AddToken(TTokenType.STAR);
    '!': AddToken(IfThen(Match('='), TTokenType.BANG_EQUAL, TTokenType.BANG));
    '=': AddToken(IfThen(Match('='), TTokenType.EQUAL_EQUAL, TTokenType.EQUAL));
    '<': AddToken(IfThen(Match('='), TTokenType.LESS_EQUAL, TTokenType.LESS));
    '>': AddToken(IfThen(Match('='), TTokenType.GREATER_EQUAL, TTokenType.GREATER));
    '/':
    begin
      if (match('/')) then
      begin
        // Um comentário vai até o final da linha.
        while (Peek() <> #10) and not isAtEnd() do
          Advance();
      end
      else
        AddToken(TTokenType.SLASH);
    end;
    ' ', #13, #9: ; // Ignorar espaço em branco, retorno do carro e tabulação.
    #10: Inc(FLineNro); // Nova linha.
    '"': ScanString();
    '0'..'9': ScanNumber();
    'a'..'z', 'A'..'Z', '_': ScanIdentifier();
  else
    Error(FLineNro, 'Caráter inesperado.');
  end;

end;

procedure TScanner.ScanIdentifier();
var
  Text: string;
  TokenType: TTokenType;
begin

  while (IsAlphaNumeric(Peek())) do
    Advance();

  // See if the identifier is a reserved word.
  Text := Copy(FSource, FStart, FCurrent - FStart);

  if not Keywords.TryGetValue(Text, TokenType) then
    TokenType := TTokenType.IDENTIFIER;

  AddToken(TokenType);
end;

function TScanner.IsAlphaNumeric(c: Char): Boolean;
begin
  Result := isAlpha(c) or isDigit(c);
end;

function TScanner.IsAlpha(c: Char): Boolean;
begin
  Result := ((c >= 'a') and (c <= 'z')) or
            ((c >= 'A') and (c <= 'Z')) or
            (c = '_');
end;

function TScanner.IsDigit(c: Char): Boolean;
begin
  Result := (c >= '0') and (c <= '9');
end;

procedure TScanner.ScanNumber;
var
  Value: TSSLangValue;
  OldDecimalSeparator: Char;
begin
  while IsDigit(Peek()) do
    Advance();

  // Procure uma parte fracionária.
  if (Peek() = '.') and isDigit(PeekNext()) then
  begin
    // Consuma o "."
    Advance();

    while IsDigit(Peek()) do
      Advance();
  end;

  OldDecimalSeparator := FormatSettings.DecimalSeparator;
  try
    FormatSettings.DecimalSeparator := '.';
    Value := Default(TSSLangValue);
    Value.ValueType := TSSLangValueType.IS_DOUBLE;
    Value.DoubleValue := StrToFloat(Copy(FSource, FStart, FCurrent - FStart));
    AddToken(TTokenType.NUMBER, Value);
  finally
    FormatSettings.DecimalSeparator := OldDecimalSeparator;
  end;
end;

procedure TScanner.ScanString();
var
  Value: TSSLangValue;
begin

  while (Peek() <> '"') and not IsAtEnd() do
  begin
    if (Peek() = #10) then
      Inc(FLineNro);

    Advance();
  end;

  // String não terminada.
  if (isAtEnd()) then
  begin
    Error(FLineNro, 'String não terminada.');
    Exit();
  end;

  // O fechamento da string ".
  Advance();

  // Apare as aspas circundantes.
  Value := Default(TSSLangValue);
  Value.ValueType := TSSLangValueType.IS_STRING;
  Value.StrValue := ShortString(Copy(FSource, FStart + 1, FCurrent - FStart - 2));
  AddToken(TTokenType.&STRING, Value);
end;

function TScanner.Peek(): Char;
begin
  if (isAtEnd()) then
    Exit(#0);

  Result := FSource[FCurrent];
end;

function TScanner.PeekNext(): Char;
begin
  if (FCurrent + 1) > FSource.Length then
    Exit(#0);

  Result := FSource[FCurrent + 1];
end;

function TScanner.Match(Expected: Char): Boolean;
begin
  if IsAtEnd() then
    Exit(False);

  if (FSource[FCurrent] <> Expected) then
    Exit(False);

  Inc(FCurrent);

  Result := True;
end;

procedure TScanner.Error(Line: Integer; Msg: string);
begin
  if Assigned(FOnError) then
    FOnError(Line, Msg);
end;

function TScanner.ScanTokens: TObjectList<TToken>;
var
  NullValue: TSSLangValue;
begin

  while not IsAtEnd() do
  begin
    // Estamos no início do próximo léxico.
    FStart := FCurrent;
    ScanToken();
  end;

  NullValue.ValueType := TSSLangValueType.IS_NULL;
  FTokens.Add(TToken.Create(TTokenType.EOF, '', NullValue, FLineNro));
  Result := FTokens;

end;

end.
