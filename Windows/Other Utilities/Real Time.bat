@ECHO OFF
TITLE Precise Time
MODE 30,3
SETLOCAL EnableDelayedExpansion
REM pull a CarriageReturn from output of dummy copy error
FOR /f %%a in ('copy /Z "%~dpf0" nul') DO SET "CR=%%a"
ECHO.
:TIMER
<nul set /p ".=%time% !cr!          "
GOTO :TIMER