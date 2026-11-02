import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/facture_model.dart';
import '../providers/app_state_provider.dart';
import '../widgets/kpi_card.dart';
import '../widgets/produit_alerte_tile.dart';
import 'reception_facture_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard — Back-office'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Pharmacie Démo',
                style: TextStyle(color: AppColors.texteSecondaire, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // --- LIGNE DE KPIs PRINCIPAUX ---
            LayoutBuilder(builder: (context, constraints) {
              final largeur = constraints.maxWidth;
              final colonnes = largeur > 900 ? 4 : (largeur > 600 ? 2 : 1);
              return GridView.count(
                crossAxisCount: colonnes,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.5,
                children: [
                  KpiCard(
                    titre: 'Valeur totale du stock (PA)',
                    valeur: currencyFormat.format(state.valeurTotaleStock),
                    icone: Icons.inventory_2_outlined,
                    couleurAccent: AppColors.primaire,
                  ),
                  KpiCard(
                    titre: 'Factures en attente',
                    valeur: '${state.nombreFacturesEnAttente}',
                    icone: Icons.hourglass_top_rounded,
                    couleurAccent: AppColors.alerteOrange,
                  ),
                  KpiCard(
                    titre: 'Factures validées',
                    valeur: '${state.nombreFacturesValidees}',
                    icone: Icons.verified_outlined,
                    couleurAccent: AppColors.alerteVert,
                  ),
                  KpiCard(
                    titre: 'Factures en litige',
                    valeur: '${state.nombreFacturesLitige}',
                    icone: Icons.report_gmailerrorred_outlined,
                    couleurAccent: AppColors.alerteRouge,
                    sousTitre: state.nombreFacturesLitige > 0 ? 'Action requise' : null,
                  ),
                ],
              );
            }),

            const SizedBox(height: 28),

            // --- BOUTON D'ACCES RAPIDE AU MODULE RECEPTION ---
            Card(
              color: AppColors.primaireFonce,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReceptionFactureScreen()),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(Icons.document_scanner_outlined, color: Colors.white, size: 28),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Réception & lecture automatique de factures',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                            SizedBox(height: 2),
                            Text('Scanner un BL grossiste et lancer le rapprochement OCR',
                                style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // --- GRAPHIQUE + ALERTES ---
            LayoutBuilder(builder: (context, constraints) {
              final estLarge = constraints.maxWidth > 900;
              final graphique = _CarteRepartitionStock(state: state);
              final alertes = _CarteAlertes(state: state);
              if (estLarge) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 5, child: graphique),
                      const SizedBox(width: 16),
                      Expanded(flex: 4, child: alertes),
                    ],
                  ),
                );
              }
              return Column(children: [graphique, const SizedBox(height: 16), alertes]);
            }),

            const SizedBox(height: 28),
            const _SectionTitre('Dernières factures traitées'),
            const SizedBox(height: 12),
            ...state.factures.take(5).map((f) => _FactureLigneCard(facture: f)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitre extends StatelessWidget {
  final String texte;
  const _SectionTitre(this.texte);

  @override
  Widget build(BuildContext context) {
    return Text(texte,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.texte));
  }
}

/// Top références (proxy "taux de rotation") sous forme de barres.
class _CarteRepartitionStock extends StatelessWidget {
  final AppStateProvider state;
  const _CarteRepartitionStock({required this.state});

  @override
  Widget build(BuildContext context) {
    final top = state.topReferences;
    final maxValeur = top.isEmpty
        ? 1.0
        : top.map((p) => p.valeurStockAchat).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitre('Top références (valeur de stock)'),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: maxValeur * 1.2,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= top.length) return const SizedBox.shrink();
                          final nom = top[i].designation.split(',').first;
                          final court = nom.length > 10 ? '${nom.substring(0, 10)}…' : nom;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(court, style: const TextStyle(fontSize: 10, color: AppColors.texteSecondaire)),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (int i = 0; i < top.length; i++)
                      BarChartGroupData(x: i, barRods: [
                        BarChartRodData(
                          toY: top[i].valeurStockAchat,
                          color: AppColors.primaire,
                          width: 28,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarteAlertes extends StatelessWidget {
  final AppStateProvider state;
  const _CarteAlertes({required this.state});

  @override
  Widget build(BuildContext context) {
    final alertes = [...state.produitsEnAlerteRouge, ...state.produitsEnAlerteOrange];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: _SectionTitre('Alertes stock')),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.alerteRouge.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${alertes.length}',
                      style: const TextStyle(color: AppColors.alerteRouge, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (alertes.isEmpty)
              const Text('Aucune alerte active.', style: TextStyle(color: AppColors.texteSecondaire))
            else
              ...alertes.take(6).map((p) => ProduitAlerteTile(produit: p)),
          ],
        ),
      ),
    );
  }
}

class _FactureLigneCard extends StatelessWidget {
  final Facture facture;
  const _FactureLigneCard({required this.facture});

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
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: _couleurStatut.withValues(alpha: 0.12),
          child: Icon(Icons.receipt_long_outlined, color: _couleurStatut, size: 20),
        ),
        title: Text('${facture.numeroFacture} — ${facture.fournisseurNom}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text('${dateFormat.format(facture.dateFacture)} • ${facture.lignes.length} ligne(s)'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _couleurStatut.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(facture.statut.label,
              style: TextStyle(color: _couleurStatut, fontWeight: FontWeight.w700, fontSize: 12)),
        ),
      ),
    );
  }
}
