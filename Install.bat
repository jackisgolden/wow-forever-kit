@echo off
title WoW Forever Kit
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol='Tls12'; & ([scriptblock]::Create((Invoke-RestMethod -UseBasicParsing 'https://raw.githubusercontent.com/jackisgolden/wow-forever-kit/main/install.ps1')))"
echo.
pause
