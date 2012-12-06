unit M2100Switcher;

{$DEFINE LOG_MESSAGE_CONTENT_BEFORE_PROCESSING}
{$DEFINE LOG_MESSAGE_CONTENT_BEFORE_SENDING}
{ $DEFINE LOG_MESSAGE_STREAM_BEFORE_SENGING}

{$DEFINE LOG_ATTACH_POLLING_TAG}
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

  UAdditionalTypes,
  UAdditionalExceptions,
  UCustomThread,
  UStreamUtilities,
  UExceptionTracer,
  UTextUtilities,

  CustomLogEntity,
  EmptyLogEntity,

  CustomSwitcherMessageUnit,
  CustomSwitcherUnit,
  CustomSwitcherFactoryUnit,
  M2100Message,
  M2100Keyer,
  M2100Command,
  M2100MessageDecoder,
  M2100MessageEncoder;

type
  TM2100Switcher = class(TCustomSwitcher)
  public
    constructor Create;
    procedure Startup; override;
  public const
    DefaultSendReceiveThreadWaitInterval = 1;
  private
    fKeyers: TM2100KeyersStatus;
    fAutomationStatus: boolean;
    procedure AssignDefaults;
    procedure InitializeKeyers;
    function GetAdditionalMessageLogTags(const aMessage: TM2100Message): string;
    function IsAutoStatPolling(const aMessage: TM2100Message): boolean;
    function SafeDecodeMessage(const aMessage: TStream): TM2100Message;
    function DecodeMessage(const aMessage: TStream): TM2100Message;
    function ProcessMessage(const aMessage: TM2100Message): TM2100Message;
    function SafeProcessMessage(const aMessage: TM2100Message): TM2100Message;
    function ProcessCommands(const aMessage: TM2100Message): TM2100Message;
    function ProcessCommand(const aCommand: TM2100Command): TM2100Command;
    function ProcessSubCommand(const aSubCommand: TM2100SubCommand): TM2100SubCommand;
    procedure SendMessage(const aMessage: TM2100Message);
    procedure SafeSendMessage(const aMessage: TStream);
    procedure DestroyThis;
  public
    property Keyers: TM2100KeyersStatus read fKeyers;
      // this propery should be assigned by the user of this class
    property AutomationStatus: boolean read fAutomationStatus write fAutomationStatus;
    destructor Destroy; override;
  end;

  
implementation

constructor TM2100Switcher.Create;
begin
  inherited Create;
end;

procedure TM2100Switcher.Startup;
begin
  InitializeKeyers;
  AssignDefaults;
end;

procedure TM2100Switcher.InitializeKeyers;
begin
  fKeyers := TM2100KeyersStatus.Create(0);
  Keyers.SetDefault;
end;

procedure TM2100Switcher.AssignDefaults;
begin
  AutomationStatus := true;
end;

function TM2100Switcher.GetAdditionalMessageLogTags(const aMessage: TM2100Message): string;
begin
  if IsAutoStatPolling(aMessage) then
    result := 'Polling';
end;

function TM2100Switcher.IsAutoStatPolling(const aMessage: TM2100Message): boolean;
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

function TM2100Switcher.DecodeMessage(const aMessage: TStream): TM2100Message;
var
  data: string;
begin
  result := nil;
  try
    result := TM2100MessageDecoder.DecodeThis(aMessage) as TM2100Message;
    AssertAssigned(result, 'result', TVariableType.Local);
  except
    on e: Exception do
    begin
      data := StreamToText(aMessage, true);
      Log.Write('ERROR', 'Unable to decode message. ' + sLineBreak
        + 'Stream data: ' + data + sLineBreak
        + GetExceptionInfo(e));
    end;
  end;
end;

function TM2100Switcher.SafeDecodeMessage(const aMessage: TStream): TM2100Message;
begin
  AssertAssigned(aMessage, 'aMessage', TVariableType.Argument);
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
  Log.Write(
    SpacedStrings(['Sending', GetAdditionalMessageLogTags(aMessage)]),
    aMessage.ToText
  );
  {$ENDIF}
  {$IFDEF LOG_MESSAGE_STREAM_BEFORE_SENGING}
  StreamRewind(stream);
  Log.Write('send message', 'Now sending message ' + StreamToText(stream));
  {$ENDIF}
  SafeSendMessage(stream);
  stream.Free;
end;

procedure TM2100Switcher.SafeSendMessage(const aMessage: TStream);
begin
  try
    AssertAssigned(aMessage, 'aMessage', TVariableType.Argument);
    AssertAssigned(@SendMessageMethod, 'SendResponse', TVariableType.Prop);
    StreamRewind(aMessage);
    SendMessageMethod(aMessage);
  except
    on e: Exception do
    begin
      Log.Write(
        'ERROR',
        'Could not send response. Exception occured:'
         + sLineBreak + GetExceptionInfo(e)
         + 'Response is: ' +StreamToText(aMessage, true)
      );
      AssertSuppressable(e);
    end;
  end;
end;

function TM2100Switcher.ProcessMessage(const aMessage: TM2100Message): TM2100Message;
begin
  AssertAssigned(aMessage, 'aMessage', TVariableType.Argument);
  {$IFDEF LOG_MESSAGE_CONTENT_BEFORE_PROCESSING}
  Log.Write(
    SpacedStrings([ 'Processing', GetAdditionalMessageLogTags(aMessage) ]),
    'Now processing message:..' + sLineBreak + '  ' + aMessage.ToText
  );
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
    result := TM2100SubCommandKeyStatAnswer.Create(Keyers.Value);
  if aSubCommand is TM2100SubCommandAutoStat then
    result := TM2100SubCommandAutoStatAnswer.Create(true);
end;

procedure TM2100Switcher.DestroyThis;
begin
  FreeAndNil(fKeyers);
  FreeAndNil(fLog);
end;

destructor TM2100Switcher.Destroy;
begin
  DestroyThis;
  inherited;
end;

initialization
  RegisterSwitcherClass(TM2100Switcher);
end.
