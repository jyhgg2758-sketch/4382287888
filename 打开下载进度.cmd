@echo off
setlocal
cd /d "%~dp0"

set "DASHBOARD_PYTHONW="
for /f "delims=" %%P in ('where pythonw.exe 2^>nul') do if not defined DASHBOARD_PYTHONW set "DASHBOARD_PYTHONW=%%P"
if not defined DASHBOARD_PYTHONW if exist "D:\SoftWare\Anaconda\pythonw.exe" set "DASHBOARD_PYTHONW=D:\SoftWare\Anaconda\pythonw.exe"

if not defined DASHBOARD_PYTHONW (
  echo [ERROR] Python GUI runtime was not found.
  echo Please run: python scripts\download-dashboard.py
  pause
  exit /b 1
)

start "" "%DASHBOARD_PYTHONW%" "%~dp0scripts\download-dashboard.py"
