import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/produit_model.dart';
import '../../core/utils/crypto_helper.dart';

/// Repository de persistance des produits.
///
/// Démontre le pattern d'accès données utilisé par l'application :
/// DatabaseHelper (SQFlite) + CryptoHelper (chiffrement champ-à-champ des
/// données jugées sensibles, ex. emplacement physique précis en rayon).
/// L'écran Dashboard de ce PoC consomme AppStateProvider (état en mémoire
/// pré-rempli via MockDataService) pour un fonctionnement immédiat sans
/// dépendance ; ce repository illustre comment brancher la persistance
/// réelle (et, à terme, une synchronisation API) sans changer la couche
/// présentation, conformément à la Clean Architecture du projet.
class ProduitRepository {
  final _crypto = CryptoHelper.instance;

  Future<void> upsert(Produit produit) async {
    final db = await DatabaseHelper.instance.database;
    final map = produit.toMap();
    // Exemple de chiffrement d'un champ jugé sensible (emplacement précis
    // dans le back-office, utile à la sécurité physique de l'officine).
    if (produit.rayon != null) {
      map['rayon'] = await _crypto.encryptField(produit.rayon!);
    }
    await db.insert('produits', map,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Produit>> listerTous() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('produits', orderBy: 'designation ASC');
    final produits = <Produit>[];
    for (final row in rows) {
      final mutable = Map<String, dynamic>.from(row);
      if (mutable['rayon'] != null) {
        mutable['rayon'] = await _crypto.decryptField(mutable['rayon'] as String);
      }
      produits.add(Produit.fromMap(mutable));
    }
    return produits;
  }

  Future<Produit?> parCodeCip(String codeCip) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('produits', where: 'code_cip = ?', whereArgs: [codeCip], limit: 1);
    if (rows.isEmpty) return null;
    return Produit.fromMap(rows.first);
  }

  Future<void> ajusterQuantite(String produitId, int delta) async {
    final db = await DatabaseHelper.instance.database;
    await db.rawUpdate(
      'UPDATE produits SET quantite_reelle = quantite_reelle + ?, date_maj = datetime(\'now\') WHERE id = ?',
      [delta, produitId],
    );
  }
}
