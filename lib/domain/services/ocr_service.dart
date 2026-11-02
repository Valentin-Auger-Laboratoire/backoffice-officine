import 'dart:math';
import 'package:uuid/uuid.dart';
import '../../data/models/facture_model.dart';

/// Résultat brut d'une extraction OCR avant tout rapprochement.
class ResultatOcr {
  final String fournisseurDetecte;
  final String numeroFacture;
  final DateTime dateFacture;
  final List<LigneFacture> lignesExtraites;
  final double confianceGlobale; // 0.0 - 1.0, simule le score moteur OCR

  ResultatOcr({
    required this.fournisseurDetecte,
    required this.numeroFacture,
    required this.dateFacture,
    required this.lignesExtraites,
    required this.confianceGlobale,
  });
}

/// SIMULATION d'un moteur OCR de lecture de factures/BL grossiste.
///
/// Dans une implémentation réelle, ce service appellerait un moteur OCR
/// (ex: Google ML Kit Text Recognition en local, ou une API Document AI /
/// Azure Form Recognizer côté serveur) puis un parseur structurant le
/// texte brut en lignes produit. Ici, pour permettre au PoC de tourner à
/// 100% sans dépendance externe ni clé API, le moteur "lit" un jeu de
/// documents mock (cf. data/mock/mock_data_service.dart) en y ajoutant un
/// bruit de confiance réaliste.
class OcrService {
  final _uuid = const Uuid();
  final _random = Random();

  /// Simule l'analyse d'une photo/PDF de facture et retourne les données
  /// structurées extraites, prêtes pour le rapprochement.
  Future<ResultatOcr> analyserDocument({
    required String fournisseur,
    required String numeroFacture,
    required DateTime dateFacture,
    required List<({String cip, String designation, int quantite, double prixUnitaire})> lignesSources,
  }) async {
    // Simule la latence d'un traitement OCR réel (vision + NLP).
    await Future.delayed(const Duration(milliseconds: 900));

    final lignes = lignesSources.map((source) {
      return LigneFacture(
        id: _uuid.v4(),
        factureId: '', // assigné après création de la facture
        codeCipExtrait: source.cip,
        designationExtraite: source.designation,
        quantiteFacturee: source.quantite,
        prixUnitaireHt: source.prixUnitaire,
      );
    }).toList();

    // Score de confiance simulé (un vrai moteur retournerait un score par
    // champ ; on simplifie ici à un score global réaliste).
    final confiance = 0.93 + _random.nextDouble() * 0.06;

    return ResultatOcr(
      fournisseurDetecte: fournisseur,
      numeroFacture: numeroFacture,
      dateFacture: dateFacture,
      lignesExtraites: lignes,
      confianceGlobale: double.parse(confiance.toStringAsFixed(3)),
    );
  }
}
