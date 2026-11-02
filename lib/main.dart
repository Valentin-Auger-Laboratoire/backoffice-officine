import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/app_state_provider.dart';
import 'presentation/screens/selection_role_screen.dart';

void main() {
  runApp(const PharmacieDemoApp());
}

class PharmacieDemoApp extends StatelessWidget {
  const PharmacieDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppStateProvider(),
      child: MaterialApp(
        title: 'Pharmacie Démo — Back-office',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const SelectionRoleScreen(),
      ),
    );
  }
}
