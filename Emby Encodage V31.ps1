# ============================================================
#          OPTIMISEUR & AUDITEUR EMBY 10-BIT V31
# ============================================================

$ErrorActionPreference = "Continue"
[Console]::OutputEncoding = [System.Text.Encoding]::Default

# --- INITIALISATION DES TEXTES ---
$TxtSeries   = "Series"
$TxtAnimes   = "Animes"
$TxtIgnore   = "IGNORE"     
$TxtTerminer = "Termine"
$TxtMAJ      = "Mise a jour"
$TxtMajMkv   = "MAJ MKVToolNix"

# --- CONFIGURATION CHEMINS ---
$HB_DIR = "C:\Tools\HandBrake"
$FF_DIR = "C:\Tools\ffmpeg\bin"
$MKV_DIR = "C:\Tools\MKVToolNix"
$HB     = Join-Path $HB_DIR "HandBrakeCLI.exe"
$FF     = Join-Path $FF_DIR "ffmpeg.exe"
$FP     = Join-Path $FF_DIR "ffprobe.exe"
$mkvPropEdit = Join-Path $MKV_DIR "mkvpropedit.exe"

$T_DIR  = "Z:\Encoder_Emby"
$L_BASE = "Z:\Encoder_Emby"

# --- ARCHITECTURE DES LOGS UNIFORMISÉE ---
$D_LOG_VIDEO = Join-Path $L_BASE "Encodage"   
$D_LOG_AUDIO = Join-Path $L_BASE "Audio"      
$D_LOG_ERR   = Join-Path $L_BASE "Erreurs"    

foreach ($dir in ($D_LOG_VIDEO, $D_LOG_AUDIO, $D_LOG_ERR)) {
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
}

# ============================================================
# FONCTIONS DE MISE A JOUR & AUDIT
# ============================================================
function Update-HandBrake {
    Clear-Host
    Write-Host "============================================" -ForegroundColor Yellow
    Write-Host "      $($TxtMAJ.ToUpper()) HANDBRAKE" -ForegroundColor Yellow
    Write-Host "============================================" -ForegroundColor Yellow
    try {
        Write-Host "[+] Recherche de la derniere version..." -NoNewline
        $hbRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/HandBrake/HandBrake/releases/latest" -TimeoutSec 10
        $hbUrl = $hbRelease.assets | Where-Object { $_.name -like "*HandBrakeCLI*-x86_64-Win_64.zip" } | Select-Object -ExpandProperty browser_download_url -First 1
        if ($hbUrl) {
            Write-Host " OK`n[+] Telechargement..." -ForegroundColor Cyan
            $tmp = Join-Path $env:TEMP "hb.zip"
            Invoke-WebRequest -Uri $hbUrl -OutFile $tmp
            Write-Host "[+] Extraction vers $HB_DIR..." -ForegroundColor Cyan
            Expand-Archive -Path $tmp -DestinationPath $HB_DIR -Force
            Remove-Item $tmp -Force
            Write-Host "[OK] HandBrakeCLI mis a jour avec succes." -ForegroundColor Green
        }
    } catch { Write-Host "`n[!] ERREUR : Verifiez les droits Admin ou la connexion." -ForegroundColor Red }
    Write-Host "`nRetour au menu..." -ForegroundColor Gray ; Start-Sleep -Seconds 2
}

function Update-FFmpeg {
    Write-Host "[+] Fermeture des processus FFmpeg en cours..." -ForegroundColor Gray
    Stop-Process -Name "ffmpeg" -Force -ErrorAction SilentlyContinue
    Stop-Process -Name "ffprobe" -Force -ErrorAction SilentlyContinue

    Clear-Host
    Write-Host "============================================" -ForegroundColor Yellow
    Write-Host "        $($TxtMAJ.ToUpper()) FFMPEG" -ForegroundColor Yellow
    Write-Host "============================================" -ForegroundColor Yellow
    try {
        Write-Host "[+] Telechargement du pack stable..." -ForegroundColor Cyan
        $ffUrl = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"
        $tmp = Join-Path $env:TEMP "ff.zip"
        $ext = Join-Path $env:TEMP "ff_ext"
        
        if (Test-Path $ext) { Remove-Item $ext -Recurse -Force }
        
        Invoke-WebRequest -Uri $ffUrl -OutFile $tmp
        Write-Host "[+] Extraction..." -ForegroundColor Cyan
        Expand-Archive -Path $tmp -DestinationPath $ext -Force
        
        $binFiles = Get-ChildItem -Path $ext -Filter "*.exe" -Recurse | Where-Object { $_.Name -match "ffmpeg|ffprobe" }
        
        if ($binFiles) {
            if (-not (Test-Path $FF_DIR)) { New-Item $FF_DIR -ItemType Directory -Force | Out-Null }
            
            foreach ($file in $binFiles) {
                Write-Host "[+] Copie de $($file.Name)..." -ForegroundColor Gray
                Move-Item -Path $file.FullName -Destination (Join-Path $FF_DIR $file.Name) -Force -ErrorAction Stop
            }
        }
        Remove-Item $tmp -Force
        Remove-Item $ext -Recurse -Force
        Write-Host "[OK] FFmpeg & FFprobe mis a jour avec succes." -ForegroundColor Green
    } catch { 
        Write-Host "`n[!] ERREUR CRITIQUE :" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host "Veuillez fermer tout logiciel utilisant FFmpeg/Emby et reessayer." -ForegroundColor Red
    }
    Write-Host "`nRetour au menu..." -ForegroundColor Gray ; Start-Sleep -Seconds 5
}

function Update-MKVToolNix {
    Write-Host "[+] Fermeture des processus MKVToolNix en cours..." -ForegroundColor Gray
    Stop-Process -Name "mkvpropedit" -Force -ErrorAction SilentlyContinue
    Stop-Process -Name "mkvmerge" -Force -ErrorAction SilentlyContinue

    Clear-Host
    Write-Host "============================================" -ForegroundColor Yellow
    Write-Host "      $($TxtMAJ.ToUpper()) MKVTOOLNIX" -ForegroundColor Yellow
    Write-Host "============================================" -ForegroundColor Yellow
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13

        Write-Host "[+] Interrogation de la derniere version via Codeberg API..." -ForegroundColor Cyan
        
        # Appel à l'API publique de Codeberg pour lister les tags de version
        $codebergTags = Invoke-RestMethod -Uri "https://codeberg.org/api/v1/repos/mbunkus/mkvtoolnix/tags" -TimeoutSec 12
        
        if ($codebergTags -and $codebergTags.name) {
            # Extraction chirurgicale : on ne garde QUE le numéro (ex: "release-99.0" ou "v99.0" devient "99.0")
            if ($codebergTags[0].name -match '(\d+\.\d+(?:\.\d+)?)') {
                $latestVersion = $Matches[1]
            } else {
                throw "Impossible d'isoler le format numerique de la version ($($codebergTags[0].name))."
            }
        } else {
            throw "Impossible de recuperer la liste des tags depuis Codeberg."
        }

        Write-Host "[+] Derniere version stable detectee : v$latestVersion" -ForegroundColor Green

        # Construction de l'URL directe vers l'archive officielle .7z
        $baseUrl = "https://mkvtoolnix.download/windows/releases/"
        $mkvUrl = "${baseUrl}${latestVersion}/mkvtoolnix-64-bit-${latestVersion}.7z"
        $tmp = Join-Path $env:TEMP "mkvtoolnix.7z"

        Write-Host "[+] Telechargement du pack portable (.7z)..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $mkvUrl -OutFile $tmp -TimeoutSec 60
        
        Write-Host "[+] Extraction vers $MKV_DIR..." -ForegroundColor Cyan
        if (-not (Test-Path $MKV_DIR)) { New-Item $MKV_DIR -ItemType Directory -Force | Out-Null }
        
        # Nettoyage des anciens binaires pour éviter les verrous
        Get-ChildItem -Path $MKV_DIR -File | Remove-Item -Force -ErrorAction SilentlyContinue

        # Extraction transparente via l'outil natif Windows (tar.exe)
        tar.exe -xf $tmp -C $MKV_DIR
        
        # Redressement si l'archive encapsule ses fichiers dans une arborescence "mkvtoolnix/"
        $subDir = Join-Path $MKV_DIR "mkvtoolnix"
        if (Test-Path $subDir) {
            Get-ChildItem -Path $subDir | Move-Item -Destination $MKV_DIR -Force
            Remove-Item $subDir -Recurse -Force
        }

        Remove-Item $tmp -Force
        Write-Host "[OK] MKVToolNix mis a jour avec succes en v$latestVersion." -ForegroundColor Green
    } catch { 
        Write-Host "`n[!] ERREUR CRITIQUE : Impossible de mettre a jour MKVToolNix." -ForegroundColor Red 
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
    Write-Host "`nRetour au menu..." -ForegroundColor Gray ; Start-Sleep -Seconds 4
}

function Start-Audit {
    if (-not (Test-Path $FP)) {
        Write-Host "[!] Erreur : FFprobe introuvable." -ForegroundColor Red
        Start-Sleep 3 ; return
    }
    Clear-Host
    Write-Host "============================================" -ForegroundColor Magenta
    Write-Host "       AUDITEUR : CHOIX DU DOSSIER"          -ForegroundColor Magenta
    Write-Host "============================================" -ForegroundColor Magenta
    Write-Host "[Y] Films      [U] $TxtSeries      [T] Mangas"
    Write-Host "[X] $TxtAnimes     [S] Cartoons    [W] Animations     "
    Write-Host "[V] Spectacle  [Q] Quitter             "
    Write-Host "============================================"
    Write-Host "Choisissez une categorie a auditer : " -NoNewline
    $keyA = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    $drv = $keyA.Character.ToString().ToUpper()
    if ($drv -eq "Q") { return }
    if ("STUVWXY" -notlike "*$drv*") { return }
    $A_ROOT = "$($drv):\"
    if (Test-Path $A_ROOT) {
        $AuditLogDir = Join-Path $L_BASE "Audit"
        if (-not (Test-Path $AuditLogDir)) { New-Item -ItemType Directory -Path $AuditLogDir -Force | Out-Null }
        $TimeStamp = Get-Date -Format "yyyyMMdd_HHmm"
        $CurrentReport = Join-Path $AuditLogDir "Audit_Lecteur_$($drv)_$($TimeStamp).txt"
        Write-Host "`n`n--- SCAN AUDIT EN COURS SUR $A_ROOT ---" -ForegroundColor Yellow
        $aFiles = Get-ChildItem -Path $A_ROOT -Include "*.mp4","*.mkv","*.webm","*.mov","*.qt","*.m4v","*.wmv","*.avi","*.asf","*.wm","*.wmx","*.asx","*.ts","*.mts","*.m2ts","*.m2t","*.mxf","*.avchd","*.mpg","*.mpeg","*.m1v","*.m2v","*.mp2","*.mpa","*.mpe","*.vob","*.ifo","*.flv","*.f4v","*.f4p","*.f4a","*.f4b","*.swf","*.3gp","*.3g2","*.3gpp","*.3gp2","*.svi","*.amv","*.ogv","*.ogg","*.ogm","*.rm","*.rmvb","*.rv","*.divx","*.xvid","*.dat","*.vcd","*.nsv","*.roq","*.ivf","*.drc","*.mng" -Recurse -File
        $count = 0
        foreach ($f in $aFiles) {
            $probe = & $FP -v error -select_streams v:0 -show_entries stream=codec_name,pix_fmt -of csv=p=0:s="|" "$($f.FullName)"
            if ($probe -notlike "hevc*10*") {
                Write-Host "[X] A REFAIRE : $($f.Name)" -ForegroundColor Yellow
                "$($f.FullName) | Codec: $probe" | Out-File $CurrentReport -Append -Encoding utf8
                $count++
            } else { Write-Host "[V] CONFORME  : $($f.Name)" -ForegroundColor Gray }
        }
        Write-Host "`n$TxtTerminer ! $count fichiers trouves." -ForegroundColor Green
        if ($count -gt 0) { Start-Process notepad.exe $CurrentReport }
    }
    Write-Host "`nRetour au menu..." -ForegroundColor Gray ; Start-Sleep -Seconds 3
}

# ============================================================
# SOUS-MENU DE TRAITEMENT AUDIO
# ============================================================
function Start-AudioMenu {
    Clear-Host
    Write-Host "============================================" -ForegroundColor DarkYellow
    Write-Host "     TRAITEMENT AUDIO : CHOIX DU DOSSIER"     -ForegroundColor DarkYellow
    Write-Host "============================================" -ForegroundColor DarkYellow
    Write-Host "[Y] Films      [U] $TxtSeries      [T] Mangas" 
    Write-Host "[X] $TxtAnimes     [S] Cartoons    [W] Animations     " 
    Write-Host "[V] Spectacle  [Q] Quitter             " 
    Write-Host "============================================"
    Write-Host "Choisissez une categorie (Audio uniquement) : " -NoNewline
    
    $keyAudio = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    $drv = $keyAudio.Character.ToString().ToUpper()
    
    if ($drv -eq "Q") { return }
    if ("STUVWXY" -notlike "*$drv*") { return }
    
    Invoke-Processing -TargetDrive $drv -isAudioOnly $true
}

# ============================================================
# TRAITEMENT PRINCIPAL MODIFICATION FLAGS IN-PLACE / ENCODAGE
# ============================================================
function Invoke-Processing {
    param (
        [string]$TargetDrive,
        [bool]$isAudioOnly
    )

    $ROOT = "$($TargetDrive):\"
    
    if ($isAudioOnly) {
        if (-not (Test-Path $mkvPropEdit)) { Write-Host "[!] mkvpropedit.exe introuvable !" -ForegroundColor Red ; Start-Sleep 2 ; return }
        $L_ROOT = Join-Path $D_LOG_AUDIO $TargetDrive
        $ErrorLogFile = Join-Path $D_LOG_ERR "Erreurs_Audio_$($TargetDrive)_$(Get-Date -Format 'yyyyMMdd').txt"
    } else {
        if (-not (Test-Path $HB)) { Write-Host "[!] HandBrakeCLI introuvable !" -ForegroundColor Red ; Start-Sleep 2 ; return }
        $L_ROOT = Join-Path $D_LOG_VIDEO $TargetDrive
        $ErrorLogFile = Join-Path $D_LOG_ERR "Erreurs_Video_$($TargetDrive)_$(Get-Date -Format 'yyyyMMdd').txt"
    }

    if (-not (Test-Path $ROOT)) { Write-Host "[!] Lecteur $ROOT introuvable." -ForegroundColor Red ; Start-Sleep 2 ; return }

    Write-Host "`n--- SCAN EN COURS SUR $ROOT ---" -ForegroundColor Yellow
    $Extensions = if ($isAudioOnly) { "*.mkv" } else { "*.mp4","*.mkv","*.webm","*.mov","*.qt","*.m4v","*.wmv","*.avi","*.ts","*.m2ts","*.mpg","*.mpeg","*.vob","*.flv" }
    
    $files = Get-ChildItem -Path $ROOT -Include $Extensions -Recurse -File
    $total = $files.Count
    $current = 0

    foreach ($file in $files) {
        $current++
        if ($file.Extension -eq ".old") { continue }

        $logPath = Join-Path $L_ROOT $file.DirectoryName.Replace($ROOT, "")
        $logFile = Join-Path $logPath "$($file.BaseName).txt"
        
        if (Test-Path -LiteralPath $logFile) {
            Write-Host "[$current/$total] [$TxtIgnore] $($file.Name)" -ForegroundColor Gray
            continue
        }

        $codec = "Inconnu"
        if (Test-Path $FP) {
            try {
                $codec = & $FP -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 -read_intervals "%10" "$($file.FullName)" 2>&1
                if ($LASTEXITCODE -ne 0 -or $codec -match "error") { $codec = "Inconnu" }
            } catch { $codec = "Inconnu" }
        }

        Write-Host "--------------------------------------------------------"
        Write-Host "[$current/$total] SOURCE : [$($codec.ToUpper())]" -ForegroundColor Magenta
        Write-Host "[ENCOURS] -> $($file.Name)" -ForegroundColor White
        
        if ($isAudioOnly) {
            # --- MODIFICATION IN-PLACE VIA MKVPROPEDIT (LOGIQUE CORRIGÉE V31) ---
            try {
                $audioTracks = & $FP -v error -select_streams a -show_entries stream=index:stream_tags=language -of csv=p=0 "$($file.FullName)"
                $subTracks = & $FP -v error -select_streams s -show_entries stream=index:stream_tags=id,language:stream_tags=title -of csv=p=0 "$($file.FullName)"
                
                $propArgs = @("$($file.FullName)")

                if ("TW" -like "*$TargetDrive*") {
                    # --- CAS MANGAS / ANIMATIONS (T & W) ---
                    # Audio : Japonais par défaut (on force la première piste japonaise trouvée)
                    $aIdx = 1
                    $foundJpn = $false
                    foreach ($track in ($audioTracks -split "`n")) {
                        if ([string]::IsNullOrWhiteSpace($track)) { continue }
                        $lang = $track.Split(',')[1]
                        
                        if (($lang -eq "jpn" -or $lang -eq "ja") -and -not $foundJpn) {
                            $propArgs += @("--edit", "track:a$aIdx", "--set", "flag-default=1")
                            $foundJpn = $true
                        } else {
                            $propArgs += @("--edit", "track:a$aIdx", "--set", "flag-default=0")
                        }
                        $aIdx++
                    }
                    
                    # Sous-titres : FR Complet par défaut (On cherche le premier FR non-forced)
                    $sIdx = 1
                    $foundSub = $false
                    foreach ($sub in ($subTracks -split "`n")) {
                        if ([string]::IsNullOrWhiteSpace($sub)) { continue }
                        
                        if ($sub -match "fra|fr" -and $sub -notmatch "forced") {
                            if (-not $foundSub) {
                                $propArgs += @("--edit", "track:s$sIdx", "--set", "flag-default=1", "--edit", "track:s$sIdx", "--set", "flag-forced=0")
                                $foundSub = $true
                            } else {
                                $propArgs += @("--edit", "track:s$sIdx", "--set", "flag-default=0", "--edit", "track:s$sIdx", "--set", "flag-forced=0")
                            }
                        } else {
                            $propArgs += @("--edit", "track:s$sIdx", "--set", "flag-default=0", "--edit", "track:s$sIdx", "--set", "flag-forced=0")
                        }
                        $sIdx++
                    }
                } else {
                    # --- CAS FILMS / SERIES / SPECTACLES / ANIMES (S, U, V, X, Y) ---
                    # Audio : Français par défaut (on force la première piste française trouvée)
                    $aIdx = 1
                    $foundFraAudio = $false
                    foreach ($track in ($audioTracks -split "`n")) {
                        if ([string]::IsNullOrWhiteSpace($track)) { continue }
                        $lang = $track.Split(',')[1]
                        
                        if (($lang -eq "fra" -or $lang -eq "fr") -and -not $foundFraAudio) {
                            $propArgs += @("--edit", "track:a$aIdx", "--set", "flag-default=1")
                            $foundFraAudio = $true
                        } else {
                            $propArgs += @("--edit", "track:a$aIdx", "--set", "flag-default=0")
                        }
                        $aIdx++
                    }
                    
                    # Sous-titres : FR Forced activé par défaut (Le premier "Forced" français trouvé)
                    $sIdx = 1
                    $foundFraForced = $false
                    foreach ($sub in ($subTracks -split "`n")) {
                        if ([string]::IsNullOrWhiteSpace($sub)) { continue }
                        
                        if ($sub -match "fra|fr" -and $sub -match "Forced") {
                            if (-not $foundFraForced) {
                                $propArgs += @("--edit", "track:s$sIdx", "--set", "flag-default=1", "--edit", "track:s$sIdx", "--set", "flag-forced=1")
                                $foundFraForced = $true
                            } else {
                                $propArgs += @("--edit", "track:s$sIdx", "--set", "flag-default=0", "--edit", "track:s$sIdx", "--set", "flag-forced=0")
                            }
                        } else {
                            # On s'assure que toutes les autres pistes (complets, anglais, etc.) perdent leurs flags default/forced
                            $propArgs += @("--edit", "track:s$sIdx", "--set", "flag-default=0", "--edit", "track:s$sIdx", "--set", "flag-forced=0")
                        }
                        $sIdx++
                    }
                }

                if ($propArgs.Count -gt 1) { & $mkvPropEdit $propArgs | Out-Null }

                if (-not (Test-Path $logPath)) { New-Item -ItemType Directory -Path $logPath -Force | Out-Null }
                "OK (In-Place Property Optimization via mkvpropedit)" | Out-File -LiteralPath $logFile -Force
                
                Write-Host "============================================" -ForegroundColor Green
                Write-Host "[OK] $TxtTerminer : Drapeaux corriges et appliques." -ForegroundColor Green
                Write-Host "============================================" -ForegroundColor Green
            } catch {
                Write-Host "[!] ERREUR : Edition des en-tetes impossible." -ForegroundColor Red
                "ERREUR EN-TETE | $($file.FullName) | $($_.Exception.Message)" | Out-File -LiteralPath $ErrorLogFile -Append
            }
        } else {
            # --- ENCODAGE COMPLET VIA HANDBRAKE (Reste inchangé) ---
            $TS = Get-Date -Format "HHmmss"
            $isBackdrop = ($file.DirectoryName -like "*\backdrops*")
            $outExt = "mkv"
            $workOut = Join-Path $T_DIR "temp_$($TargetDrive)_$TS.$outExt"
            if (-not (Test-Path $T_DIR)) { [void](New-Item -ItemType Directory -Path $T_DIR) }

            if ($isBackdrop) {
                $hbArgs = "-i `"$($file.FullName)`" -o `"$workOut`" -e nvenc_h265_10bit -q 28 --encoder-preset fast --maxWidth 1920"
            } else {
                if ("TW" -like "*$TargetDrive*") {
                    $hbArgs = "-i `"$($file.FullName)`" -o `"$workOut`" -e nvenc_h265_10bit -q 28 --encoder-preset fast --maxWidth 1920 --audio-lang-list jpn -E av_aac -B 192 --subtitle-lang-list fra --subtitle-forced 0 --native-language fra --all-subtitles --chapters 1-999 --markers"
                } else {
                    $hbArgs = "-i `"$($file.FullName)`" -o `"$workOut`" -e nvenc_h265_10bit -q 28 --encoder-preset fast --maxWidth 1920 --audio-lang-list fra -E av_aac -B 192 --subtitle-lang-list fra --subtitle-forced --subtitle-default 1 --native-language fra --chapters 1-999 --markers"
                }
            }
            
            $proc = Start-Process -FilePath $HB -ArgumentList $hbArgs -Wait -NoNewWindow -PassThru

            # --- POST-TRAITEMENT FLAGS SUBTITLES POUR HANDBRAKE ---
            if (Test-Path $workOut) {
                $probeOutput = & $FP -v error -select_streams s -show_entries stream=index:stream_tags=title -of csv=p=0 "$workOut"
                $tracks = $probeOutput -split "`n"
                
                if ("TW" -like "*$TargetDrive*") {
                    foreach ($line in $tracks) {
                        if ($line -ne "" -and $line -notmatch "Forced" -and $line -notmatch "Japan") {
                            $idx = $line.Split(',')[0]
                            & $mkvPropEdit "$workOut" --edit track:s$idx --set flag-default=1 --edit track:s$idx --set flag-forced=0 | Out-Null
                            break
                        }
                    }
                } else {
                    foreach ($line in $tracks) {
                        if ($line -ne "" -and $line -match "Forced") {
                            $idx = $line.Split(',')[0]
                            & $mkvPropEdit "$workOut" --edit track:s$idx --set flag-default=1 --edit track:s$idx --set flag-forced=1 | Out-Null
                            break
                        }
                    }
                }

                $fileSize = (Get-Item -LiteralPath $workOut).Length
                $minSize = if ($isBackdrop) { 100KB } else { 1MB }

                if ($fileSize -gt $minSize) {
                    try {
                        $error.Clear()
                        $finalPath = Join-Path $file.DirectoryName "$($file.BaseName).$outExt"
                        $oldPath = "$($file.FullName).old"
                        $originalAcl = Get-Acl -LiteralPath $file.FullName
                        
                        Rename-Item -LiteralPath $file.FullName -NewName "$($file.Name).old" -Force -ErrorAction Stop
                        Move-Item -LiteralPath $workOut -Destination $finalPath -Force -ErrorAction Stop
                        Set-Acl -LiteralPath $finalPath -AclObject $originalAcl -ErrorAction SilentlyContinue
                        if (Test-Path -LiteralPath $oldPath) { Remove-Item -LiteralPath $oldPath -Force -ErrorAction SilentlyContinue }
                        
                        if (-not (Test-Path $logPath)) { New-Item -ItemType Directory -Path $logPath -Force | Out-Null }
                        "OK (Full Encode - Source:$codec)" | Out-File -LiteralPath $logFile -Force
                        
                        Write-Host "============================================" -ForegroundColor Green
                        Write-Host "[OK] $TxtTerminer : Encodage et log d'evitement OK." -ForegroundColor Green
                        Write-Host "============================================" -ForegroundColor Green
                    }
                    catch {
                        Write-Host "============================================" -ForegroundColor Red
                        Write-Host "[!] ERREUR : Remplacement impossible." -ForegroundColor Red
                        Write-Host "============================================" -ForegroundColor Red
                        "ERREUR CRITIQUE | $($file.FullName) | $($_.Exception.Message)" | Out-File -LiteralPath $ErrorLogFile -Append
                        if (Test-Path -LiteralPath $workOut) { Remove-Item -LiteralPath $workOut -Force -ErrorAction SilentlyContinue }
                    }
                }
            }
        }
    }
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "`n--- DISQUE $TargetDrive $TxtTerminer ---" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Start-Sleep 3
}

# ============================================================
# STRUCTURE PRINCIPALE DU MENU
# ============================================================
function Show-Menu {
    Clear-Host
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "         ENCODAGE HEVC 10-BIT V31"      -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "[Y] Films      [U] $TxtSeries      [T] Mangas"
    Write-Host "[X] $TxtAnimes     [S] Cartoons    [W] Animations     "
    Write-Host "[V] Spectacle                  "
    Write-Host "================================================"
    Write-Host "         Audio FR & VOSTFR"               -ForegroundColor DarkYellow
    Write-Host "[M] ENTRER DANS LE MENU AUDIO"                -ForegroundColor DarkYellow
    Write-Host "================================================"
    Write-Host "         AUDITEUR EMBY 10-BIT"                  -ForegroundColor Magenta
    Write-Host "[A] AUDITER UNE BIBLIOTHEQUE"                 -ForegroundColor Magenta
    Write-Host "================================================"
    Write-Host "         MISES A JOUR OUTILS"                    -ForegroundColor Yellow
    Write-Host "[H] MAJ HandBrake    [F] MAJ FFmpeg"          -ForegroundColor Yellow
    Write-Host "[K] $TxtMajMkv"                               -ForegroundColor Yellow
    Write-Host "================================================"
    Write-Host "         Quitter Emby Optimizer"                    -ForegroundColor Red
    Write-Host "[Q] Quitter"                                  -ForegroundColor Red
    Write-Host "================================================"
} 

while ($true) {
    Show-Menu
    Write-Host "Appuyez sur une touche : " -NoNewline
    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    $SEL = $key.Character.ToString().ToUpper()
    Write-Host "$SEL" -ForegroundColor Green

    if ($SEL -eq "Q") { break }
    if ($SEL -eq "H") { Update-HandBrake ; continue }
    if ($SEL -eq "F") { Update-FFmpeg ; continue }
    if ($SEL -eq "K") { Update-MKVToolNix ; continue }
    if ($SEL -eq "A") { Start-Audit ; continue }
    if ($SEL -eq "M") { Start-AudioMenu ; continue }

    if ("STUVWXY" -notlike "*$SEL*") { continue }
    Invoke-Processing -TargetDrive $SEL -isAudioOnly $false
}
