import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/rendez_vous.dart';
import '../providers/auth_provider.dart';
import '../services/rendezvous_service.dart';
import '../services/avis_service.dart';
import '../models/creneau.dart';
import '../services/creneau_service.dart';
class MyRendezVousScreen extends StatefulWidget {
  const MyRendezVousScreen({super.key});

  @override
  State<MyRendezVousScreen> createState() => _MyRendezVousScreenState();
}

class _MyRendezVousScreenState extends State<MyRendezVousScreen> {
  final _service = RendezVousService();
  final _dateFormat = DateFormat('EEE dd MMM, HH:mm', 'fr_FR');
  final _avisService = AvisService();
  final _creneauService = CreneauService();

  List<RendezVousItem> _items = [];
  bool _isLoading = true;
  String? _error;
  String? _actingOnId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _token => context.read<AuthProvider>().token!;
  bool get _isPrestataire => context.read<AuthProvider>().user?.role == 'Prestataire';

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _service.getMyBookings(_token);
      result.sort((a, b) =>
          (b.startTime ?? DateTime(0)).compareTo(a.startTime ?? DateTime(0)));
      setState(() {
        _items = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Impossible de charger tes rendez-vous.';
        _isLoading = false;
      });
    }
  }

  Future<void> _act(RendezVousItem item, {required bool confirm}) async {
    setState(() => _actingOnId = item.id);
    try {
      if (confirm) {
        await _service.confirm(token: _token, id: item.id);
      } else {
        await _service.deny(token: _token, id: item.id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(confirm ? 'Rendez-vous confirmé.' : 'Rendez-vous refusé.')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _actingOnId = null);
    }
  }

    Future<void> _complete(RendezVousItem item) async {
        setState(() => _actingOnId = item.id);
        try {
          await _service.complete(token: _token, id: item.id);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rendez-vous marqué comme terminé.')),
          );
          _load();
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
          );
        } finally {
          if (mounted) setState(() => _actingOnId = null);
        }
      }
  Future<void> _openReviewSheet(RendezVousItem item) async {
    int rating = 5;
    final commentController = TextEditingController();

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Laisser un avis', style: Theme.of(sheetContext).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return IconButton(
                        icon: Icon(
                          i < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () => setSheetState(() => rating = i + 1),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Commentaire (optionnel)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                    child: const Text('Envoyer'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (submitted != true) return;

    try {
      final token = _token;
      await _avisService.create(
        token: token,
        prestataireId: item.prestataireId,
        appointmentId: item.id,
        rating: rating,
        comment: commentController.text.trim().isEmpty ? null : commentController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avis envoyé, merci !')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
      _load();
    }
  }
  Future<void> _cancel(RendezVousItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Annuler ce rendez-vous ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Retour'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Annuler le RDV', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _actingOnId = item.id);
    try {
      await _service.cancel(token: _token, id: item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rendez-vous annulé.')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _actingOnId = null);
    }
  }
  Future<void> _openRescheduleSheet(RendezVousItem item) async {
    List<Creneau> options = [];
    bool isLoadingOptions = true;
    String? loadError;

    try {
      options = await _creneauService.getByPrestataire(item.prestataireId);
      isLoadingOptions = false;
    } catch (e) {
      loadError = 'Impossible de charger les créneaux disponibles.';
      isLoadingOptions = false;
    }

    if (!mounted) return;

    final selected = await showModalBottomSheet<Creneau>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Choisir une nouvelle date', style: Theme.of(sheetContext).textTheme.titleLarge),
                const SizedBox(height: 16),
                if (isLoadingOptions)
                  const Expanded(child: Center(child: CircularProgressIndicator()))
                else if (loadError != null)
                  Expanded(child: Center(child: Text(loadError)))
                else if (options.isEmpty)
                    const Expanded(child: Center(child: Text('Aucun autre créneau disponible pour le moment.')))
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: options.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final c = options[index];
                          return ListTile(
                            tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            title: Text(_dateFormat.format(c.startTime.toLocal())),
                            onTap: () => Navigator.of(sheetContext).pop(c),
                          );
                        },
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) return;

    try {
      await _service.reschedule(
        token: _token,
        rendezVousId: item.id,
        newCreneauId: selected.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rendez-vous reprogrammé — en attente de confirmation.')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes rendez-vous')),
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
        children: [
          const SizedBox(height: 100),
          Center(child: Text('Aucun rendez-vous pour le moment.')),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _buildCard(_items[index]),
    );
  }

  Widget _buildCard(RendezVousItem item) {
    final isActing = _actingOnId == item.id;
    final otherPartyName = _isPrestataire ? item.clientName : item.prestataireName;

    final isPast = item.startTime != null &&
        item.startTime!.isBefore(DateTime.now()) &&
        (item.status == 'pending' || item.status == 'confirmed');

    final now = DateTime.now();
    final isInProgress = item.status == 'confirmed' &&
        item.startTime != null && item.endTime != null &&
        now.isAfter(item.startTime!) && now.isBefore(item.endTime!);

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
                    otherPartyName ?? 'Rendez-vous',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                _StatusChip(status: isPast ? 'expired' : (isInProgress ? 'in_progress' : item.status)),
              ],
            ),
            const SizedBox(height: 4),
            Text(item.startTime != null
                ? _dateFormat.format(item.startTime!.toLocal())
                : 'Date indisponible'),
            if (item.selectedTags.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: item.selectedTags
                    .map((t) => Chip(
                  label: Text(t, style: const TextStyle(fontSize: 12)),
                  visualDensity: VisualDensity.compact,
                ))
                    .toList(),
              ),
            ],
            if (item.notes != null && item.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(item.notes!, style: const TextStyle(color: Colors.black54)),
            ],

            // --- Prestataire : Confirmer / Refuser (uniquement si pas dépassé) ---
            if (_isPrestataire && item.status == 'pending' && !isPast) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isActing ? null : () => _act(item, confirm: false),
                      child: const Text('Refuser'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: isActing ? null : () => _act(item, confirm: true),
                      child: isActing
                          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Confirmer'),
                    ),
                  ),
                ],
              ),
            ],

            // --- Prestataire : Marquer comme terminé (uniquement pendant la plage horaire) ---
            if (_isPrestataire && item.status == 'confirmed' && isInProgress) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isActing ? null : () => _complete(item),
                  icon: const Icon(Icons.check_circle_outline),
                  label: isActing
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Marquer comme terminé'),
                ),
              ),
            ],

    if (!_isPrestataire && item.status == 'pending' && !isPast) ...[
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isActing ? null : () => _cancel(item),
              icon: const Icon(Icons.close, color: Colors.red),
              label: const Text('Annuler', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isActing ? null : () => _openRescheduleSheet(item),
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('Reprogrammer'),
            ),
          ),
        ],
      ),
    ],

            // --- Client : Laisser un avis (uniquement si terminé et pas déjà noté) ---
            if (!_isPrestataire && item.status == 'completed' && !item.hasReview) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openReviewSheet(item),
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Laisser un avis'),
                ),
              ),
            ],
            if (!_isPrestataire && item.status == 'completed' && item.hasReview) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                  SizedBox(width: 6),
                  Text('Avis déjà envoyé', style: TextStyle(color: Colors.green, fontSize: 13)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      'pending' => ('En attente', const Color(0xFFFFF4E5), const Color(0xFFB45309)),
      'confirmed' => ('Confirmé', const Color(0xFFE7F6EC), const Color(0xFF15803D)),
      'expired' => ('Dépassé', const Color(0xFFF3F4F6), const Color(0xFF6B7280)),
      'in_progress' => ('En cours', const Color(0xFFDCFCE7), const Color(0xFF16A34A)),
      'refused' => ('Refusé', const Color(0xFFFDE8E8), const Color(0xFFB91C1C)),
      'cancelled' => ('Annulé', const Color(0xFFF1F1F1), const Color(0xFF6B7280)),
      'completed' => ('Terminé', const Color(0xFFEAE6FD), const Color(0xFF6D28D9)),
      _ => (status, const Color(0xFFF1F1F1), const Color(0xFF6B7280)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}