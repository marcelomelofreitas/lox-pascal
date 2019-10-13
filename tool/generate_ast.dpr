// Marcello Mello
// 28/09/2019

program generate_ast;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Generics.Collections,
  lps.GenerateAst in '..\src\lps.GenerateAst.pas';

var
  OutputDir: string;
  AstItem: TAstItem;
  ExprGrupo: TAstGrupo;
  StmtGrupo: TAstGrupo;
  AstGrupos: TObjectList<TAstGrupo>;
begin
  if (ParamCount <> 1) then
  begin
    Writeln('uso: generate_Ast <diretório de saída>');
    Halt(1);
  end;

  AstGrupos := TObjectList<TAstGrupo>.Create();

  ExprGrupo := TAstGrupo.Create();
  ExprGrupo.Nome := 'Expression';

  AstItem := TAstItem.Create();
  AstItem.Name := 'TAssign';
  AstItem.Fields := 'Name: TToken; Value: TExpression';
  ExprGrupo.Items.Add(AstItem);
  AstItem := TAstItem.Create();
  AstItem.Name := 'TBinary';
  AstItem.Fields := 'Left: TExpression; Operador: TToken; Right: TExpression';
  ExprGrupo.Items.Add(AstItem);

  AstItem := TAstItem.Create();
  AstItem.Name := 'TCall';
  AstItem.Fields := 'Callee: TExpression; Paren: TToken; Arguments: TObjectList<TExpression>';
  ExprGrupo.Items.Add(AstItem);

  AstItem := TAstItem.Create();
  AstItem.Name := 'TGet';
  AstItem.Fields := 'Obj: TExpression; Name: TToken';
  ExprGrupo.Items.Add(AstItem);

  AstItem := TAstItem.Create();
  AstItem.Name := 'TGrouping';
  AstItem.Fields := 'Expr: TExpression';
  ExprGrupo.Items.Add(AstItem);

  AstItem := TAstItem.Create();
  AstItem.Name := 'TLiteral';
  AstItem.Fields := 'Value: TSSLangValue';
  ExprGrupo.Items.Add(AstItem);

  AstItem := TAstItem.Create();
  AstItem.Name := 'TLogical';
  AstItem.Fields := 'Left: TExpression; Operador: TToken; Right: TExpression';
  ExprGrupo.Items.Add(AstItem);

  AstItem := TAstItem.Create();
  AstItem.Name := 'TSet';
  AstItem.Fields := 'Obj: TExpression; Name: TToken; Value: TExpression';
  ExprGrupo.Items.Add(AstItem);


  AstItem := TAstItem.Create();
  AstItem.Name := 'TSuper';
  AstItem.Fields := 'Keyword: TToken; Method: TToken';
  ExprGrupo.Items.Add(AstItem);

  AstItem := TAstItem.Create();
  AstItem.Name := 'TThis';
  AstItem.Fields := 'Keyword: TToken';
  ExprGrupo.Items.Add(AstItem);


  AstItem := TAstItem.Create();
  AstItem.Name := 'TUnary';
  AstItem.Fields := 'Operador: TToken; Right: TExpression';
  ExprGrupo.Items.Add(AstItem);
  AstItem := TAstItem.Create();
  AstItem.Name := 'TVariable';
  AstItem.Fields := 'Name: TToken';
  ExprGrupo.Items.Add(AstItem);
  AstGrupos.Add(ExprGrupo);


  // Definições do arquivo sslang.stmt.pas
  StmtGrupo := TAstGrupo.Create();
  StmtGrupo.Nome := 'Statement';

  AstItem := TAstItem.Create();
  AstItem.Name := 'TBlock';
  AstItem.Fields := 'Statements: TObjectList<TStatement>';
  StmtGrupo.Items.Add(AstItem);

  AstItem := TAstItem.Create();
  AstItem.Name := 'TBreak';
  AstItem.Fields := '';
  StmtGrupo.Items.Add(AstItem);

  AstItem := TAstItem.Create();
  AstItem.Name := 'TContinue';
  AstItem.Fields := '';
  StmtGrupo.Items.Add(AstItem);

  AstItem := TAstItem.Create();
  AstItem.Name := 'TExpression';
  AstItem.Fields := 'Expression: TExpression';
  StmtGrupo.Items.Add(AstItem);
  AstItem := TAstItem.Create();
  AstItem.Name := 'TIf';
  AstItem.Fields := 'Condition: TExpression; ThenBranch: TStatement; ElseBranch: TStatement';
  StmtGrupo.Items.Add(AstItem);
  AstItem := TAstItem.Create();
  AstItem.Name := 'TFunction';
  AstItem.Fields := 'Name: TToken; Params: TObjectList<TToken>; Body: TObjectList<TStatement>';
  StmtGrupo.Items.Add(AstItem);
  AstItem := TAstItem.Create();
  AstItem.Name := 'TPrint';
  AstItem.Fields := 'Expr: TExpression';
  StmtGrupo.Items.Add(AstItem);

  AstItem := TAstItem.Create();
  AstItem.Name := 'TClass';
  AstItem.Fields := 'Name: TToken; SuperClass: TVariableExpression; Methods: TObjectList<TFunctionStatement>';
  StmtGrupo.Items.Add(AstItem);

  AstItem := TAstItem.Create();
  AstItem.Name := 'TReturn';
  AstItem.Fields := 'Keyword: TToken; Value: TExpression';
  StmtGrupo.Items.Add(AstItem);

  AstItem := TAstItem.Create();
  AstItem.Name := 'TVar';
  AstItem.Fields := 'Name: TToken; Initializer: TExpression';
  StmtGrupo.Items.Add(AstItem);
  AstItem := TAstItem.Create();
  AstItem.Name := 'TWhile';
  AstItem.Fields := 'Condition: TExpression; Body: TStatement';
  StmtGrupo.Items.Add(AstItem);
  AstGrupos.Add(StmtGrupo);

  try
    OutputDir := ParamStr(1);
    DefineAst(OutputDir, AstGrupos);
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
