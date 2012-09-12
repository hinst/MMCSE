unit M2100Switcher;

interface

uses
  SysUtils,
  Classes,
  Contnrs,

  UAdditionalTypes,
  UAdditionalExceptions,
  UCustomThread,

  CustomLogEntity,
  EmptyLogEntity,

  M2100Message,
  M2100Command,
  M2100MessageDecoder;

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
    TSendResponceMethod = procedure(const aResponce: TStream);
      // nil stream indicates that there is messages data available at the moment
    TReceiveMessageMethod = function: TStream;
  private
    fLog: TCustomLog;
    fKeyers: TM2100KeyerList;
    fReceiveMessage: TReceiveMessageMethod;
    fSendResponse: TSendResponceMethod;
    fThread: TCustomThread;
    procedure ReplaceLog(const aLog: TCustomLog);
    procedure Initialize;
    procedure InitializeKeyers;
    function GetKeyersStatusAsByte: byte;
    function GenerateResponse(const aMessage: TStream): TStream;
    procedure ExecuteSendReceiveThread(const aThread: TCustomThread);
    procedure ProcessMessage(const aStream: TStream);
    procedure Finalize;
  public
    property Log: TCustomLog read fLog write ReplaceLog;
    property Keyers: TM2100KeyerList read fKeyers;
    property ReceiveMessage: TReceiveMessageMethod read fReceiveMessage write fReceiveMessage;
    property SendResponse: TSendResponceMethod read fSendResponse write fSendResponse;
    property Thread: TCustomThread read fThread;
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
  Initialize;
end;

procedure TM2100Switcher.ReplaceLog(const aLog: TCustomLog);
begin
  Log.Free;
  fLog := aLog;
end;

procedure TM2100Switcher.Initialize;
begin
  fLog := TEmptyLog.Create;
  InitializeKeyers;
  fThread := TCustomThread.Create(ExecuteSendReceiveThread);
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

procedure TM2100Switcher.GenerateResponse(const aMessage: TStream);
begin
  
end;

procedure TM2100Switcher.ExecuteSendReceiveThread(const aThread: TCustomThread);
var
  incomingStream: TStream;
begin
  repeat
    incomingStream := ReceiveMessage;
    if Assigned(incomingStream) then
      ProcessMessage(incomingStream);
  until aThread.Stop;
end;

procedure TM2100Switcher.ProcessMessage(const aStream: TStream);
begin

end;

procedure TM2100Switcher.Finalize;
begin
  FreeAndNil(fKeyers);
end;

destructor TM2100Switcher.Destroy;
begin
  Finalize;
  inherited;
end;

end.
