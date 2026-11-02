import '../database/database_helper.dart';
import '../models/audit_models.dart';

/// Repository d'écriture des logs d'audit. Volontairement append-only :
/// aucune méthode d'update/delete n'est exposée, afin de garantir la
/// non-altération de la traçabilité réglementaire (qui a scanné/modifié
/// quoi, à quelle heure).
class AuditRepository {
  Future<void> enregistrer(LogAudit log) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('logs_audit', log.toMap());
  }

  Future<List<LogAudit>> lister({int limite = 100}) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'logs_audit',
      orderBy: 'horodatage DESC',
      limit: limite,
    );
    return rows.map(LogAudit.fromMap).toList();
  }
}
