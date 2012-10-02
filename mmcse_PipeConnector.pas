unit mmcse_PipeConnector;

interface

uses
  UCustomThread,
  M2Pipe;

type
  TPipeReader = class
  public
    constructor Create(const aPipe: T2MPipe);
  protected
    fThread: TCustomThread;
    fPipe: T2MPipe;
    procedure Routine(const aThread: TCustomThread);
  public
    property Thread: TCustomThread read fThread;
    property Pipe: T2MPipe read fPipe;
    destructor Destroy; override;
  end;


implementation

constructor TPipeReader.Create(const aPipe: T2MPipe);
begin
  inherited Create;
  fThread := TCustomThread.Create;
  Thread.OnExecute := Routine;
  Thread.Resume;
end;

procedure TPipeReader.Routine(const aThread: TCustomThread);
begin
  Pipe.WaitForClient;
  while not aThread.Stop do
  begin

  end;
end;

destructor TPipeReader.Destroy;
begin
  if Assigned(Thread) then
  begin
    Thread.WaitFor;
    Thread.Free;
  end;
  inherited Destroy;
end;

end.
