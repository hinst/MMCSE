unit ExceptionTracer;

{$DEFINE USE_MAD_EXCEPT}
{ $DEFINE USE_NICE_EXCEPTIONS}

interface

uses
  SysUtils
  {$IFDEF USE_MAD_EXCEPT}
  , madStackTrace
  {$ENDIF}
  {$IFDEF USE_NICE_EXCEPTIONS}
  , NiceExceptions
  {$ENDIF}
  ;

function GetExceptionInfo(const e: Exception): string;

implementation

function GetExceptionInfo(const e: Exception): string;
begin
  {$IFNDEF USE_NICE_EXCEPTIONS}
  result := 'Exception: ' + e.ClassName;
  result := result + sLineBreak + '  "' + e.Message + '"';
  {$ENDIF}
  {$IFDEF USE_MAD_EXCEPT}
  result := result + sLineBreak + StackAddrToStr(ExceptAddr);
  {$ENDIF}
  {$IFDEF USE_NICE_EXCEPTIONS}
  result := GetFullExceptionInfo(e);
  {$ENDIF}
end;

end.
