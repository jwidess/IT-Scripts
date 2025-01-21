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

echo !!!-MAKE SURE TO RUN THIS SCRIPT AS AN ADMINISTRATOR-!!!
C:\windows\system32\timeout 5

echo:
pause

cls
echo -------------------------------------------------
echo Checking the Windows partition - procedure 1 of 4
echo -------------------------------------------------
echo Running: chkdsk c: /scan
chkdsk c: /scan
echo -------------------------------------------
echo If chkdsk finds problems, run chkdsk c: /f
echo -------------------------------------------
echo --------------------------
echo PRESS ANY KEY TO CONTINUE.
echo --------------------------
C:\windows\system32\timeout 5
echo ------------------------------------------------
echo Windows component files check - procedure 2 of 4
echo ------------------------------------------------
echo Running: Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase
Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase
echo --------------------------------------------------
echo Phase 1 of 2 completed
echo --------------------------------------------------
echo Running: Dism.exe /online /Cleanup-Image /SPSuperseded
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
echo Running: DISM /Online /Cleanup-Image /CheckHealth
DISM /Online /Cleanup-Image /CheckHealth
echo --------------------------------------------------
echo Phase 1 of 3 completed
echo --------------------------------------------------
echo Running: DISM /Online /Cleanup-Image /ScanHealth
DISM /Online /Cleanup-Image /ScanHealth
echo --------------------------------------------------
echo Phase 2 of 3 completed
echo --------------------------------------------------
echo Running: DISM /Online /Cleanup-Image /RestoreHealth
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
echo Running: sfc /scannow
sfc /scannow
echo --------------------------------------------------------------------------------
echo If SFC found some errors and could not repair, re-run the script after a reboot.
echo --------------------------------------------------------------------------------
echo:
echo When finished press any key...
pause