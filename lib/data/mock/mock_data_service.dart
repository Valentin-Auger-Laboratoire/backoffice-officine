import 'package:uuid/uuid.dart';
import '../models/produit_model.dart';

/// Fournit un jeu de données de démonstration réaliste pour que le PoC
/// fonctionne immédiatement, sans dépendance réseau ni saisie manuelle :
/// référentiel produits (DCI/noms de spécialités couramment dispensées en
/// officine) + scénarios de factures grossiste avec écarts volontaires
/// pour illustrer le moteur de rapprochement.
class MockDataService {
  static final _uuid = Uuid();

  /// Référentiel produits "déjà en stock" côté pharmacie.
  static List<Produit> genererProduits() {
    final now = DateTime.now();
    return [
      Produit(
        id: _uuid.v4(),
        codeCip: '3400930000013',
        designation: 'Doliprane 1000mg, 8 comprimés',
        type: TypeProduit.otc,
        rayon: 'A1', tiroir: '2', colonne: 'C',
        quantiteReelle: 40, seuilCritique: 15,
        prixAchatHt: 1.90, prixVenteTtc: 2.60,
        datePeremption: now.add(const Duration(days: 540)),
      ),
      Produit(
        id: _uuid.v4(),
        codeCip: '3400930000037',
        designation: 'Amoxicilline Biogaran 500mg, 12 gélules',
        type: TypeProduit.ordonnance,
        rayon: 'B2', tiroir: '1', colonne: 'A',
        quantiteReelle: 5, seuilCritique: 10,
        prixAchatHt: 2.00, prixVenteTtc: 3.30,
        datePeremption: now.add(const Duration(days: 365)),
      ),
      Produit(
        id: _uuid.v4(),
        codeCip: '3400930000051',
        designation: 'Kardégic 75mg, 30 sachets',
        type: TypeProduit.ordonnance,
        rayon: 'B1', tiroir: '3', colonne: 'B',
        quantiteReelle: 20, seuilCritique: 12,
        prixAchatHt: 3.00, prixVenteTtc: 4.20,
        datePeremption: now.add(const Duration(days: 60)), // bientôt périmé
      ),
      Produit(
        id: _uuid.v4(),
        codeCip: '3400930000075',
        designation: 'Efferalgan 500mg, 16 comprimés effervescents',
        type: TypeProduit.otc,
        rayon: 'A1', tiroir: '2', colonne: 'D',
        quantiteReelle: 0, seuilCritique: 10, // rupture
        prixAchatHt: 1.50, prixVenteTtc: 2.20,
        datePeremption: now.add(const Duration(days: 420)),
      ),
      Produit(
        id: _uuid.v4(),
        codeCip: '3400930000099',
        designation: 'Spasfon Lyoc 80mg, 10 lyophilisats',
        type: TypeProduit.otc,
        rayon: 'A2', tiroir: '1', colonne: 'A',
        quantiteReelle: 24, seuilCritique: 10,
        prixAchatHt: 2.50, prixVenteTtc: 3.60,
        datePeremption: now.add(const Duration(days: 300)),
      ),
      Produit(
        id: _uuid.v4(),
        codeCip: '3400930000112',
        designation: 'Ventoline 100µg, flacon pressurisé',
        type: TypeProduit.ordonnance,
        rayon: 'C1', tiroir: '1', colonne: 'C',
        quantiteReelle: 10, seuilCritique: 8,
        prixAchatHt: 3.70, prixVenteTtc: 5.10,
        datePeremption: now.add(const Duration(days: 80)),
      ),
      Produit(
        id: _uuid.v4(),
        codeCip: '3400930000136',
        designation: 'Nurofen 400mg, 12 comprimés enrobés',
        type: TypeProduit.otc,
        rayon: 'A1', tiroir: '3', colonne: 'A',
        quantiteReelle: 30, seuilCritique: 15,
        prixAchatHt: 2.00, prixVenteTtc: 2.90,
        datePeremption: now.add(const Duration(days: 600)),
      ),
      Produit(
        id: _uuid.v4(),
        codeCip: '3400930000150',
        designation: 'Smecta poudre, 30 sachets-dose',
        type: TypeProduit.otc,
        rayon: 'A3', tiroir: '1', colonne: 'B',
        quantiteReelle: 15, seuilCritique: 12,
        prixAchatHt: 2.80, prixVenteTtc: 4.00,
        datePeremption: now.add(const Duration(days: 250)),
      ),
      Produit(
        id: _uuid.v4(),
        codeCip: '3400930000174',
        designation: 'Forlax 10g, 20 sachets',
        type: TypeProduit.otc,
        rayon: 'A3', tiroir: '2', colonne: 'A',
        quantiteReelle: 3, seuilCritique: 10,
        prixAchatHt: 3.10, prixVenteTtc: 4.40,
        datePeremption: now.add(const Duration(days: 200)),
      ),
      Produit(
        id: _uuid.v4(),
        codeCip: '3400930000198',
        designation: 'Lévothyrox 75µg, 28 comprimés',
        type: TypeProduit.ordonnance,
        rayon: 'B3', tiroir: '1', colonne: 'A',
        quantiteReelle: 20, seuilCritique: 15,
        prixAchatHt: 2.00, prixVenteTtc: 2.90,
        datePeremption: now.add(const Duration(days: 450)),
      ),
    ];
  }

  /// Scénario de facture grossiste n°1 — Grossiste A, sans écart (conforme).
  static ({String fournisseur, String numero, DateTime date, List<({String cip, String designation, int quantite, double prixUnitaire})> lignes})
      scenarioFactureConforme() {
    return (
      fournisseur: 'Grossiste A',
      numero: 'GA-DEMO-0001',
      date: DateTime.now().subtract(const Duration(days: 1)),
      lignes: [
        (cip: '3400930000013', designation: 'Doliprane 1000mg, 8 comprimés', quantite: 20, prixUnitaire: 1.90),
        (cip: '3400930000136', designation: 'Nurofen 400mg, 12 comprimés enrobés', quantite: 15, prixUnitaire: 2.00),
        (cip: '3400930000099', designation: 'Spasfon Lyoc 80mg, 10 lyophilisats', quantite: 10, prixUnitaire: 2.50),
      ],
    );
  }

  /// Scénario de facture grossiste n°2 — Grossiste B, AVEC écarts
  /// volontaires (boîtes manquantes + un produit non reconnu) afin de
  /// démontrer le moteur de rapprochement Match & Check.
  static ({String fournisseur, String numero, DateTime date, List<({String cip, String designation, int quantite, double prixUnitaire})> lignes})
      scenarioFactureAvecEcarts() {
    return (
      fournisseur: 'Grossiste B',
      numero: 'GB-DEMO-0002',
      date: DateTime.now(),
      lignes: [
        // Conforme
        (cip: '3400930000198', designation: 'Lévothyrox 75µg, 28 comprimés', quantite: 10, prixUnitaire: 2.00),
        // Manquant : facturé 10, mais seulement 8 seront scannés à la réception
        (cip: '3400930000037', designation: 'Amoxicilline Biogaran 500mg, 12 gélules', quantite: 10, prixUnitaire: 2.00),
        // Manquant fort : facturé 12, seulement 4 reçus
        (cip: '3400930000174', designation: 'Forlax 10g, 20 sachets', quantite: 12, prixUnitaire: 3.10),
        // Produit non reconnu (erreur fournisseur / CIP non référencé)
        (cip: '3400930009999', designation: 'Produit Référence Inconnue X', quantite: 5, prixUnitaire: 3.90),
      ],
    );
  }

  /// Simule les quantités réellement scannées au déballage du carton pour
  /// le scénario "avec écarts" (volontairement différentes du facturé).
  static Map<String, int> quantitesScanneesScenarioEcarts() {
    return {
      '3400930000198': 10, // conforme
      '3400930000037': 8,  // 2 manquantes
      '3400930000174': 4,  // 8 manquantes
      // '3400930009999' absent du référentiel -> non scanné
    };
  }

  static Map<String, int> quantitesScanneesScenarioConforme() {
    return {
      '3400930000013': 20,
      '3400930000136': 15,
      '3400930000099': 10,
    };
  }
}
