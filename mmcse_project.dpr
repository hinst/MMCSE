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
  mmcse_Application in 'mmcse_Application.pas',
  mmcse_ControlPanel in 'mmcse_ControlPanel.pas',
  M2100Command in 'M2100Command.pas',
  M2100Message in 'M2100Message.pas',
  M2100MessageDecoder in 'M2100MessageDecoder.pas',
  M2100Keyer in 'M2100Keyer.pas';

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









