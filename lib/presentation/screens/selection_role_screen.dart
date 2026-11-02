import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/services/auth_service.dart';
import 'dashboard_screen.dart';

class SelectionRoleScreen extends StatelessWidget {
  const SelectionRoleScreen({super.key});

  IconData _icone(RoleUtilisateur role) {
    switch (role) {
      case RoleUtilisateur.titulaire:
        return Icons.medical_services_outlined;
      case RoleUtilisateur.preparateur:
        return Icons.science_outlined;
      case RoleUtilisateur.stagiaire:
        return Icons.school_outlined;
    }
  }

  String _description(RoleUtilisateur role) {
    switch (role) {
      case RoleUtilisateur.titulaire:
        return 'Accès complet, y compris montants financiers et validation des litiges';
      case RoleUtilisateur.preparateur:
        return 'Accès au stock, réception et validation des litiges';
      case RoleUtilisateur.stagiaire:
        return 'Accès en lecture/scan — validation des litiges restreinte';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaire.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.local_pharmacy_outlined, color: AppColors.primaire, size: 30),
                  ),
                  const SizedBox(height: 18),
                  const Text('Pharmacie Démo',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.texte)),
                  const SizedBox(height: 4),
                  const Text('Back-office — sélection du profil de connexion (RBAC)',
                      style: TextStyle(color: AppColors.texteSecondaire)),
                  const SizedBox(height: 28),
                  ...AuthService.comptesDemo.map((utilisateur) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaire.withValues(alpha: 0.1),
                          child: Icon(_icone(utilisateur.role), color: AppColors.primaire),
                        ),
                        title: Text(utilisateur.nomAffiche, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(_description(utilisateur.role), style: const TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        onTap: () {
                          AuthService.instance.connecter(utilisateur);
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const DashboardScreen()),
                          );
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
