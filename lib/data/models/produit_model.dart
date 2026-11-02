enum TypeProduit { ordonnance, otc, parapharmacie }

extension TypeProduitX on TypeProduit {
  String get value {
    switch (this) {
      case TypeProduit.ordonnance:
        return 'ORDONNANCE';
      case TypeProduit.otc:
        return 'OTC';
      case TypeProduit.parapharmacie:
        return 'PARAPHARMACIE';
    }
  }

  static TypeProduit fromValue(String v) {
    switch (v) {
      case 'ORDONNANCE':
        return TypeProduit.ordonnance;
      case 'OTC':
        return TypeProduit.otc;
      default:
        return TypeProduit.parapharmacie;
    }
  }

  String get label {
    switch (this) {
      case TypeProduit.ordonnance:
        return 'Sur ordonnance';
      case TypeProduit.otc:
        return 'OTC';
      case TypeProduit.parapharmacie:
        return 'Parapharmacie';
    }
  }
}

/// Niveau d'alerte calculé dynamiquement pour le dashboard.
enum NiveauAlerte { rouge, orange, vert }

class Produit {
  final String id;
  final String codeCip;
  final String? codeAcl;
  final String designation;
  final TypeProduit type;
  final String? rayon;
  final String? tiroir;
  final String? colonne;
  final int quantiteReelle;
  final int seuilCritique;
  final double prixAchatHt;
  final double prixVenteTtc;
  final DateTime? datePeremption;
  final DateTime dateMaj;

  Produit({
    required this.id,
    required this.codeCip,
    this.codeAcl,
    required this.designation,
    required this.type,
    this.rayon,
    this.tiroir,
    this.colonne,
    required this.quantiteReelle,
    required this.seuilCritique,
    required this.prixAchatHt,
    required this.prixVenteTtc,
    this.datePeremption,
    DateTime? dateMaj,
  }) : dateMaj = dateMaj ?? DateTime.now();

  String get emplacement => [
        if (rayon != null) 'Rayon $rayon',
        if (tiroir != null) 'Tiroir $tiroir',
        if (colonne != null) 'Col. $colonne',
      ].join(' • ');

  /// Calcule le niveau d'alerte produit (rupture, péremption, seuil...).
  NiveauAlerte get niveauAlerte {
    final now = DateTime.now();
    if (quantiteReelle <= 0) return NiveauAlerte.rouge;
    if (datePeremption != null && datePeremption!.isBefore(now)) {
      return NiveauAlerte.rouge;
    }
    if (datePeremption != null &&
        datePeremption!.isBefore(now.add(const Duration(days: 90)))) {
      return NiveauAlerte.orange;
    }
    if (quantiteReelle <= seuilCritique) return NiveauAlerte.orange;
    return NiveauAlerte.vert;
  }

  double get valeurStockAchat => quantiteReelle * prixAchatHt;

  Produit copyWith({int? quantiteReelle, DateTime? dateMaj}) => Produit(
        id: id,
        codeCip: codeCip,
        codeAcl: codeAcl,
        designation: designation,
        type: type,
        rayon: rayon,
        tiroir: tiroir,
        colonne: colonne,
        quantiteReelle: quantiteReelle ?? this.quantiteReelle,
        seuilCritique: seuilCritique,
        prixAchatHt: prixAchatHt,
        prixVenteTtc: prixVenteTtc,
        datePeremption: datePeremption,
        dateMaj: dateMaj ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'code_cip': codeCip,
        'code_acl': codeAcl,
        'designation': designation,
        'type_produit': type.value,
        'rayon': rayon,
        'tiroir': tiroir,
        'colonne': colonne,
        'quantite_reelle': quantiteReelle,
        'seuil_critique': seuilCritique,
        'prix_achat_ht': prixAchatHt,
        'prix_vente_ttc': prixVenteTtc,
        'date_peremption': datePeremption?.toIso8601String(),
        'date_maj': dateMaj.toIso8601String(),
      };

  factory Produit.fromMap(Map<String, dynamic> map) => Produit(
        id: map['id'] as String,
        codeCip: map['code_cip'] as String,
        codeAcl: map['code_acl'] as String?,
        designation: map['designation'] as String,
        type: TypeProduitX.fromValue(map['type_produit'] as String),
        rayon: map['rayon'] as String?,
        tiroir: map['tiroir'] as String?,
        colonne: map['colonne'] as String?,
        quantiteReelle: map['quantite_reelle'] as int,
        seuilCritique: map['seuil_critique'] as int,
        prixAchatHt: (map['prix_achat_ht'] as num).toDouble(),
        prixVenteTtc: (map['prix_vente_ttc'] as num).toDouble(),
        datePeremption: map['date_peremption'] != null
            ? DateTime.parse(map['date_peremption'] as String)
            : null,
        dateMaj: DateTime.parse(map['date_maj'] as String),
      );
}
