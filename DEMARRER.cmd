@echo off
cd /d "%~dp0"
start "" /b powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "%~dp0interface.ps1"
