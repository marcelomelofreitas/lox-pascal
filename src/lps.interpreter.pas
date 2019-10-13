// Marcello Mello
// 28/09/2019

unit lps.interpreter;

interface

uses
  SysUtils,
  Classes,
  VCL.Dialogs,
  Generics.Collections,
  DateUtils,
  lps.env,
  lps.ast,
  lps.types;

type

  TInterpreter = class(TInterfacedObject, IVisitor)
  private
    FGlobals: TEnvironment;
    FEnvironment: TEnvironment;
    FLocals: TDictionary<TExpression, Integer>;
    function Evaluate(Expression: TExpression): TSSLangValue;
    function IsTruthy(Value: TSSLangValue): Boolean;
    function IsEqual(ValueA, ValueB: TSSLangValue): Boolean;
    procedure CheckNumberOperands(TokenOperator: TToken;
      left, Right: TSSLangValue);
    function Stringify(Value: TSSLangValue): string;
    procedure Execute(Statement: TStatement);
    procedure ExecuteBlock(Statements: TObjectList<TStatement>;
      Environment: TEnvironment);
    function LookUpVariable(Name: TToken; Expr: TExpression): TSSLangValue;
    procedure CheckNumberOperand(Oper: TToken; Operand: TSSLangValue);
  private
    function Visit(AssignExpression: TAssignExpression): TSSLangValue; overload;
    function Visit(BinaryExpression: TBinaryExpression): TSSLangValue; overload;
    function Visit(CallExpression: TCallExpression): TSSLangValue; overload;
    function Visit(GetExpression: TGetExpression): TSSLangValue; overload;
    function Visit(GroupingExpression: TGroupingExpression)
      : TSSLangValue; overload;
    function Visit(LiteralExpression: TLiteralExpression)
      : TSSLangValue; overload;
    function Visit(LogicalExpression: TLogicalExpression)
      : TSSLangValue; overload;
    function Visit(SetExpression: TSetExpression): TSSLangValue; overload;
    function Visit(SuperExpression: TSuperExpression): TSSLangValue; overload;
    function Visit(ThisExpression: TThisExpression): TSSLangValue; overload;
    function Visit(UnaryExpression: TUnaryExpression): TSSLangValue; overload;
    function Visit(VariableExpression: TVariableExpression)
      : TSSLangValue; overload;
    function Visit(BlockStatement: TBlockStatement): TSSLangValue; overload;
    function Visit(BreakStatement: TBreakStatement): TSSLangValue; overload;
    function Visit(ContinueStatement: TContinueStatement)
      : TSSLangValue; overload;
    function Visit(ExpressionStatement: TExpressionStatement)
      : TSSLangValue; overload;
    function Visit(IfStatement: TIfStatement): TSSLangValue; overload;
    function Visit(FunctionStatement: TFunctionStatement)
      : TSSLangValue; overload;
    function Visit(PrintStatement: TPrintStatement): TSSLangValue; overload;
    function Visit(ClassStatement: TClassStatement): TSSLangValue; overload;
    function Visit(ReturnStatement: TReturnStatement): TSSLangValue; overload;
    function Visit(VarStatement: TVarStatement): TSSLangValue; overload;
    function Visit(WhileStatement: TWhileStatement): TSSLangValue; overload;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Interpret(Statements: TObjectList<TStatement>);
    procedure Resolve(Expr: TExpression; Depth: Integer);
    property Globals: TEnvironment read FGlobals;
  end;

  TCallable = class
  private
  public
    function Call(interpreter: TInterpreter; Arguments: TList<TSSLangValue>)
      : TSSLangValue; virtual; abstract;
    function Arity(): Integer; virtual; abstract;
  end;

  TClockFunction = class(TCallable)
  public
    function Call(interpreter: TInterpreter; Arguments: TList<TSSLangValue>)
      : TSSLangValue; override;
    function Arity: Integer; override;
    function ToString(): string; override;
  end;

  EReturnException = class(Exception)
  private
    FValue: TSSLangValue;
  public
    constructor Create(Value: TSSLangValue);
    property Value: TSSLangValue read FValue;
  end;

  EContinueException = class(Exception)
  end;

  EBreakException = class(Exception)
  end;

  TCallableFunction = class;

  TSSLangClass = class(TCallable)
  private
    FName: string;
    FMethods: TDictionary<string, TCallableFunction>;
    FSuperclass: TSSLangValue;
  public
    constructor Create(Name: string; Superclass: TSSLangValue;
      Methods: TDictionary<string, TCallableFunction>);
    function FindMethod(Name: string): TCallableFunction;
    function ToString(): string; override;
    function Call(interpreter: TInterpreter; Arguments: TList<TSSLangValue>)
      : TSSLangValue; override;
    function Arity: Integer; override;
    property Name: string read FName;
  end;

  TSSLangObjectInstance = class
  private
    FClass: TSSLangClass;
    FFields: TDictionary<string, TSSLangValue>;
  public
    constructor Create(AClass: TSSLangClass);
    function ToString(): string; override;
    function GetValue(Name: TToken): TSSLangValue;
    procedure SetValue(Name: TToken; Value: TSSLangValue);
  end;

  TCallableFunction = class(TCallable)
  private
    FDeclaration: TFunctionStatement;
    FClosure: TEnvironment;
    FIsInitializer: Boolean;
  public
    constructor Create(Declaration: TFunctionStatement; Closure: TEnvironment;
      IsInitializer: Boolean);
    function Bind(Instance: TSSLangObjectInstance): TSSLangValue;
    function Call(interpreter: TInterpreter; Arguments: TList<TSSLangValue>)
      : TSSLangValue; override;
    function Arity: Integer; override;
    function ToString(): string; override;
  end;

var
  HadRuntimeError: Boolean = false;

implementation

{ TInterpreter }

function TInterpreter.Visit(GroupingExpression: TGroupingExpression)
  : TSSLangValue;
begin
  Result := Evaluate(GroupingExpression.Expr);
end;

constructor TInterpreter.Create;
var
  ClockFunction: TSSLangValue;
begin
  FGlobals := TEnvironment.Create();
  FEnvironment := FGlobals;

  FLocals := TDictionary<TExpression, Integer>.Create();

  ClockFunction := Default (TSSLangValue);
  ClockFunction.ValueType := TSSLangValueType.IS_CALLABLE;
  ClockFunction.CallableValue := TClockFunction.Create();

  FGlobals.Define('clock', ClockFunction);
end;

destructor TInterpreter.Destroy;
begin
  FEnvironment.Free();
  inherited;
end;

function TInterpreter.Evaluate(Expression: TExpression): TSSLangValue;
begin
  Result := Expression.Accept(Self);
end;

function TInterpreter.IsEqual(ValueA, ValueB: TSSLangValue): Boolean;
begin

  if (ValueA.ValueType = TSSLangValueType.IS_NULL) and
    (ValueB.ValueType = TSSLangValueType.IS_NULL) then
    Result := True
  else if (ValueA.ValueType = TSSLangValueType.IS_UNDEF) and
    (ValueB.ValueType = TSSLangValueType.IS_UNDEF) then
    Result := True
  else if (ValueA.ValueType <> ValueB.ValueType) then
    Result := false
  else if (ValueA.ValueType = TSSLangValueType.IS_NULL) or
    (ValueB.ValueType = TSSLangValueType.IS_NULL) then
    Result := false
  else if (ValueA.ValueType = TSSLangValueType.IS_UNDEF) or
    (ValueB.ValueType = TSSLangValueType.IS_UNDEF) then
    Result := false
  else
  begin
    case ValueA.ValueType of
      TSSLangValueType.IS_INT32:
        Result := ValueA.Int32Value = ValueB.Int32Value;
      TSSLangValueType.IS_INT64:
        Result := ValueA.Int64Value = ValueB.Int64Value;
      TSSLangValueType.IS_DOUBLE:
        Result := ValueA.DoubleValue = ValueB.DoubleValue;
      TSSLangValueType.IS_STRING:
        Result := ValueA.DoubleValue = ValueB.DoubleValue;
      TSSLangValueType.IS_BOOLEAN:
        Result := ValueA.BooleanValue = ValueB.BooleanValue;
      TSSLangValueType.IS_CHAR:
        Result := ValueA.BooleanValue = ValueB.BooleanValue;
      TSSLangValueType.IS_CALLABLE:
        Result := ValueA.CallableValue = ValueB.CallableValue;
      TSSLangValueType.IS_CLASS:
        Result := ValueA.ClassValue = ValueB.ClassValue;
      TSSLangValueType.IS_OBJECT:
        Result := ValueA.ObjectInstanceValue = ValueB.ObjectInstanceValue;
      TSSLangValueType.IS_METHOD:
        Result := ValueA.MethodValue = ValueB.MethodValue;
    else
      Result := false;
    end;
  end;

end;

procedure TInterpreter.CheckNumberOperands(TokenOperator: TToken;
  left, Right: TSSLangValue);
begin
  if (left.ValueType = TSSLangValueType.IS_DOUBLE) and
    (Right.ValueType = TSSLangValueType.IS_DOUBLE) then
    Exit();

  raise ERuntimeError.Create(TokenOperator, 'Operandos devem ser números.');
end;

function TInterpreter.Visit(BinaryExpression: TBinaryExpression): TSSLangValue;
var
  Left, Right: TSSLangValue;
begin
  Result := Default (TSSLangValue);

  Left := Evaluate(BinaryExpression.left);
  Right := Evaluate(BinaryExpression.Right);

  case BinaryExpression.Operador.TokenType of
    TTokenType.BANG_EQUAL:
      begin
        Result.ValueType := TSSLangValueType.IS_BOOLEAN;
        Result.BooleanValue := not IsEqual(left, Right);
      end;
    TTokenType.EQUAL_EQUAL:
      begin
        Result.ValueType := TSSLangValueType.IS_BOOLEAN;
        Result.BooleanValue := IsEqual(left, Right);
      end;
    TTokenType.GREATER:
      begin
        CheckNumberOperands(BinaryExpression.Operador, left, Right);
        Result.ValueType := TSSLangValueType.IS_BOOLEAN;
        Result.BooleanValue := left.DoubleValue > Right.DoubleValue;
      end;
    TTokenType.GREATER_EQUAL:
      begin
        CheckNumberOperands(BinaryExpression.Operador, left, Right);
        Result.ValueType := TSSLangValueType.IS_BOOLEAN;
        Result.BooleanValue := left.DoubleValue >= Right.DoubleValue;
      end;
    TTokenType.LESS:
      begin
        CheckNumberOperands(BinaryExpression.Operador, left, Right);
        Result.ValueType := TSSLangValueType.IS_BOOLEAN;
        Result.BooleanValue := left.DoubleValue < Right.DoubleValue;
      end;
    TTokenType.LESS_EQUAL:
      begin
        CheckNumberOperands(BinaryExpression.Operador, left, Right);
        Result.ValueType := TSSLangValueType.IS_BOOLEAN;
        Result.BooleanValue := left.DoubleValue <= Right.DoubleValue;
      end;
    TTokenType.MINUS:
      begin
        CheckNumberOperands(BinaryExpression.Operador, left, Right);
        Result.ValueType := TSSLangValueType.IS_DOUBLE;
        Result.DoubleValue := left.DoubleValue - Right.DoubleValue;
      end;
    TTokenType.PLUS:
      begin
        if (left.ValueType = TSSLangValueType.IS_DOUBLE) and
           (Right.ValueType = TSSLangValueType.IS_DOUBLE) then
        begin
          Result.ValueType := TSSLangValueType.IS_DOUBLE;
          Result.DoubleValue := left.DoubleValue + Right.DoubleValue;
        end
        else if (left.ValueType = TSSLangValueType.IS_STRING) and
                (Right.ValueType = TSSLangValueType.IS_STRING) then
        begin
          Result.ValueType := TSSLangValueType.IS_STRING;

          Result.StrValue := left.StrValue + Result.StrValue;

          // StrPas(, Concat(Left.StrValue, Right.StrValue));
        end
        else if (left.ValueType = TSSLangValueType.IS_STRING) or
                (Right.ValueType = TSSLangValueType.IS_STRING) then
        begin
          Result.ValueType := TSSLangValueType.IS_STRING;
          Result.StrValue := ShortString(Stringify(Left) + Stringify(Right));

          // StrPas(, Concat(Left.StrValue, Right.StrValue));
        end
        else
          raise ERuntimeError.Create(BinaryExpression.Operador,
            'Os operandos devem ter dois números ou duas strings');
      end;
    TTokenType.SLASH:
      begin
        CheckNumberOperands(BinaryExpression.Operador, left, Right);

        if (Right.DoubleValue = 0) then
          raise ERuntimeError.Create(BinaryExpression.Operador, 'Divisão por zero.');

        Result.ValueType := TSSLangValueType.IS_DOUBLE;
        Result.DoubleValue := left.DoubleValue / Right.DoubleValue;
      end;
    TTokenType.STAR:
      begin
        CheckNumberOperands(BinaryExpression.Operador, left, Right);
        Result.ValueType := TSSLangValueType.IS_DOUBLE;
        Result.DoubleValue := left.DoubleValue * Right.DoubleValue;
      end;
  else
    Result.ValueType := TSSLangValueType.IS_NULL;
  end;

end;

function TInterpreter.Visit(LiteralExpression: TLiteralExpression)
  : TSSLangValue;
begin
  Result := LiteralExpression.Value;
end;

function TInterpreter.Visit(UnaryExpression: TUnaryExpression): TSSLangValue;
var
  Right: TSSLangValue;
begin

  Right := Evaluate(UnaryExpression.Right);

  if UnaryExpression.Operador.TokenType = TTokenType.BANG then
  begin
    Result.ValueType := TSSLangValueType.IS_DOUBLE;
    Result.BooleanValue := not IsTruthy(Right);
  end
  else if UnaryExpression.Operador.TokenType = TTokenType.MINUS then
  begin
    CheckNumberOperand(UnaryExpression.Operador, Right);
    Result.ValueType := TSSLangValueType.IS_DOUBLE;
    Result.DoubleValue := -Right.DoubleValue;
  end
  else
    Result.ValueType := TSSLangValueType.IS_NULL;

end;

procedure TInterpreter.CheckNumberOperand(Oper: TToken; Operand: TSSLangValue);
begin
  if (Operand.ValueType = TSSLangValueType.IS_DOUBLE) then
    Exit();

  raise ERuntimeError.Create(Oper, 'O operando deve ser um número.');
end;

function TInterpreter.IsTruthy(Value: TSSLangValue): Boolean;
begin

  if (Value.ValueType = TSSLangValueType.IS_NULL) then
    Exit(false);

  if (Value.ValueType = TSSLangValueType.IS_BOOLEAN) then
    Result := Value.BooleanValue
  else
    Result := True;

end;

function TInterpreter.Stringify(Value: TSSLangValue): string;
var
  OldDecimalSeparator: Char;
begin

  if Value.ValueType = TSSLangValueType.IS_NULL then
    Result := 'nil'
  else if Value.ValueType = TSSLangValueType.IS_DOUBLE then
  begin
    OldDecimalSeparator := FormatSettings.DecimalSeparator;
    try
      FormatSettings.DecimalSeparator := '.';
      Result := FloatToStr(Value.DoubleValue);

      if (Result.EndsWith('.0')) then
        Result := Result.Substring(1, Result.Length - 1);
    finally
      FormatSettings.DecimalSeparator := OldDecimalSeparator;
    end;
  end
  else if Value.ValueType = TSSLangValueType.IS_BOOLEAN then
    Result := BoolToStr(Value.BooleanValue)
  else if Value.ValueType = TSSLangValueType.IS_STRING then
    Result := String(Value.StrValue)
  else if Value.ValueType = TSSLangValueType.IS_INT32 then
    Result := IntToStr(Value.Int32Value)
  else if Value.ValueType = TSSLangValueType.IS_INT64 then
    Result := IntToStr(Value.Int32Value)
  else
    Result := '';

end;

function TInterpreter.Visit(WhileStatement: TWhileStatement): TSSLangValue;
begin
  while IsTruthy(Evaluate(WhileStatement.Condition)) do
  begin
    try
      Execute(WhileStatement.Body);
    except
      on E: EBreakException do
        Break;
      on E: EContinueException do
        Continue;
    end;
  end;

  Result := Default (TSSLangValue);
  Result.ValueType := TSSLangValueType.IS_NULL;
end;

function TInterpreter.Visit(ContinueStatement: TContinueStatement): TSSLangValue;
begin
  raise EContinueException.Create('');
end;

function TInterpreter.Visit(BreakStatement: TBreakStatement): TSSLangValue;
begin
  raise EBreakException.Create('');
end;

function TInterpreter.Visit(SuperExpression: TSuperExpression): TSSLangValue;
var
  Distance: Integer;
  Superclass: TSSLangClass;
  Obj: TSSLangObjectInstance;
  Method: TCallableFunction;
begin
  Distance := FLocals[SuperExpression];
  Superclass := TSSLangClassValue(FEnvironment.GetAt(Distance, 'super')
    .ClassValue);

  Obj := TSSLangObjectInstance(FEnvironment.GetAt(Distance - 1, 'this')
    .ObjectInstanceValue);

  Method := Superclass.FindMethod(SuperExpression.Method.Lexeme);

  if (Method = nil) then
    raise ERuntimeError.Create(SuperExpression.Method,
      'Propriedade indefinida "' + SuperExpression.Method.Lexeme + '!".');

  Result := Method.Bind(Obj);
end;

function TInterpreter.Visit(ThisExpression: TThisExpression): TSSLangValue;
begin
  Result := LookUpVariable(ThisExpression.Keyword, ThisExpression);
end;

function TInterpreter.Visit(SetExpression: TSetExpression): TSSLangValue;
var
  Obj, Value: TSSLangValue;
begin

  Obj := Evaluate(SetExpression.Obj);

  if not(Obj.ValueType = TSSLangValueType.IS_OBJECT) then
    raise ERuntimeError.Create(SetExpression.Name,
      'Somente instâncias têm campos.');

  Value := Evaluate(SetExpression.Value);
  TSSLangObjectInstance(Obj.ObjectInstanceValue)
    .SetValue(SetExpression.Name, Value);

  Result := Value;

end;

function TInterpreter.Visit(GetExpression: TGetExpression): TSSLangValue;
var
  Obj: TSSLangValue;
begin
  Obj := Evaluate(GetExpression.Obj);

  if (Obj.ValueType = TSSLangValueType.IS_OBJECT) then
  begin
    Result := TSSLangObjectInstance(Obj.ObjectInstanceValue)
      .GetValue(GetExpression.Name);
    Exit();
  end;

  raise ERuntimeError.Create(GetExpression.Name,
    'Somente instâncias têm propriedades.');
end;

function TInterpreter.Visit(ClassStatement: TClassStatement): TSSLangValue;
var
  Value: TSSLangValue;
  Methods: TDictionary<string, TCallableFunction>;
  Method: TFunctionStatement;
  Func: TCallableFunction;
  Superclass: TSSLangValue;
begin
  Superclass := Default (TSSLangValue);
  Superclass.ValueType := TSSLangValueType.IS_NULL;

  if Assigned(ClassStatement.Superclass) then
  begin
    Superclass := Evaluate(ClassStatement.Superclass);

    if not(Superclass.ValueType in [TSSLangValueType.IS_CLASS,
      TSSLangValueType.IS_OBJECT]) then
      raise ERuntimeError.Create(ClassStatement.Superclass.Name,
        'A superclasse deve ser uma classe.');
  end;

  Value := Default (TSSLangValue);
  Value.ValueType := TSSLangValueType.IS_NULL;
  FEnvironment.Define(ClassStatement.Name.Lexeme, Value);

  if Assigned(ClassStatement.Superclass) then
  begin
    FEnvironment := TEnvironment.Create(FEnvironment);
    FEnvironment.Define('super', Superclass);
  end;

  Methods := TDictionary<string, TCallableFunction>.Create();

  for Method in ClassStatement.Methods do
  begin
    Func := TCallableFunction.Create(Method, FEnvironment,
      Method.Name.Lexeme = 'init');
    Methods.AddOrSetValue(Method.Name.Lexeme, Func);
  end;

  if Assigned(ClassStatement.Superclass) then
    FEnvironment := FEnvironment.Enclosing;

  Value := Default (TSSLangValue);
  Value.ValueType := TSSLangValueType.IS_OBJECT;
  Value.ClassValue := TSSLangClass.Create(ClassStatement.Name.Lexeme,
    Superclass, Methods);
  FEnvironment.Assign(ClassStatement.Name, Value);

  Result := Default (TSSLangValue);
  Result.ValueType := TSSLangValueType.IS_NULL;
end;

function TInterpreter.Visit(ReturnStatement: TReturnStatement): TSSLangValue;
var
  Value: TSSLangValue;
begin
  Result := Default (TSSLangValue);
  Result.ValueType := TSSLangValueType.IS_NULL;

  if Assigned(ReturnStatement.Value) then
    Value := Evaluate(ReturnStatement.Value);

  raise EReturnException.Create(Value);
end;

function TInterpreter.Visit(FunctionStatement: TFunctionStatement)
  : TSSLangValue;
var
  FunctionValue: TSSLangValue;
begin
  FunctionValue.ValueType := TSSLangValueType.IS_CALLABLE;
  FunctionValue.CallableValue := TCallableFunction.Create(FunctionStatement,
    FEnvironment, false);

  FEnvironment.Define(FunctionStatement.Name.Lexeme, FunctionValue);

  Result := Default (TSSLangValue);
  Result.ValueType := TSSLangValueType.IS_NULL;
end;

function TInterpreter.Visit(CallExpression: TCallExpression): TSSLangValue;
var
  Callee: TSSLangValue;
  Arguments: TList<TSSLangValue>;
  Argument: TExpression;
  FuncValue: TCallable;
begin

  Callee := Evaluate(CallExpression.Callee);

  Arguments := TList<TSSLangValue>.Create();

  for Argument in CallExpression.Arguments do
    Arguments.Add(Evaluate(Argument));

  if not(Callee.ValueType in [TSSLangValueType.IS_CALLABLE,
    TSSLangValueType.IS_CLASS, TSSLangValueType.IS_OBJECT,
    TSSLangValueType.IS_METHOD]) then
    raise ERuntimeError.Create(CallExpression.paren,
      'Somente é permitido chamar funções e classes.');

  FuncValue := TCallable(Callee.CallableValue);

  if not(Arguments.Count = FuncValue.Arity()) then
  begin
    raise ERuntimeError.Create(CallExpression.paren,
      'Experado ' + IntToStr(FuncValue.Arity()) + ' argumentos, mas tem ' +
      IntToStr(Arguments.Count) + '.');
  end;

  Result := FuncValue.Call(Self, Arguments);
end;

function TInterpreter.Visit(LogicalExpression: TLogicalExpression)
  : TSSLangValue;
var
  left: TSSLangValue;
begin
  left := Evaluate(LogicalExpression.left);

  if (LogicalExpression.Operador.TokenType = TTokenType.OR) then
  begin
    if IsTruthy(left) then
      Exit(left);
  end
  else if not IsTruthy(left) then
    Exit(left);

  Result := Evaluate(LogicalExpression.Right);
end;

function TInterpreter.Visit(VarStatement: TVarStatement): TSSLangValue;
var
  Value: TSSLangValue;
begin
  if (VarStatement.Initializer <> nil) then
    Value := Evaluate(VarStatement.Initializer)
  else
    Value.ValueType := TSSLangValueType.IS_NULL;

  FEnvironment.Define(VarStatement.Name.Lexeme, Value);

  Result := Default (TSSLangValue);
  Result.ValueType := TSSLangValueType.IS_NULL;
end;

function TInterpreter.Visit(IfStatement: TIfStatement): TSSLangValue;
begin
  if (IsTruthy(Evaluate(IfStatement.Condition))) then
    Execute(IfStatement.ThenBranch)
  else if Assigned(IfStatement.ElseBranch) then
    Execute(IfStatement.ElseBranch);

  Result := Default (TSSLangValue);
  Result.ValueType := TSSLangValueType.IS_NULL;
end;

function TInterpreter.Visit(BlockStatement: TBlockStatement): TSSLangValue;
begin
  ExecuteBlock(BlockStatement.Statements, TEnvironment.Create(FEnvironment));

  Result := Default (TSSLangValue);
  Result.ValueType := TSSLangValueType.IS_NULL;
end;

function TInterpreter.Visit(AssignExpression: TAssignExpression): TSSLangValue;
var
  Value: TSSLangValue;
  Distance: Integer;
begin
  Value := Evaluate(AssignExpression.Value);

  if FLocals.TryGetValue(AssignExpression, Distance) then
    FEnvironment.AssignAt(Distance, AssignExpression.Name, Value)
  else
    FGlobals.Assign(AssignExpression.Name, Value);

  Result := Value;
end;

function TInterpreter.Visit(VariableExpression: TVariableExpression)
  : TSSLangValue;
begin
  Result := LookUpVariable(VariableExpression.Name, VariableExpression)
end;

function TInterpreter.LookUpVariable(Name: TToken; Expr: TExpression)
  : TSSLangValue;
var
  Distance: Integer;
begin
  if FLocals.TryGetValue(Expr, Distance) then
    Result := FEnvironment.GetAt(Distance, Name.Lexeme)
  else
    Result := FGlobals.Get(Name);
end;

procedure RuntimeError(Error: ERuntimeError);
begin
  Writeln(Error.Message + sLineBreak + '[Linha Nro: ' +
    IntToStr(Error.token.LineNro) + ']');
  HadRuntimeError := True;
end;

procedure TInterpreter.Execute(Statement: TStatement);
begin
  Statement.Accept(Self);
end;

procedure TInterpreter.Resolve(Expr: TExpression; Depth: Integer);
begin
  FLocals.AddOrSetValue(Expr, Depth);
end;

procedure TInterpreter.ExecuteBlock(Statements: TObjectList<TStatement>;
  Environment: TEnvironment);
var
  PreviousEnvironment: TEnvironment;
  Statement: TStatement;
begin
  PreviousEnvironment := FEnvironment;

  try
    FEnvironment := Environment;

    for Statement in Statements do
      Execute(Statement);
  finally
    FEnvironment := PreviousEnvironment;
  end;

end;

procedure TInterpreter.Interpret(Statements: TObjectList<TStatement>);
var
  Statement: TStatement;
begin
  try
    HadRuntimeError := false;

    for Statement in Statements do
      Execute(Statement);

  except
    on E: ERuntimeError do
      RuntimeError(E);
  end;
end;

function TInterpreter.Visit(PrintStatement: TPrintStatement): TSSLangValue;
var
  Value: TSSLangValue;
begin
  Value := Evaluate(PrintStatement.Expr);
  Writeln(Stringify(Value));

  Result := Default (TSSLangValue);
  Result.ValueType := TSSLangValueType.IS_NULL;
end;

function TInterpreter.Visit(ExpressionStatement: TExpressionStatement)
  : TSSLangValue;
begin
  Evaluate(ExpressionStatement.Expression);

  Result := Default (TSSLangValue);
  Result.ValueType := TSSLangValueType.IS_NULL;
end;

{ TClockFunction }

function TClockFunction.Arity: Integer;
begin
  Result := 0;
end;

function TClockFunction.Call(interpreter: TInterpreter;
  Arguments: TList<TSSLangValue>): TSSLangValue;
begin
  Result.ValueType := TSSLangValueType.IS_INT32;
  Result.Int32Value := MillisecondOfTheDay(Now);
end;

function TClockFunction.ToString: string;
begin
  Result := '<native fn>';
end;

{ TCallableFunction }

function TCallableFunction.Arity: Integer;
begin
  Result := FDeclaration.Params.Count;
end;

function TCallableFunction.Call(interpreter: TInterpreter;
  Arguments: TList<TSSLangValue>): TSSLangValue;
var
  Environment: TEnvironment;
  i: Integer;
begin
  Environment := TEnvironment.Create(FClosure);

  for i := 0 to FDeclaration.Params.Count - 1 do
    Environment.Define(FDeclaration.Params[i].Lexeme, Arguments[i]);

  try
    interpreter.ExecuteBlock(FDeclaration.Body, Environment);
  except
    on ReturnException: EReturnException do
      if FIsInitializer then
      begin
        Result := FClosure.GetAt(0, 'this');
        Exit();
      end
      else
      begin
        Result := ReturnException.Value;
        Exit();
      end;
  end;

  if (FIsInitializer) then
    Exit(FClosure.GetAt(0, 'this'));

  Result := Default (TSSLangValue);
  Result.ValueType := TSSLangValueType.IS_NULL;
end;

constructor TCallableFunction.Create(Declaration: TFunctionStatement;
  Closure: TEnvironment; IsInitializer: Boolean);
begin
  FDeclaration := Declaration;
  FClosure := Closure;
  FIsInitializer := IsInitializer;
end;

function TCallableFunction.Bind(Instance: TSSLangObjectInstance): TSSLangValue;
var
  Environment: TEnvironment;
  Value: TSSLangValue;
begin
  Value := Default (TSSLangValue);
  Value.ValueType := TSSLangValueType.IS_OBJECT;
  Value.ObjectInstanceValue := Instance;

  Environment := TEnvironment.Create(FClosure);
  Environment.Define('this', Value);

  Value := Default (TSSLangValue);
  Value.ValueType := TSSLangValueType.IS_METHOD;
  Value.MethodValue := TCallableFunction.Create(FDeclaration, Environment,
    FIsInitializer);

  Result := Value;
end;

function TCallableFunction.ToString: string;
begin
  Result := '<fn ' + FDeclaration.Name.Lexeme + '>';
end;

{ EReturnException }

constructor EReturnException.Create(Value: TSSLangValue);
begin
  inherited Create('');
  FValue := Value;
end;

{ TSSLangClass }

function TSSLangClass.Arity: Integer;
var
  Initializer: TCallableFunction;
begin
  Initializer := FindMethod('init');
  if Assigned(Initializer) then
    Result := Initializer.Arity()
  else
    Result := 0;
end;

function TSSLangClass.Call(interpreter: TInterpreter;
  Arguments: TList<TSSLangValue>): TSSLangValue;
var
  ObjectValue: TSSLangValue;
  Initializer: TCallableFunction;
begin
  ObjectValue := Default (TSSLangValue);
  ObjectValue.ValueType := TSSLangValueType.IS_OBJECT;
  ObjectValue.ObjectInstanceValue := TSSLangObjectInstance.Create(Self);

  Initializer := FindMethod('init');
  if Assigned(Initializer) then
    TCallableFunction(Initializer.Bind(ObjectValue.ObjectInstanceValue)
      .MethodValue).Call(interpreter, Arguments);

  Result := ObjectValue;
end;

constructor TSSLangClass.Create(Name: string; Superclass: TSSLangValue;
  Methods: TDictionary<string, TCallableFunction>);
begin
  FName := Name;
  FMethods := Methods;
  FSuperclass := Superclass;
end;

function TSSLangClass.FindMethod(Name: string): TCallableFunction;
begin
  if (FMethods.ContainsKey(Name)) then
    Result := FMethods[Name]
  else if FSuperclass.ValueType in [TSSLangValueType.IS_CLASS,
    TSSLangValueType.IS_OBJECT] then
    Result := TSSLangClass(FSuperclass.ClassValue).FindMethod(Name)
  else
    Result := nil;
end;

function TSSLangClass.ToString: string;
begin
  Result := FName;
end;

{ TSSLangObjectInstance }

constructor TSSLangObjectInstance.Create(AClass: TSSLangClass);
begin
  FClass := AClass;
  FFields := TDictionary<string, TSSLangValue>.Create();
end;

function TSSLangObjectInstance.ToString: string;
begin
  Result := FClass.Name + ' instance';
end;

function TSSLangObjectInstance.GetValue(Name: TToken): TSSLangValue;
var
  Method: TCallableFunction;
begin
  if FFields.TryGetValue(Name.Lexeme, Result) then
    Exit();

  Method := FClass.FindMethod(Name.Lexeme);
  if Assigned(Method) then
  begin
    Result := Method.Bind(Self);
    Exit();
  end;

  raise ERuntimeError.Create(Name, 'Propriedade indefinida "' +
    name.Lexeme + '".');

end;

procedure TSSLangObjectInstance.SetValue(Name: TToken; Value: TSSLangValue);
begin
  FFields.AddOrSetValue(Name.Lexeme, Value);
end;

end.
