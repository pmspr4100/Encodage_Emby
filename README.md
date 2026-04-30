**🎬 Emby Library Optimizer (HEVC 10-bit)
Un outil "Portable" (sans installation) conçu pour automatiser l'optimisation de votre bibliothèque Emby. Ce script PowerShell convertit vos vidéos en HEVC 10-bit tout en préservant l'intégralité de vos pistes audio et sous-titres, garantissant un gain d'espace massif et une compatibilité maximale.

**📁 Structure du Projet
Pour que le script fonctionne correctement, respectez l'architecture suivante (conçue pour être isolée et propre) :

├── ENCODAGE.ps1          # Le cerveau de l'outil (Script PowerShell)
├── Temp_Source/          # Déposez ici vos fichiers originaux à traiter
├── Fichier Final/        # Vos vidéos optimisées apparaîtront ici
├── Tools/                # Doit contenir HandBrakeCLI.exe et ffprobe.exe et ffmpeg.exe
└── Logs_Audit/           # Rapports de scan et historique d'encodage

**🚀 Points forts de cette version
💎 Conservation Totale : Le script détecte et conserve toutes les pistes audio et tous les sous-titres sans exception.

🎧 Optimisation Audio : Conversion automatique de chaque piste en AAC (192 kbps). Cela garantit le "Direct Play" sur 99% des clients Emby (Web, Smart TV, Mobile) et réduit la charge CPU du serveur.

🛡️ Sécurité : Vos fichiers originaux dans Temp_Source ne sont jamais supprimés. Le script travaille uniquement par copie vers le dossier final.

🧠 Intelligence de scan : Un système de logs intégré évite de ré-encoder inutilement un fichier déjà traité lors des sessions précédentes.

**🛠️ Pourquoi ces réglages pour Emby ?
HEVC 10-bit (x265) : Le standard actuel. Le 10-bit élimine les effets de "banding" (artefacts dans les dégradés de couleurs) fréquents en 8-bit, tout en offrant une compression supérieure.

Universal AAC Audio : En passant les pistes en AAC, on élimine le besoin de transcodage audio côté serveur, économisant les ressources de votre machine.

Performance : Un fichier plus léger signifie un streaming à distance (Upload) fluide et sans buffering.

**📖 Mode d'emploi
Placez vos fichiers (ou dossiers/sous-dossiers) dans le dossier Temp_Source.

Faites un clic droit sur ENCODAGE.ps1 > Exécuter avec PowerShell.

Utilisez le Menu interactif :

[A] Audit : Scanne la source pour lister les fichiers qui ne sont pas encore en HEVC 10-bit.

[G] GPU (NVIDIA) : Utilise NVENC pour un encodage ultra-rapide via votre carte graphique.

[C] CPU (x265) : Utilise le processeur pour une qualité optimale (vitesse plus lente).

**⚙️ Détails Techniques (Sous le capot)
Le script pilote deux outils majeurs via la console :

Le Scan (ffprobe) : Analyse les métadonnées de chaque vidéo pour identifier le codec et la profondeur de bits. Si le fichier est déjà conforme, il est ignoré.

L'Encodage (HandBrakeCLI) : Utilise la commande --audio all couplée à -E av_aac. Cela force l'extraction de chaque piste audio, quelle que soit la langue, et sa conversion en AAC 192k.

Le Tracking : À chaque succès, une entrée est créée dans Logs_Audit. Le script compare systématiquement vos fichiers à cette liste avant de lancer un nouvel encodage.

Note : Assurez-vous d'avoir téléchargé les exécutables de HandBrakeCLI et ffprobe et de les avoir placés dans le dossier Tools avant de lancer le script.

---
*Développé pour l'optimisation de serveurs multimédias personnels.*
