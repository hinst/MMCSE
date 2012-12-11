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
    constructor Create; override;
    procedure Startup; override;
  public const
    DefaultSendReceiveThreadWaitInterval = 1;
  protected
    fKeyers: TM2100KeyersStatus;
    fAutomationStatus: boolean;
    procedure AssignDefaults;
    procedure InitializeKeyers;
    function GetAdditionalMessageLogTags(const aMessage: TCustomSwitcherMessage): string; override;
    function IsAutoStatPolling(const aMessage: TM2100Message): boolean;
    function ProcessMessage(const aMessage: TCustomSwitcherMessage): TCustomSwitcherMessage; override;
    function ProcessCommands(const aMessage: TM2100Message): TM2100Message;
    function ProcessCommand(const aCommand: TM2100Command): TM2100Command;
    function ProcessSubCommand(const aSubCommand: TM2100SubCommand): TM2100SubCommand;
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
  FDecoderClass := TM2100MessageDecoder;
  FEncoderClass := TM2100MessageEncoder;
end;

function TM2100Switcher.GetAdditionalMessageLogTags(const aMessage: TCustomSwitcherMessage): string;
var
  mssage: TM2100Message;
begin
  result := '';
  AssertType(aMessage, TM2100Message);
  mssage := aMessage as TM2100Message;
  if IsAutoStatPolling(mssage) then
    AppendSpaced(result, mssage.PollingTag);
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

function TM2100Switcher.ProcessMessage(const aMessage: TCustomSwitcherMessage)
  : TCustomSwitcherMessage;
var
  mssage: TM2100Message;
begin
  AssertType(aMessage, TM2100Message);
  mssage := aMessage as TM2100Message;
  {$IFDEF LOG_MESSAGE_CONTENT_BEFORE_PROCESSING}
  Log.Write(
    SpacedStrings([ 'Processing', GetAdditionalMessageLogTags(aMessage) ]),
    'Now processing message:..' + sLineBreak + '  ' + mssage.ToText
  );
  {$ENDIF}
  if mssage.IsAcknowledged then
  begin
    result := nil;
    exit;
  end;
  result := ProcessCommands(mssage);
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
