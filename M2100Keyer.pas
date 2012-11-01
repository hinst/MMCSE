unit M2100Keyer;

interface

uses
  SysUtils,
  Contnrs,

  UMath,
  UTextUtilities,
  UAdditionalExceptions;

type
  TM2100KeyersStatus = class
  public const
    COUNT = 5;
    Keyer1 = 0;
    Keyer2 = 1;
    Keyer3 = 2;
    Keyer4 = 4;
    SqueezeBack = 5;
  protected
    fKeyers: byte;
    function GetKeyer(const aIndex: integer): boolean;
    procedure SetKeyer(const aIndex: integer; const aStatus: boolean);
    procedure AssertKeyerIndex(const aIndex: integer);
  public
    procedure SetDefault;
    property Keyers[const aIndex: integer]: boolean read GetKeyer write SetKeyer;
    property AsByte: byte read fKeyers write fKeyers;
    function ToText: string;
  end;


implementation

function TM2100KeyersStatus.GetKeyer(const aIndex: integer): boolean;
begin
  AssertKeyerIndex(aIndex);
  result := GetBit(fKeyers, aIndex);
end;

procedure TM2100KeyersStatus.SetDefault;
var
  i: integer;
begin
  for i := Keyer1 to Keyer4 do
    Keyers[i] := true;
end;

procedure TM2100KeyersStatus.SetKeyer(const aIndex: integer; const aStatus: boolean);
begin
  AssertKeyerIndex(aIndex);
  SetBit(fKeyers, aIndex, aStatus);
end;

procedure TM2100KeyersStatus.AssertKeyerIndex(const aIndex: integer);
begin
  AssertKeyerIndex(aIndex);
end;

function TM2100KeyersStatus.ToText: string;
var
  i: integer;
begin
  result := '';
  for i := Keyer1 to Keyer4 do
    if Keyers[i] then
      result := result + 'Keyer ' + IntToStr(i) + ', ';
  if Keyers[SqueezeBack] then
    result := result + 'SqueezeBack';
  ExcludeEnding(result, ', ');
end;

end.
