@echo off
setlocal EnableExtensions DisableDelayedExpansion
chcp 65001 >nul

:MENU
cls
echo ============================================
echo      OPTIMISEUR EMBY 10-BIT V18.9.6
echo ============================================
echo STATUS : Puissance Maximale (Sans Bridage)
echo LOGS   : Miroir .txt (Succès et Erreurs)
echo ============================================
echo [S, T, U, V, W, X, Y] ou [Q] Quitter
echo --------------------------------------------

choice /c STUVWXYQ /n /m "Appuyez sur la lettre du lecteur : "
set SEL=%errorlevel%

if %SEL% EQU 8 goto :QUIT

set "L_SFX="
if %SEL% EQU 1 set "L_SFX=S"
if %SEL% EQU 2 set "L_SFX=T"
if %SEL% EQU 3 set "L_SFX=U"
if %SEL% EQU 4 set "L_SFX=V"
if %SEL% EQU 5 set "L_SFX=W"
if %SEL% EQU 6 set "L_SFX=X"
if %SEL% EQU 7 set "L_SFX=Y"

set "ROOT=%L_SFX%:\"
set "T_DIR=Z:\Encoder_Emby"
set "L_BASE=Z:\Encoder_Emby\Logs"
set "L_ROOT=%L_BASE%\Logs_%L_SFX%"
set "L_ERR_ROOT=%L_BASE%\Logs_ERREURS\%L_SFX%"
set "HB=C:\Program Files\HandBrake\HandBrakeCLI.exe"

set "LANG=fra"
if "%L_SFX%"=="T" set "LANG=jpn,fra"
if "%L_SFX%"=="W" set "LANG=jpn,fra"

echo [INFO] Analyse de %ROOT%...

:: --- BOUCLE DE SCAN ---
for /f "delims=" %%F in ('dir "%ROOT%*.mkv" "%ROOT%*.mp4" "%ROOT%*.avi" "%ROOT%*.mov" /s /b 2^>nul') do (
    set "F_PATH=%%~dpF"
    set "F_BASE=%%~nF"
    
    setlocal EnableDelayedExpansion
    :: On nettoie REL_PATH pour éviter les doubles slashes
    set "REL_PATH=!F_PATH:%ROOT%=!"
    
    :: CHEMINS ABSOLUS SANS RAJOUT DE SLASH (REL_PATH le contient déjà)
    set "CHECK_OK=%L_ROOT%\!REL_PATH!!F_BASE!.txt"
    set "CHECK_ERR=%L_ERR_ROOT%\!REL_PATH!!F_BASE!.txt"
    
    :: TEST DE PRÉSENCE ULTRA-STRICT
    if exist "!CHECK_OK!" (
        echo [IGNORE - OK] !F_BASE!
        endlocal
    ) else if exist "!CHECK_ERR!" (
        echo [IGNORE - ERR] !F_BASE!
        endlocal
    ) else (
        endlocal
        call :PROCESS "%%F"
    )
)

:QUIT
echo --------------------------------------------
echo [FIN] Scan terminé.
pause
goto MENU

:PROCESS
set "S_F=%~1"
set "S_N=%~nx1"
set "S_B=%~n1"
set "S_D=%~dp1"

setlocal EnableDelayedExpansion
:: Récupération du chemin relatif
set "P_REL=!S_D:%ROOT%=!"

:: Dossiers CIBLES (MD créera Aladdin\Saison 01 automatiquement)
set "D_OK=%L_ROOT%\!P_REL!"
set "D_ERR=%L_ERR_ROOT%\!P_REL!"

:: Fichiers LOGS
set "F_OK=%D_OK%!S_B!.txt"
set "F_ERR=%D_ERR%!S_B!.txt"

echo --------------------------------------------------------
echo [TRAVAIL] !S_B!
set "O_F=%T_DIR%\work_%L_SFX%_temp.mkv"
if exist "!O_F!" del /f /q "!O_F!"

:: --- APPEL HANDBRAKE ---
"%HB%" -i "!S_F!" -o "!O_F!" -e nvenc_h265_10bit -q 28 --encoder-preset fast --maxWidth 1920 --audio-lang-list %LANG% --all-subtitles --markers

if not exist "!O_F!" (
    :: CRÉATION ARBORESCENCE POUR ERREUR
    if not exist "!D_ERR!" md "!D_ERR!" 2>nul
    echo [%DATE% %TIME%] Erreur HandBrake > "!F_ERR!"
    echo [ERREUR] Log créé : "!F_ERR!"
    endlocal
    exit /b
)

:: --- DÉPLACEMENT ---
ren "!S_F!" "!S_N!.old" 2>nul
move /y "!O_F!" "!S_D!!S_B!.mkv" >nul

if !errorlevel! EQU 0 (
    if exist "!S_D!!S_N!.old" del /f /q "!S_D!!S_N!.old"
    :: CRÉATION ARBORESCENCE POUR SUCCÈS
    if not exist "!D_OK!" md "!D_OK!" 2>nul
    echo OK > "!F_OK!"
    if exist "!F_ERR!" del /f /q "!F_ERR!"
    echo [OK] Terminé. Log : "!F_OK!"
) else (
    if exist "!S_D!!S_N!.old" ren "!S_D!!S_N!.old" "!S_N!"
    if not exist "!D_ERR!" md "!D_ERR!" 2>nul
    echo [%DATE% %TIME%] Erreur Move > "!F_ERR!"
)
endlocal
exit /b