import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/student_profile.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';
import 'discussion_privee_page.dart';

class ChoisirProfesseurPage extends StatefulWidget {
  final StudentProfile profile;

  const ChoisirProfesseurPage({super.key, required this.profile});

  @override
  State<ChoisirProfesseurPage> createState() => _ChoisirProfesseurPageState();
}

class _ChoisirProfesseurPageState extends State<ChoisirProfesseurPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _professeurs = [];
  bool _loading = true;
  String? _erreur;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _chargerProfesseurs();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerProfesseurs() async {
    setState(() {
      _loading = true;
      _erreur = null;
    });

    try {
      final headers = await ApiService.getHeaders();
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/messages/contacts?role=professeur'),
        headers: headers,
      );

      if (res.statusCode == 200 && mounted) {
        final body = jsonDecode(utf8.decode(res.bodyBytes));
        final list = (body is Map ? body['data'] : body) as List? ?? [];
        setState(() {
          _professeurs = list.cast<Map<String, dynamic>>();
          _loading = false;
        });
      } else if (mounted) {
        setState(() {
          _erreur = 'Impossible de charger les professeurs (code ${res.statusCode}).';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erreur = 'Erreur réseau lors du chargement des professeurs.';
          _loading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filtres {
    if (_query.trim().isEmpty) return _professeurs;
    final q = _query.trim().toLowerCase();
    return _professeurs.where((p) {
      final nom = '${p['prenoms'] ?? ''} ${p['nom'] ?? ''}'.toLowerCase();
      final spec = (p['specialite'] ?? p['domaine'] ?? '').toString().toLowerCase();
      final filieres = (p['filieres'] as List? ?? [])
          .map((f) => (f['filiere_nom'] ?? '').toString().toLowerCase())
          .join(' ');
      return nom.contains(q) || spec.contains(q) || filieres.contains(q);
    }).toList();
  }

  String _getInitiales(Map<String, dynamic> prof) {
    final prenoms = (prof['prenoms'] ?? '').toString().trim();
    final nom = (prof['nom'] ?? '').toString().trim();
    final pInit = prenoms.isNotEmpty ? prenoms[0].toUpperCase() : '';
    final nInit = nom.isNotEmpty ? nom[0].toUpperCase() : '';
    return '$pInit$nInit'.isNotEmpty ? '$pInit$nInit' : 'P';
  }

  void _ouvrirDiscussion(Map<String, dynamic> prof) {
    final id = prof['id']?.toString() ?? '';
    final nomComplet = '${prof['prenoms'] ?? ''} ${prof['nom'] ?? ''}'.trim();
    final specialite = prof['specialite'] ?? prof['domaine'] ?? 'Enseignant';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DiscussionPriveePage(
          destinataireId: id,
          destinataireNom: nomComplet.isNotEmpty ? nomComplet : 'Professeur',
          destinataireRole: 'Professeur',
          destinataireSousTitre: specialite.toString(),
          themeColor: const Color(0xFF1E40AF),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final liste = _filtres;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contacter un Professeur',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            Text(
              'Posez vos questions académiques en privé',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Rechercher par nom, matière, filière...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 18),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erreur != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.redAccent),
                        const SizedBox(height: 12),
                        Text(_erreur!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _chargerProfesseurs,
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Réessayer'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppPalette.blue, foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                  ),
                )
              : liste.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_search_rounded, size: 28, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Aucun professeur trouvé',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _query.isNotEmpty ? 'Essayez un autre mot clé.' : 'Aucun enseignant actif enregistré.',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: liste.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _buildCarteProf(liste[i]),
                    ),
    );
  }

  Widget _buildCarteProf(Map<String, dynamic> prof) {
    final nomComplet = '${prof['prenoms'] ?? ''} ${prof['nom'] ?? ''}'.trim();
    final specialite = (prof['specialite'] ?? prof['domaine'] ?? 'Enseignant').toString();
    final filieres = (prof['filieres'] as List? ?? [])
        .map((f) => f['filiere_nom']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();

    return GestureDetector(
      onTap: () => _ouvrirDiscussion(prof),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  _getInitiales(prof),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          nomComplet.isNotEmpty ? nomComplet : 'Professeur',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Enseignant',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    specialite,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (filieres.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: filieres.take(2).map((f) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          f,
                          style: const TextStyle(fontSize: 10, color: Color(0xFF475569)),
                        ),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF1E40AF).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Color(0xFF1E40AF),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
