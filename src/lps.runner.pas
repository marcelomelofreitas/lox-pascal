// Marcello Mello
// 28/09/2019

unit lps.runner;

interface

uses
  Classes,
  VCL.Dialogs,
  System.SysUtils,
  Generics.Collections,
  lps.types,
  IOUtils;

type

  TSSLangRunner = class
  private
    FHadError: Boolean;
    procedure Error(LineNro: Integer; Msg: string);
    procedure Report(LineNro: Integer; Where, Msg: string);
    procedure Run(source: string);
    procedure ParserError(Token: TToken; Msg: string);
  public
    procedure RunFile(Path: string);
    procedure RunScript(Script: string);
    constructor Create;
  end;

implementation


uses
  lps.scanner,
  lps.parser,
  lps.ast,
  lps.interpreter,
  lps.resolver;

procedure TSSLangRunner.Report(LineNro: Integer; Where: string; Msg: string);
begin
  Writeln(Format('[Linha %d] Erro %s : %s', [LineNro, Where, Msg]));
  FHadError := True;
end;

constructor TSSLangRunner.Create;
begin

end;

procedure TSSLangRunner.Error(LineNro: Integer; Msg: string);
begin
  Report(LineNro, '', Msg);
end;

procedure TSSLangRunner.ParserError(Token: TToken; Msg: string);
begin
  Report(Token.LineNro, '', Msg);
end;

procedure TSSLangRunner.Run(source: string);
var
  Scanner: TScanner;
  Tokens: TObjectList<TToken>;
  Parser: TParser;
  Statements: TObjectList<TStatement>;
  Interpreter: IVisitor;
  Resolver: IVisitor;
begin
  FHadError := False;

  Scanner := TScanner.Create(source);
  Scanner.OnError := Error;

  Tokens := Scanner.ScanTokens();

  Parser := TParser.Create(Tokens);
  Parser.OnError := ParserError;

  Statements := Parser.Parse();

  if (FHadError) then
    Halt(64);

  Interpreter := TInterpreter.Create();

  Resolver := TResolver.Create(TInterpreter(Interpreter));
  TResolver(Resolver).Resolve(Statements);

  TInterpreter(Interpreter).Interpret(Statements);
end;

procedure TSSLangRunner.RunFile(Path: string);
begin
  Run(TFile.ReadAllText(Path));

  if (hadRuntimeError) then
    Halt(70);
end;


procedure TSSLangRunner.RunScript(Script: string);
begin
  Run(Script);
end;

end.
