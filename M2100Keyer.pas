unit M2100Keyer;

interface

uses
  SysUtils,
  Contnrs,

  UMath,
  UTextUtilities,
  UAdditionalExceptions,
  UAdvancedByte;

type
  TM2100KeyersStatus = class(TByte)
  public const
    Count = 5;
    Keyer1 = 0;
    Keyer2 = 1;
    Keyer3 = 2;
    Keyer4 = 3;
    SqueezeBack = 4;
  protected
    function GetBitName(const aIndex: integer): string; override;
    function GetCountOfBits: integer; override;
  public
    procedure SetDefault;
  end;

  TM2100TriggerMod = class(TByte)
  public const
    Count = 4;
    StartVideo = 0;
    StartAudio = 1;
    InhibitStartRelays = 2;
    ZeroPreroll = 3;
  protected
    function GetBitName(const aIndex: integer): string; override;
    function GetCountOfBits: integer; override;
  end;


implementation

function TM2100KeyersStatus.GetBitName(const aIndex: integer): string;
begin
  case aIndex of
    Keyer1: result := 'Keyer1';
    Keyer2: result := 'Keyer2';
    Keyer3: result := 'Keyer3';
    Keyer4: result := 'Keyer4';
    SqueezeBack: result := 'SqueezeBack';
    else result := inherited GetBitName(aIndex);
  end;
end;

function TM2100KeyersStatus.GetCountOfBits: integer;
begin
  result := COUNT;
end;

procedure TM2100KeyersStatus.SetDefault;
begin
  // включены по умолчанию:
  Bits[Keyer1] := true;
  Bits[Keyer2] := true;
  Bits[Keyer3] := true;
  Bits[Keyer4] := true;
  // а этот выключен:
  Bits[SqueezeBack] := false;
end;


function TM2100TriggerMod.GetBitName(const aIndex: integer): string;
begin
  case aIndex of
    StartVideo: result := 'StartVideo';
    StartAudio: result := 'StartAudio';
    InhibitStartRelays: result := 'InhibitStartRelays';
    ZeroPreroll: result := 'ZeroPreroll';
    else result := inherited GetBitName(aIndex);
  end;
end;

function TM2100TriggerMod.GetCountOfBits: integer;
begin
  result := Count;
end;


end.
