// Marcello Mello
// 30/09/2019

// **********************************************************************
// ESSE ARQUIVO É GERADO DE FORMA AUTOMATICA PELO PROGRAMA "GenerateAst"
// **********************************************************************

unit lps.ast;

interface

uses
  Generics.Collections,
  lps.types;

type

  IVisitor = interface;

  TASTNode = class
    function Accept(Visitor: IVisitor): TSSLangValue; virtual; abstract;
  end;

  { TExpression }

  TExpression = class(TASTNode)
  end;

  TAssignExpression = class(TExpression)
  private
    FName: TToken;
    FValue: TExpression;
  public
    constructor Create(Name: TToken; Value: TExpression);
    function Accept(Visitor: IVisitor): TSSLangValue; override; 
    property Name: TToken read FName write FName;
    property Value: TExpression read FValue write FValue;
  end;

  TBinaryExpression = class(TExpression)
  private
    FLeft: TExpression;
    FOperador: TToken;
    FRight: TExpression;
  public
    constructor Create(Left: TExpression; Operador: TToken; Right: TExpression);
    function Accept(Visitor: IVisitor): TSSLangValue; override; 
    property Left: TExpression read FLeft write FLeft;
    property Operador: TToken read FOperador write FOperador;
    property Right: TExpression read FRight write FRight;
  end;

  TCallExpression = class(TExpression)
  private
    FCallee: TExpression;
    FParen: TToken;
    FArguments: TObjectList<TExpression>;
  public
    constructor Create(Callee: TExpression; Paren: TToken; Arguments: TObjectList<TExpression>);
    function Accept(Visitor: IVisitor): TSSLangValue; override; 
    property Callee: TExpression read FCallee write FCallee;
    property Paren: TToken read FParen write FParen;
    property Arguments: TObjectList<TExpression> read FArguments write FArguments;
  end;

  TGetExpression = class(TExpression)
  private
    FObj: TExpression;
    FName: TToken;
  public
    constructor Create(Obj: TExpression; Name: TToken);
    function Accept(Visitor: IVisitor): TSSLangValue; override; 
    property Obj: TExpression read FObj write FObj;
    property Name: TToken read FName write FName;
  end;

  TGroupingExpression = class(TExpression)
  private
    FExpr: TExpression;
  public
    constructor Create(Expr: TExpression);
    function Accept(Visitor: IVisitor): TSSLangValue; override; 
    property Expr: TExpression read FExpr write FExpr;
  end;

  TLiteralExpression = class(TExpression)
  private
    FValue: TSSLangValue;
  public
    constructor Create(Value: TSSLangValue);
    function Accept(Visitor: IVisitor): TSSLangValue; override; 
    property Value: TSSLangValue read FValue write FValue;
  end;

  TLogicalExpression = class(TExpression)
  private
    FLeft: TExpression;
    FOperador: TToken;
    FRight: TExpression;
  public
    constructor Create(Left: TExpression; Operador: TToken; Right: TExpression);
    function Accept(Visitor: IVisitor): TSSLangValue; override; 
    property Left: TExpression read FLeft write FLeft;
    property Operador: TToken read FOperador write FOperador;
    property Right: TExpression read FRight write FRight;
  end;

  TSetExpression = class(TExpression)
  private
    FObj: TExpression;
    FName: TToken;
    FValue: TExpression;
  public
    constructor Create(Obj: TExpression; Name: TToken; Value: TExpression);
    function Accept(Visitor: IVisitor): TSSLangValue; override; 
    property Obj: TExpression read FObj write FObj;
    property Name: TToken read FName write FName;
    property Value: TExpression read FValue write FValue;
  end;

  TSuperExpression = class(TExpression)
  private
    FKeyword: TToken;
    FMethod: TToken;
  public
    constructor Create(Keyword: TToken; Method: TToken);
    function Accept(Visitor: IVisitor): TSSLangValue; override; 
    property Keyword: TToken read FKeyword write FKeyword;
    property Method: TToken read FMethod write FMethod;
  end;

  TThisExpression = class(TExpression)
  private
    FKeyword: TToken;
  public
    constructor Create(Keyword: TToken);
    function Accept(Visitor: IVisitor): TSSLangValue; override; 
    property Keyword: TToken read FKeyword write FKeyword;
  end;

  TUnaryExpression = class(TExpression)
  private
    FOperador: TToken;
    FRight: TExpression;
  public
    constructor Create(Operador: TToken; Right: TExpression);
    function Accept(Visitor: IVisitor): TSSLangValue; override; 
    property Operador: TToken read FOperador write FOperador;
    property Right: TExpression read FRight write FRight;
  end;

  TVariableExpression = class(TExpression)
  private
    FName: TToken;
  public
    constructor Create(Name: TToken);
    function Accept(Visitor: IVisitor): TSSLangValue; override; 
    property Name: TToken read FName write FName;
  end;

  { TStatement }

  TStatement = class(TASTNode)
  end;

  TBlockStatement = class(TStatement)
  private
    FStatements: TObjectList<TStatement>;
  public
    constructor Create(Statements: TObjectList<TStatement>);
    function Accept(Visitor: IVisitor): TSSLangValue; override; 
    property Statements: TObjectList<TStatement> read FStatements write FStatements;
  end;

  TBreakStatement = class(TStatement)
  private
  public
    constructor Create();
    function Accept(Visitor: IVisitor): TSSLangValue; override; 
  end;

  TContinueStatement = class(TStatement)
  private
  public
    constructor Create();
    function Accept(Visitor: IVisitor): TSSLangValue; override; 
  end;

  TExpressionStatement = class(TStatement)
  private
    FExpression: TExpression;
  public
    constructor Create(Expression: TExpression);
    function Accept(Visitor: IVisitor): TSSLangValue; override; 
    property Expression: TExpression read FExpression write FExpression;
  end;

  TIfStatement = class(TStatement)
  private
    FCondition: TExpression;
    FThenBranch: TStatement;
    FElseBranch: TStatement;
  public
    constructor Create(Condition: TExpression; ThenBranch: TStatement; ElseBranch: TStatement);
    function Accept(Visitor: IVisitor): TSSLangValue; override; 
    property Condition: TExpression read FCondition write FCondition;
    property ThenBranch: TStatement read FThenBranch write FThenBranch;
    property ElseBranch: TStatement read FElseBranch write FElseBranch;
  end;

  TFunctionStatement = class(TStatement)
  private
    FName: TToken;
    FParams: TObjectList<TToken>;
    FBody: TObjectList<TStatement>;
  public
    constructor Create(Name: TToken; Params: TObjectList<TToken>; Body: TObjectList<TStatement>);
    function Accept(Visitor: IVisitor): TSSLangValue; override; 
    property Name: TToken read FName write FName;
    property Params: TObjectList<TToken> read FParams write FParams;
    property Body: TObjectList<TStatement> read FBody write FBody;
  end;

  TPrintStatement = class(TStatement)
  private
    FExpr: TExpression;
  public
    constructor Create(Expr: TExpression);
    function Accept(Visitor: IVisitor): TSSLangValue; override; 
    property Expr: TExpression read FExpr write FExpr;
  end;

  TClassStatement = class(TStatement)
  private
    FName: TToken;
    FSuperClass: TVariableExpression;
    FMethods: TObjectList<TFunctionStatement>;
  public
    constructor Create(Name: TToken; SuperClass: TVariableExpression; Methods: TObjectList<TFunctionStatement>);
    function Accept(Visitor: IVisitor): TSSLangValue; override; 
    property Name: TToken read FName write FName;
    property SuperClass: TVariableExpression read FSuperClass write FSuperClass;
    property Methods: TObjectList<TFunctionStatement> read FMethods write FMethods;
  end;

  TReturnStatement = class(TStatement)
  private
    FKeyword: TToken;
    FValue: TExpression;
  public
    constructor Create(Keyword: TToken; Value: TExpression);
    function Accept(Visitor: IVisitor): TSSLangValue; override; 
    property Keyword: TToken read FKeyword write FKeyword;
    property Value: TExpression read FValue write FValue;
  end;

  TVarStatement = class(TStatement)
  private
    FName: TToken;
    FInitializer: TExpression;
  public
    constructor Create(Name: TToken; Initializer: TExpression);
    function Accept(Visitor: IVisitor): TSSLangValue; override; 
    property Name: TToken read FName write FName;
    property Initializer: TExpression read FInitializer write FInitializer;
  end;

  TWhileStatement = class(TStatement)
  private
    FCondition: TExpression;
    FBody: TStatement;
  public
    constructor Create(Condition: TExpression; Body: TStatement);
    function Accept(Visitor: IVisitor): TSSLangValue; override; 
    property Condition: TExpression read FCondition write FCondition;
    property Body: TStatement read FBody write FBody;
  end;

  IVisitor = interface
  ['{E92FFE0B-F01A-4F30-BF88-0C866382851F}']
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
  end;

implementation

  { TExpression }

constructor TAssignExpression.Create(Name: TToken; Value: TExpression);
begin
  FName := Name;
  FValue := Value;
end;

function TAssignExpression.Accept(Visitor: IVisitor): TSSLangValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TBinaryExpression.Create(Left: TExpression; Operador: TToken; Right: TExpression);
begin
  FLeft := Left;
  FOperador := Operador;
  FRight := Right;
end;

function TBinaryExpression.Accept(Visitor: IVisitor): TSSLangValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TCallExpression.Create(Callee: TExpression; Paren: TToken; Arguments: TObjectList<TExpression>);
begin
  FCallee := Callee;
  FParen := Paren;
  FArguments := Arguments;
end;

function TCallExpression.Accept(Visitor: IVisitor): TSSLangValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TGetExpression.Create(Obj: TExpression; Name: TToken);
begin
  FObj := Obj;
  FName := Name;
end;

function TGetExpression.Accept(Visitor: IVisitor): TSSLangValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TGroupingExpression.Create(Expr: TExpression);
begin
  FExpr := Expr;
end;

function TGroupingExpression.Accept(Visitor: IVisitor): TSSLangValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TLiteralExpression.Create(Value: TSSLangValue);
begin
  FValue := Value;
end;

function TLiteralExpression.Accept(Visitor: IVisitor): TSSLangValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TLogicalExpression.Create(Left: TExpression; Operador: TToken; Right: TExpression);
begin
  FLeft := Left;
  FOperador := Operador;
  FRight := Right;
end;

function TLogicalExpression.Accept(Visitor: IVisitor): TSSLangValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TSetExpression.Create(Obj: TExpression; Name: TToken; Value: TExpression);
begin
  FObj := Obj;
  FName := Name;
  FValue := Value;
end;

function TSetExpression.Accept(Visitor: IVisitor): TSSLangValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TSuperExpression.Create(Keyword: TToken; Method: TToken);
begin
  FKeyword := Keyword;
  FMethod := Method;
end;

function TSuperExpression.Accept(Visitor: IVisitor): TSSLangValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TThisExpression.Create(Keyword: TToken);
begin
  FKeyword := Keyword;
end;

function TThisExpression.Accept(Visitor: IVisitor): TSSLangValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TUnaryExpression.Create(Operador: TToken; Right: TExpression);
begin
  FOperador := Operador;
  FRight := Right;
end;

function TUnaryExpression.Accept(Visitor: IVisitor): TSSLangValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TVariableExpression.Create(Name: TToken);
begin
  FName := Name;
end;

function TVariableExpression.Accept(Visitor: IVisitor): TSSLangValue; 
begin
  Result := Visitor.Visit(Self);
end;

  { TStatement }

constructor TBlockStatement.Create(Statements: TObjectList<TStatement>);
begin
  FStatements := Statements;
end;

function TBlockStatement.Accept(Visitor: IVisitor): TSSLangValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TBreakStatement.Create();
begin
end;

function TBreakStatement.Accept(Visitor: IVisitor): TSSLangValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TContinueStatement.Create();
begin
end;

function TContinueStatement.Accept(Visitor: IVisitor): TSSLangValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TExpressionStatement.Create(Expression: TExpression);
begin
  FExpression := Expression;
end;

function TExpressionStatement.Accept(Visitor: IVisitor): TSSLangValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TIfStatement.Create(Condition: TExpression; ThenBranch: TStatement; ElseBranch: TStatement);
begin
  FCondition := Condition;
  FThenBranch := ThenBranch;
  FElseBranch := ElseBranch;
end;

function TIfStatement.Accept(Visitor: IVisitor): TSSLangValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TFunctionStatement.Create(Name: TToken; Params: TObjectList<TToken>; Body: TObjectList<TStatement>);
begin
  FName := Name;
  FParams := Params;
  FBody := Body;
end;

function TFunctionStatement.Accept(Visitor: IVisitor): TSSLangValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TPrintStatement.Create(Expr: TExpression);
begin
  FExpr := Expr;
end;

function TPrintStatement.Accept(Visitor: IVisitor): TSSLangValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TClassStatement.Create(Name: TToken; SuperClass: TVariableExpression; Methods: TObjectList<TFunctionStatement>);
begin
  FName := Name;
  FSuperClass := SuperClass;
  FMethods := Methods;
end;

function TClassStatement.Accept(Visitor: IVisitor): TSSLangValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TReturnStatement.Create(Keyword: TToken; Value: TExpression);
begin
  FKeyword := Keyword;
  FValue := Value;
end;

function TReturnStatement.Accept(Visitor: IVisitor): TSSLangValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TVarStatement.Create(Name: TToken; Initializer: TExpression);
begin
  FName := Name;
  FInitializer := Initializer;
end;

function TVarStatement.Accept(Visitor: IVisitor): TSSLangValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TWhileStatement.Create(Condition: TExpression; Body: TStatement);
begin
  FCondition := Condition;
  FBody := Body;
end;

function TWhileStatement.Accept(Visitor: IVisitor): TSSLangValue; 
begin
  Result := Visitor.Visit(Self);
end;

end.
