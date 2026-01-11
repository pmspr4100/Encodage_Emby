@echo off
setlocal EnableExtensions DisableDelayedExpansion
chcp 65001 >nul

:MENU
cls
echo ============================================
echo      OPTIMISEUR HANDBRAKE 10-BIT V18.7
echo ============================================
echo STATUS : Arborescence Logs Miroir (Z:\Logs)
echo ============================================
echo [S, T, U, V, W, X, Y] ou [Q] Quitter
echo --------------------------------------------

choice /c STUVWXYQ /n /m "Appuyez sur la lettre du lecteur : "
set SEL=%errorlevel%
if %SEL% EQU 8 exit /b

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

:: --- CORRECTION DE LA LOGIQUE DES LANGUES ---
set "LANG=fra"
if "%L_SFX%"=="T" set "LANG=jpn,fra"
if "%L_SFX%"=="W" set "LANG=jpn,fra"

echo [INFO] Analyse de %ROOT%...

:: --- BOUCLE DE SCAN RÉCURSIVE ---
for /f "delims=" %%F in ('dir "%ROOT%*.mkv" "%ROOT%*.mp4" "%ROOT%*.avi" "%ROOT%*.mov" "%ROOT%*.wmv" "%ROOT%*.m4v" "%ROOT%*.mpeg" /s /b 2^>nul') do (
    
    set "F_PATH=%%~dpF"
    set "F_BASE=%%~nF"
    
    setlocal EnableDelayedExpansion
    set "REL_PATH=!F_PATH:%ROOT%=!"
    set "LOG_DIR=%L_ROOT%\!REL_PATH!"
    set "LOG_FILE=!LOG_DIR!!F_BASE!.txt"
    
    if exist "!LOG_FILE!" (
        echo [IGNORE] !F_BASE! [cite: 3]
        endlocal
    ) else (
        endlocal
        call :PROCESS "%%F"
    )
)
echo [FIN] Scan terminé.
pause [cite: 5]
goto MENU

:PROCESS
set "S_F=%~1"
set "S_N=%~nx1"
set "S_B=%~n1"
set "S_D=%~dp1"

:: Recalcul du dossier log sans expansion retardée (Solution A)
set "P_REL=%S_D%"
call set "P_REL=%%P_REL:%ROOT%=%%"
set "P_LOG_DIR=%L_ROOT%\%P_REL%"
set "P_LOG_FILE=%P_LOG_DIR%%S_B%.txt"

echo --------------------------------------------------------
echo [TRAVAIL] Fichier : "%S_B%"
echo [LOG DIR] : "%P_LOG_DIR%"
set "O_F=%T_DIR%\work_%L_SFX%_temp.mkv" [cite: 7]
if exist "%O_F%" del /f /q "%O_F%"

"%HB%" -i "%S_F%" -o "%O_F%" -e nvenc_h265_10bit -q 28 --encoder-preset slow --maxWidth 1920 --loose-anamorphic --modulus 2 --audio-lang-list %LANG% -E aac -B 320 --audio-fallback ac3 --all-subtitles --markers

if not exist "%O_F%" (
    echo [ERREUR] HandBrake a échoué sur "%S_B%"
    exit /b
)

:: RENOMMAGE ET DÉPLACEMENT
ren "%S_F%" "%S_N%.old" 2>nul
move /y "%O_F%" "%S_D%%S_B%.mkv" >nul

if %errorlevel% EQU 0 (
    if exist "%S_D%%S_N%.old" del /f /q "%S_D%%S_N%.old" 2>nul
    
    if not exist "%P_LOG_DIR%" mkdir "%P_LOG_DIR%" 2>nul 
    echo OK > "%P_LOG_FILE%"
    echo [OK] Témoin créé : "%P_LOG_FILE%"
) else (
    if exist "%S_D%%S_N%.old" ren "%S_D%%S_N%.old" "%S_N%"
    echo [ERREUR] Échec du déplacement final.
)
exit /b