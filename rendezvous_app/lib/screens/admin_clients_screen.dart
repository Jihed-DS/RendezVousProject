import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/client_admin.dart';
import '../providers/auth_provider.dart';
import '../services/admin_client_service.dart';

class AdminClientsScreen extends StatefulWidget {
  const AdminClientsScreen({super.key});

  @override
  State<AdminClientsScreen> createState() => _AdminClientsScreenState();
}

class _AdminClientsScreenState extends State<AdminClientsScreen> {
  final _service = AdminClientService();
  List<ClientAdminItem> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final token = context.read<AuthProvider>().token!;
      final result = await _service.getAll(token);
      setState(() { _items = result; _isLoading = false; });
    } catch (e) {
      setState(() { _error = 'Impossible de charger les clients.'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return ListView(children: [
        const SizedBox(height: 100),
        Center(child: Text(_error!)),
        Center(child: TextButton(onPressed: _load, child: const Text('Réessayer'))),
      ]);
    }
    if (_items.isEmpty) {
          return ListView(children: [
            const SizedBox(height: 100),
        Center(child: Text('Aucun client pour le moment.')),
      ]);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final c = _items[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(c.fullName ?? 'Client'),
            subtitle: Text([
              if (c.email != null) c.email!,
              if (c.phone != null) c.phone!,
              if (c.address != null) c.address!,
            ].join(' • ')),
                          trailing: Text(
                        '${c.rendezVousCount} RDV',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: c.rendezVousCount > 0 ? Colors.indigo : Colors.grey,
                            ),
                        ),
          ),
        );
      },
    );
  }
}