import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../data/mock/mock_data_service.dart';
import '../../data/models/audit_models.dart';
import '../../data/models/facture_model.dart';
import '../../data/models/produit_model.dart';
import '../../domain/services/auth_service.dart';
import '../../domain/services/ocr_service.dart';
import '../../domain/services/reconciliation_service.dart';

/// Etat central de l'application — orchestre stock, factures et logs
/// d'audit. Dans une version connectée, ce provider délèguerait la
/// persistance aux repositories (cf. data/repositories), eux-mêmes
/// adossés à DatabaseHelper + CryptoHelper. Pour ce PoC, l'état est
/// maintenu en mémoire et pré-rempli avec MockDataService afin de
/// garantir un fonctionnement à 100% dès le premier lancement.
class AppStateProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  final OcrService _ocrService = OcrService();
  final ReconciliationService _reconciliationService = ReconciliationService();

  final List<Produit> _produits = [];
  final List<Facture> _factures = [];
  final List<LogAudit> _logsAudit = [];

  bool _ocrEnCours = false;

  List<Produit> get produits => List.unmodifiable(_produits);
  List<Facture> get factures => List.unmodifiable(_factures);
  List<LogAudit> get logsAudit => List.unmodifiable(_logsAudit);
  bool get ocrEnCours => _ocrEnCours;

  AppStateProvider() {
    _initialiserDonneesMock();
  }

  void _initialiserDonneesMock() {
    _produits.addAll(MockDataService.genererProduits());

    // Pré-charge une facture déjà validée (historique) et une en attente
    // pour peupler le dashboard dès l'ouverture.
    final scenarioOk = MockDataService.scenarioFactureConforme();
    final factureHistorique = Facture(
      id: _uuid.v4(),
      numeroFacture: scenarioOk.numero,
      fournisseurNom: scenarioOk.fournisseur,
      dateFacture: scenarioOk.date,
      statut: StatutFacture.validee,
      montantTotalHt: scenarioOk.lignes
          .fold(0.0, (sum, l) => sum + l.quantite * l.prixUnitaire),
    );
    _factures.add(factureHistorique);

    _journaliser(
      action: 'INITIALISATION_DEMO',
      entiteCible: 'systeme',
      details: 'Chargement du jeu de données de démonstration',
    );
  }

  // ---------------------------------------------------------------
  // AUDIT
  // ---------------------------------------------------------------
  void _journaliser({
    required String action,
    required String entiteCible,
    String? entiteId,
    String? details,
  }) {
    final acteur = AuthService.instance.utilisateurCourant;
    _logsAudit.insert(
      0,
      LogAudit(
        id: _uuid.v4(),
        utilisateurId: acteur?.id,
        roleActeur: acteur?.role.label ?? 'SYSTEME',
        action: action,
        entiteCible: entiteCible,
        entiteId: entiteId,
        details: details,
      ),
    );
  }

  // ---------------------------------------------------------------
  // KPIs DASHBOARD
  // ---------------------------------------------------------------
  double get valeurTotaleStock =>
      _produits.fold(0.0, (sum, p) => sum + p.valeurStockAchat);

  int get nombreFacturesEnAttente =>
      _factures.where((f) => f.statut == StatutFacture.enAttente).length;

  int get nombreFacturesValidees =>
      _factures.where((f) => f.statut == StatutFacture.validee).length;

  int get nombreFacturesLitige =>
      _factures.where((f) => f.statut == StatutFacture.litige).length;

  List<Produit> get produitsEnAlerteRouge =>
      _produits.where((p) => p.niveauAlerte == NiveauAlerte.rouge).toList();

  List<Produit> get produitsEnAlerteOrange =>
      _produits.where((p) => p.niveauAlerte == NiveauAlerte.orange).toList();

  /// Top références par valeur de stock (proxy simple de "taux de
  /// rotation" pour ce PoC — une version connectée API calculerait la
  /// rotation réelle à partir de l'historique des mouvements de sortie).
  List<Produit> get topReferences {
    final liste = List<Produit>.from(_produits)
      ..sort((a, b) => b.valeurStockAchat.compareTo(a.valeurStockAchat));
    return liste.take(5).toList();
  }

  // ---------------------------------------------------------------
  // RECEPTION FACTURE — OCR + RAPPROCHEMENT
  // ---------------------------------------------------------------

  /// Lance la simulation OCR sur un des deux scénarios de démonstration,
  /// puis effectue immédiatement le rapprochement avec les scans de
  /// réception simulés, et journalise chaque étape.
  Future<Facture> traiterReceptionFacture({required bool avecEcarts}) async {
    _ocrEnCours = true;
    notifyListeners();

    final scenario = avecEcarts
        ? MockDataService.scenarioFactureAvecEcarts()
        : MockDataService.scenarioFactureConforme();
    final quantitesScannees = avecEcarts
        ? MockDataService.quantitesScanneesScenarioEcarts()
        : MockDataService.quantitesScanneesScenarioConforme();

    final resultatOcr = await _ocrService.analyserDocument(
      fournisseur: scenario.fournisseur,
      numeroFacture: scenario.numero,
      dateFacture: scenario.date,
      lignesSources: scenario.lignes,
    );

    final factureId = _uuid.v4();
    final lignes = resultatOcr.lignesExtraites
        .map((l) => LigneFacture(
              id: l.id,
              factureId: factureId,
              codeCipExtrait: l.codeCipExtrait,
              designationExtraite: l.designationExtraite,
              quantiteFacturee: l.quantiteFacturee,
              prixUnitaireHt: l.prixUnitaireHt,
            ))
        .toList();

    _journaliser(
      action: 'SCAN_FACTURE_OCR',
      entiteCible: 'factures',
      entiteId: factureId,
      details:
          'Lecture OCR ${resultatOcr.numeroFacture} (${resultatOcr.fournisseurDetecte}) — confiance ${(resultatOcr.confianceGlobale * 100).toStringAsFixed(1)}%',
    );

    final referentielParCip = {for (final p in _produits) p.codeCip: p};

    final resultatsRapprochement = _reconciliationService.rapprocher(
      lignesFacture: lignes,
      referentielParCip: referentielParCip,
      quantitesScanneesParCip: quantitesScannees,
    );

    final statutGlobal = _reconciliationService.statutGlobal(resultatsRapprochement);

    final montantTotal = lignes.fold(0.0, (sum, l) => sum + l.quantiteFacturee * l.prixUnitaireHt);

    final facture = Facture(
      id: factureId,
      numeroFacture: resultatOcr.numeroFacture,
      fournisseurNom: resultatOcr.fournisseurDetecte,
      dateFacture: resultatOcr.dateFacture,
      statut: statutGlobal,
      montantTotalHt: montantTotal,
      lignes: lignes,
    );

    _factures.insert(0, facture);

    // Met à jour le stock réel pour les lignes conformes (réception OK),
    // et journalise chaque mouvement individuellement.
    for (final r in resultatsRapprochement) {
      if (r.produitCorrespondant != null && r.ligne.quantiteRecueScan > 0) {
        final index = _produits.indexWhere((p) => p.id == r.produitCorrespondant!.id);
        if (index != -1) {
          _produits[index] = _produits[index]
              .copyWith(quantiteReelle: _produits[index].quantiteReelle + r.ligne.quantiteRecueScan);
        }
        _journaliser(
          action: 'SCAN_RECEPTION_PRODUIT',
          entiteCible: 'produits',
          entiteId: r.produitCorrespondant!.id,
          details:
              '${r.ligne.quantiteRecueScan} unité(s) de "${r.produitCorrespondant!.designation}" réceptionnée(s) — ${r.conforme ? "conforme" : "écart détecté"}',
        );
      }
    }

    _journaliser(
      action: statutGlobal == StatutFacture.litige ? 'FACTURE_MISE_EN_LITIGE' : 'FACTURE_VALIDEE_AUTO',
      entiteCible: 'factures',
      entiteId: factureId,
      details: 'Statut final: ${statutGlobal.label} — ${facture.nombreEcarts} écart(s) détecté(s)',
    );

    _ocrEnCours = false;
    notifyListeners();
    return facture;
  }

  /// Validation manuelle d'une facture en litige par un rôle habilité
  /// (Titulaire/Préparateur) — démonstration du contrôle RBAC.
  bool validerFactureManuellement(String factureId) {
    final role = AuthService.instance.utilisateurCourant?.role;
    if (role == null || !role.peutValiderFactures) {
      _journaliser(
        action: 'TENTATIVE_VALIDATION_REFUSEE',
        entiteCible: 'factures',
        entiteId: factureId,
        details: 'Accès refusé — rôle insuffisant (${role?.label ?? "non connecté"})',
      );
      return false;
    }
    final index = _factures.indexWhere((f) => f.id == factureId);
    if (index == -1) return false;
    _factures[index].statut = StatutFacture.validee;
    _journaliser(
      action: 'VALIDATION_MANUELLE_LITIGE',
      entiteCible: 'factures',
      entiteId: factureId,
      details: 'Litige levé manuellement après vérification physique',
    );
    notifyListeners();
    return true;
  }
}
