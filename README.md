## Emby Optimizer & Auditor (HEVC 10-bit) — V37.0

Une solution industrielle en PowerShell conçue pour auditer, encoder, générer du contenu tiers et standardiser intelligemment vos bibliothèques de serveurs médias **Emby / Jellyfin / Plex** au format **HEVC 10-bit**. 

Le script orchestre et maintient à jour **HandBrakeCLI**, **FFmpeg (FFprobe)** et **MKVToolNix** pour maximiser le DirectPlay tout en verrouillant la sécurité de vos métadonnées.

---

## 🚀 Vue d'ensemble du pipeline (V37)

Contrairement aux anciennes versions linéaires, la **V37** exécute une logique avancée à 4 étapes pour chaque volume réseau/catégorie cible (`S:` à `Y:`) :

1. **Encodage Vidéo Initial (`HandBrakeCLI`) :** Convertit tous les fichiers non conformes en HEVC 10-bit.
2. **Génération Média Dynamique (`FFmpeg`) :** Extrait automatiquement des extraits vidéos pour créer des bandes-annonces (*trailers*) et des arrière-plans animés (*backdrops*) avec audio.
3. **Sécurisation des NFO Racines (`Séries`) :** Analyse et verrouille les fichiers `.nfo` pour figer vos titres personnalisés.
4. **Optimisation Spécifique In-Place (`mkvpropedit`) :** Réanalyse le fichier final pour configurer les en-têtes et drapeaux (*flags*) Audio/Sous-titres par défaut selon la catégorie, tout en injectant les verrous de métadonnées unitaires.

---

## 🛠️ Architecture et Fonctionnalités en Détail

### 1. Gestionnaire de Mises à Jour Intégré
Le script inclut des fonctions d'auto-mise à jour capables d'interroger les API distantes pour maintenir vos outils à la dernière version stable :
* **HandBrake :** Interroge l'API GitHub (`HandBrake/HandBrake`), télécharge le binaire CLI x64 et l'extrait proprement.
* **FFmpeg :** Récupère la version stable *Essentials* du dépôt officiel de Gyan.dev et remplace à chaud `ffmpeg.exe` et `ffprobe.exe`.
* **MKVToolNix :** Interroge l'API Codeberg (`mbunkus/mkvtoolnix`) pour isoler le dernier numéro de tag stable, télécharge l'archive portable `.7z` et restructure proprement l'arborescence.

### 2. Auditeur de Bibliothèque Dédié (`Start-Audit`)
Permet de lancer un scan de diagnostic profond à l'aide de `ffprobe`. Il vérifie le codec vidéo et le format de pixel de plus de 15 extensions différentes (`.mp4`, `.mkv`, `.avi`, `.ts`...). Tout fichier n'étant pas strictement identifié comme `hevc` en `10-bit` est consigné dans un rapport texte généré à la volée et ouvert automatiquement dans le Bloc-notes.

### 3. Logique Métiers par Catégorie (Audio & Sous-titres) Français et VOSTFR
Le traitement s'adapte précisément selon la lettre du lecteur réseau sélectionné :
* **Mangas & Animations (Lecteurs T et W) :** Le script identifie et force la piste **Audio Japonaise** (`jpn`/`ja`) par défaut. Il recherche la piste de sous-titres **Français Complets** (en excluant les pistes *Forced*) pour l'activer par défaut.
* **Films, Séries, Cartoons, Spectacles (Lecteurs S, U, V, X, Y) :** Force la piste **Audio Française** (`fra`/`fr`) par défaut et configure la première piste de sous-titres **Français Forced** (textes traduits à l'écran) en mode *Default & Forced*.
* *Note : Tous les drapeaux par défaut ou conflictuels des autres pistes (pistes anglaises, commentaires...) sont automatiquement purgés à 0 pour éviter les mauvaises sélections des lecteurs clients.*

### 4. Smart Encodage (4K intelligent & ACLs)
* **Préservation de la 4K :** Si `ffprobe` détecte une source Ultra HD (largeur > 1920px), le script retire la limite de redimensionnement de HandBrake mais applique le profil qualitatif constant (CQ 28) en HEVC 10-bit matériel (`nvenc_h265_10bit`).
* **Protection Sécurisée :** L'encodage s'effectue dans un répertoire temporaire (`Z:\Encoder_Emby`). Lors de la substitution finale, le script applique les permissions de fichiers originales (**Droits ACL Windows**) de l'ancien fichier sur le nouveau avant de purger l'élément `.old`.

### 5. Générateur Avancé de Trailers et Backdrops
Pour les arborescences de séries, le script inspecte la présence de dossiers thématiques :
* **Bande-annonce (Trailer) :** Extrait automatiquement 3 séquences distinctes de 25 secondes à des moments clés (5e, 10e et 15e minute) d'un premier épisode et les fusionne de manière complexe (`filter_complex concat`) en un fichier `theme.mkv` fluide avec piste audio.
* **Arrière-plan (Backdrop) :** Isole une séquence continue de 30 secondes à partir de la 10e minute (évitant ainsi les logos d'introduction de production) pour les menus animés de l'interface Emby.

### 6. Verrouillage Anti-Écrasement des NFO (`.NET XmlDocument`)
Afin d'empêcher les moteurs de scrap d'Emby ou Jellyfin d'écraser vos titres personnalisés, le script utilise le moteur XML natif de Windows :
* Il analyse ou génère les fichiers `.nfo` (`movie`, `episodedetails`, `tvshow`).
* Il synchronise les balises `<title>` et `<sorttitle>` avec le nom réel du dossier de votre média.
* Il injecte et fige la balise `<lockedfields>Title|SortTitle</lockedfields>`, garantissant l'immunité de vos métadonnées lors des futurs scans système.

---

## 📁 Configuration des Chemins Requise

Pour que le script s'exécute sans erreur, veillez à respecter la structure de dossiers Windows suivante :

* **Outils applicatifs :**
  * `C:\Tools\HandBrake\HandBrakeCLI.exe`
  * `C:\Tools\ffmpeg\bin\` (`ffmpeg.exe`, `ffprobe.exe`)
  * `C:\Tools\MKVToolNix\` (`mkvpropedit.exe`)
* **Stockage de travail et Logs :**
  * `Z:\Encoder_Emby\` (Sert de zone tampon d'encodage et centralise l'arborescence des journaux `/Encodage`, `/Audio`, `/Erreurs`).
* **Montages Réseau (Lettres dédiées) :**
  * `S:` à `Y:` mappés vers vos catégories respectives (Films, Séries, Animes, etc.).

---

## 🛠️ Utilisation

1. Ouvrez une invite de commande **PowerShell en mode Administrateur**.
2. Positionnez-vous dans le dossier du script et exécutez-le :
   ```powershell
   .\Emby_Encodage.ps1