unit M2100Switcher;

{ $DEFINE LOG_MESSAGE_STREAM_BEFORE_PROCESSING}
{$DEFINE LOG_MESSAGE_CONTENT_BEFORE_PROCESSING}
{$DEFINE LOG_MESSAGE_CONTENT_BEFORE_SENDING}
{ $DEFINE LOG_MESSAGE_STREAM_BEFORE_SENGING}

{$DEFINE LOG_SUPPRESS_INFO_ON_AUTO_STAT_POLLING}
  //< affects
  // LOG_MESSAGE_CONTENT_BEFORE_PROCESSING
  // and
  // LOG_MESSAGE_CONTENT_BEFORE_SENDING

{ $DEFINE LOG_COMMAND_ON_COMMAND_PROCESSING}
{ $DEFINE LOG_SUBCOMMAND_ON_SUBCOMMAND_PROCESSING}

interface

uses
  SysUtils,
  Classes,
  Contnrs,
  SyncObjs,

  UAdditionalTypes,
  UAdditionalExceptions,
  UCustomThread,
  UStreamUtilities,
  ExceptionTracer,

  CustomLogEntity,
  EmptyLogEntity,


  M2100Message,
  M2100Command,
  M2100MessageDecoder,
  M2100MessageEncoder;

type
  TM2100Keyer = class
  public
    constructor Create;
  private
    fStatus: boolean;
  public
    property Status: boolean read fStatus write fStatus;
  end;

  TM2100KeyerList = class(TObjectList)
  protected
    function GetItem(const aIndex: integer): TM2100Keyer;
  public
    property Items[const aIndex: integer]: TM2100Keyer read GetItem; default;
  end;

  TM2100Switcher = class
  public
    constructor Create;
  public type
    TSendResponceMethod = procedure(const aResponce: TStream) of object;
      // nil stream indicates that there is no message data available at the moment
    TReceiveMessageMethod = function: TStream of object;
  public const
    DefaultSendReceiveThreadWaitInterval = 1;
  private
    fLog: TEmptyLog;
    fIncomingEvent: TSimpleEvent;
    fKeyers: TM2100KeyerList;
    fOnSendResponse: TSendResponceMethod;
    fAutomationStatus: boolean;
    procedure CreateThis;
    procedure AssignDefaults;
    procedure InitializeKeyers;
    function GetKeyersStatusAsByte: byte;
    function GetLoggingSuppressed(const aMessage: TM2100Message): boolean;
    function SafeDecodeMessage(const aMessage: TStream): TM2100Message;
    function DecodeMessage(const aMessage: TStream): TM2100Message;
    function ProcessMessage(const aMessage: TM2100Message): TM2100Message; overload;
    function SafeProcessMessage(const aMessage: TM2100Message): TM2100Message;
    function ProcessCommands(const aMessage: TM2100Message): TM2100Message;
    function ProcessCommand(const aCommand: TM2100Command): TM2100Command;
    function ProcessSubCommand(const aSubCommand: TM2100SubCommand): TM2100SubCommand;
    procedure SendMessage(const aMessage: TM2100Message);
    procedure SafeSendMessage(const aMessage: TStream);
    procedure DestroyThis;
  public
    property Log: TEmptyLog read fLog;
    property IncomingEvent: TSimpleEvent read fIncomingEvent;
    property Keyers: TM2100KeyerList read fKeyers;
      // this propery should be assigned by the user of this class
    property OnSendResponse: TSendResponceMethod read fOnSendResponse write fOnSendResponse;
    property AutomationStatus: boolean read fAutomationStatus write fAutomationStatus;
    property KeyersStatusAsByte: byte read GetKeyersStatusAsByte;
    property LoggingSuppressed[const aMessage: TM2100Message]: boolean read GetLoggingSuppressed;
    procedure ProcessMessage(const aMessage: TStream); overload;
    destructor Destroy; override;
  end;

implementation

constructor TM2100Keyer.Create;
begin
  inherited Create;
end;

function TM2100KeyerList.GetItem(const aIndex: integer): TM2100Keyer;
begin
  result := inherited GetItem(aIndex) as TM2100Keyer;
end;

constructor TM2100Switcher.Create;
begin
  inherited Create;
  CreateThis;
end;

procedure TM2100Switcher.CreateThis;
begin
  fLog := TEmptyLog.Create;
  fIncomingEvent := TSimpleEvent.Create(nil, false, false, '', false);
  InitializeKeyers;
  AssignDefaults;
end;

procedure TM2100Switcher.InitializeKeyers;
var
  i: integer;
  keyer: TM2100Keyer;
begin
  fKeyers := TM2100KeyerList.Create(true);
  for i := 1 to 4 do
  begin
    keyer := TM2100Keyer.Create;
    keyer.Status := true;
    Keyers.Add(keyer);
  end;
end;

procedure TM2100Switcher.AssignDefaults;
begin
  AutomationStatus := true;
end;

function TM2100Switcher.GetKeyersStatusAsByte: byte;
begin
  result := 0;
  if keyers[0].Status then
    result := result or (1 shl 0);
  if keyers[1].Status then
    result := result or (1 shl 1);
  if keyers[2].Status then
    result := result or (1 shl 2);
  if keyers[3].Status then
    result := result or (1 shl 3);
end;

function TM2100Switcher.GetLoggingSuppressed(const aMessage: TM2100Message): boolean;

  function IsAutoStatPolling: boolean;
  var
    command: TM2100Command;
  begin
    result := aMessage.Commands.Count = 1;
    if not result  then
      exit;
    command := (aMessage.Commands[0] as TM2100Command);
    result := result and (command.SubCommands.Count = 1);
    if not result then
      exit;
    result := result
      and (command.SubCommands[0] is TM2100SubCommandAutoStat)
      or (command.SubCommands[0] is TM2100SubCommandAutoStatAnswer);
  end;
  
begin
  result := false
  {$IFDEF LOG_SUPPRESS_INFO_ON_AUTO_STAT_POLLING}
    or IsAutoStatPolling
  {$ENDIF}
  ;
end;

function TM2100Switcher.DecodeMessage(const aMessage: TStream): TM2100Message;
begin
  result := nil;
  try
    result := TM2100MessageDecoder.Decode(aMessage);
    AssertAssigned(result, 'result', TVariableType.Local);
  except
    on e: Exception do
    begin
      Log.Write('ERROR', 'Unable to decode incoming message.');
      Log.Write(GetExceptionInfo(e));
    end;
  end;
end;

function TM2100Switcher.SafeDecodeMessage(const aMessage: TStream): TM2100Message;
begin
  try
    result := DecodeMessage(aMessage);
  except
    on e: Exception do
    begin
      result := nil;
      Log.Write('ERROR', 'Exception while decoding message');
      Log.Write('ERROR', GetExceptionInfo(e));
      AssertSuppressable(e);
    end;
  end;
end;

function TM2100Switcher.SafeProcessMessage(const aMessage: TM2100Message): TM2100Message;
begin
  if not Assigned(aMessage) then
  begin
    result := nil;
    Log.Write('ERROR', 'Can not process message: aMessage argument is unassigned');
    exit;
  end;
  try
    result := ProcessMessage(aMessage);
  except
    on e: Exception do
    begin
      result := nil;
      Log.Write('ERROR', 'Exception while processing message');
      Log.Write('ERROR', GetExceptionInfo(e));
      if Assigned(aMessage) then
        try
          Log.Write('ERROR', 'Message which caused the exception: ' + sLineBreak
            + ' ' + aMessage.ToText);
        except
          Log.Write('ERROR', 'Message which caused exception can not be converted to text');
        end;
      AssertSuppressable(e);
    end;
  end;
end;

procedure TM2100Switcher.SendMessage(const aMessage: TM2100Message);
var
  stream: TStream;
begin
  AssertAssigned(aMessage, 'aMessage', TVariableType.Argument);
  stream := TM2100MessageEncoder.Encode(aMessage);
  {$IFDEF LOG_MESSAGE_CONTENT_BEFORE_SENDING}
  if not LoggingSuppressed[aMessage] then
    Log.Write('Now sending message...' + sLineBreak + '  ' + aMessage.ToText);
  {$ENDIF}
  {$IFDEF LOG_MESSAGE_STREAM_BEFORE_SENGING}
  StreamRewind(stream);
  Log.Write('Now sending message ' + StreamToText(stream));
  {$ENDIF}
  SafeSendMessage(stream);
  stream.Free;
end;

procedure TM2100Switcher.SafeSendMessage(const aMessage: TStream);
begin
  try
    AssertAssigned(aMessage, 'aMessage', TVariableType.Argument);
    AssertAssigned(@OnSendResponse, 'SendResponse', TVariableType.Prop);
    StreamRewind(aMessage);
    OnSendResponse(aMessage);
  except
    on e: Exception do
    begin
      Log.Write('ERROR', 'Could not send response. Exception occured.');
      Log.Write('ERROR', GetExceptionInfo(e));
      try
        StreamRewind(aMessage);
        Log.Write('ERROR', 'Response is: ' +StreamToText(aMessage));
      except
        Log.Write('ERROR', 'Response is: can not output response');
      end;
      AssertSuppressable(e);
    end;
  end;
end;

function TM2100Switcher.ProcessMessage(const aMessage: TM2100Message): TM2100Message;
begin
  AssertAssigned(aMessage, 'aMessage', TVariableType.Argument);
  {$IFDEF LOG_MESSAGE_CONTENT_BEFORE_PROCESSING}
  if not LoggingSuppressed[aMessage] then
    Log.Write('Now processing message:..' + sLineBreak + '  ' + aMessage.ToText);
  {$ENDIF}
  if aMessage.IsAcknowledged then
  begin
    result := nil;
    exit;
  end;
  result := ProcessCommands(aMessage);
end;

function TM2100Switcher.ProcessCommands(const aMessage: TM2100Message): TM2100Message;
var
  i: integer;
  command: TM2100Command;
  answerCommand: TM2100Command;
begin
  result := TM2100Message.Create;
  result.STX := aMessage.STX;
  for i := 0 to aMessage.Commands.Count - 1 do
  begin
    command := aMessage.Commands[i] as TM2100Command;
    answerCommand := ProcessCommand(command);
    if answerCommand <> nil then
      result.Commands.Add(answerCommand);
  end;
end;

function TM2100Switcher.ProcessCommand(const aCommand: TM2100Command): TM2100Command;
var
  i: integer;
  subCommand: TM2100SubCommand;
  answerSubCommand: TM2100SubCommand;
begin
  AssertAssigned(aCommand, 'aCommand', TVariableType.Argument);
  {$IFDEF LOG_COMMAND_ON_COMMAND_PROCESSING}
    Log.Write('Now processing command:..' + sLineBreak + ' ' + aCommand.ToText);
  {$ENDIF}
  result := nil;
  for i := 0 to aCommand.SubCommands.Count - 1 do
  begin
    subCommand := aCommand.SubCommands[i] as TM2100SubCommand;
    answerSubCommand := ProcessSubCommand(subCommand);
    if answerSubCommand <> nil then
    begin
      if result = nil then
      begin
        result := TM2100Command.Create;
        if aCommand.CommandClass = M2100MessageCommandClass_QUERY then
          result.CommandClass := M2100MessageCommandClass_STATUS;
      end;
      result.SubCommands.Add(answerSubCommand);
    end;
  end;
  if result = nil then
  begin
    if aCommand.CommandClass = M2100MessageCommandClass_CMD then
    begin
      result := TM2100Command.Create;
      result.CommandClass := M2100MessageCommandClass_ACKNOWLEDGED;
    end;
  end;
end;

function TM2100Switcher.ProcessSubCommand(const aSubCommand: TM2100SubCommand): TM2100SubCommand;
begin
  {$IFDEF LOG_SUBCOMMAND_ON_SUBCOMMAND_PROCESSING}
    Log.Write('Now processing subcommand ' + aSubCommand.ToText);
  {$ENDIF}
  result := nil;
  if aSubCommand is TM2100SubCommandKeyStat then
    result := TM2100SubCommandKeyStatAnswer.Create(KeyersStatusAsByte);
  if aSubCommand is TM2100SubCommandAutoStat then
    result := TM2100SubCommandAutoStatAnswer.Create(true);
end;

procedure TM2100Switcher.DestroyThis;
begin
  FreeAndNil(fKeyers);
  FreeAndNil(fLog);
end;

procedure TM2100Switcher.ProcessMessage(const aMessage: TStream);
var
  m: TM2100Message;
  answerM: TM2100Message;
begin
  AssertAssigned(aMessage, 'aMessage', TVariableType.Argument);
  {$IFDEF LOG_MESSAGE_STREAM_BEFORE_PROCESSING}
  StreamRewind(aMessage);
  Log.Write('Now processing message stream: ' + StreamToText(aMessage) + '...');
  {$ENDIF}
  StreamRewind(aMessage);
  m := SafeDecodeMessage(aMessage);
  answerM := SafeProcessMessage(m);
  m.Free;
  if answerM = nil then
    Log.Write('No responce for this message')
  else
    SendMessage(answerM);
  answerM.Free;
end;

destructor TM2100Switcher.Destroy;
begin
  DestroyThis;
  inherited;
end;

end.
