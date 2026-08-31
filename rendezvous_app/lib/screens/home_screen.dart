import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'prestataire_list_screen.dart';
import 'my_creneaux_screen.dart';
import 'my_rendezvous_screen.dart';
import 'my_avis_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_clients_screen.dart';
import 'create_prestataire_profile_screen.dart';
import 'profile_tab.dart';
import '../models/prestataire.dart';
import '../services/prestataire_service.dart';
import 'admin_dashboard_screen.dart';
import '../screens/admin_users_screen.dart';
import '../screens/admin_approvals_screen.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _prestataireService = PrestataireService();

  bool _isPrestataire = false;
  bool _isCheckingProfile = true;
  Prestataire? _myProfile;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkPrestataireProfile();
  }

  Future<void> _checkPrestataireProfile() async {
    final user = context.read<AuthProvider>().user;
    _isPrestataire = user?.role == 'Prestataire';

    if (!_isPrestataire) {
      setState(() => _isCheckingProfile = false);
      return;
    }

    try {
      final token = context.read<AuthProvider>().token!;
      final profile = await _prestataireService.getMyProfile(token);
      if (mounted) {
        setState(() {
          _myProfile = profile;
          _isCheckingProfile = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur _checkPrestataireProfile: $e');
      if (mounted) setState(() => _isCheckingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final role = user?.role;

    if (_isPrestataire && _isCheckingProfile) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isPrestataire && _myProfile == null) {
      return Scaffold(
        body: CreatePrestataireProfileScreen(
          onCreated: () {
            setState(() => _isCheckingProfile = true);
            _checkPrestataireProfile();
          },
        ),
      );
    }

    final tabs = _tabsForRole(role);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: tabs.map((t) => t.screen).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: tabs
            .map((t) => NavigationDestination(icon: Icon(t.icon), label: t.label))
            .toList(),
      ),
    );
  }

  List<_TabItem> _tabsForRole(String? role) {
    switch (role) {
      case 'Client':
        return const [
          _TabItem(icon: Icons.search, label: 'Découvrir', screen: PrestataireListScreen()),
          _TabItem(icon: Icons.event_note, label: 'Rendez-vous', screen: MyRendezVousScreen()),
          _TabItem(icon: Icons.person_outline, label: 'Profil', screen: ProfileTab()),
        ];
      case 'Prestataire':
        return const [
          _TabItem(icon: Icons.calendar_month, label: 'Créneaux', screen: MyCreneauxScreen()),
          _TabItem(icon: Icons.event_note, label: 'Rendez-vous', screen: MyRendezVousScreen()),
          _TabItem(icon: Icons.star_outline, label: 'Avis', screen: MyAvisScreen()),
          _TabItem(icon: Icons.person_outline, label: 'Profil', screen: ProfileTab()),
        ];
      case 'Admin':
        return const [
          _TabItem(icon: Icons.home_outlined, label: 'Accueil', screen: AdminDashboardScreen()),
          _TabItem(icon: Icons.category_outlined, label: 'Catégories', screen: AdminCategoriesScreen()),
              _TabItem(icon: Icons.people_outline, label: 'Users', screen: AdminUsersScreen()),
              _TabItem(icon: Icons.how_to_reg_outlined, label: 'Validations', screen: AdminApprovalsScreen()),
          _TabItem(icon: Icons.person_outline, label: 'Profil', screen: ProfileTab()),
        ];
      default:
        return const [
          _TabItem(icon: Icons.person_outline, label: 'Profil', screen: ProfileTab()),
        ];
    }
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  final Widget screen;

  const _TabItem({required this.icon, required this.label, required this.screen});
}