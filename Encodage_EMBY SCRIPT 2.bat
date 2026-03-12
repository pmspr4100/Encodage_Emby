@echo off
setlocal EnableExtensions DisableDelayedExpansion
chcp 65001 >nul

:: --- RÉCUPÉRATION DU MODE D'ALIMENTATION ACTUEL ---
for /f "tokens=3,4" %%i in ('powercfg /getactivescheme') do set "OLD_SCHEME=%%i"
set "NVSMI=C:\Windows\System32\nvidia-smi.exe"

:MENU
cls
echo ============================================
echo      OPTIMISEUR HANDBRAKE 10-BIT V18.8
echo ============================================
echo STATUS : Bridage CPU 50%% + GPU 25W
echo LOGS   : Arborescence Miroir (Z:\Logs)
echo ============================================
echo [S, T, U, V, W, X, Y] ou [Q] Quitter
echo --------------------------------------------

choice /c STUVWXYQ /n /m "Appuyez sur la lettre du lecteur : "
set SEL=%errorlevel%
if %SEL% EQU 8 (
    powercfg /setactive %OLD_SCHEME%
    if exist "%NVSMI%" "%NVSMI%" -rac >nul 2>&1
    exit /b
)

:: --- CONFIGURATION ---
if %SEL% EQU 1 set "L_SFX=S"
if %SEL% EQU 2 set "L_SFX=T"
if %SEL% EQU 3 set "L_SFX=U"
if %SEL% EQU 4 set "L_SFX=V"
if %SEL% EQU 5 set "L_SFX=W"
if %SEL% EQU 6 set "L_SFX=X"
if %SEL% EQU 7 set "L_SFX=Y"

set "ROOT=%L_SFX%:\"
set "T_DIR=Z:\Encoder_Emby"
set "L_ROOT=Z:\Encoder_Emby\Logs\Logs_%L_SFX%"
set "HB=C:\Program Files\HandBrake\HandBrakeCLI.exe"

:: --- ACTIVER LE BRIDAGE ---
powercfg /setactive 961cc777-2547-4f9d-8174-7d86181b8a7a
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 50
powercfg /setactive SCHEME_CURRENT
if exist "%NVSMI%" "%NVSMI%" -pl 25 >nul 2>&1

set "LANG=fra"
if "%L_SFX%"=="T" set "LANG=jpn,fra"
if "%L_SFX%"=="W" set "LANG=jpn,fra"

echo [INFO] Analyse de %ROOT%...

:: --- BOUCLE DE SCAN ---
:: On utilise une méthode plus simple pour éviter l'erreur "Paramètres non valides"
for /f "delims=" %%F in ('dir "%ROOT%*.mkv" "%ROOT%*.mp4" "%ROOT%*.avi" "%ROOT%*.mov" "%ROOT%*.wmv" "%ROOT%*.m4v" "%ROOT%*.mpeg" /s /b 2^>nul') do (
    
    set "CURRENT_FILE=%%F"
    set "F_PATH=%%~dpF"
    set "F_BASE=%%~nF"
    
    setlocal EnableDelayedExpansion
    set "REL_PATH=!F_PATH:%ROOT%=!"
    set "LOG_DIR=%L_ROOT%\!REL_PATH!"
    set "LOG_FILE=!LOG_DIR!!F_BASE!.txt"
    
    if exist "!LOG_FILE!" (
        echo [IGNORE] !F_BASE!
        endlocal
    ) else (
        :: On transfère la variable proprement avant de sortir du localenabled
        for /f "delims=" %%A in ("!CURRENT_FILE!") do (
            endlocal
            set "S_F=%%A"
            call :PROCESS
        )
    )
)

powercfg /setactive %OLD_SCHEME%
if exist "%NVSMI%" "%NVSMI%" -rac >nul 2>&1
echo [FIN] Scan terminé.
pause
goto MENU

:PROCESS
:: Extraction des infos (gère les virgules et %)
for /f "delims=" %%i in ("%S_F%") do (
    set "S_N=%%~nxi"
    set "S_B=%%~ni"
    set "S_D=%%~dpi"
)

:: Recalcul du dossier log
set "P_REL=%S_D%"
call set "P_REL=%%P_REL:%ROOT%=%%"
set "P_LOG_DIR=%L_ROOT%\%P_REL%"
set "P_LOG_FILE=%P_LOG_DIR%%S_B%.txt"

echo --------------------------------------------------------
echo [TRAVAIL] Fichier : "%S_B%"
set "O_F=%T_DIR%\work_%L_SFX%_temp.mkv"
if exist "%O_F%" del /f /q "%O_F%"

:: Correction pour le caractère %
set "S_F_HB=%S_F:%=%%%"

"%HB%" -i "%S_F_HB%" -o