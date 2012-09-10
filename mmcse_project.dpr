program mmcse_project;

{$APPTYPE CONSOLE}

uses
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  SysUtils,
  Classes,
  WindowsPipes,
  M2Pipe,
  LogLibraryDynamicModule,
  LogGlobalModule,
  PublicLogManagerFace,
  PublicLogFormatFace,
  PublicLogWriterFace,
  PublicLogTextFormat,
  LogEntityFace,
  LogEntityWrapper,
  StreamVisualizer,
  M2100MessageDecoder,
  M2100PipeThreader,
  ExceptionTracer,
  mmcse_common,
  M2100Command,
  M2100Message;

type
  TApplication = class
  public
    constructor Create;
  private
    fLog: ILogEntity;
    fLogManager: ILogManager;
    fThread: TM2100PipeThread;
    procedure InitializeLog;
    procedure ActualRun;
    procedure SafeRun;
  public
    property Log: ILogEntity read fLog;
    property LogManager: ILogManager read fLogManager;
    property Thread: TM2100PipeThread read fThread;
    procedure Run;
    destructor Destroy; override;
  end;

procedure WriteLine(const aText: PChar); safecall;
begin
  WriteLN(string(aText));
end;

procedure TApplication.ActualRun;
begin
  fThread := TM2100PipeThread.Create;
  Thread.Log := TLog.Create('PT', LogManager);
  Thread.Resume;
  Thread.WaitFor;
end;

constructor TApplication.Create;
begin
  inherited Create;
  InitializeLog;
end;

procedure TApplication.InitializeLog;
var
  clw: ILogWriterExternal;
  fmt: ILogFormatExternal;
begin
  fLogManager := GlobalLogFace.CreateLogManager;
  GlobalLogManager := LogManager;
  fLog := TLog.Create('App', LogManager);
  clw := GlobalLogFace.CreateConsoleLogWriter;
  (clw as IHasWriteProcedure).WriteProcedure := @ WriteLine;
  fmt := GlobalLogFace.CreateSimpleTextLogFormat;
  (fmt as IHasFormatString).FormatString := 'OBJECT: TEXT';
  clw.Format := fmt;
  LogManager.AddWriter(clw);
end;

procedure TApplication.Run;
begin
  Log.Write('Now running application...');
  SafeRun;
end;

procedure TApplication.SafeRun;
begin
  try
    ActualRun;
  except
    on e: Exception do
    begin
      WriteLN('Exception: ' + e.ClassName);
      WriteLN('Exc.messg: "' + e.Message + '"');
    end;
  end;
end;

destructor TApplication.Destroy;
begin
  WriteLN('Application is releasing global log manager...');
  GlobalLogManager := nil;
  inherited;
end;

var
  application: TApplication;

begin
  InitializeLogLibrary(GetEnvironmentVariable('LOGLIBRARY')
    + PathDelim + 'Library' + PathDelim + 'LogLibrary.dll');
  application := TApplication.Create;
  application.Run;
  application.Free;
  WriteLN('GLOBAL: Releasing log library');
  FinalizeLogLibrary;
  WriteLN('GLOBAL: EXECUTION END.');
  Sleep(1000);
end.
