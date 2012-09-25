unit M2100Command;

interface

uses
  SysUtils,
  Classes,
  Contnrs,

  UStreamUtilities;

type
  TM2100SubCommand = class
  public
    constructor Create(const aId: byte);
  public
    id: byte;
    class function Construct(const aId: byte): TM2100SubCommand;
    class function KEY_STAT: byte;
    class function AUTO_STAT: byte;
    procedure LoadFromStream(const aStream: TStream); virtual; abstract;
    procedure SaveToStream(const aStream: TStream); virtual; abstract;
    function IdToText: string;
    function IdToTextFull: string;
    function ToText: string; virtual;
  end;

  TM2100Command = class
  public
    constructor Create; virtual;
  public
    CommandClass: byte;
    IsDoubleLength: boolean;
    Length: integer;
    SubCommands: TObjectList;
    class function CommandClassToText(const aCommandClass: byte): string;
    function SubCommandsToText: string;
    function ToText: string; overload;
    destructor Destroy; override;
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
  if aId = KEY_STAT then
    result := TM2100SubCommandKeyStat.Create(aId);
  if aId = AUTO_STAT then
    result := TM2100SubCommandAutoStat.Create(aId);
end;

function TM2100SubCommand.IdToText: string;
begin
  result := 'UNKNOWN';
  if id = KEY_STAT then
    result := 'KEY_STAT';
  if id = AUTO_STAT then
    result := 'AUTO_STAT';
end;

function TM2100SubCommand.IdToTextFull: string;
begin
  result := '$' + IntToHex(id, 2) + '''' + IdToText + ''''; 
end;

class function TM2100SubCommand.KEY_STAT: byte;
begin
  result := $0C;
end;

function TM2100SubCommand.ToText: string;
begin
  result := '[' + IdToTextFull + ' ' + ClassName + ']';
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
  result := result + '''' + CommandClassToText(CommandClass) + '''';
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
