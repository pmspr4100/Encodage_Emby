@echo off
setlocal EnableExtensions DisableDelayedExpansion
chcp 65001 >nul

:: --- SAUVEGARDE DU MODE D'ALIMENTATION ---
for /f "tokens=3,4" %%i in ('powercfg /getactivescheme') do set "OLD_SCHEME=%%i"

:MENU
cls
echo ============================================
echo      OPTIMISEUR EMBY 10-BIT V18.9.5
echo ============================================
echo STATUS : Bridage CPU 50%% (Silencieux)
echo LOGS   : Miroir Succès ET Erreurs (Z:\Logs)
echo ============================================
echo [S, T, U, V, W, X, Y] ou [Q] Quitter
echo --------------------------------------------

set "SEL="
choice /c STUVWXYQ /n /m "Appuyez sur la lettre du lecteur : "
set SEL=%errorlevel%

:: Gestion de la sortie
if %SEL% EQU 8 goto :QUIT

:: Mapping direct (plus robuste)
set "L_SFX="
if %SEL% EQU 1 set "L_SFX=S"
if %SEL% EQU 2 set "L_SFX=T"
if %SEL% EQU 3 set "L_SFX=U"
if %SEL% EQU 4 set "L_SFX=V"
if %SEL% EQU 5 set "L_SFX=W"
if %SEL% EQU 6 set "L_SFX=X"
if %SEL% EQU 7 set "L_SFX=Y"

:: Vérification de sécurité
if "%L_SFX%"=="" goto :MENU

set "ROOT=%L_SFX%:\"
set "T_DIR=Z:\Encoder_Emby"
set "L_BASE=Z:\Encoder_Emby\Logs"
set "L_ROOT=%L_BASE%\Logs_%L_SFX%"
set "L_ERR_ROOT=%L_BASE%\Logs_ERREURS\%L_SFX%"
set "HB=C:\Program Files\HandBrake\HandBrakeCLI.exe"

:: --- BRIDAGE CPU ---
powercfg /setactive 961cc777-2547-4f9d-8174-7d86181b8a7a >nul 2>&1
powercfg /setacvalueindex 961cc777-2547-4f9d-8174-7d86181b8a7a SUB_PROCESSOR PROCTHROTTLEMAX 50 >nul 2>&1
powercfg /setactive 961cc777-2547-4f9d-8174-7d86181b8a7a >nul 2>&1

:: Langues
set "LANG=fra"
if "%L_SFX%"=="T" set "LANG=jpn,fra"
if "%L_SFX%"=="W" set "LANG=jpn,fra"

echo [INFO] Analyse de %ROOT% en cours...

:: --- SCAN ---
for /f "delims=" %%F in ('dir "%ROOT%*.mkv" "%ROOT%*.mp4" "%ROOT%*.avi" "%ROOT%*.mov" "%ROOT%*.wmv" "%ROOT%*.m4v" "%ROOT%*.mpeg" /s /b 2^>nul') do (
    set "F_PATH=%%~dpF"
    set "F_BASE=%%~nF"
    setlocal EnableDelayedExpansion
    set "REL_PATH=!F_PATH:%ROOT%=!"
    set "LOG_FILE=%L_ROOT%\!REL_PATH!!F_BASE!.txt"
    if exist "!LOG_FILE!" (
        echo [IGNORE] !F_BASE!
        endlocal
    ) else (
        endlocal
        call :PROCESS "%%F"
    )
)

:QUIT
powercfg /setactive %OLD_SCHEME% >nul 2>&1
echo --------------------------------------------
echo [FIN] Scan terminé. Mode CPU normal rétabli.
pause
goto MENU

:PROCESS
set "S_F=%~1"
set "S_N=%~nx1"
set "S_B=%~n1"
set "S_D=%~dp1"

setlocal EnableDelayedExpansion
:: Arborescence miroir pour Succès et Erreurs
set "P_REL=!S_D:%ROOT%=!"
set "P_LOG_DIR=%L_ROOT%\!P_REL!"
set "P_LOG_FILE=!P_LOG_DIR!!S_B!.txt"
set "E_LOG_DIR=%L_ERR_ROOT%\!P_REL!"
set "E_LOG_FILE=!E_LOG_DIR!!S_B!.err"

echo --------------------------------------------------------
echo [TRAVAIL] !S_B!
set "O_F=%T_DIR%\work_%L_SFX%_temp.mkv"
if exist "!O_F!" del /f /q "!O_F!"

"%HB%" -i "!S_F!" -o "!O_F!" -e nvenc_h265_10bit -q 28 --encoder-preset slow --maxWidth 1920 --loose-anamorphic --modulus 2 --audio-lang-list %LANG% -E aac -B 320 --audio-fallback ac3 --all-subtitles --markers

if not exist "!O_F!" (
    if not exist "!E_LOG_DIR!" mkdir "!E_LOG_DIR!" 2>nul
    echo [%DATE% %TIME%] Erreur HandBrake > "!E_LOG_FILE!"
    endlocal
    exit /b
)

:: Renommage et Déplacement
ren "!S_F!" "!S_N!.old" 2>nul
move /y "!O_F!" "!S_D!!S_B!.mkv" >nul

if !errorlevel! EQU 0 (
    if exist "!S_D!!S_N!.old" del /f /q "!S_D!!S_N!.old"
    if not exist "!P_LOG_DIR!" mkdir "!P_LOG_DIR!" 2>nul 
    echo OK > "!P_LOG_FILE!"
    if exist "!E_LOG_FILE!" del /f /q "!E_LOG_FILE!"
    echo [OK] Terminé.
) else (
    if exist "!S_D!!S_N!.old" ren "!S_D!!S_N!.old" "!S_N!"
    if not exist "!E_LOG_DIR!" mkdir "!E_LOG_DIR!" 2>nul
    echo [%DATE% %TIME%] Erreur Déplacement > "!E_LOG_FILE!"
)
endlocal
exit /b