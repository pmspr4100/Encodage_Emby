## 🚀 Emby Optimizer 10-Bit
- Emby Optimizer est un outil de maintenance automatisé conçu pour uniformiser et optimiser votre bibliothèque multimédia. Il convertit massivement vos fichiers vers le format HEVC 10-bit, garantissant un gain  d'espace disque considérable tout en assurant une lecture fluide (Direct Play) sur Emby.

## ✨ Quoi de neuf ?

- Multi-Instance : Code réécrit pour permettre plusieurs lancements simultanés. Chaque instance utilise un nom de fichier temporaire unique (temp_Lecteur_Heure.mkv), évitant tout conflit de ressources.
- Scan de Progression Temps Réel : Affichage dynamique du scan avec compteur [X/Total]. Les fichiers déjà traités sont marqués [IGNORÉ] en gris pour une meilleure lisibilité.
- Auto-Détection des Dépendances : Le script recherche désormais automatiquement HandBrake et FFmpeg dans le PATH système Windows.
- Correction Unicode "Blindée" : Reconstruction des caractères par octets pour un affichage parfait des accents (Séries, Animés), peu importe la configuration de votre console PowerShell.
- Priorité Audio Étendue : Support automatique du Japonais étendu aux lecteurs

## ⚙️ Installation et Configuration

- Assurez-vous que les outils suivants sont installés et ajoutés à votre PATH Windows :
- HandBrake CLI (Essentiel pour la gestion des pistes audio/sous-titres).
- FFmpeg (Moteur de secours).

## Paramétrage du Script

- Ouvrez le fichier .ps1 et ajustez les variables suivantes selon votre installation :
- $T_DIR : Dossier de travail temporaire (ex: Z:\Encoder_Emby).
- $L_BASE : Dossier de stockage des logs de succès.

## 📖 Utilisation

- Lancez le script en mode Administrateur (si nécessaire pour l'accès aux lecteurs).
- Choisissez la lettre du lecteur à traiter via le menu interactif.
- Le script scanne récursivement tous les sous-dossiers.
- Une fois terminé, le fichier original est remplacé par la version optimisée et un témoin `.txt` est créé dans `Z:\Encoder_Emby\Logs\`.

## ⚙️ Paramètres d'encodage (HandBrake)

| Paramètre | Valeur | Description |
| :--- | :--- | :--- |
| Codec | HEVC 10-bit (GPU) | Haute efficacité, profondeur de couleur 10 bits. |
| Codec | HEVC 10-bit (CPU) | Haute efficacité, profondeur de couleur 10 bits. |
| Qualité | RF 28 (Slow) | Équilibre optimal entre poids et fidélité visuelle. |
| Résolution | Max 1920px | Limite le format au Full HD. |
| Audio | AAC 320kbps | Excellente compatibilité et qualité sonore. |

## ⚠️ Sécurité des données

- Le script utilise une méthode sécurisée pour le remplacement des fichiers :
- Encodage vers un dossier temporaire sur `Z:`.
- Renommage du fichier source en `.old`.
- Déplacement du nouveau fichier vers la destination finale.
- Suppression du `.old` uniquement si l'opération a réussi.

---
*Développé pour l'optimisation de serveurs multimédias personnels.*
