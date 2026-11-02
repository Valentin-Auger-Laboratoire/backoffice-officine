import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/produit_model.dart';

class ProduitAlerteTile extends StatelessWidget {
  final Produit produit;

  const ProduitAlerteTile({super.key, required this.produit});

  Color get _couleur {
    switch (produit.niveauAlerte) {
      case NiveauAlerte.rouge:
        return AppColors.alerteRouge;
      case NiveauAlerte.orange:
        return AppColors.alerteOrange;
      case NiveauAlerte.vert:
        return AppColors.alerteVert;
    }
  }

  String get _motif {
    if (produit.quantiteReelle <= 0) return 'Rupture de stock';
    if (produit.datePeremption != null && produit.datePeremption!.isBefore(DateTime.now())) {
      return 'Produit périmé';
    }
    if (produit.datePeremption != null &&
        produit.datePeremption!.isBefore(DateTime.now().add(const Duration(days: 90)))) {
      final jours = produit.datePeremption!.difference(DateTime.now()).inDays;
      return 'Péremption dans $jours j';
    }
    return 'Seuil critique atteint (${produit.quantiteReelle}/${produit.seuilCritique})';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _couleur.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _couleur.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: _couleur, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(produit.designation,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.texte, fontSize: 13)),
                Text('${produit.emplacement} • CIP ${produit.codeCip}',
                    style: const TextStyle(fontSize: 11, color: AppColors.texteSecondaire)),
              ],
            ),
          ),
          Text(_motif, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _couleur)),
        ],
      ),
    );
  }
}
