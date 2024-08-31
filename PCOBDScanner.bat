@echo off
title Comprehensive PC Diagnostic Scan
cls

:: Check for administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
    cls
)
cls
:main
cls
echo =======================================================
echo                     PC OBD Scanner
echo 1. Option 1 - Start
echo 2. Option 2 - Exit
echo             Thanks For using this program
echo =======================================================
set /p choice="Please choose an option (1-2): "

if "%choice%"=="1" goto startscan
if "%choice%"=="2" goto exit

echo Invalid Choice Please Select From (1-2)
pause
goto main

:startscan
cls
REM Initialize variables to store test results
setlocal enabledelayedexpansion
set healthy=True
set disk_status=UNKNOWN
set file_check_status=UNKNOWN
set log_status=UNKNOWN
set network_status=UNKNOWN
set internet_status=UNKNOWN
set cpu_status=UNKNOWN
set memory_status=UNKNOWN

echo.
echo --- System Information ---
systeminfo | findstr /B /C:"OS Name" /C:"OS Version" /C:"System Type" /C:"Total Physical Memory" /C:"Available Physical Memory"
echo.

echo --- Checking Disk Health (SMART) ---
echo Please wait...
wmic diskdrive get status | find /i "OK" >nul
if %errorlevel% equ 0 (
    set disk_status=PASSED
) else (
    set disk_status=FAILED
    set healthy=False
)
echo Disk Health: %disk_status%
echo.

echo --- Checking for Corrupted Files ---
sfc /scannow >nul
if %errorlevel% equ 0 (
    set file_check_status=PASSED
) else (
    set file_check_status=FAILED
    set healthy=False
)
echo Corrupted Files Check: %file_check_status%
echo.

echo --- Checking System Logs for Errors ---
set error_count=0
for /f "tokens=*" %%A in ('wevtutil qe System /c:10 /rd:true /f:text /q:"*[System[(Level=1 or Level=2)]]" ^| find /i "Error"') do (
    echo %%A
    set /a error_count+=1
)
if !error_count! gtr 0 (
    set log_status=FAILED
    set healthy=False
) else (
    set log_status=PASSED
)
echo System Logs Check: %log_status%
echo.

echo --- Checking Network Configuration ---
ipconfig /all | find /i "Media disconnected" >nul
if %errorlevel% equ 0 (
    set network_status=FAILED
    set healthy=False
) else (
    set network_status=PASSED
)
echo Network Configuration: %network_status%
echo.

echo --- Checking for Network Connectivity ---
ping google.com -n 3 | find /i "Reply from" >nul
if %errorlevel% equ 0 (
    set internet_status=PASSED
) else (
    set internet_status=FAILED
    set healthy=False
)
echo Internet Connectivity: %internet_status%
echo.

echo --- Checking CPU Load ---
set /a cpu_load=0
for /f "tokens=2 delims==" %%A in ('wmic cpu get loadpercentage /value') do (
    set /a cpu_load=%%A
)
if !cpu_load! lss 80 (
    set cpu_status=PASSED
) else (
    set cpu_status=FAILED
    set healthy=False
)
echo CPU Load: !cpu_load!%% - %cpu_status%
echo.

echo --- Checking Available Memory ---
for /f "tokens=2 delims==" %%A in ('wmic os get freephysicalmemory /value') do (
    set free_mem=%%A
)
set /a free_mem_mb=!free_mem!/1024
echo Free Memory: !free_mem_mb! MB
if !free_mem_mb! gtr 1024 (
    set memory_status=PASSED
) else (
    set memory_status=FAILED
    set healthy=False
)
echo Memory Status: %memory_status%
echo.

cls
echo =======================================================
echo                 Final Health Report
echo =======================================================
echo Disk Health Check:            %disk_status%
echo Corrupted Files Check:        %file_check_status%
echo System Logs Check:            %log_status%
echo Network Configuration:        %network_status%
echo Internet Connectivity:        %internet_status%
echo CPU Load Check:               %cpu_status%
echo Available Memory:             %memory_status%
echo -------------------------------------------------------
if "%healthy%" == "True" (
    echo Overall Status:            PASSED - Your system is healthy!
) else (
    echo Overall Status:            FAILED - Issues detected, please review.
)
echo =======================================================
pause
goto main

:exit
cls
exit