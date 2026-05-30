# Emby Optimizer & Auditor (HEVC 10-bit) — V31

Une solution robuste en PowerShell conçue pour auditer, encoder et standardiser automatiquement les bibliothèques de serveurs médias Emby / Jellyfin / Plex en **HEVC 10-bit**. 

Le script orchestre intelligemment **HandBrakeCLI**, **FFmpeg** et **MKVToolNix** pour garantir une compatibilité maximale en DirectPlay tout en optimisant massivement l'espace de stockage de votre NAS.

## 🚀 Évolution majeure (V31)
Contrairement à la version V22 qui fonctionnait en mode local/portable sur un seul répertoire de travail, la **V31** passe à l'échelle industrielle :
* **Multi-disques Réseau :** Scan et traite directement vos différents volumes de stockage par catégorie de média.
* **Modification In-Place (Instantane) :** Plus besoin de réencoder la vidéo si seuls les drapeaux audio/sous-titres sont incorrects. `mkvpropedit` modifie les en-têtes en moins d'une seconde.
* **Auto-Mise à jour :** Gestionnaire de mise à jour intégré utilisant les API GitHub et Codeberg pour maintenir vos outils tiers à jour.

---

## 🛠️ Fonctionnalités clés

### 1. Encodage Vidéo HEVC 10-bit standardisé
* Compression matérielle via **NVIDIA NVENC** (`nvenc_h265_10bit`).
* Traitement adapté pour les dossiers `backdrops` (profils légers, max 1080p).
* Remplacement sécurisé des fichiers originaux avec conservation des permissions système (**droits ACL**).

### 2. Logique Audio & Sous-titres Intelligente
Le script applique des règles strictes selon le type de contenu sélectionné via le menu :
* **Films, Séries, Cartoons, Spectacles :** Force la piste Audio Française par défaut et active le sous-titrage **Français Forced** (Idéal pour les textes traduits ou passages traduits à l'écran).
* **Animes & Mangas :** Force la piste Audio Japonaise par défaut et active la piste de sous-titres **Français Complets** (VOSTFR native).
* Nettoyage automatique des drapeaux conflictuels sur les autres pistes.

### 3. Auditeur de Bibliothèque Évolué
* Analyse approfondie via `ffprobe` sur plus de 50 extensions de fichiers conteneurs (mkv, mp4, ts, m2ts, vob, avi...).
* Génération automatique d'un rapport au format bloc-notes listant tous les fichiers non conformes au standard `HEVC 10-bit`.

---

## 📁 Architecture des dossiers requise

Pour fonctionner de manière optimale, les chemins d'accès suivants doivent être configurés sur votre machine Windows :
* **Outils tiers :**
  * `C:\Tools\HandBrake\HandBrakeCLI.exe`
  * `C:\Tools\ffmpeg\bin\` (`ffmpeg.exe`, `ffprobe.exe`)
  * `C:\Tools\MKVToolNix\` (`mkvpropedit.exe`)
* **Stockage & Logs :**
  * `Z:\Encoder_Emby\` (Espace temporaire de travail et centralisation des logs d'encodage, audio et erreurs).
  * Lecteurs réseau/partitions montés de `S:` à `Y:` pour vos différentes catégories de médias Emby.

---

## 🔧 Utilisation

1. Exécutez une console PowerShell en mode Administrateur.
2. Lancez le script :
   ```powershell
   .\Emby_Encodage_V31.ps1
