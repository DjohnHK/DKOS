@echo off
chcp 1252 >nul
wpeinit
powershell set-executionpolicy -executionpolicy unrestricted
powershell start.ps1
