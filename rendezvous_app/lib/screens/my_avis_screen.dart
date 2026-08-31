import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/avis.dart';
import '../providers/auth_provider.dart';
import '../services/avis_service.dart';

class MyAvisScreen extends StatefulWidget {
  const MyAvisScreen({super.key});

  @override
  State<MyAvisScreen> createState() => _MyAvisScreenState();
}

class _MyAvisScreenState extends State<MyAvisScreen> {
  final _service = AvisService();
  final _dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');

  List<Avis> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final token = context.read<AuthProvider>().token!;
      final result = await _service.getMyReviews(token);
      setState(() {
        _items = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Impossible de charger tes avis.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes avis')),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Center(child: Text(_error!)),
          Center(child: TextButton(onPressed: _load, child: const Text('Réessayer'))),
        ],
      );
    }

    if (_items.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 100),
          Center(child: Text('Aucun avis reçu pour le moment.')),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final avis = _items[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        avis.clientName ?? 'Client',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < avis.rating ? Icons.star : Icons.star_border,
                          size: 18,
                          color: Colors.amber,
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(_dateFormat.format(avis.createdAt.toLocal()),
                    style: const TextStyle(fontSize: 12, color: Colors.black45)),
                if (avis.comment != null && avis.comment!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(avis.comment!),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}