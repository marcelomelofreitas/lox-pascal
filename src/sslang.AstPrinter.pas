// Marcello Mello
// 28/09/2019

unit sslang.AstPrinter;

interface

uses
  sslang.ast,
  sslang.types;

type

  TAstPrinter = class(TInterfacedObject, IVisitor)
  public
    function Visit(BinaryExpression: TBinaryExpression): TLangValue; overload;
    function Visit(GroupingExpression: TGroupingExpression): TLangValue; overload;
    function Visit(LiteralExpression: TLiteralExpression): TLangValue; overload;
    function Visit(UnaryExpression: TUnaryExpression): TLangValue; overload;
    function Visit(ExpressionStatement: TExpressionStatement): TLangValue; overload;
    function Visit(PrintStatement: TPrintStatement): TLangValue; overload;
    function Print(Node: TASTNode): TLangValue;
  end;

implementation

uses
  SysUtils;

{ TAstPrinter }


function TAstPrinter.Print(Node: TASTNode): TLangValue;
begin
  Node.accept(Self);
end;

function TAstPrinter.Visit(BinaryExpression: TBinaryExpression): TLangValue;
begin
  Write('(');
  Write(BinaryExpression.Operador.Lexeme);
  Write(' ');
  Expr.Left.Accept(Self);
  Write(' ');
  Expr.Right.Accept(Self);
  Write(')');
end;

function TAstPrinter.Visit(Expr: TGroupingExpression): TLangValue;
begin
  Write('(');
  Write('Group');
  Write(' ');
  Expr.Expr.Accept(Self);
  Write(')');
end;

function TAstPrinter.Visit(Expr: TLiteralExpression): TLangValue;
begin
  case VarType(Expr.Value) of
    varString: Write(Expr.Value.ToString());
    varDouble: Write(FloatToStr(Expr.Value));
    varSingle: Write(FloatToStr(Expr.Value));
    varInteger: Write(IntToStr(Expr.Value));
    varByte: Write(IntToStr(Expr.Value));
    varCurrency: Write(CurrToStr(Expr.Value));
  else
    raise Exception.Create('Error Message');
  end;
end;

function TAstPrinter.Visit(Expr: TUnaryExpression): TLangValue;
begin
  Write('(');
  Write(Expr.Operador.Lexeme);
  Write(' ');
  Expr.Right.Accept(Self);
  Write(')');
end;

function TAstPrinter.Visit(Stmt: TPrintStatement): Variant;
begin

end;

function TAstPrinter.Visit(Stmt: TExpressionStatement): TLangValue;
begin

end;

end.
