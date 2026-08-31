import 'package:flutter/material.dart';
import '../models/prestataire.dart';
import '../models/categorie.dart';
import '../services/prestataire_service.dart';
import 'prestataire_detail_screen.dart';
import '../theme/category_style.dart';
import '../widgets/star_rating.dart';
import '../config/api_config.dart';
import '../utils/page_transitions.dart';
import '../widgets/staggered_fade_in.dart';
import '../widgets/shimmer_loader.dart';
class PrestataireListScreen extends StatefulWidget {
  const PrestataireListScreen({super.key});

  @override
  State<PrestataireListScreen> createState() => _PrestataireListScreenState();
}

class _PrestataireListScreenState extends State<PrestataireListScreen> {
  final _service = PrestataireService();
  final _searchController = TextEditingController();

  List<Prestataire> _all = [];
  List<Categorie> _categories = [];
  String? _selectedCategorieName; // null = "Toutes"
  String? _selectedCity; // null = "Toutes"
  double _minRating = 0;
  String _searchQuery = '';

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.getAll(),
        _service.getCategories(),
      ]);
      setState(() {
        _all = results[0] as List<Prestataire>;
        _categories = results[1] as List<Categorie>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur de chargement. Vérifie ta connexion.';
        _isLoading = false;
      });
    }
  }

  List<Prestataire> get _filtered {
    var list = _all;

    if (_selectedCategorieName != null) {
      list = list.where((p) => p.categorieName == _selectedCategorieName).toList();
    }
    if (_selectedCity != null) {
      list = list.where((p) => p.city == _selectedCity).toList();
    }
    if (_minRating > 0) {
      list = list.where((p) => p.ratingAvg >= _minRating).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((p) {
        final name = (p.fullName ?? '').toLowerCase();
        final bio = (p.bio ?? '').toLowerCase();
        return name.contains(query) || bio.contains(query);
      }).toList();
    }
    return list;
  }

  List<String> get _availableCities {
    final cities = _all.map((p) => p.city).whereType<String>().toSet().toList();
    cities.sort();
    return cities;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prestataires'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _selectedCity != null || _minRating > 0,
              child: const Icon(Icons.tune),
            ),
            onPressed: _openFiltersSheet,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: 6,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, __) => const ShimmerListTile(),
          );
    }

    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.wifi_off, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Center(child: Text(_error!, textAlign: TextAlign.center)),
          const SizedBox(height: 12),
          Center(
            child: TextButton(onPressed: _load, child: const Text('Réessayer')),
          ),
        ],
      );
    }

    final filtered = _filtered;

    return Column(
        children: [
          _buildHeroBanner(),
    _buildSearchBar(),
    _buildCategoryFilter(),
            if (_selectedCategorieName == null && _searchQuery.isEmpty) _buildFeaturedSection(),
    Expanded(
          child: filtered.isEmpty
              ? ListView(
            children: [
              const SizedBox(height: 120),
              Center(
                child: Text(
                  _searchQuery.isNotEmpty
                      ? 'Aucun résultat pour "$_searchQuery".'
                      : 'Aucun prestataire ne correspond à ces filtres.',
                ),
              ),
            ],
          )
              : ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length,
            separatorBuilder: (_, _) =>  SizedBox(height: 10),
            itemBuilder: (context, index) => StaggeredFadeIn(
              index: index,
              child: _PrestataireCard(prestataire: filtered[index]),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher un prestataire...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          )
              : null,
          isDense: true,
        ),
        onChanged: (value) => setState(() => _searchQuery = value.trim()),
      ),
    );
  }
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient:  LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
                colors: Theme.of(context).brightness == Brightness.dark
                  ? [Color(0xFF3730A3), Color(0xFF5B21B6)]
                : [Color(0xFF4F46E5), Color(0xFF7C3AED)],        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trouve ton prestataire idéal',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            '${_all.length} prestataires disponibles dans ${_categories.length} secteurs',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedSection() {
    final featured = [..._all]
      ..sort((a, b) => b.ratingAvg.compareTo(a.ratingAvg));
    final topRated = featured.take(6).toList();

    if (topRated.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('En vedette', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: topRated.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) => _FeaturedCard(prestataire: topRated[index]),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text('Tous les prestataires', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ],
    );
  }
  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        children: [
          _CategoryChip(
            label: 'Toutes',
            selected: _selectedCategorieName == null,
            onTap: () => setState(() => _selectedCategorieName = null),
          ),
          ..._categories.map(
                (c) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _CategoryChip(
                label: c.name,
                selected: _selectedCategorieName == c.name,
                onTap: () => setState(() => _selectedCategorieName = c.name),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFiltersSheet() async {
    String? tempCity = _selectedCity;
    double tempMinRating = _minRating;

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filtres', style: Theme.of(sheetContext).textTheme.titleLarge),
                      TextButton(
                        onPressed: () => setSheetState(() {
                          tempCity = null;
                          tempMinRating = 0;
                        }),
                        child: const Text('Réinitialiser'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Localisation', style: Theme.of(sheetContext).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Toutes'),
                        selected: tempCity == null,
                        onSelected: (_) => setSheetState(() => tempCity = null),
                      ),
                      ..._availableCities.map((city) => ChoiceChip(
                        label: Text(city),
                        selected: tempCity == city,
                        onSelected: (_) => setSheetState(() => tempCity = city),
                      )),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Note minimum', style: Theme.of(sheetContext).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [0.0, 3.0, 4.0, 4.5].map((min) {
                      return ChoiceChip(
                        label: Text(min == 0 ? 'Toutes' : '$min ★ et +'),
                        selected: tempMinRating == min,
                        onSelected: (_) => setSheetState(() => tempMinRating = min),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _selectedCity = tempCity;
                        _minRating = tempMinRating;
                      });
                      Navigator.of(sheetContext).pop();
                    },
                    child: const Text('Appliquer'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
class _FeaturedCard extends StatelessWidget {
  final Prestataire prestataire;

  const _FeaturedCard({required this.prestataire});

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(prestataire.categorieName);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context).push(
        FadeSlideRoute(page: PrestataireDetailScreen(prestataire: prestataire)),

      ),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                    Hero(
                      tag: 'prestataire-avatar-${prestataire.id}',
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: style.color.withValues(alpha: 0.15),
                          backgroundImage: prestataire.photoUrl != null
                          ? NetworkImage(ApiConfig.resolvePhotoUrl(prestataire.photoUrl))
                        : null,
                    child: prestataire.photoUrl == null
                        ? Icon(style.icon, size: 20, color: style.color)
                        : null,
                  ),
                ),
            const SizedBox(height: 6),
            Text(
              prestataire.fullName ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
            ),
            Text(
              prestataire.categorieName ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: style.color, fontSize: 9),
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.star, size: 11, color: Colors.amber),
                const SizedBox(width: 3),
                Text(prestataire.ratingAvg.toStringAsFixed(1), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
class _PrestataireCard extends StatelessWidget {
  final Prestataire prestataire;

  const _PrestataireCard({required this.prestataire});

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(prestataire.categorieName);
    return Card(
      elevation: 1,
      child: InkWell(
            splashColor: style.color.withValues(alpha: 0.1),
          highlightColor: style.color.withValues(alpha: 0.05),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PrestataireDetailScreen(prestataire: prestataire),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                        child: Hero(
                          tag: 'prestataire-avatar-${prestataire.id}',
                              child: CircleAvatar(
                                radius: 28,
                                backgroundColor: style.color.withValues(alpha: 0.15),
                              backgroundImage: prestataire.photoUrl != null
                              ? NetworkImage(ApiConfig.resolvePhotoUrl(prestataire.photoUrl))
                              : null,
                          child: prestataire.photoUrl == null
                          ? Icon(style.icon, size: 26, color: style.color)
                          : null,
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prestataire.fullName ?? 'Prestataire',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (prestataire.categorieName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          prestataire.categorieName!,
                          style: TextStyle(color: style.color, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    if (prestataire.city != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 13, color: Colors.black45),
                            const SizedBox(width: 2),
                            Text(prestataire.city!, style: const TextStyle(fontSize: 12, color: Colors.black45)),
                          ],
                        ),
                      ),
                    if (prestataire.bio != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          prestataire.bio!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ),
                    if (prestataire.subcategories.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: prestataire.subcategories
                              .map((s) => Chip(
                            label: Text(s, style: const TextStyle(fontSize: 11)),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ))
                              .toList(),
                        ),
                      ),
                    const SizedBox(height: 6),
                    StarRating(
                      rating: prestataire.ratingAvg,
                      totalReviews: prestataire.totalReviews,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}