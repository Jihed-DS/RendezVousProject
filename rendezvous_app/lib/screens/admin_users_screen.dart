import 'package:flutter/material.dart';
import 'admin_clients_screen.dart';
import 'prestataire_list_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _showClients = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Prestataires')),
                ButtonSegment(value: true, label: Text('Clients')),
              ],
              selected: {_showClients},
              onSelectionChanged: (s) => setState(() => _showClients = s.first),
            ),
          ),
        ),
      ),
      body: _showClients ? const AdminClientsScreen() : const PrestataireListScreen(),
    );
  }
}