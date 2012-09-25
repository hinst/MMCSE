unit M2100MessageEncoder;

interface

uses
  SysUtils,
  Classes,

  CustomLogEntity,
  EmptyLogEntity,

  M2100Message,
  M2100Command;

type
  TM2100MessageEncoder = class
  public
    constructor Create(const aMessage: TM2100Message);
  private
    fLog: TCustomLog;
    fMessage: TM2100Message;
    fStream: TStream;
    procedure SetLog(const aLog: TCustomLog);
    procedure EstimateMessageLength;
    procedure EstimateCommandLength(const aCommand: TM2100Command);
    function EstimateSubCommandLength(const aSubCommand: TM2100SubCommand): integer;
    function IsDoubleLength(const aLength: integer): boolean;
    procedure WriteLength(const aLength: integer);

    function EncodeAsAcknowledged: boolean;
    procedure WriteSTX;
    procedure WriteMessageLength;
    procedure WriteCommands;
    procedure WriteCommand(const aCommand: TM2100Command);
    procedure WriteSubCommands(const aCommand: TM2100Command);
    procedure WriteSubCommand(const aSub: TM2100SubCommand);
      // this method assigns Msg.CheckSum property
    procedure EvaluateMessageCheckSum;
      // Msg.CheckSum property should contain correct CheckSum value before this method is called
    procedure WriteMessageCheckSum;
  public
    property Log: TCustomLog write SetLog;
    property Msg: TM2100Message read fMessage;
    property Stream: TStream read fStream;
    procedure Encode; overload;
    class function Encode(const aMessage: TM2100Message): TStream; overload;
    destructor Destroy; override;
  end;

  
implementation

constructor TM2100MessageEncoder.Create(const aMessage: TM2100Message);
begin
  inherited Create;
  fLog := TEmptyLog.Create;
  fMessage := aMessage;
  fStream := TMemoryStream.Create;
end;

procedure TM2100MessageEncoder.SetLog(const aLog: TCustomLog);
begin
  FreeAndNil(fLog);
  fLog := aLog;
end;

procedure TM2100MessageEncoder.EstimateMessageLength;
var
  i: integer;
  command: TM2100Command;
begin
  Msg.Length := 0;
  for i := 0 to Msg.Commands.Count - 1 do
  begin
    command := Msg.Commands[i] as TM2100Command;
    Msg.Length := Msg.Length + 1; // +COMMAND ID: one byte
    EstimateCommandLength(command);
    {$REGION ADD COMMAND LENGTH} // +COMMAND LENGTH: one or two bytes
    Msg.Length := Msg.Length + 1;
    if command.IsDoubleLength then
      Msg.Length := Msg.Length + 1;
    {$ENDREGION}
    Msg.Length := Msg.Length + command.Length; // + COMMAND BODY: as estimated
  end;
end;

procedure TM2100MessageEncoder.EstimateCommandLength(const aCommand: TM2100Command);
var
  i: integer;
  subCommand: TM2100SubCommand;
begin
  aCommand.Length := 0;
  for i := 0 to aCommand.SubCommands.Count - 1 do
  begin
    subCommand := aCommand.SubCommands[i] as TM2100SubCommand;
    aCommand.Length := aCommand.Length + 1 + EstimateSubCommandLength(subCommand);
  end;
  aCommand.IsDoubleLength := IsDoubleLength(aCommand.Length);
end;

function TM2100MessageEncoder.EstimateSubCommandLength(const aSubCommand: TM2100SubCommand):
  integer;
var
  memory: TMemoryStream;
begin
  memory := TMemoryStream.Create;
  aSubCommand.SaveToStream(memory);
  result := memory.Size;
  memory.Free;
end;

function TM2100MessageEncoder.IsDoubleLength(const aLength: integer): boolean;
begin
  result := aLength >= 128;
end;

procedure TM2100MessageEncoder.WriteSTX;
begin
  Stream.WriteBuffer(Msg.STX, 1);
end;

procedure TM2100MessageEncoder.WriteCommands;
var
  i: integer;
  command: TM2100Command;
begin
  for i := 0 to Msg.Commands.Count - 1 do
  begin
    command := Msg.Commands[i] as TM2100Command;
    WriteCommand(command);
  end;
end;

procedure TM2100MessageEncoder.WriteCommand(const aCommand: TM2100Command);
begin
  Stream.WriteBuffer(aCommand.CommandClass, 1);
  WriteLength(aCommand.Length);
  WriteSubCommands(aCommand);
end;

procedure TM2100MessageEncoder.WriteSubCommands(const aCommand: TM2100Command);
var
  i: integer;
  subCommand: TM2100SubCommand;
begin
  for i := 0 to aCommand.SubCommands.Count - 1 do
  begin
    subCommand := aCommand.SubCommands[i] as TM2100SubCommand;
    WriteSubCommand(subCommand);
  end;
end;

procedure TM2100MessageEncoder.WriteSubCommand(const aSub: TM2100SubCommand);
begin
  Stream.WriteBuffer(aSub.id, 1);
  aSub.SaveToStream(Stream);
end;

procedure TM2100MessageEncoder.EvaluateMessageCheckSum;
var
  currentByte: byte;
  sum: integer;
begin
  Stream.Seek(1, soBeginning);
  sum := 0;
  while Stream.Position < Stream.Size do
  begin
    Stream.ReadBuffer(currentByte, 1);
    sum := (sum + currentByte) and $00FF;
  end;
  Msg.CheckSum := TM2100Message.TwosComponent(sum);
end;

procedure TM2100MessageEncoder.WriteMessageCheckSum;
begin
  Stream.Seek(0, soEnd);
  Stream.WriteBuffer(Msg.CheckSum, 1);
end;

procedure TM2100MessageEncoder.WriteLength(const aLength: integer);
var
  shortLength: byte;
begin
  if IsDoubleLength(aLength) then
    Stream.WriteBuffer(aLength, 2)
  else
  begin
    shortLength := byte(aLength) or 128;
    Stream.WriteBuffer(shortLength, 1);
  end;
end;

procedure TM2100MessageEncoder.WriteMessageLength;
begin
  WriteLength(Msg.Length);
end;

destructor TM2100MessageEncoder.Destroy;
begin
  FreeAndNil(fLog);
  inherited Destroy;
end;

procedure TM2100MessageEncoder.Encode;
begin
  if EncodeAsAcknowledged then
    exit;    
  EstimateMessageLength;
  WriteSTX;
  WriteMessageLength;
  WriteCommands;
  EvaluateMessageCheckSum;
  WriteMessageCheckSum;
end;

class function TM2100MessageEncoder.Encode(const aMessage: TM2100Message): TStream;
var
  encoder: TM2100MessageEncoder;
begin
  encoder := TM2100MessageEncoder.Create(aMessage);
  try
    encoder.Encode;
    result := encoder.Stream;
  finally
    encoder.Free;
  end;
end;

function TM2100MessageEncoder.EncodeAsAcknowledged: boolean;
begin
  result := Msg.IsAcknowledged;
  Stream.WriteBuffer(M2100MessageCommandClass_ACKNOWLEDGED, 1);
end;


end.

