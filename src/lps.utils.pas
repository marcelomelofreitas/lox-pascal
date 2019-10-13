// Marcello Mello
// 28/09/2019

unit lps.utils;

interface

uses
  Classes,
  Generics.Collections,
  lps.types;

type

  TEnumConversor<T: record> = class
  public
    class function ToString(const Enum: T): string; reintroduce; overload;
    class function ToEnum(const Str: string): T;
    class function ToEnumDef(const Str: string; const Default: T): T;
  end;

function IfThen(AValue: Boolean; const ATrue: TTokenType; const AFalse: TTokenType): TTokenType; overload; inline;

implementation

uses
  SysUtils,
  TypInfo;

function IfThen(AValue: Boolean; const ATrue: TTokenType; const AFalse: TTokenType): TTokenType; overload; inline;
begin
  if AValue then
    Result := ATrue
  else
    Result := AFalse;

end;

{ TEnumConversor }

class function TEnumConversor<T>.ToEnum(const Str: string): T;
var
  P: ^T;
  num: Integer;
begin
  try
    num := GetEnumValue(TypeInfo(T), Str);
    if num = -1 then
      abort;

    P := @num;
    result := P^;
  except
    raise EConvertError.Create('O Parâmetro "' + Str + '" passado não ' +
      sLineBreak + ' corresponde a um Tipo Enumerado ' + GetTypeName(TypeInfo(T)));
  end;
end;

class function TEnumConversor<T>.ToEnumDef(const Str: string; const Default: T): T;
var
  P: ^T;
  num: Integer;
begin
  try
    num := GetEnumValue(TypeInfo(T), Str);
    if num = -1 then
      abort;

    P := @num;
    result := P^;
  except
    Result := Default;
  end;
end;

class function TEnumConversor<T>.ToString(const Enum: T): string;

type
  TGenerico = 0..255;

var
  P: PInteger;
  num: Integer;
begin

  try
    P := @Enum;
    num := Integer(TGenerico((P^)));
    result := GetEnumName(TypeInfo(T), num);
  except
    raise EConvertError.Create('O Parâmetro passado não corresponde a ' +
      sLineBreak + 'Ou a um Tipo Enumerado ' + GetTypeName(TypeInfo(T)));
  end;
end;

end.
