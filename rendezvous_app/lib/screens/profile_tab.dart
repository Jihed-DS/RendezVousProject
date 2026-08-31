import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';
import 'login_screen.dart';
import 'notification_screen.dart';
import 'chat_screen.dart';
import '../services/prestataire_service.dart';
import '../models/prestataire.dart';
import '../config/api_config.dart';
import 'package:image_picker/image_picker.dart';
import '../services/client_service.dart';
import '../providers/theme_provider.dart';
import '../theme/category_style.dart';
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _notificationService = NotificationService();
  final _prestataireService = PrestataireService();
  final _clientService = ClientService();
  final _imagePicker = ImagePicker();
  int _unreadCount = 0;
    Prestataire? _myProfile;
    String? _clientPhotoUrl;
    bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    _loadPrestataireProfile();
    _loadClientProfile();
  }
  bool get _isClient => context.read<AuthProvider>().user?.role == 'Client';

    Future<void> _loadClientProfile() async {
        if (!_isClient) return;
        final token = context.read<AuthProvider>().token!;
        final data = await _clientService.getMyProfile(token);
        if (mounted) setState(() => _clientPhotoUrl = data?['photoUrl'] as String?);
      }
  bool get _isPrestataire => context.read<AuthProvider>().user?.role == 'Prestataire';

    Future<void> _loadPrestataireProfile() async {
        if (!_isPrestataire) return;
        try {
          final token = context.read<AuthProvider>().token!;
          final profile = await _prestataireService.getMyProfile(token);
          if (mounted) setState(() => _myProfile = profile);
        } catch (_) {}
      }

    Future<void> _pickAndUploadPhoto() async {
        final picked = await _imagePicker.pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 90);
        if (picked == null) return;

        setState(() => _isUploadingPhoto = true);
        try {
          final token = context.read<AuthProvider>().token!;
            if (_isPrestataire) {
              await _prestataireService.uploadPhoto(token: token, photoFile: picked);
              await _loadPrestataireProfile();
            } else if (_isClient) {
              await _clientService.uploadPhoto(token: token, photoFile: picked);
              await _loadClientProfile();
            }
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo mise à jour.')),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
          );
        } finally {
          if (mounted) setState(() => _isUploadingPhoto = false);
        }
      }
  Future<void> _loadUnreadCount() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    final count = await _notificationService.getUnreadCount(token);
    if (mounted) setState(() => _unreadCount = count);
  }
  Future<void> _editBio() async {
    final controller = TextEditingController(text: _myProfile?.bio ?? '');
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Modifier ma bio', style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(sheetContext).pop(true),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
    if (saved != true || _myProfile == null) return;

    try {
      final token = context.read<AuthProvider>().token!;
      await _prestataireService.updateProfile(
        token: token, id: _myProfile!.id, bio: controller.text.trim(), photoUrl: _myProfile!.photoUrl,
      );
      await _loadPrestataireProfile();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }
  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    _loadUnreadCount();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final currentPhotoUrl = _isPrestataire ? _myProfile?.photoUrl : _clientPhotoUrl;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          Center(
            child: ClipOval(
              child: SizedBox(
                width: 72,
                height: 72,
                child: currentPhotoUrl != null
                    ? Image.network(
                  ApiConfig.resolvePhotoUrl(currentPhotoUrl),
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  width: 72,
                  height: 72,
                )
                    : Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Center(
                    child: Text(
                      (user?.fullName ?? user?.email ?? '?').substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
    if (_isPrestataire || _isClient)
                    Center(
                          child: TextButton.icon(
                        onPressed: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                            icon: _isUploadingPhoto
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.camera_alt_outlined, size: 16),
                    label: Text(_isUploadingPhoto ? 'Envoi...' : 'Changer la photo'),
                  ),
                ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              user?.fullName ?? user?.email ?? '',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          Center(
            child: Text(user?.role ?? '', style: const TextStyle(color: Colors.black54)),
          ),
              if (_isPrestataire && _myProfile?.categorieName != null) ...[
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: CategoryStyle.of(_myProfile!.categorieName).color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CategoryStyle.of(_myProfile!.categorieName).icon,
                            size: 15, color: CategoryStyle.of(_myProfile!.categorieName).color),
                        const SizedBox(width: 6),
                        Text(
                          _myProfile!.categorieName!,
                          style: TextStyle(
                            color: CategoryStyle.of(_myProfile!.categorieName).color,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

    ],
              if (_isPrestataire && _myProfile?.bio != null && _myProfile!.bio!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bio', style: Theme.of(context).textTheme.titleSmall),
                        IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: _editBio,
                        visualDensity: VisualDensity.compact,
                ),
                        const SizedBox(height: 6),
                        Text(_myProfile!.bio!),
                      ],
                    ),
                  ),
                ),
              ],
          const SizedBox(height: 24),

        Card(
                        child: ListTile(
                      leading: const Icon(Icons.chat_bubble_outline),
                      title: const Text('Assistant'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ChatScreen()),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
    child: Stack(
    alignment: Alignment.centerRight,
    children: [
    ListTile(
    leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notifications'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openNotifications,
                ),
                if (_unreadCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 44),
                    child: Container(
                      width: 9, height: 9,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                  );
                }
              },
            ),
          ),
          Card(
            child: SwitchListTile(
              secondary: Icon(context.watch<ThemeProvider>().isDark ? Icons.dark_mode : Icons.light_mode_outlined),
              title: const Text('Mode sombre'),
              value: context.watch<ThemeProvider>().isDark,
              onChanged: (_) => context.read<ThemeProvider>().toggle(),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}