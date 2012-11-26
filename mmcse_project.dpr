program mmcse_project;

{$APPTYPE CONSOLE}

uses
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  Windows,
  SysUtils,
  Classes,
  Forms,
  UExceptionTracer,
  CommonUnit in 'CommonUnit.pas',
  MainWindowUnit in 'MainWindowUnit.pas',
  M2100Switcher in 'M2100Switcher.pas',
  MessageBiDirectionalPipeUnit in 'MessageBiDirectionalPipeUnit.pas',
  SwitcherDebugPipeConnectorUnit in 'SwitcherDebugPipeConnectorUnit.pas',
  MMCSEApplicationUnit in 'MMCSEApplicationUnit.pas',
  ControlPanelUnit in 'ControlPanelUnit.pas',
  M2100Command in 'M2100Command.pas',
  M2100Message in 'M2100Message.pas',
  M2100MessageDecoder in 'M2100MessageDecoder.pas',
  M2100Keyer in 'M2100Keyer.pas',
  CustomSwitcherUnit in 'CustomSwitcherUnit.pas',
  SwitcherFactoryUnit in 'SwitcherFactoryUnit.pas',
  PresmasterSwitcher in 'PresmasterSwitcher.pas';

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









