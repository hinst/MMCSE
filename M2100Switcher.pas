unit M2100Switcher;

interface

uses
  SysUtils,
  Classes,
  Contnrs,

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
    DefaultThreadWaitInterval = 300;
  private
    fLog: TCustomLog;
    fKeyers: TM2100KeyerList;
    fReceiveMessage: TReceiveMessageMethod;
    fSendResponse: TSendResponceMethod;
    fThread: TCustomThread;
    fThreadWaitInterval: integer;
    fAutomationStatus: boolean;
    procedure ReplaceLog(const aLog: TCustomLog);
    procedure Construction;
    procedure AssignDefaults;
    procedure InitializeKeyers;
    function GetKeyersStatusAsByte: byte;
    procedure ExecuteSendReceiveThread(const aThread: TCustomThread);
    procedure OnSendRecieveThreadException(const aThread: TCustomThread;
      const aException: Exception);
    function SafeDecodeMessage(const aMessage: TStream): TM2100Message;
    function DecodeMessage(const aMessage: TStream): TM2100Message;
    procedure ProcessMessage(const aMessage: TStream); overload;
    function ProcessMessage(const aMessage: TM2100Message): TM2100Message; overload;
    function SafeProcessMessage(const aMessage: TM2100Message): TM2100Message;
    function ProcessCommands(const aMessage: TM2100Message): TM2100Message;
    function ProcessCommand(const aCommand: TM2100Command): TM2100Command;
    function ProcessSubCommand(const aSubCommand: TM2100SubCommand): TM2100SubCommand;
    procedure SendMessage(const aMessage: TM2100Message);
    procedure Destruction;
  public
    property Log: TCustomLog read fLog write ReplaceLog;
    property Keyers: TM2100KeyerList read fKeyers;
    property ReceiveMessage: TReceiveMessageMethod read fReceiveMessage write fReceiveMessage;
    property SendResponse: TSendResponceMethod read fSendResponse write fSendResponse;
    property Thread: TCustomThread read fThread;
    property ThreadWaitInterval: integer read fThreadWaitInterval write fThreadWaitInterval;
    property AutomationStatus: boolean read fAutomationStatus write fAutomationStatus;
    property KeyersStatusAsByte: byte read GetKeyersStatusAsByte;
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
  Construction;
end;

procedure TM2100Switcher.ReplaceLog(const aLog: TCustomLog);
begin
  Log.Free;
  fLog := aLog;
end;

procedure TM2100Switcher.Construction;
begin
  fLog := TEmptyLog.Create;
  InitializeKeyers;
  fThread := TCustomThread.Create;
  Thread.OnExecute := ExecuteSendReceiveThread;
  Thread.OnException :=  OnSendRecieveThreadException;
  fThreadWaitInterval := DefaultThreadWaitInterval;
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

procedure TM2100Switcher.ExecuteSendReceiveThread(const aThread: TCustomThread);
var
  incomingStream: TStream;
begin
  Log.Write('TM2100 Switcher thread starts... [>]');
  repeat
    if @ReceiveMessage <> nil then
    begin
      Log.Write('(checking data)');
      incomingStream := ReceiveMessage;
      if Assigned(incomingStream) then
      begin
        ProcessMessage(incomingStream);
        incomingStream.Free;
      end;
    end;
    Sleep(ThreadWaitInterval);
  until aThread.Stop;
  Log.Write('TM2100 Switcher thread end. [#]');
end;

procedure TM2100Switcher.OnSendRecieveThreadException(const aThread: TCustomThread;
  const aException: Exception);
begin
  Log.Write('ERROR', 'An exception occured while executing thread');
  Log.Write(GetExceptionInfo(aException));
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

procedure TM2100Switcher.ProcessMessage(const aMessage: TStream);
var
  response: TStream;
  m: TM2100Message;
  answerM: TM2100Message;
begin
  AssertAssigned(aMessage, 'aMessage', TVariableType.Argument);
  StreamRewind(aMessage);
  Log.Write('Now processing message: ' + StreamToText(aMessage));
  StreamRewind(aMessage);
  m := SafeDecodeMessage(aMessage);
  answerM := SafeProcessMessage(m);
  if answerM = nil then
    Log.Write('No responce for this message')
  else
    SendMessage(answerM);
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
  try
    result := ProcessMessage(aMessage);
  except
    on e: Exception do
    begin
      result := nil;
      Log.Write('ERROR', 'Exception while processing message');
      Log.Write('ERROR', GetExceptionInfo(e));
      Log.Write('ERROR', 'Message which caused the exception: ' + sLineBreak
        + ' ' + aMessage.ToText);
      AssertSuppressable(e);
    end;
  end;
end;

procedure TM2100Switcher.SendMessage(const aMessage: TM2100Message);
var
  stream: TStream;
begin
  AssertAssigned(aMessage, 'aMessage', TVariableType.Argument);
  Log.Write('Now encoding message...' + sLineBreak
    + '  ' + aMessage.ToText);
  stream := TM2100MessageEncoder.Encode(aMessage);
  Log.Write('Now sending message...' + sLineBreak
    + '  ' + aMessage.ToText);
end;

function TM2100Switcher.ProcessMessage(const aMessage: TM2100Message): TM2100Message;
begin
  AssertAssigned(aMessage, 'aMessage', TVariableType.Argument);
  Log.Write('Now processing message:..' + sLineBreak + ' ' + aMessage.ToText);
  result := ProcessCommands(aMessage);
end;

function TM2100Switcher.ProcessCommands(const aMessage: TM2100Message): TM2100Message;
var
  i: integer;
  command: TM2100Command;
  answerCommand: TM2100Command;
begin
  result := TM2100Message.Create;
  for i := 0 to aMessage.Commands.Count - 1 do
  begin
    command := aMessage.Commands[i] as TM2100Command;
    answerCommand := ProcessCommand(command);
    if answerCommand <> nil then
    begin
      Log.Write('Got result: ' + answerCommand.ToText);
      result.Commands.Add(answerCommand);
    end;
  end;
end;

function TM2100Switcher.ProcessCommand(const aCommand: TM2100Command): TM2100Command;
var
  i: integer;
  subCommand: TM2100SubCommand;
  answerSubCommand: TM2100SubCommand;
begin
  AssertAssigned(aCommand, 'aCommand', TVariableType.Argument);
  Log.Write('Now processing command:..' + sLineBreak + ' ' + aCommand.ToText);
  result := nil;
  for i := 0 to aCommand.SubCommands.Count - 1 do
  begin
    subCommand := aCommand.SubCommands[i] as TM2100SubCommand;
    answerSubCommand := ProcessSubCommand(subCommand);
    if answerSubCommand <> nil then
    begin
      Log.Write('Got subCommand answer: ' + answerSubCommand.ToText);
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
  Log.Write('Now processing subcommand ' + aSubCommand.ToText);
  result := nil;
  if aSubCommand is TM2100SubCommandKeyStat then
    result := TM2100SubCommandKeyStatAnswer.Create(KeyersStatusAsByte);
  if aSubCommand is TM2100SubCommandAutoStat then
    result := TM2100SubCommandAutoStatAnswer.Create(true);
end;

procedure TM2100Switcher.Destruction;
begin
  if not Thread.Suspended then
    Thread.WaitFor;
  FreeAndNil(fThread);
  FreeAndNil(fKeyers);
  FreeAndNil(fLog);
end;

destructor TM2100Switcher.Destroy;
begin
  Destruction;
  inherited;
end;

end.
