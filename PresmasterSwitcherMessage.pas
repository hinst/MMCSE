unit PresmasterSwitcherMessage;

{ $Define ClassToText}

interface

uses
  SysUtils,
  Classes,

  UStreamUtilities,

  CustomSwitcherMessageUnit;

type
  TPresmasterMessageClass = class of TPresmasterMessage;

  TPresmasterMessage = class(TCustomSwitcherMessage)
  public
    constructor Create; override;
    class function CreateSpecific(const aMessage: TPresmasterMessage): TPresmasterMessage;
  public const
    {$Region Formats}
    FormatSimple = $FF;
    FormatExtended = $FE;
    FormatSimpleTail = $7F;
    {$EndRegion}
    {$Region Simple Commands}
    SetAUXBusCommand = $08;
    SetPGMBusCommand = $09;
    SetPSTBusCommand = $0B;
    PollCommand = $1E;
    AnswerPollCommand = $5E;
    {$EndRegion}
  protected
    FFormat: byte;
    FCommand: word;
    function ToTextInternal: string; override;
  public
    property Format: byte read FFormat write FFormat;
    property Command: word read FCommand write FCommand;
    function IsValidFormat: boolean; overload;
    function IsSimpleSetCommand: boolean; overload;
    function FormatToText: string; overload;
    function CommandToText: string; overload;
    function IsPolling: boolean; overload;
    procedure Assign(const aMessage: TPresmasterMessage);
    class function IsValidFormat(const aFormat: byte): boolean; overload;
    class function IsSimpleSetCommand(const aCommand: byte): boolean; overload;
    class function FormatToText(const aFormat: byte): string; overload;
    class function CommandToText(const aFormat: byte; const aCommand: word): string; overload;
    class function IsPolling(const aCommand: byte): boolean; overload;
    function DetectClass: TPresmasterMessageClass;
    class procedure ResolveSpecific(var aResult: TPresmasterMessage);
  end;

  TPresmasterMessageUnknown = class(TPresmasterMessage)
  public
    constructor Create; override;
  protected
    FStream: TStream;
    function ToTextInternal: string; override;
  public
    property Stream: TStream read FStream;
    destructor Destroy; override;
  end;

  TPresmasterMessagePoll = class(TPresmasterMessage)
  end;

  TPresmasterMessagePollAnswer = class(TPresmasterMessage)
  public
    constructor Create; override;
  end;

implementation

constructor TPresmasterMessage.Create;
begin
  inherited Create;
end;

class function TPresmasterMessage.CreateSpecific(const aMessage: TPresmasterMessage): TPresmasterMessage;
var
  t: TPresmasterMessageClass;
begin
  t := aMessage.DetectClass;
  result := t.Create;
  result.Assign(aMessage);
end;

function TPresmasterMessage.ToTextInternal: string;
begin
  result := 'Cmmd: ' + CommandToText;
  {$IfDef ClassToText}
  result := result + '; Class: ' + ClassName;
  {$EndIf}
end;

function TPresmasterMessage.IsValidFormat: boolean;
begin
  result := IsValidFormat(Format);
end;

function TPresmasterMessage.FormatToText: string;
begin
  result := FormatToText(Format);
end;

function TPresmasterMessage.CommandToText: string;
begin
  result := CommandToText(Format, Command);
end;

function TPresmasterMessage.IsSimpleSetCommand: boolean;
begin
  result := IsSimpleSetCommand(Command);
end;

function TPresmasterMessage.IsPolling: boolean;
begin
  result := IsPolling(Command);
end;

procedure TPresmasterMessage.Assign(const aMessage: TPresmasterMessage);
begin
  Format := aMessage.Format;
  Command := aMessage.Command;
end;

class function TPresmasterMessage.IsValidFormat(const aFormat: byte): boolean;
begin
  result := (aFormat = FormatSimple) or (aFormat = FormatExtended);
end;

class function TPresmasterMessage.IsSimpleSetCommand(const aCommand: byte): boolean;
begin
  result := (aCommand = SetAUXBusCommand) or (aCommand = SetPGMBusCommand)
     or (aCommand = SetPSTBusCommand);
end;

class function TPresmasterMessage.FormatToText(const aFormat: byte): string;
begin
  case aFormat of
    FormatSimple:
      result := 'Simple';
    FormatExtended:
      result := 'Extended';
    else
      result := 'Unknown';
  end;
end;

class function TPresmasterMessage.CommandToText(const aFormat: byte; const aCommand: word): string;
  function CommandAsHex(const aFormat: byte; const aCommand: word): string; inline;
  begin
    result := '';
    if aFormat = FormatSimple then
      result := IntToHex(aCommand, 2);
    if aFormat = FormatExtended then
      result := IntToHex(aCommand, 4);
    if result = '' then
      result := 'Invalid format';
  end;
begin
  result := '';
  if aCommand = SetAUXBusCommand then
    result := 'Set AUX Bus';
  if aCommand = SetPGMBusCommand then
    result := 'Set PGM Bus';
  if aCommand = SetPSTBusCommand then
    result := 'Set PST Bus';
  if aCommand = PollCommand then
    result := 'Poll';
  if aCommand = AnswerPollCommand then
    result := 'AnswerPoll';
  if result = '' then
    result := 'Unknown: ' + CommandAsHex(aFormat, aCommand);
end;

class function TPresmasterMessage.IsPolling(const aCommand: byte): boolean;
begin
  result := aCommand = PollCommand;
end;

function TPresmasterMessage.DetectClass: TPresmasterMessageClass;
begin
  result := nil;
  {$Region TypeDetection}
  if (Format = FormatSimple) and (Command = PollCommand) then
    result := TPresmasterMessagePoll;
  {$EndRegion}
  if result = nil then
    result := TPresmasterMessageUnknown;
end;

class procedure TPresmasterMessage.ResolveSpecific(var aResult: TPresmasterMessage);
var
  result: TPresmasterMessage;
begin
  result := CreateSpecific(aResult);
  aResult.Free;
  aResult := result;
end;


constructor TPresmasterMessageUnknown.Create;
begin
  inherited Create;
  FStream := TMemoryStream.Create;
end;

function TPresmasterMessageUnknown.ToTextInternal: string;
begin
  result := 'Cmmd: ' + CommandToText + '; Stream: ' + StreamToText(Stream, true);
end;

destructor TPresmasterMessageUnknown.Destroy;
begin
  FreeAndNil(FStream);
  inherited Destroy;
end;

constructor TPresmasterMessagePollAnswer.Create;
begin
  inherited Create;
  Format := FormatSimple;
  Command := AnswerPollCommand;
end;

end.
