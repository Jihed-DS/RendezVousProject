import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/creneau.dart';
import '../models/prestataire.dart';
import '../providers/auth_provider.dart';
import '../services/creneau_service.dart';
import '../services/rendezvous_service.dart';
import '../models/avis.dart';
import '../services/avis_service.dart';
import '../config/api_config.dart';
import '../theme/category_style.dart';
import '../models/avis_summary.dart';
import '../widgets/rating_distribution_bar.dart';
import '../widgets/bouncy_button.dart';
import 'dart:async';
class PrestataireDetailScreen extends StatefulWidget {
  final Prestataire prestataire;

  const PrestataireDetailScreen({super.key, required this.prestataire});

  @override
  State<PrestataireDetailScreen> createState() => _PrestataireDetailScreenState();
}

class _PrestataireDetailScreenState extends State<PrestataireDetailScreen> {
  final _creneauService = CreneauService();
  final _rendezVousService = RendezVousService();
  final _avisService = AvisService();
  final _dayFormat = DateFormat('EEE dd MMM', 'fr_FR');
  final _hourFormat = DateFormat.Hm();

  List<Creneau> _creneaux = [];
  List<Avis> _avisList = [];
  AvisSummary? _avisSummary;
  bool _isLoading = true;
  bool _isLoadingAvis = true;
  String? _error;
  bool _isBooking = false;
  Timer? _refreshTimer;
  @override
  void initState() {
    super.initState();
    _load();
    _loadAvis();
    _refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) => _load());
  }
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _creneauService.getByPrestataire(widget.prestataire.id);
      setState(() {
        _creneaux = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Impossible de charger les disponibilités.';
        _isLoading = false;
      });
    }
  }

  // Regroupe les créneaux par jour pour un affichage plus lisible.
  Map<String, List<Creneau>> get _groupedByDay {
    final Map<String, List<Creneau>> groups = {};
    for (final c in _creneaux) {
      final key = _dayFormat.format(c.startTime.toLocal());
      groups.putIfAbsent(key, () => []).add(c);
    }
    return groups;
  }
  Future<void> _loadAvis() async {
    try {
          final results = await Future.wait([
            _avisService.getByPrestataire(widget.prestataire.id),
            _avisService.getSummary(widget.prestataire.id),
          ]);
      setState(() {
                _avisList = results[0] as List<Avis>;
                _avisSummary = results[1] as AvisSummary;
        _isLoadingAvis = false;
      });
    } catch (e) {
      setState(() => _isLoadingAvis = false);
    }
  }
  Future<void> _openBookingSheet(Creneau creneau) async {
    final notesController = TextEditingController();
    final selectedTags = <String>{};

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (sheetContext, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Confirmer le rendez-vous', style: Theme.of(sheetContext).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    '${_dayFormat.format(creneau.startTime.toLocal())} • '
                        '${_hourFormat.format(creneau.startTime.toLocal())} - '
                        '${_hourFormat.format(creneau.endTime.toLocal())}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 16),

                  if (creneau.tags.isNotEmpty) ...[
                    Text('Sous-catégorie souhaitée (optionnel)',
                        style: Theme.of(sheetContext).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                                    ...creneau.tags.map((t) => FilterChip(
                                          label: Text(t),
                                          selected: selectedTags.contains(t),
                                          onSelected: (sel) => setSheetState(() {
                                            sel ? selectedTags.add(t) : selectedTags.remove(t);
                                          }),
                                        )),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optionnel)',
                      hintText: 'Précise ta demande si besoin...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
              BouncyTap(
                onTap: () => Navigator.of(sheetContext).pop(true),
                child: FilledButton(
                  onPressed: null, // le tap est géré par BouncyTap
                  child: const Text('Confirmer la réservation'),
                ),
              ),
                ],
              );
            },
          ),
        );
      },
    );

    if (confirmed != true) return;
        await _book(creneau, notesController.text.trim(), selectedTags.toList());  }

  Future<void> _book(Creneau creneau, String notes, List<String> selectedTags) async {
    setState(() => _isBooking = true);
    try {
      final token = context.read<AuthProvider>().token!;
      final combinedNotes = selectedTags != null
          ? (notes.isEmpty ? 'Sous-catégorie: $selectedTags' : '$notes\n(Sous-catégorie: $selectedTags)')
          : notes;

      await _rendezVousService.create(
        token: token,
        creneauId: creneau.id,
              notes: notes.isEmpty ? null : notes,
              selectedTags: selectedTags,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rendez-vous demandé — en attente de confirmation.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
      _load();
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.prestataire;

    return Scaffold(
      appBar: AppBar(title: Text(p.fullName ?? 'Prestataire')),
      body: Stack(
        children: [
          RefreshIndicator(
                      onRefresh: () async {
                  await _load();
                  await _loadAvis();
                },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(p),
                const SizedBox(height: 24),
                Text('Créneaux disponibles', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _buildSlots(),
                                const SizedBox(height: 28),
                                Text('Avis', style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 12),
                                _buildAvisSection(),
              ],
            ),
          ),
          if (_isBooking)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(Prestataire p) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
              child: Hero(
                tag: 'prestataire-avatar-${p.id}',
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: CategoryStyle.of(p.categorieName).color.withValues(alpha: 0.15),
                  backgroundImage: p.photoUrl != null
                      ? NetworkImage(ApiConfig.resolvePhotoUrl(p.photoUrl))
                      : null,
                  child: p.photoUrl == null
                      ? Icon(CategoryStyle.of(p.categorieName).icon, size: 30, color: CategoryStyle.of(p.categorieName).color)
                      : null,
                ),
              ),
            ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (p.categorieName != null)
                Text(p.categorieName!, style: TextStyle(color: Colors.indigo.shade400)),
              if (p.bio != null) ...[
                const SizedBox(height: 4),
                Text(p.bio!),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text('${p.ratingAvg.toStringAsFixed(1)} (${p.totalReviews} avis)'),
                ],
              ),
              if (p.subcategories.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: p.subcategories.map((s) => Chip(label: Text(s))).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildAvisSection() {
    if (_isLoadingAvis) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_avisSummary != null) ...[
              RatingDistributionBar(summary: _avisSummary!),
              const SizedBox(height: 16),
            ],
            _buildAvisList(),
          ],
        );
      }

    Widget _buildAvisList() {
    if (_avisList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('Aucun avis pour le moment.', style: TextStyle(color: Colors.black54)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _avisList.map((avis) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
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
                          size: 16,
                          color: Colors.amber,
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd/MM/yyyy', 'fr_FR').format(avis.createdAt.toLocal()),
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
                if (avis.comment != null && avis.comment!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(avis.comment!),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
  Widget _buildSlots() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Text(_error!),
            TextButton(onPressed: _load, child: const Text('Réessayer')),
          ],
        ),
      );
    }

    if (_creneaux.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('Aucun créneau disponible pour le moment.'),
      );
    }

    final grouped = _groupedByDay;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.value.map((c) {
                  return OutlinedButton(
                    onPressed: () => _openBookingSheet(c),
                    child: Text(
                      '${_hourFormat.format(c.startTime.toLocal())} - ${_hourFormat.format(c.endTime.toLocal())}',
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}