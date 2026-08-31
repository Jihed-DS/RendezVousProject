import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/categorie.dart';
import '../providers/auth_provider.dart';
import '../services/prestataire_service.dart';
class CreatePrestataireProfileScreen extends StatefulWidget {
  final VoidCallback onCreated;

  const CreatePrestataireProfileScreen({super.key, required this.onCreated});

  @override
  State<CreatePrestataireProfileScreen> createState() => _CreatePrestataireProfileScreenState();
}

class _CreatePrestataireProfileScreenState extends State<CreatePrestataireProfileScreen> {
  final _service = PrestataireService();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();

  List<Categorie> _categories = [];
  String? _selectedCategorieId;
  bool _isLoadingCategories = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final result = await _service.getCategories();
      setState(() {
        _categories = result;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Impossible de charger les catégories.';
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedCategorieId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisis une catégorie.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final token = context.read<AuthProvider>().token!;
      await _service.createProfile(
        token: token,
        categorieId: _selectedCategorieId!,
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      );
      widget.onCreated();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Complète ton profil',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choisis ta catégorie principale pour que les clients puissent te trouver.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),

          if (_isLoadingCategories)
            const Center(child: CircularProgressIndicator())
          else ...[
            DropdownButtonFormField<String>(
              initialValue: _selectedCategorieId,
              decoration: const InputDecoration(
                labelText: 'Catégorie',
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedCategorieId = value),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Bio (optionnel)',
                hintText: 'Présente-toi en quelques mots...',
                border: OutlineInputBorder(),
              ),
            ),
                const SizedBox(height: 16),
                TextField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'Ville (optionnel)',
                    hintText: 'Ex: Tunis',
                    border: OutlineInputBorder(),
                  ),
                ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                height: 20, width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Text('Créer mon profil'),
            ),
          ],
        ],
      ),
    );
  }
}