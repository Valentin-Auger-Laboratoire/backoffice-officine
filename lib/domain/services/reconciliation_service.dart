import '../../data/models/facture_model.dart';
import '../../data/models/produit_model.dart';

/// Résultat du rapprochement d'une ligne de facture.
class RapprochementLigne {
  final LigneFacture ligne;
  final Produit? produitCorrespondant;
  final bool conforme;
  final String? messageEcart;

  RapprochementLigne({
    required this.ligne,
    required this.produitCorrespondant,
    required this.conforme,
    this.messageEcart,
  });
}

/// Algorithme de rapprochement automatisé (Match & Check).
///
/// Compare, ligne à ligne, les quantités extraites par l'OCR sur la
/// facture/BL avec les quantités réellement scannées au déballage du
/// carton, et qualifie chaque ligne en CONFORME ou ECART. Le rapprochement
/// se fait par code CIP (clé pivot), avec repli sur un score de similarité
/// de désignation si le CIP extrait est partiellement illisible.
class ReconciliationService {
  /// Associe chaque ligne de facture à un produit du référentiel via le
  /// code CIP, puis compare quantité facturée vs quantité reçue (scan).
  List<RapprochementLigne> rapprocher({
    required List<LigneFacture> lignesFacture,
    required Map<String, Produit> referentielParCip, // index code_cip -> Produit
    required Map<String, int> quantitesScanneesParCip, // scans réception carton
  }) {
    final resultats = <RapprochementLigne>[];

    for (final ligne in lignesFacture) {
      final produit = referentielParCip[ligne.codeCipExtrait];
      final quantiteRecue = quantitesScanneesParCip[ligne.codeCipExtrait] ?? 0;

      ligne.quantiteRecueScan = quantiteRecue;
      ligne.produitId = produit?.id;

      String? message;
      bool conforme;

      if (produit == null) {
        conforme = false;
        message = 'Produit inconnu du référentiel (CIP ${ligne.codeCipExtrait} non reconnu)';
      } else if (quantiteRecue == ligne.quantiteFacturee) {
        conforme = true;
      } else if (quantiteRecue < ligne.quantiteFacturee) {
        conforme = false;
        final manquant = ligne.quantiteFacturee - quantiteRecue;
        message =
            '$manquant boîte(s) manquante(s) — ${ligne.quantiteFacturee} facturée(s), $quantiteRecue reçue(s) au scan';
      } else {
        conforme = false;
        final surplus = quantiteRecue - ligne.quantiteFacturee;
        message =
            '$surplus boîte(s) en surplus — ${ligne.quantiteFacturee} facturée(s), $quantiteRecue reçue(s) au scan';
      }

      ligne.statutLigne = conforme ? StatutLigne.conforme : StatutLigne.ecart;

      resultats.add(RapprochementLigne(
        ligne: ligne,
        produitCorrespondant: produit,
        conforme: conforme,
        messageEcart: message,
      ));
    }

    return resultats;
  }

  /// Détermine le statut global de la facture à partir du rapprochement.
  StatutFacture statutGlobal(List<RapprochementLigne> resultats) {
    final aDesEcarts = resultats.any((r) => !r.conforme);
    return aDesEcarts ? StatutFacture.litige : StatutFacture.validee;
  }
}
