import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../models/admin_dashboard.dart';
import '../providers/auth_provider.dart';
import '../services/admin_dashboard_service.dart';
import '../theme/category_style.dart';
import '../widgets/pie_chart.dart';
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _service = AdminDashboardService();
  AdminDashboard? _data;
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
      final result = await _service.get(token);
      setState(() {
        _data = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Impossible de charger le dashboard.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
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

    final data = _data!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatsGrid(data),
        const SizedBox(height: 24),
        Text('Services les plus demandés', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        _buildTopCategories(data.topCategories),
        const SizedBox(height: 24),
        Text('Prestataires tendance', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        const Text('Classés par nombre de rendez-vous reçus', style: TextStyle(fontSize: 12, color: Colors.black45)),
        const SizedBox(height: 12),
        ...data.trendingPrestataires.map((p) => _buildPrestataireTile(p, showCount: true)),
        const SizedBox(height: 24),
        Text('Mieux notés', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ...data.topRatedPrestataires.map((p) => _buildPrestataireTile(p, showCount: false)),
      ],
    );
  }

  Widget _buildStatsGrid(AdminDashboard data) {
    final stats = [
      (Icons.groups_outlined, 'Clients', data.totalClients.toString(), Colors.blue),
      (Icons.people_outline, 'Prestataires', data.totalPrestataires.toString(), Colors.indigo),
      (Icons.category_outlined, 'Catégories', data.totalCategories.toString(), Colors.purple),
      (Icons.event_note, 'RDV total', data.totalRendezVous.toString(), Colors.teal),
      (Icons.trending_up, 'Cette semaine', data.rendezVousThisWeek.toString(), Colors.green),
      (Icons.hourglass_empty, 'En attente', data.pendingRendezVousCount.toString(), Colors.orange),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.4,
      children: stats.map((s) {
        final (icon, label, value, color) = s;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                builder: (context, value, child) => Opacity(opacity: value, child: Transform.scale(scale: value, child: child)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8), // FIXED: Replaced Spacer() with fixed width spacing
              Text(
                value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopCategories(List<CategoryDemand> categories) {
    if (categories.isEmpty) {
      return const Text('Aucune donnée pour le moment.', style: TextStyle(color: Colors.black54));
    }
    final slices = categories.map((c) {
      final style = CategoryStyle.of(c.categoryName);
      return PieSlice(label: c.categoryName, value: c.bookingCount.toDouble(), color: style.color);
    }).toList();

    return Row(
      children: [
        SimplePieChart(slices: slices),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: categories.map((c) {
              final style = CategoryStyle.of(c.categoryName);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: style.color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(c.categoryName, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 8),
                    Text(
                      '(${c.bookingCount})',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPrestataireTile(TrendingPrestataire p, {required bool showCount}) {
    final style = CategoryStyle.of(p.categoryName);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: style.color.withValues(alpha: 0.15),
          backgroundImage: p.photoUrl != null
              ? NetworkImage(ApiConfig.resolvePhotoUrl(p.photoUrl))
              : null,
          child: p.photoUrl == null ? Icon(style.icon, color: style.color, size: 18) : null,
        ),
        title: Text(p.fullName ?? 'Prestataire'),
        subtitle: Text(p.categoryName ?? '', style: TextStyle(color: style.color, fontSize: 12)),
        trailing: showCount
            ? Text('${p.bookingCount} RDV', style: const TextStyle(fontWeight: FontWeight.w600))
            : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, size: 16, color: Colors.amber),
            const SizedBox(width: 4),
            Text(p.ratingAvg.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}