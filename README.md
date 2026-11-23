<div align="center">
  <img src="assets/icon/renovo_logo.png" alt="Logo Renovo" width="96" height="96" />
  <h1>Renovo</h1>
  <p><strong>Renouveau &amp; Paix intérieure</strong></p>
  <p>
    Application mobile minimaliste et apaisante pour suivre son rythme de confession,
    anticiper les prochaines échéances sur un cycle de 21 jours et visualiser son cheminement spirituel.
  </p>

  <p>
    <a href="https://github.com/CrepinJr/renovo/releases/latest">
      <img src="https://img.shields.io/badge/Télécharger-APK%20Android%20(v2.0.0)-2C3E6B?style=for-the-badge&logo=android&logoColor=white" alt="Télécharger l'APK" />
    </a>
    <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
    <img src="https://img.shields.io/badge/Firebase-Auth%20%26%20Firestore-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase" />
    <img src="https://img.shields.io/badge/Architecture-Offline--First-2E7D5B?style=for-the-badge" alt="Offline-First" />
  </p>
</div>

---

## Aperçu

**Renovo** a été conçue selon la philosophie **Sacred Minimalism** : une interface épurée, silencieuse et sans surcharge cognitive, pensée pour accompagner la régularité de la vie sacramentelle en toute confidentialité.

L'application fonctionne aussi bien **100 % hors-ligne** (stockage local SQLite) qu'en **synchronisation cloud multi-appareils** via Google Sign-In et Cloud Firestore.

---

## Fonctionnalités principales

- **Calendrier & Cycle de 21 jours aligné sur le samedi :**
  - Suivi visuel des confessions effectuées (pastilles **Vert Émeraude**) et des prochaines échéances recommandées (repères **Or antique**).
  - Ajout, consultation, modification et suppression rapide des entrées avec notes personnelles optionnelles.
- **Architecture hybride Offline-First & Cloud Sync (V2) :**
  - **Mode local :** utilisation immédiate sans création de compte grâce à SQLite.
  - **Sauvegarde Cloud :** connexion en un geste avec Google Sign-In, migration automatique et sans doublon des données locales vers Cloud Firestore, et persistance hors-ligne native.
  - **Déconnexion maîtrisée :** choix explicite entre conserver une copie locale sur l'appareil ou effacer les données locales lors de la déconnexion.
- **Bilan annuel & Partage respectueux de la vie privée :**
  - Sélecteur d'année dynamique avec statistiques consolidées et grille d'activité sur 12 mois.
  - **Export CSV :** téléchargement complet de l'historique annuel au format tableur.
  - **Carte de partage PNG haute résolution :** génération d'une carte visuelle personnalisable avec choix d'un **pseudo** (et masquage de l'adresse e-mail par défaut) prête à être partagée.
- **Thèmes Clair & Sombre :**
  - Palette *Albâtre* (`#FAF8F5`) le jour et *Obsidienne* (`#121316`) la nuit, relevée par l'Indigo liturgique (`#2C3E6B`), l'Or antique (`#D49A3A`) et le Vert Émeraude (`#2E7D5B`).

---

## Installation sur Android

1. Rendez-vous sur la page des [**Releases GitHub**](https://github.com/CrepinJr/renovo/releases) ou téléchargez directement l'APK de la dernière version :
   - [**Renovo-v2.0.0-arm64.apk**](https://github.com/CrepinJr/renovo/releases/download/v2.0.0/Renovo-v2.0.0-arm64.apk) *(Android 7.0+ / architectures 64-bit `arm64-v8a`)*.
2. Ouvrez le fichier `.apk` téléchargé sur votre smartphone Android.
3. Si Android le demande, autorisez l'installation d'applications provenant de cette source, puis finalisez l'installation.

---

## Stack technique & Architecture

- **Framework :** Flutter & Dart
- **Gestion d'état :** Riverpod (`flutter_riverpod`)
- **Persistance locale :** SQLite (`sqflite`)
- **Backend & Synchronisation :** Firebase Authentication (Google Sign-In) & Cloud Firestore (persistance locale activée)
- **Export & Partage :** `share_plus`, `path_provider`, `shared_preferences`, capture `RepaintBoundary` haute densité (`pixelRatio: 3.0`)
- **Typographie :** `Lora` (titres et compteurs) & `Plus Jakarta Sans` (interface et corps de texte)

### Structure du projet

    lib/
    ├── core/
    │   ├── theme/          # Charte Sacred Minimalism (Clair / Sombre)
    │   └── utils/          # Utilitaires de dates et calcul du cycle de 21 jours
    ├── data/
    │   ├── database/       # Helper SQLite local
    │   ├── models/         # Modèle de données Confession
    │   └── repositories/   # Implémentations Local & Firestore + migration sans doublon
    ├── providers/          # Providers Riverpod (auth, confessions, prédictions, thème)
    ├── screens/            # Écran principal, formulaire d'ajout, Compte & Sauvegarde
    ├── services/           # Service d'authentification Google / Firebase
    └── widgets/            # Calendrier, carte bilan annuel, modales et exports PNG

---

## Compiler le projet depuis les sources

### Prérequis
- Flutter SDK (`>= 3.x`)
- Android Studio / JDK 17
- Un projet Firebase configuré (si vous souhaitez activer la synchronisation cloud sur votre propre instance)

### Étapes de compilation

1. **Cloner le dépôt :**

       git clone https://github.com/CrepinJr/renovo.git
       cd renovo

2. **Installer les dépendances :**

       flutter pub get

3. **Lancer les vérifications et tests :**

       flutter analyze
       flutter test

4. **Générer un APK Release optimisé (`arm64`) :**

       flutter build apk --release --target-platform android-arm64 --obfuscate --split-debug-info=build/app/outputs/symbols

   *(Pour signer l'APK avec votre propre certificat, créez un fichier `android/key.properties` référençant votre keystore et ajoutez son empreinte SHA-1/SHA-256 dans la console Firebase).*

---

## Sécurité & Confidentialité

- Les données enregistrées en mode local ne quittent jamais l'appareil.
- En mode synchronisé, l'accès à Cloud Firestore est strictement isolé par identifiant utilisateur (`request.auth.uid == userId`) : aucun utilisateur ne peut consulter ni modifier les données d'un autre compte.
- Lors de l'exportation d'un bilan annuel en image, l'adresse e-mail est masquée par défaut et remplacée par un pseudonyme librement configurable.

---

## Versions

- **`v2.0.0`** — Synchronisation Cloud Firestore, Google Sign-In, migration locale sans doublon, options de déconnexion, bilan annuel CSV & carte de partage personnalisable.
- **`v1.0.0`** — Version initiale 100 % hors-ligne (SQLite), calendrier interactif et cycle prédictif de 21 jours.

---

## Auteur

Développé par **Crépin Généreux Junior HOUESSOU** ([@CrepinJr](https://github.com/CrepinJr)).