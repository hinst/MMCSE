unit PresmasterSwitcherMessage;

{ $Define ClassToText}

interface

uses
  SysUtils,
  Classes,

  UAdditionalTypes,
  UAdditionalExceptions,
  UStreamUtilities,

  EmptyLogEntity,
  DefaultLogEntity,

  CommonUnit,
  CustomSwitcherMessageUnit;

type
  TPresmasterMessageClass = class of TPresmasterMessage;

  TPresmasterMessage = class(TCustomSwitcherMessage)
  public
    constructor Create; override;
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
    AnswerSwitchTransitionType = $41;
    AnswerSwitchVideoPresetCommand = $4B;
    AnswerSwitchAudioPresetCommand = $4C;
    AnswerPollCommand = $5E;
    {$EndRegion}
    {$Region ExtendedCommands}
    VoiceoverArmCommand = $0013;
    AnswerVoiceoverArmCommand = $0813;
    {$EndRegion}
  protected
    FFormat: byte;
    FCommand: word;
    FLog: TEmptyLog;
    function ToTextInternal: string; override;
  public
    property Format: byte read FFormat write FFormat;
    property Command: word read FCommand write FCommand;
    property Log: TEmptyLog read FLog;
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
    class function SimpleCommandToText(const aCommand: Word): string;
    class function ExtendedCommandToText(const aCommand: Word): string;
    procedure ReadSpecific(const aStream: TStream); virtual;
    procedure WriteSpecific(const aStream: TStream); virtual;
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
    constructor Create; overload; override;
    constructor Create(const aSwitchTo: Word); overload;
  protected
    FSwitchTo: Word;
    function ToTextInternal: string; override;
  public
    property SwitchTo: Word read FSwitchTo write FSwitchTo;
    procedure ReadSpecific(const aStream: TStream); override;
    procedure WriteSpecific(const aStream: TStream); override;
  end;

  // HEX 01
  TPresmasterMessageSwitchTransitionType = class(TPresmasterMessageSwitch)
  protected
    function ToTextInternal: string; override;
  end;

  // HEX 41 ->
  TPresmasterMessageSwitchTransitionTypeReport = class(TPresmasterMessageSwitch)
  public
    constructor Create; override;
  protected
    function ToTextInternal: string; override;
  end;

  // HEX 09
  TPresmasterMessageSwitchVideo = class(TPresmasterMessageSwitch)
  protected
    function ToTextInternal: string; override;
  end;

  // HEX 0A
  TPresmasterMessageSwitchAudio = class(TPresmasterMessageSwitch)
  protected
    function ToTextInternal: string; override;
  end;

  // HEX 0B
  TPresmasterMessageSwitchPresetVideo = class(TPresmasterMessageSwitch)
  protected
    function ToTextInternal: string; override;
  end;

  TPresmasterMessageSwitchPresetVideoAnswer = class(TPresmasterMessageSwitch)
  public
    constructor Create; override;
  protected
    function ToTextInternal: string; override;
  end;

  TPresmasterMessageSwitchPresetAudio = class(TPresmasterMessageSwitch)
  protected
    function ToTextInternal: string; override;
  end;

  TPresmasterMessageSwitchPresetAudioAnswer = class(TPresmasterMessageSwitch)
  public
    constructor Create; override;
  protected
    function ToTextInternal: string; override;
  end;

implementation

constructor TPresmasterMessage.Create;
begin
  inherited Create;
  FLog := TLog.Create(GlobalLogManager, self.ClassName);
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

class function TPresmasterMessage.CommandToHex(const aFormat: Byte; const aCommand: Word): string;
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

class function TPresmasterMessage.CommandToText(const aFormat: Byte; const aCommand: Word): string;
begin
  case aFormat of
  FormatSimple:
    result := SimpleCommandToText(aCommand);
  FormatExtended:
    result := ExtendedCommandToText(aCommand);
  else
    result := 'Unknown: ' + CommandToHex(aFormat, aCommand) + '; format: unknown';
  end;
end;

class function TPresmasterMessage.SimpleCommandToText(const aCommand: Word): string;
begin
  case aCommand of
  SetAUXBusCommand:
    result := 'Set AUX Bus';
  SetTXVideo:
    result := 'Set TX Video';
  SetTXAudio:
    result := 'Set TX Audio';
  SetPresetVideo:
    result := 'Set Preset Video';
  SetPresetAudio:
    result := 'Set Preset Audio';
  PollCommand:
    result := 'Poll';
  AnswerPollCommand:
    result := 'AnswerPoll';
  else
    result := 'Unknown simple: ' + CommandToHex(FormatSimple, aCommand);
  end;
end;

class function TPresmasterMessage.ExtendedCommandToText(const aCommand: Word): string;
begin
  result := '';
  case aCommand of
  VoiceoverArmCommand:
    result := 'Voiceover Arm';
  AnswerVoiceoverArmCommand:
    result := 'Answer Voiceover Arm';
  end;
end;

procedure TPresmasterMessage.ReadSpecific(const aStream: TStream);
begin
end;

procedure TPresmasterMessage.WriteSpecific(const aStream: TStream);
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
  Format := FormatSimple;
  Command := AnswerPollCommand;
end;

// You should assign Command property in derived constructors
constructor TPresmasterMessageSwitch.Create;
begin
  inherited Create;
  Format := FormatSimple;
end;

constructor TPresmasterMessageSwitch.Create(const aSwitchTo: Word);
begin
  Create;
  SwitchTo := aSwitchTo;
end;

function TPresmasterMessageSwitch.ToTextInternal: string;
begin
  result := 'Switch to ' + IntToStr(SwitchTo);
end;

// not sure about whether this function is implemented correctly or not
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

procedure WritePresmasterWord(const aStream: TStream; const aWord: Word);
var
  x: byte;
begin
  AssertAssigned(aStream, 'aStream', TVariableType.Argument);
  if aWord < $7F then
  begin
    x := byte(aWord);
    aStream.Write(x, 1)
  end
  else
  begin
    x := byte(aWord) and $7F;
    aStream.Write(x, 1);
    x := byte(aWord shr 7) and $7F;
    aStream.Write(x, 1);
  end;
end;

procedure TPresmasterMessageSwitch.ReadSpecific(const aStream: TStream);
begin
  SwitchTo := ReadPresmasterWord(aStream);
end;

procedure TPresmasterMessageSwitch.WriteSpecific(const aStream: TStream);
begin
  WritePresmasterWord(aStream, SwitchTo);
end;

function TPresmasterMessageSwitchTransitionType.ToTextInternal: string;
begin
  result := 'Set Transition Type: ' + IntToStr(SwitchTo);
end;


constructor TPresmasterMessageSwitchTransitionTypeReport.Create;
begin
  inherited Create;
  Command := AnswerSwitchTransitionType;
end;

function TPresmasterMessageSwitchTransitionTypeReport.ToTextInternal: string;
begin
  result := 'Transition Type Set: ' + IntToStr(SwitchTo);
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

constructor TPresmasterMessageSwitchPresetVideoAnswer.Create;
begin
  inherited Create;
  Command := AnswerSwitchAudioPresetCommand;
end;

function TPresmasterMessageSwitchPresetVideoAnswer.ToTextInternal: string;
begin
  result := 'Set Preset Video Answer ' + IntToStr(SwitchTo);
end;

constructor TPresmasterMessageSwitchPresetAudioAnswer.Create;
begin
  inherited Create;
  Command := AnswerSwitchAudioPresetCommand;
end;

function TPresmasterMessageSwitchPresetAudio.ToTextInternal: string;
begin
  result := 'Set Preset Audio ' + IntToStr(SwitchTo);
end;

function TPresmasterMessageSwitchPresetAudioAnswer.ToTextInternal: string;
begin
  result := 'Set Preset Audio Answer ' + IntToStr(SwitchTo);
end;


end.
