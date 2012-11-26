unit SwitcherFactoryUnit;

interface

uses
  SysUtils,
  Contnrs,

  UAdditionalExceptions,

  CustomSwitcherUnit;

function GetGlobalSwitcherClasses: TClassList; 

function RegisterSwitcherClass(const aClass: TCustomSwitcherClass): integer;

function SwitcherClassRegistred(const aClass: TCustomSwitcherClass): boolean;

function GetSwitcherClassByName(const aClassName: string): TCustomSwitcherClass;

function CreateSwitcherInstance(const aClassName: string): TCustomSwitcher;


implementation

var
  GlobalSwitcherClasses: TClassList;

function GetGlobalSwitcherClasses: TClassList;
begin
  result := GlobalSwitcherClasses;
end;

function GetCreateGlobalRegistredSwitchers: TClassList;
begin
  if GlobalSwitcherClasses = nil then
    GlobalSwitcherClasses := TClassList.Create;
  result := GlobalSwitcherClasses;
end;

function RegisterSwitcherClass(const aClass: TCustomSwitcherClass): integer;
begin
  if SwitcherClassRegistred(aClass) then
    raise EDuplicateClass.Create(aClass);
  result := GetCreateGlobalRegistredSwitchers.Add(aClass);
end;

function SwitcherClassRegistred(const aClass: TCustomSwitcherClass): boolean;
begin
  result := GetCreateGlobalRegistredSwitchers.IndexOf(aClass) >= 0;
end;

function GetSwitcherClassByName(const aClassName: string): TCustomSwitcherClass;
var
  i: integer;
begin
  if GlobalSwitcherClasses = nil then
  begin
    result := nil;
    exit;
  end;
  result := nil;
  for i := 0 to GlobalSwitcherClasses.Count - 1 do
    if GlobalSwitcherClasses[i].ClassName = aClassName then
    begin
       result := TCustomSwitcherClass(GlobalSwitcherClasses[i]);
       break;
    end;
end;

function CreateSwitcherInstance(const aClassName: string): TCustomSwitcher;
var
  c: TCustomSwitcherClass;
begin
  c := GetSwitcherClassByName(aClassName);
  if c = nil then
  begin
    result := nil;
    exit;
  end
  else
    result := c.Create;
end;

initialization
  RegisterSwitcherClass(TCustomSwitcher);
finalization
  FreeAndNil(GlobalSwitcherClasses);
end.
