import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/notification_item.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationService();
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

  List<NotificationItem> _items = [];
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
      final result = await _service.getMyNotifications(_token);
      setState(() {
        _items = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Impossible de charger les notifications.';
        _isLoading = false;
      });
    }
  }

  Future<void> _onTapNotification(NotificationItem item) async {
    if (item.isRead) return;
    try {
      await _service.markAsRead(token: _token, id: item.id);
      setState(() {
        _items = _items
            .map((n) => n.id == item.id
            ? NotificationItem(
          id: n.id,
          title: n.title,
          message: n.message,
          type: n.type,
          isRead: true,
          createdAt: n.createdAt,
        )
            : n)
            .toList();
      });
    } catch (_) {
      // silencieux — pas critique si le marquage échoue
    }
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'BookingRequest':
        return Icons.event_note;
      case 'BookingConfirmed':
        return Icons.check_circle_outline;
      case 'BookingDeclined':
        return Icons.cancel_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
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
          Center(child: Text('Aucune notification pour le moment.')),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final item = _items[index];
        return Card(
          color: item.isRead ? null : Colors.indigo.shade50,
          child: ListTile(
            leading: Icon(
              _iconForType(item.type),
              color: item.isRead ? Colors.grey : Colors.indigo,
            ),
            title: Text(
              item.title,
              style: TextStyle(fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.message),
                const SizedBox(height: 4),
                Text(
                  _dateFormat.format(item.createdAt.toLocal()),
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ],
            ),
            isThreeLine: true,
            onTap: () => _onTapNotification(item),
          ),
        );
      },
    );
  }
}