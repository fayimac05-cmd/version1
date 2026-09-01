import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../bulletin_screen.dart';
import '../canal_screen.dart';
import '../class_detail_screen.dart';
import 'parent_schedule_tab.dart';

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
      setState(() {
        _notifs = (result['data'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _loading = false;
      });
    } else {
      setState(() {
        _error = result['error']?.toString() ?? 'Erreur de chargement.';
        _loading = false;
      });
    }
  }

  IconData _iconFromTitre(String titre) {
    final t = titre.toLowerCase();
    if (t.contains('emploi du temps') || t.contains('planning')) return Icons.calendar_today_outlined;
    if (t.contains('note') || t.contains('bulletin')) return Icons.grade_outlined;
    if (t.contains('cours')) return Icons.menu_book_outlined;
    if (t.contains('message')) return Icons.chat_bubble_outline;
    if (t.contains('bienvenue') || t.contains('inscription')) return Icons.check_circle_outline;
    return Icons.notifications_none_rounded;
  }
  void _onNotifTap(Map<String, dynamic> n, String titre) {
final t = titre.toLowerCase();

if (t.contains('emploi du temps') || t.contains('planning')) {
Navigator.push(context,
MaterialPageRoute(builder: (_) => const ParentScheduleTab()));
} else if (t.contains('note') || t.contains('bulletin')) {
Navigator.push(context,
MaterialPageRoute(builder: (_) => const BulletinScreen()));
} else if (t.contains('cours')) {
Navigator.push(context, MaterialPageRoute(
builder: (_) => ClassDetailScreen(
className: titre,
studentCount: 0,
),
));
} else if (t.contains('message')) {
Navigator.push(context,
MaterialPageRoute(builder: (_) => const CanalScreen()));
} else if (t.contains('bienvenue') || t.contains('inscription')) {
Navigator.popUntil(context, (route) => route.isFirst);
}
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF64748B),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _charger, child: const Text('Réessayer')),
          ],
        ),
      );
    }
    if (_notifs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_none_rounded, size: 52, color: Color(0xFF94A3B8)),
              SizedBox(height: 14),
              Text('Aucune notification',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              SizedBox(height: 6),
              Text('Les nouvelles notifications apparaîtront ici.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _notifs.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final n = _notifs[index];
          final titre = (n['titre'] ?? '').toString();
          return ListTile(
leading: CircleAvatar(
backgroundColor: const Color(0xFFEFF6FF),
child: Icon(_iconFromTitre(titre), color: const Color(0xFF1D4ED8), size: 20),
),
title: Text(titre,
style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
subtitle: Text((n['corps'] ?? '').toString(),
style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
trailing: Text(_tempsEcoule(n['created_at']),
style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
onTap: () => _onNotifTap(n, titre),
);
        },
      ),
    );
  }
}