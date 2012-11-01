unit M2100Command;

{ $DEFINE DEBUG_INCLUDE_HEXREP_XPT_TAKE_BUS}
{ $DEFINE INCLUDE_SUBCOMMAND_CLASSNAME_TR}
{ $DEFINE INCLUDE_COMMAND_CLASS_HEXREPRESENTATION}

interface

uses
  SysUtils,
  Classes,
  Contnrs,

  UStreamUtilities,

  M2100Keyer;

type
  TM2100SubCommandClass = class of TM2100SubCommand;

  TM2100SubCommand = class
  public
    constructor Create(const aId: byte); virtual;
  public
    id: byte;
    class function Construct(const aCommandClass, aCommandId: byte): TM2100SubCommand;
    class function GetClass(const aCommandClass, aCommandId: byte): TM2100SubCommandClass;
    class function TX_TYPE: byte; // HEX 03
    class function XPT_TAKE: byte; // HEX 06
    class function OVER_SELECT: byte; // HEX 08
    class function KEY_ENABLE: byte; // HEX 0B
    class function KEY_STAT: byte; // HEX OC
    class function AUTO_STAT: byte; // HEX 0D
    procedure LoadFromStream(const aStream: TStream); virtual; abstract;
    procedure SaveToStream(const aStream: TStream); virtual; abstract;
    function IdToText: string;
    function IdToTextFull: string; virtual;
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
    function IdToTextFull: string; override;
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

  // HEX 03
  TM2100SubCommandTxType = class(TM2100SubCommand)
  protected
    fTran: byte;
  public
    property Tran: byte read fTran;
    procedure LoadFromStream(const aStream: TStream); override;
    function DataToText: string; override;
  end;

  // HEX 06
  TM2100SubCommandXptTake = class(TM2100SubCommand)
  protected
    fBus: word;
    fCrosspoint: byte;
    fAudioOnlyCrosspoint: byte;
    function BusToText: string;
  public
    property Bus: word read fBus;
    property Crosspoint: byte read fCrosspoint;
    property AudioOnlyCrosspoint: byte read fAudioOnlyCrosspoint;
    procedure LoadFromStream(const aStream: TStream); override;
    function DataToText: string; override;
  end;

  // HEX 08
  TM2100SubQueryOverSelect = class(TM2100SubCommand)
  protected
    fBus: word;
  public
    property Bus: word read fBus;
    procedure LoadFromStream(const aStream: TStream); override;
  end;

  TM2100SubCommandOverSelect = class(TM2100SubQueryOverSelect)
  protected
    fOver: byte;
    property Over: byte read fOver;
    procedure LoadFromStream(const aStream: TStream); override;
    function DataToText: string; override;
  end;

  // HEX OB
  TM2100SubQueryKeyEnable = class(TM2100SubCommand)
  public
    procedure LoadFromStream(const aStream: TStream); override;
  end;

  TM2100SubCommandKeyEnable = class(TM2100SubQueryKeyEnable)
  public
    constructor Create(const aId: byte); override;
  protected
    fKeyers: TM2100KeyersStatus;
  public
    property Keyers: TM2100KeyersStatus read fKeyers;
    procedure LoadFromStream(const aStream: TStream); override;
    function DataToText: string; override;
    destructor Destroy; override;
  end;

  // HEX OC
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

  // HEX OD
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

class function TM2100SubCommand.Construct(const aCommandClass, aCommandId: byte): TM2100SubCommand;
var
  resultClass: TM2100SubCommandClass;
begin
  resultClass := GetClass(aCommandClass, aCommandId);
  result := resultClass.Create(aCommandId);
end;

class function TM2100SubCommand.GetClass(const aCommandClass, aCommandId: byte)
  : TM2100SubCommandClass;
begin
  result := TM2100SubCommandUnknown;
  if aCommandId = TX_TYPE then
    result := TM2100SubCommandTxType;
  if aCommandId = XPT_TAKE then
    result := TM2100SubCommandXptTake;
  if aCommandId = OVER_SELECT then
  begin
    if aCommandClass = M2100MessageCommandClass_QUERY then
      result := TM2100SubQueryOverSelect;
    if aCommandClass = M2100MessageCommandClass_CMD then
      result := TM2100SubCommandOverSelect;
  end;
  if aCommandId = KEY_ENABLE then
  begin
    if aCommandClass = M2100MessageCommandClass_QUERY then
      result := TM2100SubQueryKeyEnable;
    if aCommandClass = M2100MessageCommandClass_CMD then
      result := TM2100SubCommandKeyEnable;
  end;
  if aCommandId = KEY_STAT then
    result := TM2100SubCommandKeyStat;
  if aCommandId = AUTO_STAT then
    result := TM2100SubCommandAutoStat;
  if result = nil then
    result := TM2100SubCommandUnknown;
end;

function TM2100SubCommand.IdToText: string;
begin
  result := 'UNKNOWN';
  if id = TX_TYPE then
    result := 'TX_TYPE';
  if id = XPT_TAKE then
    result := 'XPT_TAKE';
  if id = OVER_SELECT then
    result := 'OVER_SELECT';
  if id = KEY_ENABLE then
    result := 'KEY_ENABLE';
  if id = KEY_STAT then
    result := 'KEY_STAT';
  if id = AUTO_STAT then
    result := 'AUTO_STAT';
end;

function TM2100SubCommand.IdToTextFull: string;
begin
  result := IdToText;
end;

function TM2100SubCommand.DataToText: string;
begin
  result := '';
end;

function TM2100SubCommand.ToText: string;
var
  dataAsText: string;
begin
  dataAsText := DataToText;

  result := '[';
  {$IFDEF INCLUDE_SUBCOMMAND_CLASSNAME_TR}
  result := result + ClassName + ' ';
  {$ENDIF}
  result := result + IdToTextFull;
  if dataAsText <> '' then
    result := result + ' ' + dataAsText;
  result := result + ']';
end;

class function TM2100SubCommand.TX_TYPE: byte;
begin
  result := $03;
end;

class function TM2100SubCommand.XPT_TAKE: byte;
begin
  result := $06;
end;

class function TM2100SubCommand.OVER_SELECT: byte;
begin
  result := $08;
end;

class function TM2100SubCommand.KEY_ENABLE: byte;
begin
  result := $0B;
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
  {$IFDEF INCLUDE_COMMAND_CLASS_HEXREPRESENTATION}
  result := result + '$' + IntToHex(CommandClass, 2);
  {$ENDIF}
  result := result + '' + CommandClassToText(CommandClass) + '';
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


function TM2100SubCommandUnknown.IdToTextFull: string;
begin
  result := '$' + IntToHex(id, 2);
end;

procedure TM2100SubCommandTxType.LoadFromStream(const aStream: TStream);
begin
  aStream.ReadBuffer(fTran, 1);
end;

function TM2100SubCommandTxType.DataToText: string;
begin
  result := 'tran: ' + IntToStr(Tran);
end;


function M2100BusPositionToText(const aBus: byte): string;
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

function M2100BusToText(const aBus: word): string;
var
  i: integer;
  b: word;
begin
  result := 'Bus: ';
  b := aBus;
  for i := 0 to SizeOf(b)*8 - 1 do
  begin
    if (b and 1) = 1 then
      result := result + M2100BusPositionToText(i) + ', ';
    b := b shr 1;
  end;
  RemoveTrailing(result, ', ');
  result := result + '.';
end;

function TM2100SubCommandXptTake.BusToText: string;
begin
  result := M2100BusToText(Bus);
end;

procedure TM2100SubCommandXptTake.LoadFromStream(const aStream: TStream);
begin
  aStream.ReadBuffer(fBus, 2);
  ReverseWord(fBus);
  aStream.ReadBuffer(fCrosspoint, 1);
  aStream.ReadBuffer(fAudioOnlyCrosspoint, 1);
end;

function TM2100SubCommandXptTake.DataToText: string;
begin
  result := '';
  {$IFDEF DEBUG_INCLUDE_HEXREP_XPT_TAKE_BUS}
  result := result + '$' + IntToHex(Bus, 4) + '_';
  {$ENDIF}
  result := result + BusToText;
end;


procedure TM2100SubQueryOverSelect.LoadFromStream(const aStream: TStream);
begin
  aStream.ReadBuffer(fBus, 2);
  ReverseWord(fBus);
end;


procedure TM2100SubCommandOverSelect.LoadFromStream(const aStream: TStream);
begin
  inherited LoadFromStream(aStream);
  aStream.ReadBuffer(fOver, 1);
end;

function TM2100SubCommandOverSelect.DataToText: string;
begin
  result := '';
  result := result + M2100BusToText(Bus);
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


procedure TM2100SubQueryKeyEnable.LoadFromStream(const aStream: TStream);
begin
  // no data
end;


constructor TM2100SubCommandKeyEnable.Create(const aId: byte);
begin
  inherited Create(aId);
  fKeyers := TM2100KeyersStatus.Create;
end;

procedure TM2100SubCommandKeyEnable.LoadFromStream(const aStream: TStream);
var
  keyersStatus: byte;
begin
  inherited LoadFromStream(aStream);
  aStream.ReadBuffer(keyersStatus, 1);
  Keyers.AsByte := keyersStatus;
end;


function TM2100SubCommandKeyEnable.DataToText: string;
begin
  result := Keyers.ToText;
end;

destructor TM2100SubCommandKeyEnable.Destroy;
begin
  FreeAndNil(fKeyers);
  inherited Destroy;
end;


procedure TM2100SubCommandAutoStat.LoadFromStream(const aStream: TStream);
begin
  // no data
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


end.






