unit M2100SwitcherClone;

interface

uses
  M2100Switcher,
  CustomSwitcherFactoryUnit;

type
  TM2100SwitcherClone = class(TM2100Switcher)
  
  end;

implementation

initialization
  RegisterSwitcherClass(TM2100SwitcherClone);
end.
