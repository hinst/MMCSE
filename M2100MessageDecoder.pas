unit M2100MessageDecoder;

{ $DEFINE DEBUG_LOG_MESSAGE_DECODING_STAGES}

interface

uses
  SysUtils,
  Classes,
  Contnrs,

  CustomLogEntity,
  DefaultLogEntity,
  EmptyLogEntity,

  UStreamUtilities,
  M2100Command,
  M2100Message,
  mmcse_common;

type

  { TM2100MessageDecoder }

  TM2100MessageDecoder = class
  public
      // does not owns the stream
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
    function ReadSubCommand(const aId: byte): TM2100SubCommand;
    procedure ReadCheckSum;
    {$ENDREGION}
    procedure LogDecoding(const aText: string);
    procedure ReplaceLog(const aLog: TCustomLog);
  public
    property Log: TCustomLog read fLog write ReplaceLog;
    property Stream: TStream read fStream;
    property Msg: TM2100Message read fMessage;
    procedure Decode; overload;
    class function Decode(const aStream: TStream): TM2100Message; overload;
  end;

  EM2100Message = class(Exception);

implementation

function M2100ReadLength(const aStream: TStream; out aDoubleLength: boolean): integer;
var
  lengthA, lengthB: byte;
begin
  lengthA := 0;
  lengthB := 0;
  aStream.ReadBuffer(lengthA, 1);
  aDoubleLength := (lengthA and $80) = 0;
  if aDoubleLength then
  begin
    aStream.ReadBuffer(lengthB, 1);
    result := lengthB + integer(lengthA) shl 8;
  end
  else
    result := lengthA xor $80;
end;

constructor TM2100MessageDecoder.Create(const aStream: TStream);
begin
  inherited Create;
  fLog := TEmptyLog.Create;
  fStream := aStream;
  fMessage := TM2100Message.Create
end;

function TM2100MessageDecoder.ReadLength(out aDoubleLength: boolean): integer;
begin
  result := M2100ReadLength(Stream, aDoubleLength);
end;

procedure TM2100MessageDecoder.Decode;
begin
  ReadSTX;
  ReadMessageLength;
  ReadCommands;
  ReadCheckSum;
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
    subCommand := ReadSubCommand(subCommandId);
    aCommand.SubCommands.Add(subCommand);
    LogDecoding('Subcommand decoded.');
  end;
end;

procedure TM2100MessageDecoder.ReplaceLog(const aLog: TCustomLog);
begin
  Log.Free;
  fLog := aLog;
end;

function TM2100MessageDecoder.ReadSubCommand(const aId: byte): TM2100SubCommand;
begin
  result := TM2100SubCommand.Construct(aId);
  if result = nil then
    result := TM2100SubCommand.Create(aId)
  else
    result.LoadFromStream(Stream);
end;

procedure TM2100MessageDecoder.ReadCheckSum;
begin
  LogDecoding('Now reading checksum...');
  Stream.ReadBuffer(Msg.CheckSum, 1);
  LogDecoding('Checksum is $' + IntToHex(Msg.CheckSum, 2));
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
  result := nil;
  decoder := nil;
  try
    decoder := TM2100MessageDecoder.Create(aStream);
    decoder.Log := TLog.Create(GlobalLogManager, 'Decoder');
    decoder.Decode;
    result := decoder.Msg;
    decoder.Free;
  except
    decoder.Log.Write('Exception while decoding...');
    decoder.Log := nil;
  end;
end;

end.
