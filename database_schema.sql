-- =====================================================================
-- SCHEMA BASE DE DONNEES LOCALE - PHARMACIE DÉMO BACK-OFFICE
-- Moteur : SQLite (via sqflite) — chiffrement champ-à-champ AES-256
--          appliqué côté Dart avant écriture (cf. core/utils/crypto_helper.dart)
--          Pour une volumétrie production, migrer vers sqflite_sqlcipher
--          (chiffrement de fichier complet AES-256 transparent).
-- =====================================================================

PRAGMA foreign_keys = ON;

-- ---------------------------------------------------------------------
-- TABLE: utilisateurs (RBAC)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS utilisateurs (
    id              TEXT PRIMARY KEY,                 -- UUID
    nom_affiche     TEXT NOT NULL,                     -- nom non-sensible affiché
    role            TEXT NOT NULL CHECK (role IN ('TITULAIRE', 'PREPARATEUR', 'STAGIAIRE')),
    identifiant_hash TEXT NOT NULL UNIQUE,              -- hash SHA-256 de l'identifiant (pas de PII en clair)
    actif           INTEGER NOT NULL DEFAULT 1 CHECK (actif IN (0,1)),
    date_creation   TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ---------------------------------------------------------------------
-- TABLE: produits
-- Données techniques de stock — séparées de toute donnée patient
-- (aucune donnée patient n'est gérée par ce PoC, cf. note RGPD README)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS produits (
    id                  TEXT PRIMARY KEY,              -- UUID interne
    code_cip            TEXT NOT NULL UNIQUE,           -- Code CIP/CIP13
    code_acl            TEXT,                           -- Code ACL grossiste
    designation         TEXT NOT NULL,
    type_produit        TEXT NOT NULL CHECK (type_produit IN ('ORDONNANCE', 'OTC', 'PARAPHARMACIE')),
    rayon               TEXT,
    tiroir              TEXT,
    colonne             TEXT,
    quantite_reelle     INTEGER NOT NULL DEFAULT 0 CHECK (quantite_reelle >= 0),
    seuil_critique      INTEGER NOT NULL DEFAULT 5 CHECK (seuil_critique >= 0),
    prix_achat_ht       REAL NOT NULL DEFAULT 0,
    prix_vente_ttc      REAL NOT NULL DEFAULT 0,
    date_peremption     TEXT,                           -- ISO 8601, NULL si non périssable
    date_maj            TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_produits_cip ON produits(code_cip);
CREATE INDEX IF NOT EXISTS idx_produits_peremption ON produits(date_peremption);

-- ---------------------------------------------------------------------
-- TABLE: fournisseurs (grossistes-répartiteurs)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fournisseurs (
    id              TEXT PRIMARY KEY,
    nom             TEXT NOT NULL UNIQUE                -- ex: Grossiste A, Grossiste B, Grossiste C
);

-- ---------------------------------------------------------------------
-- TABLE: factures (Bons de Livraison / Factures grossiste)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS factures (
    id                  TEXT PRIMARY KEY,
    numero_facture      TEXT NOT NULL,
    fournisseur_id      TEXT NOT NULL REFERENCES fournisseurs(id) ON DELETE RESTRICT,
    date_facture        TEXT NOT NULL,
    date_reception_scan TEXT NOT NULL DEFAULT (datetime('now')),
    statut              TEXT NOT NULL DEFAULT 'EN_ATTENTE'
                         CHECK (statut IN ('EN_ATTENTE', 'VALIDEE', 'LITIGE')),
    montant_total_ht    REAL NOT NULL DEFAULT 0,
    chemin_document      TEXT,                           -- chemin local du scan/PDF source
    utilisateur_id      TEXT REFERENCES utilisateurs(id) ON DELETE SET NULL,
    UNIQUE (numero_facture, fournisseur_id)
);

CREATE INDEX IF NOT EXISTS idx_factures_statut ON factures(statut);

-- ---------------------------------------------------------------------
-- TABLE: lignes_facture (lignes extraites par l'OCR, avant/après rapprochement)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lignes_facture (
    id                  TEXT PRIMARY KEY,
    facture_id          TEXT NOT NULL REFERENCES factures(id) ON DELETE CASCADE,
    produit_id          TEXT REFERENCES produits(id) ON DELETE SET NULL,
    code_cip_extrait    TEXT NOT NULL,                   -- valeur brute lue par l'OCR
    designation_extraite TEXT NOT NULL,
    quantite_facturee   INTEGER NOT NULL CHECK (quantite_facturee >= 0),
    quantite_recue_scan INTEGER NOT NULL DEFAULT 0 CHECK (quantite_recue_scan >= 0),
    prix_unitaire_ht    REAL NOT NULL DEFAULT 0,
    statut_ligne        TEXT NOT NULL DEFAULT 'EN_ATTENTE'
                         CHECK (statut_ligne IN ('CONFORME', 'ECART', 'EN_ATTENTE'))
);

CREATE INDEX IF NOT EXISTS idx_lignes_facture_facture ON lignes_facture(facture_id);

-- ---------------------------------------------------------------------
-- TABLE: mouvements_stock (traçabilité des entrées/sorties)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS mouvements_stock (
    id              TEXT PRIMARY KEY,
    produit_id      TEXT NOT NULL REFERENCES produits(id) ON DELETE CASCADE,
    type_mouvement  TEXT NOT NULL CHECK (type_mouvement IN ('ENTREE', 'SORTIE', 'AJUSTEMENT', 'RETOUR')),
    quantite        INTEGER NOT NULL,
    facture_id      TEXT REFERENCES factures(id) ON DELETE SET NULL,
    utilisateur_id  TEXT REFERENCES utilisateurs(id) ON DELETE SET NULL,
    horodatage      TEXT NOT NULL DEFAULT (datetime('now')),
    commentaire     TEXT
);

CREATE INDEX IF NOT EXISTS idx_mouvements_produit ON mouvements_stock(produit_id);
CREATE INDEX IF NOT EXISTS idx_mouvements_horodatage ON mouvements_stock(horodatage);

-- ---------------------------------------------------------------------
-- TABLE: logs_audit (journalisation obligatoire — qui / quoi / quand)
-- Append-only : aucune mise à jour ni suppression ne doit être permise
-- au niveau applicatif sur cette table.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS logs_audit (
    id              TEXT PRIMARY KEY,
    utilisateur_id  TEXT REFERENCES utilisateurs(id) ON DELETE SET NULL,
    role_acteur     TEXT NOT NULL,
    action          TEXT NOT NULL,                       -- ex: 'SCAN_PRODUIT', 'VALIDATION_FACTURE'
    entite_cible    TEXT NOT NULL,                       -- ex: 'produits', 'factures'
    entite_id       TEXT,
    details         TEXT,                                -- JSON sérialisé, sans donnée patient
    horodatage      TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_logs_audit_horodatage ON logs_audit(horodatage);
CREATE INDEX IF NOT EXISTS idx_logs_audit_utilisateur ON logs_audit(utilisateur_id);
