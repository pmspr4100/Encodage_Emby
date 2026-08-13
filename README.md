## Emby Optimizer & Auditeur (HEVC 10-Bit)
Script PowerShell tout-en-un conçu pour automatiser l'optimisation, le nettoyage des métadonnées, la génération de trailers/backdrops et la mise à jour des outils pour un serveur multimédia Emby.

## 🚀 Fonctionnalités principales
Encodage Vidéo Intelligent : Conversion automatique des flux vidéo en HEVC 10-bit (via NVENC matériel) tout en préservant la qualité (CQ 28).

Compatibilité Apple (Tags HVC1) : Ajout indispensable du tag vidéo hvc1 sur les flux HEVC pour garantir une lecture directe (sans transcodage) sur l'ensemble de vos appareils Apple (Apple TV, iPhone, iPad via Infuse par exemple).

Gestion des Pistes & Langues :

Pour les Films, Séries, Spectacles et Animes : Audio principal en Français et sous-titres forcés gérés automatiquement.

Pour les Mangas et Animations : Audio principal en Japonais et sous-titres en Français.

Mise à jour automatisée des outils : Téléchargement et installation en un clic des dernières versions de HandBrakeCLI, FFmpeg et MKVToolNix.

Trailers & Backdrops dynamiques : Découpe et création automatique de mini-trailers multi-extraits et d'arrière-plans (theme.mkv) pour vos séries à partir des épisodes.

Verrouillage NFO (Emby) : Génération et verrouillage automatique des fichiers NFO et tvshow.nfo pour figer les titres et éviter les modifications indésirables par les scrapers.

Double Journalisation (Logs) : Suivi précis via des dossiers de logs séparés (Encodage, Audio, HVC1, Erreurs) pour éviter de retraiter inutilement les fichiers déjà optimisés.

## 🛠️ Prérequis
Windows 10 / 11 avec PowerShell.

Une carte graphique compatible NVENC pour l'accélération matérielle.

Les outils tiers installés dans les chemins par défaut du script :

C:\Tools\HandBrake\

C:\Tools\ffmpeg\

C:\Tools\MKVToolNix\

Configuration des disques : ⚠️ Les lettres de lecteurs utilisées dans le script (S à Y) et les chemins associés doivent être adaptés au préalable dans le code selon votre propre configuration machine.

⚙## ️ Utilisation
Modifiez les chemins et lettres de lecteurs dans le script pour les faire correspondre à votre installation.

Lancez le script PowerShell (Emby Encodage.ps1).

Le menu principal s'affiche, vous permettant de choisir l'action souhaitée :

[S à Y] : Traiter un lecteur ou une catégorie spécifique.

[A] : Lancer le traitement global de tous les disques configurés.

[H / F / K] : Mettre à jour HandBrake, FFmpeg ou MKVToolNix.

[P] : Appliquer les tags hvc1 ciblés pour la compatibilité Apple.

[Q] : Quitter le script.