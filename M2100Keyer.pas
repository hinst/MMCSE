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
    Keyer4 = 3;
    SqueezeBack = 4;
  protected
    fKeyers: byte;
    function GetKeyer(const aIndex: integer): boolean;
    procedure SetKeyer(const aIndex: integer; const aStatus: boolean);
    function GetCountOfEnabled: byte;
    procedure AssertKeyerIndex(const aIndex: integer);
  public
    procedure SetDefault;
    property AsByte: byte read fKeyers write fKeyers;
    property Keyers[const aIndex: integer]: boolean read GetKeyer write SetKeyer;
    property CountOfEnabled: byte read GEtCountOfEnabled;
    function ToText: string;
  end;


implementation

function TM2100KeyersStatus.GetKeyer(const aIndex: integer): boolean;
begin
  AssertKeyerIndex(aIndex);
  result := GetBit(fKeyers, aIndex);
end;

procedure TM2100KeyersStatus.SetDefault;
begin
  // включены по умолчанию:
  Keyers[Keyer1] := true;
  Keyers[Keyer2] := true;
  Keyers[Keyer3] := true;
  Keyers[Keyer4] := true;
  // а этот выключен:
  Keyers[SqueezeBack] := false;
end;

procedure TM2100KeyersStatus.SetKeyer(const aIndex: integer; const aStatus: boolean);
begin
  AssertKeyerIndex(aIndex);
  SetBit(fKeyers, aIndex, aStatus);
end;

function TM2100KeyersStatus.GetCountOfEnabled: byte;
var
  i: integer;
begin
  result := 0;
  for i := 0 to COUNT - 1 do
    if Keyers[i] then
      result := result + 1;
end;

procedure TM2100KeyersStatus.AssertKeyerIndex(const aIndex: integer);
begin
  AssertIndex(0, aIndex, COUNT - 1);
end;

function TM2100KeyersStatus.ToText: string;
var
  i: integer;
begin
  if CountOfEnabled = 0 then
    result := 'no keyers enabled'
  else
  begin
    result := '';
    for i := Keyer1 to Keyer4 do
      if Keyers[i] then
        result := result + 'Keyer ' + IntToStr(i) + ', ';
    if Keyers[SqueezeBack] then
      result := result + 'SqueezeBack';
    ExcludeEnding(result, ', ');
  end;
end;

end.
