import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // 10.0.2.2 = alias de "localhost de la machine hôte" vu depuis l'émulateur Android.
  // Sur iOS simulator, "localhost" fonctionne directement.
  // Sur appareil physique, remplace par l'IP locale de ta machine (ex: 192.168.1.X).
  static String get baseUrl {
    if (kIsWeb) return 'https://localhost:7170/api';
    if (Platform.isAndroid) return 'https://192.168.68.105:7170/api';
    return 'https://localhost:7170/api';
  }

    // Même hôte que baseUrl, mais sans le segment /api — pour construire
    // les URLs des fichiers uploadés (photos, etc.)
    static String get mediaBaseUrl {
        if (kIsWeb) return 'https://localhost:7170';
        if (Platform.isAndroid) return 'https://192.168.68.105:7170';
        return 'https://localhost:7170';
      }

    static String resolvePhotoUrl(String? photoUrl) {
        if (photoUrl == null || photoUrl.isEmpty) return '';
        if (photoUrl.startsWith('http')) return photoUrl;
        return '$mediaBaseUrl$photoUrl';
      }
}

// Autorise le certificat auto-signé de dotnet dev-certs — UNIQUEMENT en debug.
// Ne jamais activer ça en release (ça désactiverait toute vérification TLS).
class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}