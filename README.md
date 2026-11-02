# Back-office officine — PoC Flutter

> 🇫🇷 Français · [🇬🇧 English below](#english)

> **Toutes les données sont fictives.** Le nom de la pharmacie, les comptes
> utilisateurs, les grossistes, les numéros de facture, les codes CIP, les prix
> et les stocks ont été inventés pour la démonstration. Les noms de médicaments
> sont cités uniquement comme exemples de références courantes en officine.

## Contexte

Projet réalisé pendant mon **stage de découverte en officine** (sujet :
« procédure d'optimisation du back-office »), dans le cadre de ma formation à
l'**EPISEN, filière ITS** (Informatique et Technologies pour la Santé), en 2026.

## Problème observé

Au back-office d'une pharmacie, la réception des commandes grossistes reste en
grande partie manuelle :

- la facture ou le bon de livraison est vérifié ligne par ligne, à la main,
  par rapport au contenu réel des cartons ;
- les écarts (boîtes manquantes, produits non commandés, références inconnues)
  sont repérés tard, voire pas du tout ;
- les ruptures de stock et les produits proches de la péremption ne sont pas
  signalés de façon centralisée ;
- il est difficile de savoir qui a validé quoi, et quand.

L'objectif du PoC est de montrer qu'une application simple peut automatiser ce
contrôle et donner une vue d'ensemble au titulaire.

## Fonctionnalités

- **Sélection du profil (RBAC simulé)** : Titulaire, Préparateur, Stagiaire,
  avec des droits différents (seul le titulaire voit les montants financiers ;
  titulaire et préparateur peuvent lever un litige).
- **Dashboard** : indicateurs clés, principales références par valeur de stock
  (graphique), alertes de stock critique et de péremption proche (< 90 jours),
  historique des factures.
- **Réception et lecture automatique (OCR simulé)** d'une facture grossiste.
- **Rapprochement automatique « Match & Check »** : comparaison ligne par ligne,
  via le code CIP, des quantités facturées et des quantités scannées à la
  réception ; détection des boîtes manquantes, des surplus et des produits
  inconnus ; statut final *Validée* ou *Litige*.
- **Levée manuelle d'un litige**, réservée aux rôles autorisés.
- **Journal d'audit** (qui / quoi / quand) en ajout seul.

Deux scénarios de démonstration sont disponibles dans l'écran de réception :
**BL conforme** et **BL avec écarts** (boîtes manquantes + produit au CIP
inconnu).

## Lancer le projet

Prérequis : [Flutter](https://docs.flutter.dev/get-started/install) 3.41 ou plus.

```bash
flutter pub get
flutter run -d chrome
```

L'application démarre directement avec le jeu de données de démo, sans aucune
configuration.

### Démo web

```bash
flutter build web --release
```

Le dossier `build/web/` peut être publié tel quel sur n'importe quel
hébergement statique. Pour GitHub Pages (site servi sous
`/backoffice-officine/`) :

```bash
flutter build web --release --base-href /backoffice-officine/
```

> La version web fonctionne parce que l'état de l'application est en mémoire.
> La couche SQLite (`sqflite`) n'est pas disponible sur le web ; elle est
> prévue pour les versions mobile et desktop.

## Architecture

Organisation en couches (inspirée de la Clean Architecture) :

```
lib/
├── core/
│   ├── constants/app_constants.dart     # constantes, rôles RBAC et droits
│   ├── theme/app_theme.dart             # couleurs et thème
│   └── utils/crypto_helper.dart         # chiffrement AES-256 et hash SHA-256
├── data/
│   ├── database/database_helper.dart    # base SQLite (sqflite), création du schéma
│   ├── models/                          # Produit, Facture, LigneFacture, Utilisateur, LogAudit…
│   ├── repositories/                    # accès aux données persistantes
│   └── mock/mock_data_service.dart      # données fictives et scénarios de factures
├── domain/services/
│   ├── auth_service.dart                # simulation RBAC
│   ├── ocr_service.dart                 # simulation du moteur OCR
│   └── reconciliation_service.dart      # algorithme Match & Check
├── presentation/
│   ├── providers/app_state_provider.dart  # état de l'application (ChangeNotifier)
│   ├── screens/                         # sélection du profil, dashboard, réception
│   └── widgets/                         # KpiCard, ProduitAlerteTile
└── main.dart
```

- `database_schema.sql` : script SQL complet du modèle de données (7 tables :
  utilisateurs, produits, fournisseurs, factures, lignes_facture,
  mouvements_stock, logs_audit), avec contraintes et index.
- `test/widget_test.dart` : test de démarrage de l'application.

**Technologies** : Dart, Flutter, Material Design, `provider`, `sqflite`,
`encrypt`, `crypto`, `flutter_secure_storage`, `fl_chart`, `intl`, `uuid`.

## Sécurité

- **Chiffrement des champs sensibles** en AES-256-CBC avant écriture en base.
  Un **IV aléatoire de 16 octets** est généré à chaque chiffrement et stocké
  avec le texte chiffré, au format `iv:texte_chiffré` (Base64).
- **Clé de chiffrement** générée aléatoirement au premier lancement et
  conservée dans le coffre sécurisé du système (Keystore / Keychain) via
  `flutter_secure_storage` ; elle n'est jamais écrite dans le code.
- **Identifiants hachés** en SHA-256 : aucun identifiant de connexion n'est
  stocké en clair.
- **Journal d'audit en ajout seul** : le repository n'expose aucune méthode de
  modification ou de suppression.
- **Aucune donnée patient** : le modèle ne contient que des données de stock et
  de gestion.
- Pistes pour une version de production : chiffrement complet du fichier de
  base (`sqflite_sqlcipher`), contrôle des droits côté serveur (le RBAC
  actuel est uniquement côté client), analyse d'impact RGPD si des données
  patients devaient être ajoutées.

## Limites actuelles

- **OCR simulé** : aucun vrai moteur de reconnaissance n'est branché. Le
  service lit des factures fictives et renvoie un score de confiance simulé.
  L'interface `ResultatOcr` permet de brancher plus tard un vrai moteur
  (Google ML Kit, Document AI, Azure Form Recognizer…).
- **SQLite pas encore branchée sur l'interface** : la base et les repositories
  sont écrits, mais l'état affiché est conservé en mémoire
  (`AppStateProvider`). Les données repartent de zéro à chaque lancement.
- **Pas de tests** au-delà d'un test de démarrage : l'algorithme de
  rapprochement et le chiffrement ne sont pas encore couverts par des tests
  unitaires.
- **Authentification simulée** : pas de mot de passe ni de session ; on
  choisit simplement un profil.

---

<a id="english"></a>

# Pharmacy back-office — Flutter PoC

> 🇬🇧 English · [🇫🇷 Français plus haut](#back-office-officine--poc-flutter)

> **All data is fictitious.** The pharmacy name, user accounts, wholesalers,
> invoice numbers, CIP codes, prices and stock levels were made up for the
> demo. Drug names are only used as examples of common pharmacy items.

## Context

Project built during my **discovery internship in a community pharmacy**
(topic: "back-office optimisation procedure"), as part of my studies at
**EPISEN, ITS track** (IT and technologies for healthcare), in 2026.

## Problem observed

In a pharmacy back-office, receiving wholesaler deliveries is still largely
manual:

- the invoice or delivery note is checked line by line, by hand, against
  what is actually in the boxes;
- discrepancies (missing boxes, items not ordered, unknown references) are
  spotted late, or not at all;
- stock-outs and items close to expiry are not flagged in one place;
- it is hard to know who validated what, and when.

The goal of this PoC is to show that a simple app can automate this check and
give the head pharmacist an overview.

## Features

- **Profile selection (simulated RBAC)**: Head pharmacist, Pharmacy
  technician, Intern, each with different rights (only the head pharmacist
  sees financial amounts; head pharmacist and technician can resolve a
  dispute).
- **Dashboard**: key indicators, top items by stock value (chart),
  low-stock and near-expiry (< 90 days) alerts, invoice history.
- **Reception and automatic reading (simulated OCR)** of a wholesaler invoice.
- **Automatic "Match & Check" reconciliation**: line-by-line comparison, by CIP
  code, of invoiced quantities against quantities scanned at reception;
  detects missing boxes, surplus and unknown products; final status
  *Validated* or *Dispute*.
- **Manual dispute resolution**, restricted to authorised roles.
- **Append-only audit log** (who / what / when).

Two demo scenarios are available on the reception screen: **compliant delivery
note** and **delivery note with discrepancies** (missing boxes + unknown CIP).

## Running the project

Requirements: [Flutter](https://docs.flutter.dev/get-started/install) 3.41 or later.

```bash
flutter pub get
flutter run -d chrome
```

The app starts straight away with the demo dataset, no configuration needed.

### Web demo

```bash
flutter build web --release
```

The `build/web/` folder can be deployed as is to any static host. For GitHub
Pages (site served under `/backoffice-officine/`):

```bash
flutter build web --release --base-href /backoffice-officine/
```

> The web version works because the app state is kept in memory. The SQLite
> layer (`sqflite`) is not available on the web; it targets mobile and
> desktop.

## Architecture

Layered structure (inspired by Clean Architecture): `core` (constants, theme,
crypto), `data` (SQLite database, models, repositories, mock data), `domain`
(RBAC, OCR and reconciliation services) and `presentation` (state provider,
screens, widgets). See the tree in the French section above.

- `database_schema.sql`: full SQL script of the data model (7 tables), with
  constraints and indexes.
- `test/widget_test.dart`: app start-up test.

**Stack**: Dart, Flutter, Material Design, `provider`, `sqflite`, `encrypt`,
`crypto`, `flutter_secure_storage`, `fl_chart`, `intl`, `uuid`.

## Security

- **Sensitive fields encrypted** with AES-256-CBC before being written to the
  database. A **random 16-byte IV** is generated for every encryption and
  stored with the ciphertext, as `iv:ciphertext` (Base64).
- **Encryption key** randomly generated on first launch and kept in the OS
  secure store (Keystore / Keychain) through `flutter_secure_storage`; it is
  never written in the code.
- **Identifiers hashed** with SHA-256: no login identifier is stored in clear.
- **Append-only audit log**: the repository exposes no update or delete method.
- **No patient data**: the model only holds stock and management data.
- Next steps for production: full database-file encryption
  (`sqflite_sqlcipher`), server-side permission checks (the current RBAC is
  client-side only), GDPR impact assessment if patient data were ever added.

## Current limitations

- **Simulated OCR**: no real recognition engine is plugged in. The service
  reads fictitious invoices and returns a simulated confidence score. The
  `ResultatOcr` interface allows a real engine to be plugged in later
  (Google ML Kit, Document AI, Azure Form Recognizer…).
- **SQLite not yet wired to the UI**: the database and repositories are
  written, but the displayed state is kept in memory (`AppStateProvider`).
  Data resets on every launch.
- **No tests** beyond a start-up test: the reconciliation algorithm and the
  encryption are not yet covered by unit tests.
- **Simulated authentication**: no password or session; you just pick a
  profile.
