@echo off
color 09
title WinFix Script
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
echo ! The script contains 4 procedures.
echo ! The 1st procedure checks the disk - regular Checkdisk - 1 phase
echo ! The 2nd procedure checks and repairs the Windows Component Files - 2 phases
echo ! The 3rd procedure checks and repairs the Windows image - 4 phases
echo ! The 4th procedure uses System file check to check system files - 1 phase
echo ! In Windows 7 only CHKDSK and SFC work, the rest is new (Windows 8 +)
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
echo:

:: BatchGotAdmin
:-------------------------------------
REM  --> Check for permissions
    IF "%PROCESSOR_ARCHITECTURE%" EQU "amd64" (
>nul 2>&1 "%SYSTEMROOT%\SysWOW64\cacls.exe" "%SYSTEMROOT%\SysWOW64\config\system"
) ELSE (
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
)

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params = %*:"=""
    echo UAC.ShellExecute "cmd.exe", "/c ""%~s0"" %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"
:--------------------------------------

echo:
pause

cls
echo -------------------------------------------------
echo Checking the Windows partition - procedure 1 of 4
echo -------------------------------------------------
chkdsk c: /scan
echo -------------------------------------------
echo If it finds some problems, run chkdsk c: /f
echo -------------------------------------------
echo --------------------------
echo PRESS ANY KEY TO CONTINUE.
echo --------------------------
C:\windows\system32\timeout 5
echo ------------------------------------------------
echo Windows component files check - procedure 2 of 4
echo ------------------------------------------------
Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase
echo --------------------------------------------------
echo Phase 1 of 2 completed
echo --------------------------------------------------
Dism.exe /online /Cleanup-Image /SPSuperseded
echo --------------------------------------------------
echo Phase 2 of 2 completed
echo --------------------------
echo PRESS ANY KEY TO CONTINUE.
echo --------------------------
C:\windows\system32\timeout 5
echo --------------------------------------------------------------
echo Checking the integrity of the Windows image - procedure 3 of 4
echo --------------------------------------------------------------
DISM /Online /Cleanup-Image /CheckHealth
echo --------------------------------------------------
echo Phase 1 of 3 completed
echo --------------------------------------------------
DISM /Online /Cleanup-Image /ScanHealth
echo --------------------------------------------------
echo Phase 2 of 3 completed
echo --------------------------------------------------
DISM /Online /Cleanup-Image /RestoreHealth
echo --------------------------------------------------
echo Phase 3 of 3 completed 
echo --------------------------
echo PRESS ANY KEY TO CONTINUE.
echo --------------------------
C:\windows\system32\timeout 5
echo -------------------------------------------------
echo Running System file check - procedure 4 of 4
echo -------------------------------------------------
sfc /scannow
echo --------------------------------------------------------------------------------
echo If SFC found some errors and could not repair, re-run the script after a reboot.
echo --------------------------------------------------------------------------------
echo:
echo When finished press any key...
pause