// Marcello Mello
// 02/10/2019

unit lps.resolver;

interface

uses
  SysUtils,
  Classes,
  VCL.Dialogs,
  Generics.Collections,
  lps.ast,
  lps.interpreter,
  lps.types;

type

  TOnResolverErrorEvent = procedure(Token: TToken; Msg: string) of object;

  EResolverError = class(Exception)
  end;

  TResolver = class(TInterfacedObject, IVisitor)
  private
    FCurrentClass: TClassType;
    FInterpreter: TInterpreter;
    FCurrentFunction: TFunctionType;
    FScopes: TObjectStack<TDictionary<string, Boolean>>;
    FOnError: TOnResolverErrorEvent;
    procedure BeginScope;
    procedure Resolve(Expr: TExpression); overload;
    procedure Resolve(Statement: TStatement); overload;
    procedure EndScope();
    procedure Declare(Name: TToken);
    procedure Define(Name: TToken);
    function Error(Token: TToken; Msg: string): EResolverError;
    procedure ResolveLocal(Expr: TExpression; Name: TToken);
    procedure ResolveFunction(FunctionStatement: TFunctionStatement; FunctionType: TFunctionType);
  private
    function Visit(AssignExpression: TAssignExpression): TSSLangValue; overload;
    function Visit(BinaryExpression: TBinaryExpression): TSSLangValue; overload;
    function Visit(CallExpression: TCallExpression): TSSLangValue; overload;
    function Visit(GetExpression: TGetExpression): TSSLangValue; overload;
    function Visit(GroupingExpression: TGroupingExpression): TSSLangValue; overload;
    function Visit(LiteralExpression: TLiteralExpression): TSSLangValue; overload;
    function Visit(LogicalExpression: TLogicalExpression): TSSLangValue; overload;
    function Visit(SetExpression: TSetExpression): TSSLangValue; overload;
    function Visit(SuperExpression: TSuperExpression): TSSLangValue; overload;
    function Visit(ThisExpression: TThisExpression): TSSLangValue; overload;
    function Visit(UnaryExpression: TUnaryExpression): TSSLangValue; overload;
    function Visit(VariableExpression: TVariableExpression): TSSLangValue; overload;
    function Visit(BlockStatement: TBlockStatement): TSSLangValue; overload;
    function Visit(BreakStatement: TBreakStatement): TSSLangValue; overload;
    function Visit(ContinueStatement: TContinueStatement): TSSLangValue; overload;
    function Visit(ExpressionStatement: TExpressionStatement): TSSLangValue; overload;
    function Visit(IfStatement: TIfStatement): TSSLangValue; overload;
    function Visit(FunctionStatement: TFunctionStatement): TSSLangValue; overload;
    function Visit(PrintStatement: TPrintStatement): TSSLangValue; overload;
    function Visit(ClassStatement: TClassStatement): TSSLangValue; overload;
    function Visit(ReturnStatement: TReturnStatement): TSSLangValue; overload;
    function Visit(VarStatement: TVarStatement): TSSLangValue; overload;
    function Visit(WhileStatement: TWhileStatement): TSSLangValue; overload;
  public
    constructor Create(Interpreter: TInterpreter);
    destructor Destroy; override;
    procedure Resolve(Statements: TObjectList<TStatement>); overload;
    property OnError: TOnResolverErrorEvent read FOnError write FOnError;
  end;

implementation

{ TResolver }

function TResolver.Visit(LiteralExpression: TLiteralExpression): TSSLangValue;
begin
  Result := Default(TSSLangValue);
  Result.ValueType := TSSLangValueType.IS_NULL;
end;

function TResolver.Visit(LogicalExpression: TLogicalExpression): TSSLangValue;
begin
  Resolve(LogicalExpression.Left);
  Resolve(LogicalExpression.Right);

  Result := Default(TSSLangValue);
  Result.ValueType := TSSLangValueType.IS_NULL;
end;

function TResolver.Visit(UnaryExpression: TUnaryExpression): TSSLangValue;
begin
  Resolve(UnaryExpression.Right);

  Result := Default(TSSLangValue);
  Result.ValueType := TSSLangValueType.IS_NULL;
end;

function TResolver.Error(Token: TToken; Msg: string): EResolverError;
begin
  if Assigned(OnError) then
    OnError(Token, Msg);

  Result := EResolverError.Create(Msg);
end;

function TResolver.Visit(VariableExpression: TVariableExpression): TSSLangValue;
begin
  if (not FScopes.Count = 0) and (FScopes.peek()[VariableExpression.Name.Lexeme] = False) then
    Error(VariableExpression.Name, 'Não é possível ler a variável local em seu próprio inicializador.');

  ResolveLocal(VariableExpression, VariableExpression.Name);

  Result := Default(TSSLangValue);
  Result.ValueType := TSSLangValueType.IS_NULL;
end;

procedure TResolver.ResolveLocal(Expr: TExpression; Name: TToken);
var
  i: Integer;
begin

  for i := FScopes.Count - 1 downto 0 do
  begin
    if FScopes.List[i].ContainsKey(Name.Lexeme) then
    begin
      FInterpreter.Resolve(Expr, FScopes.Count - 1 - i);
      Exit();
    end;
  end;

  // Não encontrado. Suponha que seja global.
end;

function TResolver.Visit(AssignExpression: TAssignExpression): TSSLangValue;
begin
  Resolve(AssignExpression.value);
  ResolveLocal(AssignExpression, AssignExpression.name);

  Result := Default(TSSLangValue);
  Result.ValueType := TSSLangValueType.IS_NULL;
end;

function TResolver.Visit(BinaryExpression: TBinaryExpression): TSSLangValue;
begin
  Resolve(BinaryExpression.Left);
  Resolve(BinaryExpression.Right);

  Result := Default(TSSLangValue);
  Result.ValueType := TSSLangValueType.IS_NULL;
end;

function TResolver.Visit(CallExpression: TCallExpression): TSSLangValue;
var
  Argument: TExpression;
begin
  Resolve(CallExpression.Callee);

  for Argument in CallExpression.Arguments do
    Resolve(Argument);

  Result := Default(TSSLangValue);
  Result.ValueType := TSSLangValueType.IS_NULL;
end;

function TResolver.Visit(GroupingExpression: TGroupingExpression): TSSLangValue;
begin
  Resolve(GroupingExpression.Expr);

  Result := Default(TSSLangValue);
  Result.ValueType := TSSLangValueType.IS_NULL;
end;

function TResolver.Visit(PrintStatement: TPrintStatement): TSSLangValue;
begin
  Resolve(PrintStatement.Expr);

  Result := Default(TSSLangValue);
  Result.ValueType := TSSLangValueType.IS_NULL;
end;

function TResolver.Visit(ReturnStatement: TReturnStatement): TSSLangValue;
begin
  if (FCurrentFunction = TFunctionType.NONE) then
    Error(ReturnStatement.Keyword, 'Não é possível retornar do código de nível superior.');


  if Assigned(ReturnStatement.Value) then
  begin
    if (FCurrentFunction = TFunctionType.INITIALIZER) then
      Error(ReturnStatement.Keyword, 'Não é possível retornar um valor de um inicializador.');

    Resolve(ReturnStatement.Value);
  end;

  Result := Default(TSSLangValue);
  Result.ValueType := TSSLangValueType.IS_NULL;
end;

procedure TResolver.Declare(Name: TToken);
var
  Scope: TDictionary<string, Boolean>;
begin
  if (FScopes.Count = 0) then
    Exit();

  Scope := FScopes.Peek();

  if Scope.ContainsKey(Name.lexeme) then
    Error(name, 'Variável com este nome já declarada neste escopo.');

  Scope.Add(Name.Lexeme, False);
end;

procedure TResolver.Define(Name: TToken);
var
  Scope: TDictionary<string, Boolean>;
begin
  if (FScopes.Count = 0) then
    Exit();

  Scope := FScopes.Peek();
  Scope.AddOrSetValue(Name.Lexeme, True);
end;

function TResolver.Visit(VarStatement: TVarStatement): TSSLangValue;
begin
  Declare(VarStatement.Name);

  if Assigned(VarStatement.initializer) then
    Resolve(VarStatement.Initializer);

  Define(VarStatement.name);

  Result := Default(TSSLangValue);
  Result.ValueType := TSSLangValueType.IS_NULL;
end;

constructor TResolver.Create(Interpreter: TInterpreter);
begin
  FCurrentFunction := TFunctionType.NONE;
  FCurrentClass := TClassType.NONE;
  FScopes := TObjectStack<TDictionary<string, Boolean>>.Create();
  FInterpreter := Interpreter;
end;

destructor TResolver.Destroy;
begin
  FScopes.Free();

  inherited;
end;

function TResolver.Visit(WhileStatement: TWhileStatement): TSSLangValue;
begin
  Resolve(WhileStatement.Condition);
  Resolve(WhileStatement.Body);

  Result := Default(TSSLangValue);
  Result.ValueType := TSSLangValueType.IS_NULL;
end;

function TResolver.Visit(ContinueStatement: TContinueStatement): TSSLangValue;
begin
  Result := Default(TSSLangValue);
  Result.ValueType := TSSLangValueType.IS_NULL;
end;

function TResolver.Visit(BreakStatement: TBreakStatement): TSSLangValue;
begin
  Result := Default(TSSLangValue);
  Result.ValueType := TSSLangValueType.IS_NULL;
end;

function TResolver.Visit(SuperExpression: TSuperExpression): TSSLangValue;
begin
  if (FCurrentClass = TClassType.NONE) then
    Error(SuperExpression.Keyword, 'Não é possível usar "super" fora de uma classe.')
  else if not (FCurrentClass = TClassType.SUBCLASS) then
    Error(SuperExpression.Keyword, 'Não é possível usar "super" em uma classe sem superclasse.');

  ResolveLocal(SuperExpression, SuperExpression.Keyword);

  Result := Default(TSSLangValue);
  Result.ValueType := TSSLangValueType.IS_NULL;
end;

function TResolver.Visit(ThisExpression: TThisExpression): TSSLangValue;
begin
  if (FCurrentClass = TClassType.NONE) then
  begin
    Error(ThisExpression.Keyword, 'Não é possível usar "this" fora de uma classe.');

    Result := Default(TSSLangValue);
    Result.ValueType := TSSLangValueType.IS_NULL;
    Exit();
  end;

  ResolveLocal(ThisExpression, ThisExpression.Keyword);

  Result := Default(TSSLangValue);
  Result.ValueType := TSSLangValueType.IS_NULL;
end;

function TResolver.Visit(SetExpression: TSetExpression): TSSLangValue;
begin
  Resolve(SetExpression.Value);
  Resolve(SetExpression.Obj);

  Result := Default(TSSLangValue);
  Result.ValueType := TSSLangValueType.IS_NULL;
end;

function TResolver.Visit(GetExpression: TGetExpression): TSSLangValue;
begin
  Resolve(GetExpression.Obj);

  Result := Default(TSSLangValue);
  Result.ValueType := TSSLangValueType.IS_NULL;
end;

function TResolver.Visit(ClassStatement: TClassStatement): TSSLangValue;
var
  Method: TFunctionStatement;
  Declaration: TFunctionType;
  EnclosingClass: TClassType;
begin
  EnclosingClass := FCurrentClass;
  FCurrentClass := TClassType.CLASS;

  Declare(ClassStatement.Name);
  Define(ClassStatement.Name);

  if Assigned(ClassStatement.SuperClass) and (ClassStatement.Name.Lexeme = ClassStatement.SuperClass.Name.Lexeme) then
    Error(ClassStatement.Superclass.Name, 'Uma classe não pode herdar de si mesma.');

  if Assigned(ClassStatement.Superclass) then
  begin
    FCurrentClass := TClassType.SUBCLASS;
    Resolve(ClassStatement.SuperClass);
  end;

  if Assigned(ClassStatement.Superclass) then
  begin
    BeginScope();
    FScopes.Peek().Add('super', True);
  end;

  BeginScope();
  FScopes.Peek().Add('this', True);

  for Method in ClassStatement.Methods do
  begin
    Declaration := TFunctionType.METHOD;

    if (Method.Name.Lexeme = 'init') then
      Declaration := TFunctionType.INITIALIZER;

    ResolveFunction(Method, Declaration);
  end;


  EndScope();

  if Assigned(ClassStatement.SuperClass) then
    EndScope();

  FCurrentClass := EnclosingClass;

  Result := Default(TSSLangValue);
  Result.ValueType := TSSLangValueType.IS_NULL;
end;

procedure TResolver.EndScope();
begin
  FScopes.Pop();
end;

procedure TResolver.Resolve(Expr: TExpression);
begin
  Expr.Accept(Self);
end;

procedure TResolver.Resolve(Statement: TStatement);
begin
  Statement.Accept(Self);
end;

function TResolver.Visit(BlockStatement: TBlockStatement): TSSLangValue;
begin
  BeginScope();
  Resolve(BlockStatement.Statements);
  EndScope();

  Result := Default(TSSLangValue);
  Result.ValueType := TSSLangValueType.IS_NULL;
end;

procedure TResolver.Resolve(Statements: TObjectList<TStatement>);
var
  Statement: TStatement;
begin
  for Statement in Statements do
    Resolve(Statement);
end;

procedure TResolver.BeginScope;
var
  Item: TDictionary<string, Boolean>;
begin
  Item := TDictionary<string, Boolean>.Create();
  FScopes.Push(Item);
end;

function TResolver.Visit(ExpressionStatement: TExpressionStatement): TSSLangValue;
begin
  Resolve(ExpressionStatement.Expression);

  Result := Default(TSSLangValue);
  Result.ValueType := TSSLangValueType.IS_NULL;
end;

function TResolver.Visit(IfStatement: TIfStatement): TSSLangValue;
begin
  Resolve(IfStatement.Condition);
  Resolve(IfStatement.ThenBranch);

  if Assigned(IfStatement.ElseBranch) then
    Resolve(IfStatement.ElseBranch);

  Result := Default(TSSLangValue);
  Result.ValueType := TSSLangValueType.IS_NULL;
end;

function TResolver.Visit(FunctionStatement: TFunctionStatement): TSSLangValue;
begin
  Declare(FunctionStatement.name);
  Define(FunctionStatement.name);

  ResolveFunction(FunctionStatement, TFunctionType.FUNCTION);

  Result := Default(TSSLangValue);
  Result.ValueType := TSSLangValueType.IS_NULL;
end;

procedure TResolver.ResolveFunction(FunctionStatement: TFunctionStatement; FunctionType: TFunctionType);
var
  Param: TToken;
  EnclosingFunction: TFunctionType;
begin

  EnclosingFunction := FCurrentFunction;
  FCurrentFunction := FunctionType;
  try
    BeginScope();

    for Param in FunctionStatement.Params do
    begin
      Declare(Param);
      Define(Param);
    end;

    Resolve(FunctionStatement.Body);
    EndScope();

  finally
    FCurrentFunction := EnclosingFunction;
  end;

end;

end.
