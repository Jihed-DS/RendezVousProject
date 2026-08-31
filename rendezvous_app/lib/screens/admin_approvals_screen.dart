import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../providers/auth_provider.dart';

class AdminApprovalsScreen extends StatefulWidget {
  const AdminApprovalsScreen({super.key});

  @override
  State<AdminApprovalsScreen> createState() => _AdminApprovalsScreenState();
}

class _AdminApprovalsScreenState extends State<AdminApprovalsScreen> {
  List<dynamic> _pending = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final token = context.read<AuthProvider>().token!;
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/User/pending'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      setState(() {
        _pending = jsonDecode(response.body) as List<dynamic>;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _act(String id, bool approve) async {
    final token = context.read<AuthProvider>().token!;
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/User/$id/${approve ? "approve" : "reject"}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comptes à valider')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _pending.isEmpty
            ? ListView(children: const [
          SizedBox(height: 100),
          Center(child: Text('Aucun compte en attente.')),
        ])
            : ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _pending.length,
          itemBuilder: (context, index) {
            final u = _pending[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u['fullName'] ?? u['email'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${u['email']} • ${u['role']}'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _act(u['id'], false),
                            child: const Text('Refuser'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _act(u['id'], true),
                            child: const Text('Approuver'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}