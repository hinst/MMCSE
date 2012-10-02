unit M2100MessageDecoder;

{ $DEFINE DEBUG_LOG_MESSAGE_DECODING_STAGES}

interface

uses
  SysUtils,
  Classes,
  Contnrs,

  CustomLogEntity,
  EmptyLogEntity,

  UStreamUtilities,
  M2100Command,
  M2100Message,
  mmcse_common;

type

  { TM2100MessageDecoder }

  EM2100MessageDecoder = class(EM2100Message);

  TM2100MessageDecoder = class
  public
      // instance does not owns the aStream
    constructor Create(const aStream: TStream);
  private
    fLog: TCustomLog;
    fStream: TStream;
    fMessage: TM2100Message;
    function ReadLength(out aDoubleLength: boolean): integer;
    {$REGION reading routine}
    procedure ReadSTX;
    procedure ReadMessageLength;
    procedure ReadCommands;
    procedure ReadSubCommands(const aCommand: TM2100Command);
      // aLeft: how much data left in the current command
    function ReadSubCommand(const aId: byte; const aLeft: integer): TM2100SubCommand; overload;
    procedure ReadSubCommand(const aCommand: TM2100SubCommand; const aLeft: integer); overload;
    procedure ReadCheckSum;
    {$ENDREGION}
    function EvaluateCheckSum: byte;
    procedure AssertCheckSumCorrect;
    procedure LogDecoding(const aText: string);
    procedure ReplaceLog(const aLog: TCustomLog);
  public
      // owns the Log
    property Log: TCustomLog read fLog write ReplaceLog;
    property Stream: TStream read fStream;
      // does not owns the Msg
    property Msg: TM2100Message read fMessage;
    procedure Decode; overload;
    class function Decode(const aStream: TStream): TM2100Message; overload;
    destructor Destroy; override;
  end;

  EM2100MessageDecoderCheckSumIncorrect = class(EM2100MessageDecoder)
  public
    constructor Create(const aDeclared, aActual: byte);
  private
    fActual, fDeclared: byte;
  public
    property Actual: byte read fActual;
    property Declared: byte read fDeclared;
  end;

implementation

constructor TM2100MessageDecoder.Create(const aStream: TStream);
begin
  inherited Create;
  fLog := TEmptyLog.Create;
  fStream := aStream;
  fMessage := TM2100Message.Create
end;

function TM2100MessageDecoder.ReadLength(out aDoubleLength: boolean): integer;
var
  lengthA, lengthB: byte;
begin
  lengthA := 0;
  lengthB := 0;
  Stream.ReadBuffer(lengthA, 1);
  aDoubleLength := (lengthA and $80) = 0;
  if aDoubleLength then
  begin
    Stream.ReadBuffer(lengthB, 1);
    result := lengthB + integer(lengthA) shl 8;
  end
  else
    result := lengthA xor $80;
end;

procedure TM2100MessageDecoder.Decode;
begin
  ReadSTX;
  if Msg.IsAcknowledged then
    exit;
  ReadMessageLength;
  ReadCommands;
  ReadCheckSum;
  AssertCheckSumCorrect;
end;

procedure TM2100MessageDecoder.ReadSTX;
begin
  Stream.ReadBuffer(Msg.STX, 1);
end;

procedure TM2100MessageDecoder.ReadMessageLength;
begin
  Msg.Length := ReadLength(Msg.IsDoubleLength);
  LogDecoding('Message length is ' + IntToStr(Msg.Length)
    + '; DL is ' + BoolToStr(Msg.IsDoubleLength, true));
end;

procedure TM2100MessageDecoder.ReadCommands;
var
  command: TM2100Command;
  initialPosition: integer;
begin
  initialPosition := Stream.Position;
  LogDecoding('Now reading commands...');
  while Stream.Position - initialPosition < Msg.Length do
  begin
    command := TM2100Command.Create;
    Stream.ReadBuffer(command.CommandClass, 1);
    LogDecoding('Command class is $' + IntToHex(command.CommandClass, 2));
    command.Length := ReadLength(command.IsDoubleLength);
    LogDecoding('Command length is ' + IntToStr(command.Length)
      + '; DL = ' + BoolToStr(command.IsDoubleLength));
    if command.Length > 0 then
      ReadSubCommands(command);
    Msg.Commands.Add(command);
  end;
  LogDecoding('Reading commands - finished.');
end;

procedure TM2100MessageDecoder.ReadSubCommands(const aCommand: TM2100Command);
var
  initialPosition: integer;
  subCommand: TM2100SubCommand;
  subCommandId: byte;
begin
  LogDecoding('Now decoding subcommands...');
  initialPosition := Stream.Position;
  while Stream.Position - initialPosition < aCommand.Length do
  begin
    subCommandId := 0;
    Stream.ReadBuffer(subCommandId, 1);
    subCommand := ReadSubCommand(subCommandId,
      aCommand.Length - (Stream.Position - initialPosition));
    aCommand.SubCommands.Add(subCommand);
    LogDecoding('Subcommand decoded.');
  end;
end;

function TM2100MessageDecoder.ReadSubCommand(const aId: byte; const aLeft: integer)
  : TM2100SubCommand;
begin
  result := TM2100SubCommand.Construct(aId);
  ReadSubCommand(result, aLeft);
end;

procedure TM2100MessageDecoder.ReadSubCommand(const aCommand: TM2100SubCommand;
  const aLeft: integer);
begin
  if aCommand is TM2100SubCommandUnknown then
    (aCommand as TM2100SubCommandUnknown).UnknownData.Size := aLeft;
  aCommand.LoadFromStream(Stream);
end;

procedure TM2100MessageDecoder.ReplaceLog(const aLog: TCustomLog);
begin
  Log.Free;
  fLog := aLog;
end;

procedure TM2100MessageDecoder.ReadCheckSum;
begin
  LogDecoding('Now reading checksum...');
  Stream.ReadBuffer(Msg.CheckSum, 1);
  LogDecoding('Checksum is $' + IntToHex(Msg.CheckSum, 2));
end;

function TM2100MessageDecoder.EvaluateCheckSum: byte;
var
  currentByte: byte;
  sum: integer;
begin
  sum := 0;
  Stream.Seek(1, soBeginning);
  while Stream.Position < Stream.Size - 1 do
  begin
    Stream.ReadBuffer(currentByte, 1);
    sum := (sum + currentByte) and $00FF;
  end;
  result := TM2100Message.TwosComponent(sum);
end;

procedure TM2100MessageDecoder.AssertCheckSumCorrect;
var
  declared, actual: byte;
begin
  declared := Msg.CheckSum;
  actual := EvaluateCheckSum;
  if declared <> actual then
    raise EM2100MessageDecoderCheckSumIncorrect.Create(declared, actual);
end;

procedure TM2100MessageDecoder.LogDecoding(const aText: string);
var
  text: string;
begin
  {$IFDEF DEBUG_LOG_MESSAGE_DECODING_STAGES}
  text := aText + ' @' + IntToStr(Stream.Position);
  Log.Write(text);
  {$ENDIF}
end;

class function TM2100MessageDecoder.Decode(const aStream: TStream): TM2100Message;
var
  decoder: TM2100MessageDecoder;
begin
  decoder := TM2100MessageDecoder.Create(aStream);
  try
    decoder.Decode;
    result := decoder.Msg;
  finally
    decoder.Free;
  end;
end;

destructor TM2100MessageDecoder.Destroy;
begin
  FreeAndNil(fLog);
  inherited;
end;

constructor EM2100MessageDecoderCheckSumIncorrect.Create(const aDeclared, aActual: byte);
begin
  inherited Create('');
  fActual := aActual;
  fDeclared := aDeclared;
  Message := 'Actual: $' + IntToHex(Actual, 2) + ' = ' + IntToHex(Declared, 2) + '$ :declared';
end;

end.
