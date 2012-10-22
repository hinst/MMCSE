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
  Forms,
  ExceptionTracer,
  mmcse_common in 'mmcse_common.pas',
  mmcse_MainWindow in 'mmcse_MainWindow.pas',
  M2100Switcher in 'M2100Switcher.pas',
  M2Pipe in 'M2Pipe.pas',
  mmcse_PipeConnector in 'mmcse_PipeConnector.pas',
  mmcse_project_ApplicationClass in 'mmcse_project_ApplicationClass.pas',
  mmcse_ControlPanel in 'mmcse_ControlPanel.pas';

var
  application: TMMCSEApplication;

begin
  try
    application := TMMCSEApplication.Create;
    application.Run;
    application.Free;
  except
    on e: Exception do
      if IsConsole then
        WriteLN('GLOBAL EXCEPTION:' + sLineBreak + GetExceptionInfo(e));
  end;
end.






