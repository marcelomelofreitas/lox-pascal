// Marcello Mello
// 28/09/2019

program printer_ast;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  sslang.AstPrinter in '..\src\sslang.AstPrinter.pas',
  sslang.EnumConversor in '..\src\sslang.EnumConversor.pas',
  sslang.expr in '..\src\sslang.expr.pas',
  sslang.GenerateAst in '..\src\sslang.GenerateAst.pas',
  sslang in '..\src\sslang.pas',
  sslang.scanner in '..\src\sslang.scanner.pas',
  sslang.types in '..\src\sslang.types.pas',
  sslang.utils in '..\src\sslang.utils.pas',
  sslang.parser in '..\src\sslang.parser.pas';

var
  Expression: TASTNode;
  AstPrinter: TAstPrinter;
begin

  Expression := TASTBinary.Create(TASTUnary.Create(TToken.Create(TTokenType.MINUS, '-', varNull, 1),
                                  TASTLiteral.Create(123)),
                                  TToken.Create(TTokenType.STAR, '*', varNull, 1),
                                  TASTGrouping.Create(TASTLiteral.Create(45.67)));

  AstPrinter := TAstPrinter.Create();
  AstPrinter.Print(Expression);
  AstPrinter.Free();

end.
