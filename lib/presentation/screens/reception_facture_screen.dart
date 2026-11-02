import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/facture_model.dart';
import '../providers/app_state_provider.dart';

class ReceptionFactureScreen extends StatefulWidget {
  const ReceptionFactureScreen({super.key});

  @override
  State<ReceptionFactureScreen> createState() => _ReceptionFactureScreenState();
}

class _ReceptionFactureScreenState extends State<ReceptionFactureScreen> {
  Facture? _factureTraitee;

  Future<void> _lancerScan({required bool avecEcarts}) async {
    final state = context.read<AppStateProvider>();
    final facture = await state.traiterReceptionFacture(avecEcarts: avecEcarts);
    if (!mounted) return;
    setState(() => _factureTraitee = facture);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Réception & lecture automatique')),
      body: state.ocrEnCours
          ? const _ChargementOcr()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const _ZoneDepotDocument(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _lancerScan(avecEcarts: false),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Simuler scan — BL conforme'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: AppColors.alerteVert,
                          side: const BorderSide(color: AppColors.alerteVert),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _lancerScan(avecEcarts: true),
                        icon: const Icon(Icons.warning_amber_rounded),
                        label: const Text('Simuler scan — avec écarts'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.alerteOrange),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                if (_factureTraitee != null) _ResultatRapprochement(facture: _factureTraitee!),
              ],
            ),
    );
  }
}

class _ChargementOcr extends StatelessWidget {
  const _ChargementOcr();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primaire),
          const SizedBox(height: 20),
          const Text('Analyse OCR du document en cours…',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.texte)),
          const SizedBox(height: 6),
          Text('Extraction des lignes produit et rapprochement avec les scans réception',
              style: TextStyle(color: AppColors.texteSecondaire, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ZoneDepotDocument extends StatelessWidget {
  const _ZoneDepotDocument();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: AppColors.carte,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.bordure, width: 1.4),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaire.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.document_scanner_outlined, size: 32, color: AppColors.primaire),
          ),
          const SizedBox(height: 14),
          const Text('Déposez ou photographiez une facture / BL',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.texte)),
          const SizedBox(height: 4),
          Text('Formats supportés : PDF, JPG, PNG — Grossistes : A, B, C',
              style: TextStyle(color: AppColors.texteSecondaire, fontSize: 12)),
          const SizedBox(height: 16),
          Text('— PoC : utilisez les boutons ci-dessous pour simuler un scan —',
              style: TextStyle(color: AppColors.texteSecondaire, fontSize: 11, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}

class _ResultatRapprochement extends StatelessWidget {
  final Facture facture;
  const _ResultatRapprochement({required this.facture});

  Color get _couleurStatut {
    switch (facture.statut) {
      case StatutFacture.validee:
        return AppColors.alerteVert;
      case StatutFacture.litige:
        return AppColors.alerteRouge;
      case StatutFacture.enAttente:
        return AppColors.alerteOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _couleurStatut.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        facture.statut == StatutFacture.litige
                            ? Icons.report_gmailerrorred_outlined
                            : Icons.task_alt_outlined,
                        color: _couleurStatut,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${facture.numeroFacture} — ${facture.fournisseurNom}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          Text(dateFormat.format(facture.dateReceptionScan),
                              style: const TextStyle(color: AppColors.texteSecondaire, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _couleurStatut.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(facture.statut.label,
                          style: TextStyle(color: _couleurStatut, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const Divider(height: 32),
                Row(
                  children: [
                    _StatChip(label: 'Lignes extraites', valeur: '${facture.lignes.length}'),
                    const SizedBox(width: 10),
                    _StatChip(
                      label: 'Écarts détectés',
                      valeur: '${facture.nombreEcarts}',
                      couleur: facture.nombreEcarts > 0 ? AppColors.alerteRouge : AppColors.alerteVert,
                    ),
                    const SizedBox(width: 10),
                    _StatChip(label: 'Montant HT', valeur: currencyFormat.format(facture.montantTotalHt)),
                  ],
                ),
                if (facture.statut == StatutFacture.litige) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final ok = context.read<AppStateProvider>().validerFactureManuellement(facture.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok
                                ? 'Litige levé manuellement.'
                                : 'Accès refusé : rôle insuffisant pour valider une facture en litige.'),
                            backgroundColor: ok ? AppColors.alerteVert : AppColors.alerteRouge,
                          ),
                        );
                      },
                      icon: const Icon(Icons.gavel_outlined),
                      label: const Text('Lever le litige manuellement (Titulaire/Préparateur)'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Détail du rapprochement (Match & Check)',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.texte)),
        const SizedBox(height: 12),
        ...facture.lignes.map((ligne) => _LigneRapprochementTile(ligne: ligne)),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String valeur;
  final Color couleur;
  const _StatChip({required this.label, required this.valeur, this.couleur = AppColors.primaire});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: couleur.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(valeur, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: couleur)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.texteSecondaire)),
          ],
        ),
      ),
    );
  }
}

class _LigneRapprochementTile extends StatelessWidget {
  final LigneFacture ligne;
  const _LigneRapprochementTile({required this.ligne});

  bool get _conforme => ligne.statutLigne == StatutLigne.conforme;
  bool get _produitInconnu => ligne.produitId == null;

  Color get _couleur {
    if (_produitInconnu) return AppColors.alerteRouge;
    return _conforme ? AppColors.alerteVert : AppColors.alerteRouge;
  }

  String get _messageEcart {
    if (_produitInconnu) {
      return 'Produit non reconnu — CIP ${ligne.codeCipExtrait} absent du référentiel';
    }
    if (_conforme) return 'Quantité conforme à la réception';
    final ecart = ligne.ecart;
    return ecart < 0
        ? '${-ecart} boîte(s) manquante(s) à la réception'
        : '${ecart} boîte(s) en surplus à la réception';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              _conforme && !_produitInconnu ? Icons.check_circle : Icons.error_outline,
              color: _couleur,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ligne.designationExtraite,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  const SizedBox(height: 2),
                  Text('CIP ${ligne.codeCipExtrait}',
                      style: const TextStyle(fontSize: 11, color: AppColors.texteSecondaire)),
                  const SizedBox(height: 4),
                  Text(_messageEcart, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _couleur)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Facturé: ${ligne.quantiteFacturee}',
                    style: const TextStyle(fontSize: 12, color: AppColors.texteSecondaire)),
                Text('Reçu: ${ligne.quantiteRecueScan}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _couleur)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
