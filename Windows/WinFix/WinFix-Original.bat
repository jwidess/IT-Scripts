@echo off
color 0C
title WinFix script for LinusTechTips forum members made by 191x7
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
echo ! The script contains 4 procedures.
echo ! The 1st procedure checks the disk - regular Checkdisk - 1 phase
echo ! The 2nd procedure checks and repairs the Windows Component Files - 2 phases
echo ! The 3rd procedure checks and repairs the Windows image - 4 phases
echo ! The 4th procedure uses System file check to check system files - 1 phase
echo ! In Windows 7 only CHKDSK and SFC work, the rest is new (Windows 8 +)
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
echo PRESS ANY KEY TO CONTINUE.
pause >null
del null
cls
echo -------------------------------------------------
echo Checking the Windows partition - procedure 1 of 4
echo -------------------------------------------------
chkdsk c: /scan
echo -------------------------------------------
echo If it finds some problems, run chkdsk c: /f
echo -------------------------------------------
echo PRESS ANY KEY TO CONTINUE.
pause >null
del null
cls
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
echo PRESS ANY KEY TO CONTINUE.
pause >null
del null
cls
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
echo PRESS ANY KEY TO CONTINUE.
pause >null
del null
cls
echo -------------------------------------------------
echo Running System file check - procedure 4 of 4
echo -------------------------------------------------
sfc /scannow
echo --------------------------------------------------------------------------------
echo If SFC found some errors and could not repair, re-run the script after a reboot.
echo --------------------------------------------------------------------------------
echo PRESS F TO PAY RESPECTS.
pause >null
del null