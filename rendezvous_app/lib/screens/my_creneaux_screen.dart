import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/creneau.dart';
import '../providers/auth_provider.dart';
import '../services/creneau_service.dart';
import '../widgets/shimmer_loader.dart';

class MyCreneauxScreen extends StatefulWidget {
  const MyCreneauxScreen({super.key});

  @override
  State<MyCreneauxScreen> createState() => _MyCreneauxScreenState();
}

class _MyCreneauxScreenState extends State<MyCreneauxScreen> {
  final _service = CreneauService();
  final _dateFormat = DateFormat('EEE dd MMM, HH:mm', 'fr_FR');

  List<Creneau> _creneaux = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _token => context.read<AuthProvider>().token!;

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _service.getMySlots(_token);
      result.sort((a, b) => a.startTime.compareTo(b.startTime));
      setState(() {
        _creneaux = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Impossible de charger tes créneaux.';
        _isLoading = false;
      });
    }
  }

  Future<void> _openCreateSheet() async {
    DateTime? pickedDate = DateTime.now();
    TimeOfDay? startTod;
    TimeOfDay? endTod;
    final tags = <String>[];
    final tagController = TextEditingController();

    await showModalBottomSheet(
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Nouveau créneau', style: Theme.of(sheetContext).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: Text(pickedDate == null
                          ? 'Choisir une date'
                          : DateFormat('EEE dd MMM yyyy', 'fr_FR').format(pickedDate!)),
                      onTap: () async {
                        final now = DateTime.now();
                        final result = await showDatePicker(
                          context: sheetContext,
                          initialDate: pickedDate ?? now,
                          firstDate: now,
                          lastDate: now.add(const Duration(days: 365)),
                        );
                        if (result != null) setSheetState(() => pickedDate = result);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.play_circle_outline),
                      title: Text(startTod == null ? 'Heure de début' : startTod!.format(sheetContext)),
                      onTap: () async {
                        final result = await showTimePicker(
                          context: sheetContext,
                          initialTime: const TimeOfDay(hour: 9, minute: 0),
                        );
                        if (result != null) setSheetState(() => startTod = result);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.stop_circle_outlined),
                      title: Text(endTod == null ? 'Heure de fin' : endTod!.format(sheetContext)),
                      onTap: () async {
                        final result = await showTimePicker(
                          context: sheetContext,
                          initialTime: const TimeOfDay(hour: 10, minute: 0),
                        );
                        if (result != null) setSheetState(() => endTod = result);
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('Sous-catégories proposées (optionnel)',
                        style: Theme.of(sheetContext).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: tagController,
                            decoration: const InputDecoration(
                              hintText: 'Ex: Ongles, Sourcils...',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onSubmitted: (_) {
                              final value = tagController.text.trim();
                              if (value.isNotEmpty && tags.length < 10) {
                                setSheetState(() {
                                  tags.add(value);
                                  tagController.clear();
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            final value = tagController.text.trim();
                            if (value.isNotEmpty && tags.length < 10) {
                              setSheetState(() {
                                tags.add(value);
                                tagController.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: tags.map((t) {
                          return Chip(
                            label: Text(t),
                            onDeleted: () => setSheetState(() => tags.remove(t)),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () async {
                        if (pickedDate == null || startTod == null || endTod == null) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(content: Text('Remplis la date et les deux heures.')),
                          );
                          return;
                        }

                        final start = DateTime(
                          pickedDate!.year, pickedDate!.month, pickedDate!.day,
                          startTod!.hour, startTod!.minute,
                        );
                        final end = DateTime(
                          pickedDate!.year, pickedDate!.month, pickedDate!.day,
                          endTod!.hour, endTod!.minute,
                        );

                        if (!end.isAfter(start)) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(content: Text("L'heure de fin doit être après le début.")),
                          );
                          return;
                        }

                        Navigator.of(sheetContext).pop();
                        await _createCreneau(start, end, tags);
                      },
                      child: const Text('Créer'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _createCreneau(DateTime start, DateTime end, List<String> tags) async {
    try {
      await _service.create(token: _token, startTime: start, endTime: end, tags: tags);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Créneau créé.')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _openBulkCreateSheet() async {
    DateTime? pickedDate = DateTime.now();
    TimeOfDay startTod = const TimeOfDay(hour: 7, minute: 0);
    TimeOfDay endTod = const TimeOfDay(hour: 11, minute: 0);
    int durationMinutes = 60;
    final tags = <String>[];
    final tagController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final slotsPreview = _computeSlotCount(startTod, endTod, durationMinutes);

            return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Générer plusieurs créneaux', style: Theme.of(sheetContext).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    const Text(
                      'Ex: de 7h à 11h avec des créneaux d\'1h -> 4 créneaux créés d\'un coup.',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: Text(pickedDate == null
                          ? 'Choisir une date'
                          : DateFormat('EEE dd MMM yyyy', 'fr_FR').format(pickedDate!)),
                      onTap: () async {
                        final now = DateTime.now();
                        final result = await showDatePicker(
                          context: sheetContext,
                          initialDate: pickedDate ?? now,
                          firstDate: now,
                          lastDate: now.add(const Duration(days: 365)),
                        );
                        if (result != null) setSheetState(() => pickedDate = result);
                      },
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('Début: ${startTod.format(sheetContext)}'),
                            onTap: () async {
                              final result = await showTimePicker(context: sheetContext, initialTime: startTod);
                              if (result != null) setSheetState(() => startTod = result);
                            },
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('Fin: ${endTod.format(sheetContext)}'),
                            onTap: () async {
                              final result = await showTimePicker(context: sheetContext, initialTime: endTod);
                              if (result != null) setSheetState(() => endTod = result);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Durée par créneau', style: Theme.of(sheetContext).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [30, 45, 60, 90, 120].map((min) {
                        return ChoiceChip(
                          label: Text('$min min'),
                          selected: durationMinutes == min,
                          onSelected: (_) => setSheetState(() => durationMinutes = min),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      slotsPreview > 0
                          ? '→ $slotsPreview créneau(x) seront créés'
                          : '→ Plage trop courte pour ce format',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: slotsPreview > 0 ? Colors.green.shade700 : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Sous-catégories pour ces créneaux (optionnel)',
                        style: Theme.of(sheetContext).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: tagController,
                            decoration: const InputDecoration(hintText: 'Ex: Coupe', isDense: true),
                            onSubmitted: (_) {
                              final value = tagController.text.trim();
                              if (value.isNotEmpty && tags.length < 10) {
                                setSheetState(() {
                                  tags.add(value);
                                  tagController.clear();
                                });
                              }
                            },
                          ),
                        ),
                        IconButton.filled(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            final value = tagController.text.trim();
                            if (value.isNotEmpty && tags.length < 10) {
                              setSheetState(() {
                                tags.add(value);
                                tagController.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: tags.map((t) => Chip(
                          label: Text(t),
                          onDeleted: () => setSheetState(() => tags.remove(t)),
                        )).toList(),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: slotsPreview <= 0 || pickedDate == null
                          ? null
                          : () async {
                        Navigator.of(sheetContext).pop();
                        await _createBulk(pickedDate!, startTod, endTod, durationMinutes, tags);
                      },
                      child: Text(slotsPreview > 0 ? 'Générer $slotsPreview créneaux' : 'Générer'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  int _computeSlotCount(TimeOfDay start, TimeOfDay end, int durationMinutes) {
    final startMin = start.hour * 60 + start.minute;
    final endMin = end.hour * 60 + end.minute;
    if (endMin <= startMin) return 0;
    return (endMin - startMin) ~/ durationMinutes;
  }

  Future<void> _createBulk(
      DateTime date, TimeOfDay start, TimeOfDay end, int durationMinutes, List<String> tags,
      ) async {
    try {
      final count = await _service.createBulk(
        token: _token,
        date: date,
        startHour: start.hour,
        startMinute: start.minute,
        endHour: end.hour,
        endMinute: end.minute,
        slotDurationMinutes: durationMinutes,
        tags: tags,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count créneaux créés.')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _confirmDelete(Creneau creneau) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer ce créneau ?'),
        content: Text(_dateFormat.format(creneau.startTime.toLocal())),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.delete(token: _token, id: creneau.id);
      if (!mounted) return;
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
      appBar: AppBar(title: const Text('Mes créneaux')),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'bulk',
            onPressed: _openBulkCreateSheet,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Générer plusieurs'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'single',
            onPressed: _openCreateSheet,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, __) => const ShimmerListTile(),
      );
    }

    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Center(child: Text(_error!)),
          const SizedBox(height: 12),
          Center(child: TextButton(onPressed: _load, child: const Text('Réessayer'))),
        ],
      );
    }

    final now = DateTime.now();

    // Visible ici : disponible (futur, pas réservé) ou dépassé — mais on
    // exclut les créneaux liés à un RDV "completed", déjà affichés dans
    // l'onglet "Mes rendez-vous" (pas de doublon entre les deux écrans).
    final visibleCreneaux = _creneaux.where((c) {
      final isPast = c.endTime.isBefore(now);
      final isAvailableFuture = c.isAvailable && !isPast;
      final isCompleted = c.appointmentStatus == 'completed';
      return (isAvailableFuture || isPast) && !isCompleted;
    }).toList();

    if (visibleCreneaux.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 100),
          Center(child: Text('Aucun créneau. Ajoute-en un avec le bouton +.')),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: visibleCreneaux.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final c = visibleCreneaux[index];
        final isPast = c.endTime.isBefore(now);

        final (icon, iconColor, statusLabel) = isPast
            ? (Icons.history, Colors.grey, 'Dépassé')
            : (Icons.event_available, Colors.green, 'Disponible');

        // Un créneau dépassé est supprimable, sauf s'il reste lié à un RDV
        // actif (pending/confirmed) que le prestataire doit encore résoudre —
        // le supprimer ferait perdre la date de ce rendez-vous en historique.
        final canDelete = isPast &&
            c.appointmentStatus != 'pending' &&
            c.appointmentStatus != 'confirmed';

        return Card(
          child: ListTile(
            leading: Icon(icon, color: iconColor),
            title: Text(_dateFormat.format(c.startTime.toLocal())),
            subtitle: Text(
              '${DateFormat.Hm().format(c.startTime.toLocal())} - ${DateFormat.Hm().format(c.endTime.toLocal())}'
                  '  •  $statusLabel',
            ),
            isThreeLine: c.tags.isNotEmpty,
            trailing: canDelete
                ? IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDelete(c),
            )
                : (isPast
                ? Tooltip(
              message: 'Rendez-vous en attente de traitement',
              child: Icon(Icons.lock_outline, color: Colors.grey.shade400),
            )
                : null),
          ),
        );
      },
    );
  }
}