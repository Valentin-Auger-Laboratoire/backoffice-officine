enum StatutFacture { enAttente, validee, litige }

extension StatutFactureX on StatutFacture {
  String get value {
    switch (this) {
      case StatutFacture.enAttente:
        return 'EN_ATTENTE';
      case StatutFacture.validee:
        return 'VALIDEE';
      case StatutFacture.litige:
        return 'LITIGE';
    }
  }

  static StatutFacture fromValue(String v) {
    switch (v) {
      case 'VALIDEE':
        return StatutFacture.validee;
      case 'LITIGE':
        return StatutFacture.litige;
      default:
        return StatutFacture.enAttente;
    }
  }

  String get label {
    switch (this) {
      case StatutFacture.enAttente:
        return 'En attente';
      case StatutFacture.validee:
        return 'Validée';
      case StatutFacture.litige:
        return 'En litige';
    }
  }
}

enum StatutLigne { conforme, ecart, enAttente }

extension StatutLigneX on StatutLigne {
  String get value {
    switch (this) {
      case StatutLigne.conforme:
        return 'CONFORME';
      case StatutLigne.ecart:
        return 'ECART';
      case StatutLigne.enAttente:
        return 'EN_ATTENTE';
    }
  }
}

class LigneFacture {
  final String id;
  final String factureId;
  String? produitId;
  final String codeCipExtrait;
  final String designationExtraite;
  final int quantiteFacturee;
  int quantiteRecueScan;
  final double prixUnitaireHt;
  StatutLigne statutLigne;

  LigneFacture({
    required this.id,
    required this.factureId,
    this.produitId,
    required this.codeCipExtrait,
    required this.designationExtraite,
    required this.quantiteFacturee,
    this.quantiteRecueScan = 0,
    required this.prixUnitaireHt,
    this.statutLigne = StatutLigne.enAttente,
  });

  int get ecart => quantiteRecueScan - quantiteFacturee;

  Map<String, dynamic> toMap() => {
        'id': id,
        'facture_id': factureId,
        'produit_id': produitId,
        'code_cip_extrait': codeCipExtrait,
        'designation_extraite': designationExtraite,
        'quantite_facturee': quantiteFacturee,
        'quantite_recue_scan': quantiteRecueScan,
        'prix_unitaire_ht': prixUnitaireHt,
        'statut_ligne': statutLigne.value,
      };

  factory LigneFacture.fromMap(Map<String, dynamic> map) => LigneFacture(
        id: map['id'] as String,
        factureId: map['facture_id'] as String,
        produitId: map['produit_id'] as String?,
        codeCipExtrait: map['code_cip_extrait'] as String,
        designationExtraite: map['designation_extraite'] as String,
        quantiteFacturee: map['quantite_facturee'] as int,
        quantiteRecueScan: map['quantite_recue_scan'] as int,
        prixUnitaireHt: (map['prix_unitaire_ht'] as num).toDouble(),
        statutLigne: map['statut_ligne'] == 'CONFORME'
            ? StatutLigne.conforme
            : map['statut_ligne'] == 'ECART'
                ? StatutLigne.ecart
                : StatutLigne.enAttente,
      );
}

class Facture {
  final String id;
  final String numeroFacture;
  final String fournisseurNom; // dénormalisé pour simplicité PoC
  final DateTime dateFacture;
  final DateTime dateReceptionScan;
  StatutFacture statut;
  double montantTotalHt;
  final String? cheminDocument;
  final List<LigneFacture> lignes;

  Facture({
    required this.id,
    required this.numeroFacture,
    required this.fournisseurNom,
    required this.dateFacture,
    DateTime? dateReceptionScan,
    this.statut = StatutFacture.enAttente,
    this.montantTotalHt = 0,
    this.cheminDocument,
    List<LigneFacture>? lignes,
  })  : dateReceptionScan = dateReceptionScan ?? DateTime.now(),
        lignes = lignes ?? [];

  int get nombreEcarts => lignes.where((l) => l.statutLigne == StatutLigne.ecart).length;

  bool get aDesEcarts => nombreEcarts > 0;
}
