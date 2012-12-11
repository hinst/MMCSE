unit PresmasterSwitcherMessage;

interface

uses
  CustomSwitcherMessageUnit;

type
  TPresmasterMessage = class(TCustomSwitcherMessage)
  public
    constructor Create; override;
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
    FCommand: byte;
    function ToTextInternal: string; override;
  public
    property Format: byte read FFormat write FFormat;
    property Command: byte read FCommand write FCommand;
    function IsValidFormat: boolean; overload;
    function IsSimpleSetCommand: boolean; overload;
    function FormatToText: string; overload;
    function CommandToText: string; overload;
    function IsPolling: boolean; overload;
    procedure Assign(const aMessage: TPresmasterMessage);
    class function IsValidFormat(const aFormat: byte): boolean; overload;
    class function IsSimpleSetCommand(const aCommand: byte): boolean; overload;
    class function FormatToText(const aFormat: byte): string; overload;
    class function CommandToText(const aCommand: byte): string; overload;
    class function IsPolling(const aCommand: byte): boolean; overload;
    function Transform: TPresmasterMessage;
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

function TPresmasterMessage.ToTextInternal: string;
begin
  result := 'Cmmd: ' + CommandToText;
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
  result := CommandToText(Command);
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

class function TPresmasterMessage.CommandToText(const aCommand: byte): string;
begin
  result := 'Unknown';
  if aCommand = SetAUXBusCommand then
    result := 'Set AUX Bus';
  if aCommand = SetPGMBusCommand then
    result := 'Set PGM Bus';
  if aCommand = SetPSTBusCommand then
    result := 'Set PST Bus';
  if aCommand = PollCommand then
    result := 'Poll';
end;

class function TPresmasterMessage.IsPolling(const aCommand: byte): boolean;
begin
  result := aCommand = PollCommand;
end;

function TPresmasterMessage.Transform: TPresmasterMessage;
begin
  result := nil;
  if IsPolling then
  begin
    result := TPresmasterMessagePoll.Create;
    result.Assign(self);
  end;
  if result = nil then
  begin
    result := TPresmasterMessage.Create
    result.Assign(self);
  end;
end;


constructor TPresmasterMessagePollAnswer.Create;
begin
  inherited Create;
  Format := FormatSimple;
  Command := AnswerPollCommand;
end;

end.
