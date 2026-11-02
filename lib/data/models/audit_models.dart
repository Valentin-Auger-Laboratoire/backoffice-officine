import '../../core/constants/app_constants.dart';

class Utilisateur {
  final String id;
  final String nomAffiche;
  final RoleUtilisateur role;

  Utilisateur({required this.id, required this.nomAffiche, required this.role});
}

class LogAudit {
  final String id;
  final String? utilisateurId;
  final String roleActeur;
  final String action;
  final String entiteCible;
  final String? entiteId;
  final String? details;
  final DateTime horodatage;

  LogAudit({
    required this.id,
    this.utilisateurId,
    required this.roleActeur,
    required this.action,
    required this.entiteCible,
    this.entiteId,
    this.details,
    DateTime? horodatage,
  }) : horodatage = horodatage ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'utilisateur_id': utilisateurId,
        'role_acteur': roleActeur,
        'action': action,
        'entite_cible': entiteCible,
        'entite_id': entiteId,
        'details': details,
        'horodatage': horodatage.toIso8601String(),
      };

  factory LogAudit.fromMap(Map<String, dynamic> map) => LogAudit(
        id: map['id'] as String,
        utilisateurId: map['utilisateur_id'] as String?,
        roleActeur: map['role_acteur'] as String,
        action: map['action'] as String,
        entiteCible: map['entite_cible'] as String,
        entiteId: map['entite_id'] as String?,
        details: map['details'] as String?,
        horodatage: DateTime.parse(map['horodatage'] as String),
      );
}

enum TypeMouvement { entree, sortie, ajustement, retour }

extension TypeMouvementX on TypeMouvement {
  String get value {
    switch (this) {
      case TypeMouvement.entree:
        return 'ENTREE';
      case TypeMouvement.sortie:
        return 'SORTIE';
      case TypeMouvement.ajustement:
        return 'AJUSTEMENT';
      case TypeMouvement.retour:
        return 'RETOUR';
    }
  }
}

class MouvementStock {
  final String id;
  final String produitId;
  final TypeMouvement type;
  final int quantite;
  final String? factureId;
  final String? utilisateurId;
  final DateTime horodatage;
  final String? commentaire;

  MouvementStock({
    required this.id,
    required this.produitId,
    required this.type,
    required this.quantite,
    this.factureId,
    this.utilisateurId,
    DateTime? horodatage,
    this.commentaire,
  }) : horodatage = horodatage ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'produit_id': produitId,
        'type_mouvement': type.value,
        'quantite': quantite,
        'facture_id': factureId,
        'utilisateur_id': utilisateurId,
        'horodatage': horodatage.toIso8601String(),
        'commentaire': commentaire,
      };
}
