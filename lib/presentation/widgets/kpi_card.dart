import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class KpiCard extends StatelessWidget {
  final String titre;
  final String valeur;
  final IconData icone;
  final Color couleurAccent;
  final String? sousTitre;

  const KpiCard({
    super.key,
    required this.titre,
    required this.valeur,
    required this.icone,
    this.couleurAccent = AppColors.primaire,
    this.sousTitre,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: couleurAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icone, color: couleurAccent, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              valeur,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.texte,
              ),
            ),
            const SizedBox(height: 4),
            Text(titre, style: const TextStyle(color: AppColors.texteSecondaire, fontSize: 13)),
            if (sousTitre != null) ...[
              const SizedBox(height: 2),
              Text(sousTitre!,
                  style: TextStyle(color: couleurAccent, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }
}
