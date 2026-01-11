# 🎬 Emby Library Optimizer (HandBrake 10-bit NVENC)

Ce script Batch automatisé permet de traiter massivement une bibliothèque multimédia pour l'optimiser pour **Emby**, **Plex** ou **Jellyfin**. Il utilise l'accélération matérielle NVIDIA pour convertir vos vidéos en HEVC 10-bit.

## 🚀 Fonctionnalités Clés

- **Encodage Hardware** : Utilisation de `nvenc_h265_10bit` pour une vitesse de traitement ultra-rapide.
- **Auto-Downscale** : Réduction automatique des sources 4K en **1080p (Full HD)** pour économiser l'espace.
- **Logique de Langues** : 
  - Standard : Pistes audio **Françaises**.
  - Détection automatique (Lecteurs T & W) : Priorité **Japonais + Français** (idéal pour les Animes).
- **Système de Logs Miroir** : Création d'une empreinte (témoin) dans `Z:\Logs` pour éviter de retraiter un fichier déjà optimisé.
- **Gestion des Sous-titres** : Conservation de l'intégralité des pistes de sous-titres et des chapitres.

## 🛠️ Configuration Requise

1. **HandBrakeCLI** : Doit être installé dans `C:\Program Files\HandBrake\`.
2. **GPU NVIDIA** : Compatible avec l'encodage HEVC 10-bit.
3. **Structure des Lecteurs** :
   - Sources : Lecteurs mappés de `S:` à `Y:`.
   - Travail & Logs : Un lecteur `Z:` pour le dossier temporaire et l'archivage des logs.

## 📖 Utilisation

1. Lancez le script en mode Administrateur (si nécessaire pour l'accès aux lecteurs).
2. Choisissez la lettre du lecteur à traiter via le menu interactif.
3. Le script scanne récursivement tous les sous-dossiers.
4. Une fois terminé, le fichier original est remplacé par la version optimisée et un témoin `.txt` est créé dans `Z:\Encoder_Emby\Logs\`.

## ⚙️ Paramètres d'encodage (HandBrake)

| Paramètre | Valeur | Description |
| :--- | :--- | :--- |
| Codec | HEVC 10-bit (NVENC) | Haute efficacité, profondeur de couleur 10 bits. |
| Qualité | RF 28 (Slow) | Équilibre optimal entre poids et fidélité visuelle. |
| Résolution | Max 1920px | Limite le format au Full HD. |
| Audio | AAC 320kbps | Excellente compatibilité et qualité sonore. |
| Subtitles | All | Conservation de tous les sous-titres originaux. |

## ⚠️ Sécurité des données

Le script utilise une méthode sécurisée pour le remplacement des fichiers :
1. Encodage vers un dossier temporaire sur `Z:`.
2. Renommage du fichier source en `.old`.
3. Déplacement du nouveau fichier vers la destination finale.
4. Suppression du `.old` uniquement si l'opération a réussi.

---
*Développé pour l'optimisation de serveurs multimédias personnels.*