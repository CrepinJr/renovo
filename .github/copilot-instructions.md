# Contexte Projet — Renovo V2
- Application Flutter (Android/iOS) de suivi et planification des confessions catholiques.
- Architecture : Riverpod + Repository Pattern (Mode Invité SQLite local + Mode Connecté Firebase Firestore).
- Design System : "Sacred Minimalism" (Lora + Plus Jakarta Sans, Indigo #2C3E6B, Émeraude #2E7D5B, Or #D49A3A, Albâtre #FAF8F5, Obsidienne #121316).
- Règle métier critique : cycle de 21 jours à partir de la dernière confession effectuée, aligné automatiquement sur le samedi le plus proche.
- Mode Offline-First : activer `persistenceEnabled: true` sur Firestore. Préserver l'utilisation hors-ligne sans compte (mode invité).


Ne modifie ni le splash screen ni le layout principal existant. Ajoute uniquement la pastille de statut dans l'en-tête de l'accueil, le nouvel écran 'Compte & Sauvegarde Cloud' et la modale de fusion en suivant fidèlement le design de docs/stitch_v2/, puis branche-les sur authStateProvider et FirestoreConfessionRepository.