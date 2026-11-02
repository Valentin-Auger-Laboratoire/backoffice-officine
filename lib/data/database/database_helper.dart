import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_constants.dart';

/// Singleton d'accès à la base SQFlite locale.
///
/// Sécurité : les champs jugés sensibles (cf. modèles) sont chiffrés/
/// déchiffrés au niveau repository via [CryptoHelper] avant d'atteindre
/// ce helper — la base elle-même reste donc en SQLite standard ici.
/// Pour un chiffrement de fichier complet (recommandé en production HDS),
/// remplacer `sqflite` par `sqflite_sqlcipher` (API quasi identique).
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, AppConstants.dbName);

    return openDatabase(
      dbPath,
      version: AppConstants.dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
      },
    );
  }

  Future<void> _createSchema(Database db) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE IF NOT EXISTS utilisateurs (
        id TEXT PRIMARY KEY,
        nom_affiche TEXT NOT NULL,
        role TEXT NOT NULL CHECK (role IN ('TITULAIRE','PREPARATEUR','STAGIAIRE')),
        identifiant_hash TEXT NOT NULL UNIQUE,
        actif INTEGER NOT NULL DEFAULT 1 CHECK (actif IN (0,1)),
        date_creation TEXT NOT NULL DEFAULT (datetime('now'))
      );
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS produits (
        id TEXT PRIMARY KEY,
        code_cip TEXT NOT NULL UNIQUE,
        code_acl TEXT,
        designation TEXT NOT NULL,
        type_produit TEXT NOT NULL CHECK (type_produit IN ('ORDONNANCE','OTC','PARAPHARMACIE')),
        rayon TEXT,
        tiroir TEXT,
        colonne TEXT,
        quantite_reelle INTEGER NOT NULL DEFAULT 0 CHECK (quantite_reelle >= 0),
        seuil_critique INTEGER NOT NULL DEFAULT 5 CHECK (seuil_critique >= 0),
        prix_achat_ht REAL NOT NULL DEFAULT 0,
        prix_vente_ttc REAL NOT NULL DEFAULT 0,
        date_peremption TEXT,
        date_maj TEXT NOT NULL DEFAULT (datetime('now'))
      );
    ''');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_produits_cip ON produits(code_cip);');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_produits_peremption ON produits(date_peremption);');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS fournisseurs (
        id TEXT PRIMARY KEY,
        nom TEXT NOT NULL UNIQUE
      );
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS factures (
        id TEXT PRIMARY KEY,
        numero_facture TEXT NOT NULL,
        fournisseur_id TEXT NOT NULL REFERENCES fournisseurs(id) ON DELETE RESTRICT,
        date_facture TEXT NOT NULL,
        date_reception_scan TEXT NOT NULL DEFAULT (datetime('now')),
        statut TEXT NOT NULL DEFAULT 'EN_ATTENTE' CHECK (statut IN ('EN_ATTENTE','VALIDEE','LITIGE')),
        montant_total_ht REAL NOT NULL DEFAULT 0,
        chemin_document TEXT,
        utilisateur_id TEXT REFERENCES utilisateurs(id) ON DELETE SET NULL,
        UNIQUE (numero_facture, fournisseur_id)
      );
    ''');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_factures_statut ON factures(statut);');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS lignes_facture (
        id TEXT PRIMARY KEY,
        facture_id TEXT NOT NULL REFERENCES factures(id) ON DELETE CASCADE,
        produit_id TEXT REFERENCES produits(id) ON DELETE SET NULL,
        code_cip_extrait TEXT NOT NULL,
        designation_extraite TEXT NOT NULL,
        quantite_facturee INTEGER NOT NULL CHECK (quantite_facturee >= 0),
        quantite_recue_scan INTEGER NOT NULL DEFAULT 0 CHECK (quantite_recue_scan >= 0),
        prix_unitaire_ht REAL NOT NULL DEFAULT 0,
        statut_ligne TEXT NOT NULL DEFAULT 'EN_ATTENTE' CHECK (statut_ligne IN ('CONFORME','ECART','EN_ATTENTE'))
      );
    ''');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_lignes_facture_facture ON lignes_facture(facture_id);');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS mouvements_stock (
        id TEXT PRIMARY KEY,
        produit_id TEXT NOT NULL REFERENCES produits(id) ON DELETE CASCADE,
        type_mouvement TEXT NOT NULL CHECK (type_mouvement IN ('ENTREE','SORTIE','AJUSTEMENT','RETOUR')),
        quantite INTEGER NOT NULL,
        facture_id TEXT REFERENCES factures(id) ON DELETE SET NULL,
        utilisateur_id TEXT REFERENCES utilisateurs(id) ON DELETE SET NULL,
        horodatage TEXT NOT NULL DEFAULT (datetime('now')),
        commentaire TEXT
      );
    ''');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_mouvements_produit ON mouvements_stock(produit_id);');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS logs_audit (
        id TEXT PRIMARY KEY,
        utilisateur_id TEXT REFERENCES utilisateurs(id) ON DELETE SET NULL,
        role_acteur TEXT NOT NULL,
        action TEXT NOT NULL,
        entite_cible TEXT NOT NULL,
        entite_id TEXT,
        details TEXT,
        horodatage TEXT NOT NULL DEFAULT (datetime('now'))
      );
    ''');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_logs_audit_horodatage ON logs_audit(horodatage);');

    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
