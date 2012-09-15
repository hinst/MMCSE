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
    function WriteCommands: integer;
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
    EstimateCommandLength(command);
    Msg.Length := Msg.Length + 1;
    if command.IsDoubleLength then
      Msg.Length := Msg.Length + 1;
    Msg.Length := Msg.Length + command.Length;
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
  if aCommand.Length >= 128 then
    aCommand.IsDoubleLength := true;
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

function TM2100MessageEncoder.WriteCommands: integer;
begin

end;

destructor TM2100MessageEncoder.Destroy;
begin
  FreeAndNil(fLog);
  inherited Destroy;
end;

procedure TM2100MessageEncoder.Encode;
begin
  EstimateMessageLength;
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


end.

