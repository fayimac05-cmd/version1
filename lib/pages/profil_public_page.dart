import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../widgets/image_viewer_dialog.dart';

/// Fiche « Infos du contact » d'un membre, ouverte en touchant sa petite photo
/// dans une discussion. N'affiche ni email, ni téléphone, ni matricule.
class ProfilPublicPage extends StatefulWidget {
  const ProfilPublicPage({
    super.key,
    required this.userId,
    this.nom = '',
    this.prenoms = '',
    this.photoUrl,
    this.couleur = const Color(0xFF1E40AF),
  });

  final String userId;
  // Connus d'avance (depuis le message) : affichés tout de suite pendant le chargement.
  final String nom;
  final String prenoms;
  final String? photoUrl;
  final Color couleur;

  /// Les identifiants utilisateurs sont des UUID.
  static bool estIdentifiantValide(String id) => RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
      .hasMatch(id);

  /// Ouvre la fiche, sauf si l'identifiant n'est pas exploitable.
  static void ouvrir(
    BuildContext context, {
    required String userId,
    String nom = '',
    String prenoms = '',
    String? photoUrl,
    Color couleur = const Color(0xFF1E40AF),
  }) {
    if (!estIdentifiantValide(userId)) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProfilPublicPage(
        userId: userId, nom: nom, prenoms: prenoms, photoUrl: photoUrl, couleur: couleur,
      ),
    ));
  }

  @override
  State<ProfilPublicPage> createState() => _ProfilPublicPageState();
}

class _ProfilPublicPageState extends State<ProfilPublicPage> {
  static const Color _textMain = Color(0xFF0F172A);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);

  Map<String, dynamic>? _d;
  bool _chargement = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final headers = await ApiService.getHeaders();
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/profil-public/${widget.userId}'),
        headers: headers,
      );
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      if (!mounted) return;
      if (res.statusCode == 200 && body['success'] == true) {
        setState(() {
          _d = Map<String, dynamic>.from(body['data'] as Map);
          _chargement = false;
        });
      } else {
        setState(() {
          _erreur = body['message']?.toString() ?? 'Profil indisponible.';
          _chargement = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _erreur = 'Serveur injoignable. Réessayez.';
          _chargement = false;
        });
      }
    }
  }

  String _s(String k) => (_d?[k] ?? '').toString().trim();

  String _roleLabel(String r) {
    switch (r) {
      case 'delegue': return 'Délégué(e)';
      case 'delegue_adjoint': return 'Adjoint(e) Délégué(e)';
      case 'bde_president': return 'Délégué(e) Général(e) BDE';
      case 'bde_adjoint': return 'Adjoint(e) Délégué(e) Général(e) BDE';
      case 'bde_membre': return 'Membre BDE';
      case 'admin': return 'Administration';
      case 'professeur': return 'Professeur';
      case 'parent': return 'Parent';
      default: return '';
    }
  }

  void _agrandir(String? url, String titre) {
    if (url == null || url.isEmpty) return;
    ImageViewerDialog.show(context, imagePathOrUrl: url, title: titre);
  }

  void _copier(String texte) {
    Clipboard.setData(ClipboardData(text: texte));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copié'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prenoms = _d != null ? _s('prenoms') : widget.prenoms;
    final nom = _d != null ? _s('nom') : widget.nom;
    final nomComplet = '$prenoms $nom'.trim();
    final photo = (_d != null ? (_s('photo_url').isNotEmpty ? _s('photo_url') : null) : widget.photoUrl);
    final cover = _d != null && _s('cover_url').isNotEmpty ? _s('cover_url') : null;
    final initiales =
        '${prenoms.isNotEmpty ? prenoms[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'.toUpperCase();
    final filiere = _d != null ? _s('filiere') : '';
    final niveau = _d != null ? _s('niveau') : '';
    final sousTitre = [filiere, niveau].where((e) => e.isNotEmpty).join(' · ');
    final role = _d != null ? _roleLabel(_s('role')) : '';
    const double rayon = 58;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _textMain,
        title: const Text('Infos du contact', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _textMain)),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Couverture + photo de profil ──────────────────────────────
          Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: rayon),
                child: GestureDetector(
                  onTap: () => _agrandir(cover, 'Photo de couverture'),
                  child: Container(
                    height: 170,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        widget.couleur.withValues(alpha: 0.9),
                        widget.couleur.withValues(alpha: 0.55),
                      ]),
                    ),
                    child: cover != null
                        ? Image.network(cover, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink())
                        : null,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () => _agrandir(photo, 'Photo de profil'),
                    child: Container(
                      width: rayon * 2,
                      height: rayon * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: ClipOval(
                        child: (photo != null && photo.isNotEmpty)
                            ? Image.network(photo, fit: BoxFit.cover, width: rayon * 2, height: rayon * 2,
                                errorBuilder: (_, __, ___) => _initiales(initiales))
                            : _initiales(initiales),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Identité ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(children: [
              Text(nomComplet,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _textMain, letterSpacing: -0.4)),
              if (sousTitre.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(sousTitre, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: _textMuted)),
              ],
              if (role.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: widget.couleur.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(role, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: widget.couleur)),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: _border),

          if (_chargement)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_erreur != null)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(_erreur!, textAlign: TextAlign.center, style: const TextStyle(color: _textMuted)),
            )
          else
            ..._sections(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _initiales(String t) => Container(
        color: widget.couleur.withValues(alpha: 0.12),
        alignment: Alignment.center,
        child: Text(t, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: widget.couleur)),
      );

  List<Widget> _sections() {
    final bio = _s('biographie');
    final adresse = _s('adresse');
    final interets = _s('centres_interet')
        .split(RegExp(r'[,;\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final liens = <List<dynamic>>[
      [Icons.facebook, 'Facebook', _s('facebook')],
      [Icons.chat_bubble_outline_rounded, 'WhatsApp', _s('whatsapp')],
      [Icons.work_outline_rounded, 'LinkedIn', _s('linkedin')],
    ].where((l) => (l[2] as String).isNotEmpty).toList();

    final blocs = <Widget>[];
    if (bio.isNotEmpty) {
      blocs.add(_bloc('Biographie', child: Text(bio, style: const TextStyle(fontSize: 15, height: 1.45, color: _textMain))));
    }
    if (adresse.isNotEmpty) {
      blocs.add(_bloc('Domicile', child: Row(children: [
        const Icon(Icons.location_on_outlined, size: 18, color: _textMuted),
        const SizedBox(width: 8),
        Expanded(child: Text(adresse, style: const TextStyle(fontSize: 15, color: _textMain))),
      ])));
    }
    if (interets.isNotEmpty) {
      blocs.add(_bloc("Centres d'intérêt", child: Wrap(spacing: 8, runSpacing: 8, children: [
        for (final t in interets)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.couleur.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: widget.couleur)),
          ),
      ])));
    }
    if (liens.isNotEmpty) {
      blocs.add(_bloc('Liens', child: Column(children: [
        for (final l in liens)
          InkWell(
            onTap: () => _copier(l[2] as String),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                Icon(l[0] as IconData, size: 20, color: _textMuted),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l[1] as String, style: const TextStyle(fontSize: 11.5, color: _textMuted)),
                  Text(l[2] as String, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: _textMain), maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
                const Icon(Icons.copy_rounded, size: 16, color: _textMuted),
              ]),
            ),
          ),
      ])));
    }
    if (blocs.isEmpty) {
      blocs.add(const Padding(
        padding: EdgeInsets.all(32),
        child: Text("Ce membre n'a pas encore complété son profil.",
            textAlign: TextAlign.center, style: TextStyle(color: _textMuted)),
      ));
    }
    return blocs;
  }

  Widget _bloc(String titre, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _border, width: 6))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textMuted)),
        const SizedBox(height: 10),
        child,
      ]),
    );
  }
}