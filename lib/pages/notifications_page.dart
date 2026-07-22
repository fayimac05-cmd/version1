import 'package:flutter/material.dart';
import '../widgets/app_bubble_bg.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> _notifs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _charger();
    // Temps réel : une nouvelle notification arrive en tête de liste.
    SocketService().onNotification(_onNotifTempsReel);
  }

  @override
  void dispose() {
    SocketService().off('notification');
    super.dispose();
  }

  void _onNotifTempsReel(dynamic data) {
    if (!mounted || data is! Map) return;
    setState(() => _notifs.insert(0, Map<String, dynamic>.from(data)));
  }

  Future<void> _charger() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ApiService.getNotifications();
    if (!mounted) return;
    if (result['success'] == true) {
      final list = (result['data'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      setState(() {
        _notifs = list;
        _loading = false;
      });
    } else {
      setState(() {
        _error = result['error']?.toString() ?? 'Erreur de chargement.';
        _loading = false;
      });
    }
  }

  Future<void> _toutLire() async {
    final ok = await ApiService.marquerToutesNotificationsLues();
    if (!mounted) return;
    if (ok) {
      setState(() {
        for (final n in _notifs) {
          n['lue'] = true;
        }
      });
    }
  }

  Future<void> _marquerLue(Map<String, dynamic> n) async {
    if (n['lue'] == true) return;
    final id = n['id']?.toString();
    if (id == null) return;
    setState(() => n['lue'] = true);
    await ApiService.marquerNotificationLue(id);
  }

  int get _nonLues => _notifs.where((n) => n['lue'] != true).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF4FB),
      body: Column(
        children: [
          AppPageHeader(
            title: 'Notifications',
            subtitle: _loading
                ? 'Chargement…'
                : '$_nonLues non lue${_nonLues > 1 ? 's' : ''}',
            onBack: () => Navigator.of(context).pop(),
            trailing: GestureDetector(
              onTap: _nonLues == 0 ? null : _toutLire,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('Tout lire',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _etatVide(
        icon: Icons.wifi_off_rounded,
        titre: 'Impossible de charger',
        sous: _error!,
        action: true,
      );
    }
    if (_notifs.isEmpty) {
      return _etatVide(
        icon: Icons.notifications_none_rounded,
        titre: 'Aucune notification',
        sous: 'Vous êtes à jour ! Les nouvelles notifications apparaîtront ici.',
      );
    }
    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _notifs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _carte(_notifs[index]),
      ),
    );
  }

  Widget _etatVide({
    required IconData icon,
    required String titre,
    required String sous,
    bool action = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 16),
            Text(titre,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Text(sous,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
            if (action) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _charger, child: const Text('Réessayer')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _carte(Map<String, dynamic> n) {
    final titre = (n['titre'] ?? '').toString();
    final corps = (n['corps'] ?? '').toString();
    final lue = n['lue'] == true;
    final style = _styleFromTitre(titre);

    return Container(
      decoration: BoxDecoration(
        color: lue ? Colors.white : const Color(0xFFF5F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: lue ? const Color(0xFFE2E8F0) : const Color(0xFFBFDBFE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: () => _marquerLue(n),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: style.$2,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(style.$1, color: style.$3, size: 22),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                titre,
                style: TextStyle(
                  fontWeight: lue ? FontWeight.w600 : FontWeight.w700,
                  fontSize: 14,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            if (!lue)
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                    color: Color(0xFF2563EB), shape: BoxShape.circle),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(corps,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF64748B), height: 1.4)),
            const SizedBox(height: 4),
            Text(_tempsEcoule(n['created_at']),
                style:
                    const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }

  // Icône + couleurs selon le sujet de la notification.
  (IconData, Color, Color) _styleFromTitre(String titre) {
    final t = titre.toLowerCase();
    if (t.contains('emploi du temps') || t.contains('planning')) {
      return (Icons.calendar_today_outlined, const Color(0xFFE6F1FB), const Color(0xFF185FA5));
    }
    if (t.contains('note') || t.contains('bulletin') || t.contains('évaluation')) {
      return (Icons.grade_outlined, const Color(0xFFFAEEDA), const Color(0xFF854F0B));
    }
    if (t.contains('cours') || t.contains('support')) {
      return (Icons.menu_book_outlined, const Color(0xFFE6F1FB), const Color(0xFF185FA5));
    }
    if (t.contains('message') || t.contains('réclamation')) {
      return (Icons.chat_bubble_outline, const Color(0xFFEEEDFE), const Color(0xFF534AB7));
    }
    if (t.contains('bienvenue') || t.contains('inscription')) {
      return (Icons.check_circle_outline, const Color(0xFFEAF3DE), const Color(0xFF3B6D11));
    }
    return (Icons.notifications_none_rounded, const Color(0xFFE6F1FB), const Color(0xFF185FA5));
  }

  String _tempsEcoule(dynamic iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso.toString());
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
