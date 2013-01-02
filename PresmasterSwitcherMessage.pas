unit PresmasterSwitcherMessage;

{ $Define ClassToText}

interface

uses
  SysUtils,
  Classes,

  UAdditionalTypes,
  UAdditionalExceptions,
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
    {$Region SimpleCommands}
    SetTransitionType = $01;
    SetAUXBusCommand = $08;
    SetTXVideo = $09;
    SetTXAudio = $0A;
    SetPresetVideo = $0B;
    SetPresetAudio = $0C;
    PollCommand = $1E;
    AnswerPollCommand = $5E;
    {$EndRegion}
    {$Region ExtendedCommands}
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
    procedure Assign(const aMessage: TPresmasterMessage);
    class function IsValidFormat(const aFormat: byte): boolean; overload;
    class function IsSimpleSetCommand(const aCommand: byte): boolean; overload;
    class function FormatToText(const aFormat: byte): string; overload;
    class function CommandToHex(const aFormat: byte; const aCommand: word): string;
    class function CommandToText(const aFormat: byte; const aCommand: word): string; overload;
    class function SimpleCommandToText(const aCommand: word): string;
    function DetectClass: TPresmasterMessageClass;
    class procedure ResolveSpecific(var aResult: TPresmasterMessage);
    procedure ReadSpecific(const aStream: TStream); virtual;
  end;

  TPresmasterMessageUnknown = class(TPresmasterMessage)
  public
    constructor Create; override;
  protected
    FBeginning: TStream;
    FRest: TStream;
    function ToTextInternal: string; override;
  public
    property Beginning: TStream read FBeginning;
    property Rest: TStream read FRest;
    procedure ReadSpecific(const aStream: TStream); override;
    destructor Destroy; override;
  end;

  TPresmasterMessagePoll = class(TPresmasterMessage)
  end;

  TPresmasterMessagePollAnswer = class(TPresmasterMessage)
  public
    constructor Create; override;
  end;

  TPresmasterMessageSwitch = class(TPresmasterMessage)
  public
    constructor Create; override;
  protected
    FSwitchTo: Word;
    function ToTextInternal: string; override;
  public
    property SwitchTo: Word read FSwitchTo;
    procedure ReadSpecific(const aStream: TStream); override;
  end;

  TPresmasterMessageSwitchTransitionType = class(TPresmasterMessageSwitch)
  protected
    function ToTextInternal: string; override;
  end;

  TPresmasterMessageSwitchVideo = class(TPresmasterMessageSwitch)
  protected
    function ToTextInternal: string; override;
  end;

  TPresmasterMessageSwitchAudio = class(TPresmasterMessageSwitch)
  protected
    function ToTextInternal: string; override;
  end;

  TPresmasterMessageSwitchPresetVideo = class(TPresmasterMessageSwitch)
  protected
    function ToTextInternal: string; override;
  end;

  TPresmasterMessageSwitchPresetAudio = class(TPresmasterMessageSwitch)
  protected
    function ToTextInternal: string; override;
  end;

implementation

constructor TPresmasterMessage.Create;
begin
  inherited Create;
end;

class function TPresmasterMessage.CreateSpecific(const aMessage: TPresmasterMessage)
  : TPresmasterMessage;
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
  result := (aCommand = SetAUXBusCommand) or (aCommand = SetTXVideo)
     or (aCommand = SetPresetVideo);
end;

class function TPresmasterMessage.FormatToText(const aFormat: byte): string;
begin
  case aFormat of
    FormatSimple:
      result := 'Simple Format';
    FormatExtended:
      result := 'Extended Format';
    else
      result := 'Unknown Format (' + IntToHex(aFormat,2) + ')';
  end;
end;

class function TPresmasterMessage.CommandToHex(const aFormat: byte; const aCommand: word): string;
var
  commandAsHex: string;
begin
  result := FormatToText(aFormat) + ': ';
  case aFormat of
    FormatSimple:
      commandAsHex := IntToHex(aCommand, 2);
    FormatExtended:
      commandAsHex := IntToHex(aCommand, 4);
    else
      commandAsHex := IntToHex(aCommand, 4);
  end;
  result := result + commandAsHex;
end;

class function TPresmasterMessage.CommandToText(const aFormat: byte; const aCommand: word): string;
begin
  result := '';
  if aFormat = FormatSimple then
    result := SimpleCommandToText(aCommand);
  if result = '' then
    result := 'Unknown command: ' + CommandToHex(aFormat, aCommand);
end;

class function TPresmasterMessage.SimpleCommandToText(const aCommand: word): string;
begin
  result := '';
  if aCommand = SetAUXBusCommand then
    result := 'Set AUX Bus';
  if aCommand = SetTXVideo then
    result := 'Set TX Video';
  if aCommand = SetTXAudio then
    result := 'Set TX Audio';
  if aCommand = SetPresetVideo then
    result := 'Set Preset Video';
  if aCommand = SetPresetAudio then
    result := 'Set Preset Audio';
  if aCommand = PollCommand then
    result := 'Poll';
  if aCommand = AnswerPollCommand then
    result := 'AnswerPoll';
  if result = '' then
    result := 'Unknown simple: ' + CommandToHex(FormatSimple, aCommand);
end;

  // this is where command Delphi classes and command hexadecimal codes
function TPresmasterMessage.DetectClass: TPresmasterMessageClass;
begin
  result := nil;
  {$Region TypeDetection}
  if (Format = FormatSimple) and (Command = PollCommand) then
    result := TPresmasterMessagePoll;
  if (Format = FormatSimple) and (Command = SetTXVideo) then
    result := TPresmasterMessageSwitchVideo;
  if (Format = FormatSimple) and (Command = SetTXAudio) then
    result := TPresmasterMessageSwitchAudio;
  if (Format = FormatSimple) and (Command = SetPresetVideo) then
    result := TPresmasterMessageSwitchPresetVideo;
  if (Format = FormatSimple) and (Command = SetPresetAudio) then
    result := TPresmasterMessageSwitchPresetAudio;
  {$EndRegion}
  if result = nil then
    result := TPresmasterMessageUnknown;
end;

class procedure TPresmasterMessage.ResolveSpecific(var aResult: TPresmasterMessage);
var
  result: TPresmasterMessage;
begin
  result := CreateSpecific(aResult);
  result.Assign(aResult);
  aResult.Free;
  aResult := result;
end;

procedure TPresmasterMessage.ReadSpecific(const aStream: TStream);
begin
end;


constructor TPresmasterMessageUnknown.Create;
begin
  inherited Create;
  FBeginning := TMemoryStream.Create;
  FRest := TMemoryStream.Create;
end;

function TPresmasterMessageUnknown.ToTextInternal: string;
begin
  result :=
    'Cmmd: ' + CommandToText + '; '
    + StreamToText(Beginning, true) + ', '
    + StreamToText(Rest, true);
end;

procedure TPresmasterMessageUnknown.ReadSpecific(const aStream: TStream);
var
  remainingSize: integer;
  beginningSize: integer;
begin
  AssertAssigned(aStream, 'aStream', TVariableType.Argument);
  remainingSize := GetRemainingSize(aStream);
  beginningSize := aStream.Position;
  Rewind(aStream);
  Beginning.CopyFrom(aStream, beginningSize);
  //log.Write('remaining size is ' + IntToStr(remainingSize));
  Rest.CopyFrom(aStream, remainingSize);
end;

destructor TPresmasterMessageUnknown.Destroy;
begin
  FreeAndNil(FBeginning);
  FreeAndNil(FRest);
  inherited Destroy;
end;

constructor TPresmasterMessagePollAnswer.Create;
begin
  inherited Create;
end;

constructor TPresmasterMessageSwitch.Create;
begin
  inherited Create;
end;

function TPresmasterMessageSwitch.ToTextInternal: string;
begin
  result := 'Switch to ' + IntToStr(SwitchTo);
end;

function ReadPresmasterWord(const aStream: TStream): Word;
var
  nextByte: byte;
  aa, bb: byte;
begin
  aStream.Read(nextByte, 1);
  if nextByte <> $7F then
    result := nextByte
  else
  begin
    aStream.Read(aa, 1);
    aStream.Read(bb, 1);
    result := (bb and $7F) or ((Word(aa) and $7F) shl 7);
  end;
end;

procedure TPresmasterMessageSwitch.ReadSpecific(const aStream: TStream);
begin
  inherited ReadSpecific(aStream);
  FSwitchTo := ReadPresmasterWord(aStream);
end;

function TPresmasterMessageSwitchTransitionType.ToTextInternal: string;
begin
  result := 'Set Transition Type: ' + IntToS
end;

function TPresmasterMessageSwitchVideo.ToTextInternal: string;
begin
  result := 'Set TX Video ' + IntToStr(SwitchTo);
end;

function TPresmasterMessageSwitchAudio.ToTextInternal: string;
begin
  result := 'Set TX Audio ' + IntToStr(SwitchTo);
end;

function TPresmasterMessageSwitchPresetVideo.ToTextInternal: string;
begin
  result := 'Set Preset Video ' + IntToStr(SwitchTo);
end;

function TPresmasterMessageSwitchPresetAudio.ToTextInternal: string;
begin
  result := 'Set Preset Audio ' + IntToStr(SwitchTo);
end;

end.
