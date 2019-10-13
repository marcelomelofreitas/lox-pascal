// Marcello Mello
// 28/09/2019

unit lps.parser;

interface

uses
  SysUtils,
  Generics.Collections,
  lps.types,
  lps.ast;

type

  TOnParserErrorEvent = procedure(Token: TToken; Msg: string) of object;

  EParseError = class(Exception)
  end;

  TParser = class
  private
    FLoopDepth: Integer;
    FOnError: TOnParserErrorEvent;
    FTokens: TObjectList<TToken>;
    FCurrent: Integer;
    function Expression: TExpression;
    function Assignment: TExpression;
    function LogicalOr(): TExpression;
    function LogicalAnd(): TExpression;
    function Unary: TExpression;
    function Call(): TExpression;
    function FinishCall(Callee: TExpression): TExpression;
    function Addition: TExpression;
    function Multiplication: TExpression;
    function Equality: TExpression;
    function Primary(): TExpression;
    function Match(TokenType: TTokenType): Boolean; overload;
    function Match(TokenTypeA, TokenTypeB: TTokenType): Boolean; overload;
    function Match(TokenTypes: array of TTokenType): Boolean; overload;
    function Check(TokenType: TTokenType): Boolean;
    function Consume(TokenType: TTokenType; Msg: string): TToken;
    function Error(Token: TToken; Msg: string): EParseError;
    function Comparison(): TExpression;
    function Advance: TToken;
    function Previous: TToken;
    function IsAtEnd(): Boolean;
    function Peek(): TToken;
    procedure Synchronize();
    function Statement(): TStatement;
    function BreakStatement(): TStatement;
    function DoStatement(): TStatement;
    function ContinueStatement(): TStatement;
    function ReturnStatement(): TStatement;
    function ForStatement(): TStatement;
    function WhileStatement(): TStatement;
    function ifStatement: TStatement;
    function Declaration(): TStatement;
    function ClassDeclaration(): TStatement;
    function FunctionDeclaration(Kind: string): TFunctionStatement;
    function VarDeclaration(): TStatement;
    function ExpressionStatement(): TStatement;
    function Block: TObjectList<TStatement>;
    function PrintStatement(): TStatement;
  public
    constructor Create(Tokens: TObjectList<TToken>);
    function Parse: TObjectList<TStatement>;
    property OnError: TOnParserErrorEvent read FOnError write FOnError;
  end;

implementation

{ TParser }

constructor TParser.Create(Tokens: TObjectList<TToken>);
begin
  FLoopDepth := 0;
  FCurrent := 0;
  FTokens := Tokens;
end;

function TParser.Expression(): TExpression;
begin
  Result := Assignment();
end;

function TParser.Assignment: TExpression;
var
  Expr: TExpression;
  Get: TGetExpression;
  Equals: TToken;
  Value: TExpression;
  Name: TToken;
begin
  Expr := LogicalOr();

  if Match(TTokenType.EQUAL) then
  begin
    Equals := Previous();
    Value := Assignment();

    if Expr is TVariableExpression then
    begin
      Name := TVariableExpression(Expr).Name;
      Exit(TAssignExpression.Create(name, value));
    end
    else if (Expr is TGetExpression) then
    begin
      Get := TGetExpression(Expr);
      Exit(TSetExpression.Create(Get.Obj, Get.Name, Value));
    end;

    Error(Equals, 'Destino de atribuição inválido.');
  end;

  Result := Expr;
end;

function TParser.LogicalOr(): TExpression;
var
  Expr,
  Right: TExpression;
  Oper: TToken;
begin
  Expr := LogicalAnd();

  while Match(TTokenType.OR) do
  begin
    Oper := Previous();
    Right := LogicalAnd();
    Expr := TLogicalExpression.Create(Expr, Oper, Right);
  end;

  Result := Expr;
end;

function TParser.LogicalAnd(): TExpression;
var
  Expr,
  Right: TExpression;
  Oper: TToken;
begin
  Expr := Equality();

  while Match(TTokenType.AND) do
  begin
    Oper := Previous();
    Right := equality();
    Expr := TLogicalExpression.Create(Expr, Oper, Right);
  end;

  Result := Expr;
end;

function TParser.Unary: TExpression;
var
  Right: TExpression;
  Oper: TToken;
begin

  if Match([TTokenType.BANG, TTokenType.MINUS]) then
  begin
    Oper := Previous();
    Right := Unary();
    Exit(TUnaryExpression.Create(Oper, Right));
  end;

  Result := Call();
end;

function TParser.Call(): TExpression;
var
  Expr: TExpression;
  Name: TToken;
begin
  Expr := Primary();

  while True do
  begin
    if Match(TTokenType.LEFT_PAREN) then
      Expr := FinishCall(Expr)
    else if Match(TTokenType.DOT) then
    begin
      Name := Consume(TTokenType.IDENTIFIER, 'Espere o nome da propriedade depois "."');
      Expr := TGetExpression.Create(Expr, Name);
    end
    else
      Break;
  end;

  Result := Expr;
end;

function TParser.FinishCall(Callee: TExpression): TExpression;
var
  Arguments: TObjectList<TExpression>;
  Paren: TToken;
begin
  Arguments := TObjectList<TExpression>.Create();

  if not Check(TTokenType.RIGHT_PAREN) then
  begin
    repeat
      if (Arguments.Count >= 255) then
        Error(Peek(), 'Não pode ter mais de 255 argumentos.');

      Arguments.Add(Expression());
    until not Match(TTokenType.COMMA);
  end;

  Paren := Consume(TTokenType.RIGHT_PAREN, 'Esperado ")" após argumentos.');

  Result := TCallExpression.Create(Callee, Paren, Arguments);
end;

function TParser.primary(): TExpression;
var
  Expr: TExpression;
  Value: TSSLangValue;
  Keyword,
  Method: TToken;
begin

  if (Match(TTokenType.FALSE)) then
  begin
    Value.ValueType := TSSLangValueType.IS_BOOLEAN;
    Value.BooleanValue := False;
    Result := TLiteralExpression.Create(Value);
    Exit();
  end;

  if (Match(TTokenType.TRUE)) then
  begin
    Value.ValueType := TSSLangValueType.IS_BOOLEAN;
    Value.BooleanValue := True;
    Result := TLiteralExpression.Create(Value);
    Exit();
  end;

  if Match(TTokenType.NIL) then
  begin
    Value.ValueType := TSSLangValueType.IS_NULL;
    Result := TLiteralExpression.Create(Value);
    Exit();
  end;

  if Match(TTokenType.NUMBER, TTokenType.STRING) then
  begin
    Result := TLiteralExpression.Create(Previous().Literal);
    Exit();
  end;

  if Match(TTokenType.SUPER) then
  begin
    Keyword := Previous();
    Consume(TTokenType.DOT, 'Esperado "." depois de "super".');
    Method := Consume(TTokenType.IDENTIFIER, 'Espere o nome do método da superclasse.');
    Result := TSuperExpression.Create(Keyword, Method);
    Exit();
  end;

  if Match(TTokenType.THIS) then
  begin
    Result := TThisExpression.Create(Previous());
    Exit();
  end;

  if Match(TTokenType.IDENTIFIER) then
  begin
    Result := TVariableExpression.Create(Previous());
    Exit();
  end;

  if (Match(TTokenType.LEFT_PAREN)) then
  begin
    Expr := Expression();
    Consume(TTokenType.RIGHT_PAREN, 'Esperado um ")" após a expressão.');
    Exit(TGroupingExpression.Create(Expr));
  end;

  raise Error(Peek(), 'Esperado expressão.');
end;

function TParser.Consume(TokenType: TTokenType; Msg: string): TToken;
begin
  if (Check(TokenType)) then
    Exit(Advance());

  raise Error(Peek(), Msg);
end;

function TParser.ContinueStatement: TStatement;
begin
  if (FLoopDepth = 0) then
    Error(Previous(), 'Cannot use "continue" outside of a loop.');

  Consume(TTokenType.SEMICOLON, 'Expect ";" after continue.');

  Result := TContinueStatement.Create();
end;

function TParser.Error(Token: TToken; Msg: string): EParseError;
begin
  if Assigned(OnError) then
    OnError(Token, Msg);

  Result := EParseError.Create(Msg);
end;

function TParser.Addition: TExpression;
var
  Expr,
  Right: TExpression;
  Oper: TToken;
begin
  Expr := Multiplication();

  while (Match([TTokenType.MINUS, TTokenType.PLUS])) do
  begin
    Oper := Previous();
    Right := multiplication();
    Expr := TBinaryExpression.Create(Expr, Oper, Right);
  end;

  Result := Expr;
end;

function TParser.multiplication: TExpression;
var
  Expr,
  Right: TExpression;
  Oper: TToken;
begin
    expr := Unary();

    while (Match(TTokenType.SLASH, TTokenType.STAR)) do
    begin
      Oper := previous();
      right := Unary();
      expr := TBinaryExpression.Create(expr, Oper, right);
    end;

    Result := Expr;
end;

function TParser.Comparison(): TExpression;
var
  Expr,
  Right: TExpression;
  Oper: TToken;
begin
  Expr := Addition();

  while (Match([TTokenType.GREATER, TTokenType.GREATER_EQUAL, TTokenType.LESS, TTokenType.LESS_EQUAL])) do
  begin
    Oper := Previous();
    Right := Addition();
    Expr := TBinaryExpression.Create(Expr, Oper, Right);
  end;

  Result := Expr;
end;

function TParser.IsAtEnd(): Boolean;
begin
  Result := Peek().TokenType = TTokenType.EOF;
end;

function TParser.peek(): TToken;
begin
  Result := FTokens[FCurrent];
end;

function TParser.previous(): TToken;
begin
  Result := FTokens[FCurrent - 1];
end;

function TParser.Equality(): TExpression;
var
  Expr,
  Right: TExpression;
  Oper: TToken;
begin
  Expr := Comparison();

  while (Match(TTokenType.BANG_EQUAL, TTokenType.EQUAL_EQUAL)) do
  begin
    Oper := Previous();
    Right := Comparison();
    Expr := TBinaryExpression.Create(expr, Oper, right);
  end;

  Result := Expr;
end;

function TParser.Check(TokenType: TTokenType): Boolean;
begin
  if (IsAtEnd()) then
    Exit(False);

  Result := Peek().TokenType = TokenType;
end;

function TParser.Match(TokenTypes: array of TTokenType): Boolean;
var
  TokenType: TTokenType;
begin

  for TokenType in TokenTypes do
  begin
    if (Check(TokenType)) then
    begin
      Advance();
      Exit(True);
    end;
  end;

  Result := False;
end;

function TParser.Match(TokenType: TTokenType): Boolean;
begin
  Result := Match([TokenType]);
end;

function TParser.Match(TokenTypeA, TokenTypeB: TTokenType): Boolean;
begin
  Result := Match([TokenTypeA, TokenTypeB]);
end;

function TParser.Advance: TToken;
begin
  if not isAtEnd() then
    Inc(FCurrent);

  Result := previous();
end;

procedure TParser.Synchronize();
begin
  Advance();

  while not isAtEnd() do
  begin
    if (Previous().TokenType = TTokenType.SEMICOLON) then
      Exit();

    case peek().TokenType of
      TTokenType.CLASS,
      TTokenType.FUN,
      TTokenType.VAR,
      TTokenType.FOR,
      TTokenType.IF,
      TTokenType.WHILE,
      TTokenType.PRINT,
      TTokenType.RETURN: Exit();
    end;

    Advance();
  end;

end;

function TParser.Parse: TObjectList<TStatement>;
var
  Statements: TObjectList<TStatement>;
begin
  Statements := TObjectList<TStatement>.Create();

  while not IsAtEnd() do
    Statements.Add(Declaration());

  Result := Statements;
end;

function TParser.Statement: TStatement;
begin
  if Match(TTokenType.FOR) then
    Result := ForStatement()
  else if Match(TTokenType.BREAK) then
    Result := BreakStatement()
  else if Match(TTokenType.CONTINUE) then
    Result := ContinueStatement()
  else if Match(TTokenType.DO) then
    Result := DoStatement()
  else if Match(TTokenType.IF) then
    Result := ifStatement()
  else if Match(TTokenType.PRINT) then
    Result := PrintStatement()
  else if Match(TTokenType.RETURN) then
    Result := ReturnStatement()
  else if Match(TTokenType.WHILE) then
    Result := WhileStatement()
  else if Match(TTokenType.LEFT_BRACE) then
    Result := TBlockStatement.Create(Block())
  else
    Result := ExpressionStatement();
end;

function TParser.BreakStatement(): TStatement;
begin
  if (FLoopDepth = 0) then
    Error(Previous(), 'Cannot use "continue" outside of a loop.');

  Consume(TTokenType.SEMICOLON, 'Expect ";" after break.');

  Result := TBreakStatement.Create();
end;

function TParser.ReturnStatement(): TStatement;
var
  Keyword: TToken;
  Value: TExpression;
begin
  Keyword := Previous();
  Value := nil;

  if not Check(TTokenType.SEMICOLON) then
    Value := Expression();

  Consume(TTokenType.SEMICOLON, 'Esperado ";" após o valor de retorno.');
  Result := TReturnStatement.Create(Keyword, Value);
end;

function TParser.ForStatement(): TStatement;
var
  Initializer: TStatement;
  Condition: TExpression;
  Increment: TExpression;
  Body: TStatement;
  Statements: TObjectList<TStatement>;
  Value: TSSLangValue;
begin

  Inc(FLoopDepth);
  try
    Consume(TTokenType.LEFT_PAREN, 'Esperado "(" depois de "for".');

    if Match(TTokenType.SEMICOLON) then
      Initializer := nil
    else if Match(TTokenType.VAR) then
      Initializer := VarDeclaration()
    else
      Initializer := ExpressionStatement();

    if not Check(TTokenType.SEMICOLON) then
      Condition := Expression()
    else
      Condition := nil;

    Consume(TTokenType.SEMICOLON, 'Esperado ";" após condição do loop.');

    Increment := nil;

    if not check(TTokenType.RIGHT_PAREN) then
      Increment := Expression();

    Consume(TTokenType.RIGHT_PAREN, 'Esperado ")" depois da cláusula "for".');

    Body := Statement();

    if Assigned(Increment) then
    begin
      Statements := TObjectList<TStatement>.Create();
      Statements.Add(body);
      Statements.Add(TExpressionStatement.Create(Increment));
      Body := TBlockStatement.Create(Statements);
    end;

    if (Condition = nil) then
    begin
      Value.ValueType := TSSLangValueType.IS_BOOLEAN;
      Value.BooleanValue := True;
      Condition := TLiteralExpression.Create(Value);
    end;

    Body := TWhileStatement.Create(Condition, Body);

    if not (Initializer = nil) then
    begin
      Statements := TObjectList<TStatement>.Create();
      Statements.Add(Initializer);
      Statements.Add(Body);
      Body := TBlockStatement.Create(Statements);
    end;

    Result := Body;
  finally
    Dec(FLoopDepth);
  end;

end;

function TParser.WhileStatement(): TStatement;
var
  Condition: TExpression;
  Body: TStatement;
begin
  Inc(FLoopDepth);
  try

    Consume(TTokenType.LEFT_PAREN, 'Esperado "(" depois de "while".');
    Condition := Expression();

    Consume(TTokenType.RIGHT_PAREN, 'Esperado ")" após a condição.');
    Body := Statement();

    Result := TWhileStatement.Create(Condition, Body);
  finally
    Dec(FLoopDepth);
  end;
end;

function TParser.ifStatement: TStatement;
var
  Condition: TExpression;
  ThenBranch,
  ElseBranch: TStatement;
begin
  Consume(TTokenType.LEFT_PAREN, 'Esperado "(" depois do "if".');
  Condition := Expression();

  Consume(TTokenType.RIGHT_PAREN, 'Esperado ")" após a condição "if".');

  ThenBranch := Statement();

  if Match(TTokenType.ELSE) then
    ElseBranch := statement()
  else
    ElseBranch := nil;

  Result :=  TIfStatement.Create(Condition, ThenBranch, ElseBranch);
end;

function TParser.Declaration(): TStatement;
begin
  Result := nil;

  try
    if Match(TTokenType.CLASS) then
      Result := ClassDeclaration()
    else if Match(TTokenType.FUN) then
      Result := FunctionDeclaration('function')
    else if Match(TTokenType.VAR) then
      Result := VarDeclaration()
    else
      Result := Statement();
  except on Error: EParseError do
    Synchronize();
  end;

end;

function TParser.DoStatement: TStatement;
var
  Body: TObjectList<TStatement>;
  Condition: TExpression;
  Value: TSSLangValue;
begin

  Inc(FLoopDepth);
  try
    // Body must be a block
    Consume(TTokenType.LEFT_BRACE, 'Expect "{" after do.');
    Body := Block();

    // While
    Consume(TTokenType.WHILE, 'Expect "while" after do loop body.');

    // Condition
    Consume(TTokenType.LEFT_PAREN, 'Expect "(" after "while."');
    Condition := Expression();
    Consume(TTokenType.RIGHT_PAREN, 'Expect ")" after while condition.');
    Consume(TTokenType.SEMICOLON, 'Expect ";" after while condition.');

    Body.Add(TIfStatement.Create(Condition, TBlockStatement.Create(TObjectList<TStatement>.Create()), TBreakStatement.Create()));


    Value := Default(TSSLangValue);
    Value.ValueType := TSSLangValueType.IS_BOOLEAN;
    Value.BooleanValue := True;

    Result := TWhileStatement.Create(TLiteralExpression.Create(Value), TBlockStatement.Create(Body));
  finally
    Dec(FLoopDepth);
  end;

end;

function TParser.ClassDeclaration(): TStatement;
var
  Name: TToken;
  Methods: TObjectList<TFunctionStatement>;
  Superclass: TVariableExpression;
begin
  Name := Consume(TTokenType.IDENTIFIER, 'Espere o nome da classe.');

  if Match(TTokenType.LESS) then
  begin
    Consume(TTokenType.IDENTIFIER, 'Esperado o nome da superclasse.');
    Superclass := TVariableExpression.Create(Previous());
  end
  else
    Superclass := nil;

  Consume(TTokenType.LEFT_BRACE, 'Esperado "{" antes do corpo da classe');

  Methods := TObjectList<TFunctionStatement>.Create();

  while not Check(TTokenType.RIGHT_BRACE) and not IsAtEnd() do
    Methods.Add(FunctionDeclaration('method'));

  Consume(TTokenType.RIGHT_BRACE, 'Esperado "}" após o corpo da classe.');

  Result := TClassStatement.Create(Name, Superclass, Methods);

end;

function TParser.FunctionDeclaration(Kind: string): TFunctionStatement;
var
  Name: TToken;
  Parameters: TObjectList<TToken>;
  Body: TObjectList<TStatement>;
begin
  Name := Consume(TTokenType.IDENTIFIER, 'Esperado o nome ' + kind + '.');

  Consume(TTokenType.LEFT_PAREN, 'Esperado "(" após o nome ' + kind + ' .');

  Parameters := TObjectList<TToken>.Create();

  if not Check(TTokenType.RIGHT_PAREN) then
  begin
    repeat
      if (Parameters.Count >= 255) then
        Error(Peek(), 'Não pode ter mais de 255 parâmetros.');

      Parameters.Add(Consume(TTokenType.IDENTIFIER, 'Espere o nome do parâmetro.'));
    until not Match(TTokenType.COMMA);
  end;

  Consume(TTokenType.RIGHT_PAREN, 'Esperado ")" depois dos parâmetros.');
  Consume(TTokenType.LEFT_BRACE, 'Esperado "{" antes ' + kind + ' body.');

  Body := Block();

  Result := TFunctionStatement.Create(Name, Parameters, Body);
end;

function TParser.VarDeclaration(): TStatement;
var
  Name: TToken;
  Initializer: TExpression;
begin
  Name := Consume(TTokenType.IDENTIFIER, 'Esperado o nome da variável.');

  if Match(TTokenType.EQUAL) then
    Initializer := Expression()
  else
    Initializer := nil;

  Consume(TTokenType.SEMICOLON, 'Esperado ";" após declaração de variável.');
  Result := TVarStatement.Create(Name, Initializer);
end;

function TParser.ExpressionStatement: TStatement;
var
  expr: TExpression;
begin
  Expr := Expression();
  Consume(TTokenType.SEMICOLON, 'Esperado ";" depois da expressão.');
  Result := TExpressionStatement.Create(expr);
end;

function TParser.Block: TObjectList<TStatement>;
var
  Statements: TObjectList<TStatement>;
begin
  Statements := TObjectList<TStatement>.Create();

  while not Check(TTokenType.RIGHT_BRACE) and not IsAtEnd() do
    Statements.add(Declaration());

  Consume(TTokenType.RIGHT_BRACE, 'Espere "}" após o bloco.');
  Result := Statements;
end;

function TParser.PrintStatement(): TStatement;
var
  Value: TExpression;
begin
  Value := Expression();

  Consume(TTokenType.SEMICOLON, 'Esperado ";" depois do valor.');

  Result := TPrintStatement.Create(Value);
end;

end.
