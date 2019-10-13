// Marcello Mello
// 28/09/2019

unit lps.types;

interface

uses
  SysUtils,
  Classes,
  Generics.Collections;

{$SCOPEDENUMS ON}

type

  TTokenType = (
    // Tokens de caractere único
    LEFT_PAREN, RIGHT_PAREN, LEFT_BRACE, RIGHT_BRACE,
    COMMA, DOT, MINUS, PLUS, SEMICOLON, SLASH, STAR,

    // Um ou dois tokens de caracteres
    BANG, BANG_EQUAL,
    EQUAL, EQUAL_EQUAL,
    GREATER, GREATER_EQUAL,
    LESS, LESS_EQUAL,

    // Literais
    IDENTIFIER, &STRING, NUMBER, &INTEGER,

    // Palavras-chave
    &AND, &BREAK, &CLASS, &CONTINUE, &DO, &ELSE, &FALSE, &FUN, &FOR, &IF, &NIL, &OR,
    &PRINT, &RETURN, SUPER, THIS, &TRUE, &VAR, &WHILE,

    EOF
  );

  TFunctionType = (NONE, &FUNCTION, INITIALIZER, METHOD);
  TClassType = (NONE, &CLASS, SUBCLASS);

  TSSLangValueType = (
    IS_UNDEF     = 0,
    IS_NULL      = 1,
    IS_FALSE     = 2,
    IS_TRUE      = 3,
    IS_INT32     = 4,
    IS_INT64     = 5,
    IS_DOUBLE    = 6,
    IS_STRING    = 7,
    IS_BOOLEAN   = 8,
    IS_CHAR      = 9,
    IS_CALLABLE	 = 10,
    IS_CLASS		 = 11,
    IS_OBJECT		 = 12,
    IS_METHOD    = 13
  );

  TSSLangCallableValue = Pointer;
  TSSLangObjectValue = Pointer;
  TSSLangClassValue = Pointer;
  TSSLangMethodValue = Pointer;

  TSSLangValue = record
    ValueType: TSSLangValueType;
    case Byte of
      0: (Int32Value: Integer);
      1: (Int64Value: Int64);
      2: (DoubleValue: Double);
      3: (StrValue: ShortString);
      4: (BooleanValue: Boolean);
      5: (CharValue: Char);
      6: (CallableValue: TSSLangCallableValue);
      7: (ClassValue: TSSLangClassValue);
      8: (ObjectInstanceValue: TSSLangObjectValue);
      9: (MethodValue: TSSLangMethodValue);
  end;

//  TSSLangCallableValue = class
//  private
//    FArity: Integer;
//  public
//    function Call(Interpreter: Pointer; Arguments: TList<TSSLangValue>): TSSLangValue;
//    property Arity: Integer read FArity;
//  end;
//
//
  TToken = class
  private
    FTokenType: TTokenType;
    FLexeme: string;
    FLiteral: TSSLangValue;
    FLineNro: Integer;
  public
    constructor Create(TokenType: TTokenType; Lexeme: string; Literal: TSSLangValue; LineNro: Integer);
    function ToString(): string; override;
    property TokenType: TTokenType read FTokenType;
    property Lexeme: string read FLexeme;
    property Literal: TSSLangValue read FLiteral;
    property LineNro: Integer read FLineNro;
  end;

  ERuntimeError = class(Exception)
  private
    FToken: TToken;
  public
    constructor Create(Token: TToken; Msg: string);
    property Token: TToken read FToken;
  end;

var
  Keywords: TDictionary<string, TTokenType>;

implementation

uses
  lps.utils;

{ TToken }

constructor TToken.Create(TokenType: TTokenType; Lexeme: string; Literal: TSSLangValue; LineNro: Integer);
begin
  FTokenType := TokenType;
  FLexeme := Lexeme;
  FLiteral := Literal;
  FLineNro := LineNro;
end;

function TToken.ToString: string;
var
  StrValue: string;
begin

  if FLiteral.ValueType = TSSLangValueType.IS_STRING then
    StrValue := String(FLiteral.StrValue)
  else
    StrValue := '';

  Result := Format('%s %s %s',
                   [TEnumConversor<TTokenType>.ToString(FTokenType),
                   FLexeme,
                   StrValue]);
  Result := 'vendao';
end;

{ ERuntimeError }

constructor ERuntimeError.Create(Token: TToken; Msg: string);
begin
  inherited Create(Msg);
  FToken := Token;
end;

initialization
  Keywords := TDictionary<string, TTokenType>.Create();
  keywords.Add('and',    TTokenType.AND);
  keywords.Add('break',  TTokenType.BREAK);
  keywords.Add('class',  TTokenType.CLASS);
  keywords.Add('continue',  TTokenType.continue);
  keywords.Add('do',  TTokenType.DO);
  keywords.Add('else',   TTokenType.ELSE);
  keywords.Add('false',  TTokenType.FALSE);
  keywords.Add('for',    TTokenType.FOR);
  keywords.Add('fun',    TTokenType.FUN);
  keywords.Add('if',     TTokenType.IF);
  keywords.Add('nil',    TTokenType.NIL);
  keywords.Add('or',     TTokenType.OR);
  keywords.Add('print',  TTokenType.PRINT);
  keywords.Add('return', TTokenType.RETURN);
  keywords.Add('super',  TTokenType.SUPER);
  keywords.Add('this',   TTokenType.THIS);
  keywords.Add('true',   TTokenType.TRUE);
  keywords.Add('var',    TTokenType.VAR);
  keywords.Add('while',  TTokenType.WHILE);

finalization
  Keywords.Free();


end.
