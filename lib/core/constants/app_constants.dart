/// Constantes globales de l'application.
class AppConstants {
  AppConstants._();

  static const String dbName = 'backoffice_officine.db';
  static const int dbVersion = 1;

  // Seuils métiers
  static const int seuilPeremptionProcheJours = 90; // < 3 mois

  // Clés de stockage sécurisé (flutter_secure_storage)
  static const String secureStorageEncryptionKey = 'db_field_encryption_key_v1';
}

/// Rôles RBAC disponibles.
enum RoleUtilisateur { titulaire, preparateur, stagiaire }

extension RoleUtilisateurX on RoleUtilisateur {
  String get label {
    switch (this) {
      case RoleUtilisateur.titulaire:
        return 'TITULAIRE';
      case RoleUtilisateur.preparateur:
        return 'PREPARATEUR';
      case RoleUtilisateur.stagiaire:
        return 'STAGIAIRE';
    }
  }

  /// Accès au module de facturation/validation des litiges.
  bool get peutValiderFactures =>
      this == RoleUtilisateur.titulaire || this == RoleUtilisateur.preparateur;

  /// Accès aux montants financiers agrégés du dashboard.
  bool get peutVoirMontantsFinanciers => this == RoleUtilisateur.titulaire;
}
