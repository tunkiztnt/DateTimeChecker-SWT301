@echo off
chcp 65001 > nul
cd /d "%~dp0..\.."
title DateTimeChecker - API Testing Server (Postman)

echo ============================================================
echo  STARTING API SERVER FOR TOPIC 1 DEMO (Postman)
echo ============================================================
echo.

echo [1/3] Compiling Java backend...
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\build.ps1" > nul 2>&1

echo [2/3] Starting backend server in the background...
start /b java -cp out/classes com.datetimechecker.App > nul 2>&1
timeout /t 2 /nobreak > nul

echo [3/3] Server is running at http://localhost:4173!
echo.
echo Please open Postman, import the collection:
echo "topics\01-api-testing\DateTimeChecker.postman_collection.json"
echo and run the requests.
echo.
echo Press ANY KEY in this window to stop the server when you are done.
echo ============================================================
echo.
pause

echo [INFO] Stopping backend server...
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\stop-server.ps1" > nul 2>&1
echo.
exit /b 0
