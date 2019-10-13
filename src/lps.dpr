// Marcello Mello
// 28/09/2019
// LPS (Linguagem de programação Se7e)
// Lets go

program lps;

uses
  VCL.Dialogs,
  System.SysUtils,
  lps.runner in 'lps.runner.pas',
  lps.types in 'lps.types.pas',
  lps.scanner in 'lps.scanner.pas',
  lps.utils in 'lps.utils.pas',
  lps.parser in 'lps.parser.pas',
  lps.interpreter in 'lps.interpreter.pas',
  lps.ast in 'lps.ast.pas',
  lps.env in 'lps.env.pas',
  lps.resolver in 'lps.resolver.pas';

var
  SSLangRun: TSSLangRunner;
  Script: string;
begin
  ReportMemoryLeaksOnShutdown := True;

  Script := '                                                              ' + sLineBreak +
            '                                                              ' + sLineBreak +
            'class TRosquinha {                                            ' + sLineBreak +
            '                                                              ' + sLineBreak +
            '  cozinhar() {                                                ' + sLineBreak +
            '    print "Frite ateh dourar.";                               ' + sLineBreak +
            '  }                                                           ' + sLineBreak +
            '                                                              ' + sLineBreak +
            '  init() {                                             ' + sLineBreak +
            '    print "construido rosquinha.";                                      ' + sLineBreak +
            '  }                                                           ' + sLineBreak +
            '                                                              ' + sLineBreak +
            '}                                                             ' + sLineBreak +
            '                                                              ' + sLineBreak +
            '                                                              ' + sLineBreak +
            'class TCremeDeBoston < TRosquinha {                      ' + sLineBreak +
            '                                                              ' + sLineBreak +
            '                                                              ' + sLineBreak +
            '  cozinhar() {                                                ' + sLineBreak +
            '    super.cozinhar();                                         ' + sLineBreak +
            '    print "Tubo cheio de creme com chocolate.";               ' + sLineBreak +
            '  }                                                           ' + sLineBreak +
            '                                                              ' + sLineBreak +
            '                                                              ' + sLineBreak +
            '  init() {                                             ' + sLineBreak +
            '    super.init();                                         ' + sLineBreak +
            '    print "construido cremedeboston.";                                      ' + sLineBreak +
            '  }                                                           ' + sLineBreak +
            '                                                              ' + sLineBreak +
            '                                                              ' + sLineBreak +
            '}                                                             ' + sLineBreak +
            '                                                              ' + sLineBreak +
            '                                                              ' + sLineBreak +
            'var creme = TCremeDeBoston();                             ' + sLineBreak +
            'creme.cozinhar();                                             ' + sLineBreak +
            '                                                              ' + sLineBreak +
            '                                                              ' + sLineBreak +
            '                                                              ' + sLineBreak +
            '                                                              ' + sLineBreak +
            '                                                              ' + sLineBreak +
            '                                                              ' + sLineBreak +
            '                                                              ';
























  Script := 'var i = 0;                                     ' + sLineBreak +
            'while (true)                                   ' + sLineBreak +
            '{                                              ' + sLineBreak +
            '	i = i + 1;                                    ' + sLineBreak +
            '                                               ' + sLineBreak +
            '	print i;                                      ' + sLineBreak +
            '                                               ' + sLineBreak +
            '	if (i > 10)                                   ' + sLineBreak +
            '	{                                             ' + sLineBreak +
            '		print "breaking";                           ' + sLineBreak +
            '		break;                                      ' + sLineBreak +
            '	}                                             ' + sLineBreak +
            '                                               ' + sLineBreak +
            '	if (i > 5)                                    ' + sLineBreak +
            '	{                                             ' + sLineBreak +
            '		print "continuing";                         ' + sLineBreak +
            '		continue();                                   ' + sLineBreak +
            '	}                                             ' + sLineBreak +
            '                                               ' + sLineBreak +
            '	print "looping";                              ' + sLineBreak +
            '}                                              ' + sLineBreak +
            '                                               ' + sLineBreak +
            'print "Complete";                              ' + sLineBreak +
            '                                               ' + sLineBreak +
            '                                               ';

  Script := ' var i = 10;               ' + sLineBreak +
            ' do {                      ' + sLineBreak +
            '    print i;                ' + sLineBreak +
            ' 	 i = i - 1;              ' + sLineBreak +
            ' } while (i > 0);          ' + sLineBreak +
            '                           ' + sLineBreak +
            ' print "Complete";         ' + sLineBreak +
            '                           ' + sLineBreak +
            '                           ';

  Script := ' var i = 10;                  ' + sLineBreak +
            ' print i + 10 + " Complete";  ' + sLineBreak +
            '                              ' + sLineBreak +
            '                              ';


  SSLangRun := TSSLangRunner.Create();
  SSLangRun.RunScript(Script);
  SSLangRun.Free();
  Exit();


  if (ParamCount > 1) then
  begin
    Writeln('Uso: lps [script]');
    Halt(0);
  end
  else if (ParamCount = 1) then
  begin
    SSLangRun := TSSLangRunner.Create();
    SSLangRun.RunFile(ParamStr(1));
    SSLangRun.Free();
  end;

end.
