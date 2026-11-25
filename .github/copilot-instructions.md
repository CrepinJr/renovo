# Contexte Projet — Renovo V2.1
- Application Flutter (Android/iOS) de suivi et planification des confessions catholiques.
- Architecture : Riverpod + Repository Pattern (Mode Invité SQLite local + Mode Connecté Firebase Firestore).
- Design System : "Sacred Minimalism" (Lora + Plus Jakarta Sans, Indigo #2C3E6B, Émeraude #2E7D5B, Or #D49A3A, Albâtre #FAF8F5, Obsidienne #121316).
- Règle métier : cycle personnalisable (1 à 12 semaines, 3 semaines par défaut) aligné automatiquement sur le samedi le plus proche, basculement en statut « Non effectuée » après 72h, et rappels locaux programmés.
- Mode Offline-First : activer `persistenceEnabled: true` sur Firestore. Préserver l'utilisation hors-ligne sans compte (mode invité).
- Les maquettes de référence se trouvent dans `docs/stitch_v2/` (`Ecran de démarrage.html`, `Calendrier & Détails.html`, `Menu Latéral.html`, `Paramètres.html`, `Account & Cloud Backup.html`).