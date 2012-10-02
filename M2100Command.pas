unit M2100Command;

{ $DEFINE DEBUG_INCLUDE_HEXREP_XPT_TAKE_BUS}

interface

uses
  SysUtils,
  Classes,
  Contnrs,

  UStreamUtilities;

type
  TM2100SubCommand = class
  public
    constructor Create(const aId: byte); virtual;
  public
    id: byte;
    class function Construct(const aId: byte): TM2100SubCommand;
    class function XPT_TAKE: byte;
    class function KEY_STAT: byte;
    class function AUTO_STAT: byte;
    procedure LoadFromStream(const aStream: TStream); virtual; abstract;
    procedure SaveToStream(const aStream: TStream); virtual; abstract;
    function IdToText: string;
    function IdToTextFull: string;
    function DataToText: string; virtual;
    function ToText: string; virtual;
  end;

  TM2100SubCommandUnknown = class(TM2100SubCommand)
  public
    constructor Create(const aId: byte); override;
  private
    fUnknownData: TStream;
  public
    property UnknownData: TStream read fUnknownData;
    procedure LoadFromStream(const aStream: TStream); override;
    function DataToText: string; override;
    destructor Destroy; override;
  end;

  TM2100Command = class
  public
    constructor Create; virtual;
  public
    CommandClass: byte;
    IsDoubleLength: boolean;
    Length: integer;
    SubCommands: TObjectList;
    UnknownData: TStream;
    class function CommandClassToText(const aCommandClass: byte): string;
    function SubCommandsToText: string;
    function ToText: string; overload;
    destructor Destroy; override;
  end;

  TM2100SubCommandXptTake = class(TM2100SubCommand)
  protected
    fBus: word;
    fCrosspoint: byte;
    fAudioOnlyCrosspoint: byte;
    class function BusPositionToText(const aBus: byte): string;
    function BusToText: string;
  public
    property Bus: word read fBus;
    property Crosspoint: byte read fCrosspoint;
    property AudioOnlyCrosspoint: byte read fAudioOnlyCrosspoint;
    procedure LoadFromStream(const aStream: TStream); override;
    function DataToText: string; override;
  end;

  TM2100SubCommandKeyStat = class(TM2100SubCommand)
  public
    procedure LoadFromStream(const aStream: TStream); override;
  end;

  TM2100SubCommandKeyStatAnswer = class(TM2100SubCommand)
  public
    constructor Create(const aStatus: byte);
  private
    fStatus: byte;
  public
    property Status: byte read fStatus;
    procedure SaveToStream(const aStream: TStream); override;
  end;

  TM2100SubCommandAutoStat = class(TM2100SubCommand)
  public
    procedure LoadFromStream(const aStream: TStream); override;
  end;

  TM2100SubCommandAutoStatAnswer = class(TM2100SubCommand)
  public
    constructor Create(const aStatus: boolean);
  private
    fStatus: boolean;
  public
    property Status: boolean read fStatus;
    procedure SaveToStream(const aStream: TStream); override;
    function DataToText: string; override;
  end;

const
  M2100MessageCommandClass_CMD = $01;
  M2100MessageCommandClass_QUERY = $02;
  M2100MessageCommandClass_STATUS = $03;
  M2100MessageCommandClass_SUBSCRIPTION = $04;
  M2100MessageCommandClass_ACKNOWLEDGED: byte = $04;

implementation

constructor TM2100SubCommand.Create(const aId: byte);
begin
  inherited Create;
  id := aId;
end;

class function TM2100SubCommand.Construct(const aId: byte): TM2100SubCommand;
begin
  result := nil;
  if aId = XPT_TAKE then
    result := TM2100SubCommandXptTake.Create(aId);
  if aId = KEY_STAT then
    result := TM2100SubCommandKeyStat.Create(aId);
  if aId = AUTO_STAT then
    result := TM2100SubCommandAutoStat.Create(aId);
  if result = nil then
    result := TM2100SubCommandUnknown.Create(aId);
end;

function TM2100SubCommand.IdToText: string;
begin
  result := 'UNKNOWN';
  if id = XPT_TAKE then
    result := 'XPT_TAKE';
  if id = KEY_STAT then
    result := 'KEY_STAT';
  if id = AUTO_STAT then
    result := 'AUTO_STAT';
end;

function TM2100SubCommand.IdToTextFull: string;
begin
  result := '$' + IntToHex(id, 2) + '''' + IdToText + '''';
end;

function TM2100SubCommand.DataToText: string;
begin
  result := '';
end;

function TM2100SubCommand.ToText: string;
var
  data: string;
begin
  data := DataToText;
  result := '[' + ClassName + ' ' + IdToTextFull;
  if data <> '' then
    result := result + ' ' + data;
  result := result + ']';
end;

class function TM2100SubCommand.XPT_TAKE: byte;
begin
  result := $06;
end;

class function TM2100SubCommand.KEY_STAT: byte;
begin
  result := $0C;
end;

class function TM2100SubCommand.AUTO_STAT: byte;
begin
  result := $0D;
end;

constructor TM2100Command.Create;
begin
  inherited Create;
  SubCommands := TObjectList.Create(true);
end;

class function TM2100Command.CommandClassToText(const aCommandClass: byte): string;
begin
  result := 'UNKNOWN';
  if aCommandClass = M2100MessageCommandClass_CMD then
    result := 'CMD';
  if aCommandClass = M2100MessageCommandClass_QUERY then
    result := 'QUERY';
  if aCommandClass = M2100MessageCommandClass_STATUS then
    result := 'STATUS';
  if aCommandClass = M2100MessageCommandClass_SUBSCRIPTION then
    result := 'SUBSCRIPTION|ACK';
end;

function TM2100Command.ToText: string;
begin
  result := '(';
  result := result + '$' + IntToHex(CommandClass, 2);
  result := result + '"' + CommandClassToText(CommandClass) + '"';
  result := result + ' |' + IntToStr(Length);
  if IsDoubleLength then
    result := result + '/'
  else
    result := result + '|';
  result := result + ' ' + SubCommandsToText;  
  result := result + ')';
end;

destructor TM2100Command.Destroy;
begin
  SubCommands.Free;
  inherited Destroy;
end;

function TM2100Command.SubCommandsToText: string;
var
  i: integer;
begin
  result := '';
  for i := 0 to SubCommands.Count - 1 do
    result := result + (SubCommands[i] as TM2100SubCommand).ToText;
end;

procedure TM2100SubCommandKeyStat.LoadFromStream(const aStream: TStream);
begin
  // this command has no parameters
end;

constructor TM2100SubCommandKeyStatAnswer.Create(const aStatus: byte);
begin
  inherited Create(KEY_STAT);
  fStatus := aStatus;
end;

procedure TM2100SubCommandKeyStatAnswer.SaveToStream(const aStream: TStream);
begin
  aStream.Write(fStatus, 1);
end;

procedure TM2100SubCommandAutoStat.LoadFromStream(const aStream: TStream);
begin
end;

constructor TM2100SubCommandAutoStatAnswer.Create(const aStatus: boolean);
begin
  inherited Create(AUTO_STAT);
  fStatus := aStatus;
end;

function TM2100SubCommandAutoStatAnswer.DataToText: string;
begin
  result := BoolToStr(Status, true);
end;

procedure TM2100SubCommandAutoStatAnswer.SaveToStream(const aStream: TStream);
var
  statusByte: byte;
begin
  if Status then
    statusByte := $01
  else
    statusByte := $00;
  aStream.Write(statusByte, 1);
end;

constructor TM2100SubCommandUnknown.Create(const aId: byte);
begin
  inherited Create(aId);
  fUnknownData := TMemoryStream.Create;
end;

procedure TM2100SubCommandUnknown.LoadFromStream(const aStream: TStream);
begin
  StreamRewind(UnknownData);
  UnknownData.CopyFrom(aStream, UnknownData.Size);
end;

function TM2100SubCommandUnknown.DataToText: string;
begin
  StreamRewind(UnknownData);
  result := StreamToText(UnknownData);
end;

destructor TM2100SubCommandUnknown.Destroy;
begin
  FreeAndNil(fUnknownData);
  inherited;
end;

class function TM2100SubCommandXptTake.BusPositionToText(const aBus: byte): string;
begin
  result := 'unrecognized';
  case aBus of
      0: result := 'Program Bus';
      1: result := 'Preset Bus';
      2: result := 'Audio Processor 1';
      3: result := 'Audio Processor 2';
      4: result := 'Audio Processor 3';
      5: result := 'Audio Processor 4';
      6: result := 'Aux 1 Bus';
      7: result := 'Aux 2 Bus';
      8: result := 'Aux 3 Bus';
      9: result := 'Aux 4 Bus';
      10..15: result := 'Reserved';
  end;
  {$IFDEF DEBUG_INCLUDE_HEXREP_XPT_TAKE_BUS}
  result := result + ' #' + IntToStr(aBus);
  {$ENDIF}
end;

function TM2100SubCommandXptTake.BusToText: string;
var
  i: integer;
  b: word;
begin
  result := 'Bus: ';
  b := Bus;
  for i := 0 to SizeOf(b)*8 - 1 do
  begin
    if (b and 1) = 1 then
      result := result + BusPositionToText(i) + ', ';
    b := b shr 1;
  end;
  RemoveTrailing(result, ', ');
  result := result + '.';
end;

function TM2100SubCommandXptTake.DataToText: string;
begin
  result := '';
  {$IFDEF DEBUG_INCLUDE_HEXREP_XPT_TAKE_BUS}
  result := result + '$' + IntToHex(Bus, 4) + '_';
  {$ENDIF}
  result := result + BusToText;
end;

procedure TM2100SubCommandXptTake.LoadFromStream(const aStream: TStream);
begin
  aStream.ReadBuffer(fBus, 2);
  ReverseWord(fBus);
  aStream.ReadBuffer(fCrosspoint, 1);
  aStream.ReadBuffer(fAudioOnlyCrosspoint, 1);
end;

end.
