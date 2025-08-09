:: Video inspiration: https://www.youtube.com/watch?v=4AH4SV7bGN0
@ setlocal enableextensions 
@ cd /d "%~dp0"
@echo off
color 09
title FirewallBlockExe
echo ------------------------------------------------------------
echo This script will recursively block all .exe files.
echo Press any key to begin.
echo PLACE THIS .BAT IN THE LOCATION TO BLOCK RECURSIVELY!
echo ------------------------------------------------------------
pause
@echo on

for /R %%f in (*.exe) do (
  netsh advfirewall firewall add rule name="Blocked: %%f" dir=in program="%%f" action=block
  netsh advfirewall firewall add rule name="Blocked: %%f" dir=out program="%%f" action=block
)

pause