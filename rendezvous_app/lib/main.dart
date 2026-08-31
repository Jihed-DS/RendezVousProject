import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'config/api_config.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);

  // Autorise le certificat auto-signé de l'API en dev UNIQUEMENT.
  // En release, ce bloc ne s'exécute jamais.
  if (kDebugMode) {
    HttpOverrides.global = DevHttpOverrides();
  }
  runApp(const RendezVousApp());
}

class RendezVousApp extends StatelessWidget {
  const RendezVousApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
          create: (_) => AuthProvider(),
      child: ChangeNotifierProvider(
        create: (_) => ThemeProvider()..load(),
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) => MaterialApp(
            title: 'RendezVous',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.mode,
            home: const _SplashGate(),
          ),
        ),
      ),
    );
  }
}

// Écran de démarrage : tente de restaurer la session, puis route
// vers Home ou Login selon le résultat.
class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await context.read<AuthProvider>().tryAutoLogin();
    setState(() => _checked = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isAuthenticated = context.watch<AuthProvider>().isAuthenticated;
    return isAuthenticated ? const HomeScreen() : const LoginScreen();
  }
}