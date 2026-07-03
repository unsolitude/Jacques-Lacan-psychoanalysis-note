@echo off
setlocal

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\obsidian-auto-sync.ps1"
if errorlevel 1 (
  echo.
  echo Obsidian sync failed. Press any key to close this window.
  pause >nul
)
