import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../widgets/profile_header_cover.dart';

import '../models/student_profile.dart';
import 'splash_screen.dart';

enum NotifType { examen, note, cours, inscription, message }

class AppNotification {
  final String id;
  final NotifType type;
  final String titre;
  final String corps;
  final String temps;
  bool lu;

  AppNotification({
    required this.id,
    required this.type,
    required this.titre,
    required this.corps,
    required this.temps,
    this.lu = false,
  });
}

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key, required this.profile, required this.onLogout, this.onPhotoChanged, this.onBack});
  final StudentProfile profile;
  final VoidCallback onLogout;
  /// Remonte la nouvelle photo/couverture au shell qui héberge cet écran,
  /// pour qu'elle survive à un changement d'onglet (voir StudentShell).
  final void Function(String? photoUrl, String? coverUrl)? onPhotoChanged;

  /// Action du bouton retour. Par défaut : ferme l'écran s'il a été ouvert par-dessus un autre.
  /// Si le profil est un onglet du shell, passer ici le retour vers l'onglet d'accueil.
  final VoidCallback? onBack;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> with TickerProviderStateMixin {
  // Constantes de Design Système
  static const Color _bgGlobal = Color(0xFFF8FAFC);
  static const Color _textMain = Color(0xFF0F172A);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _brandBlue = Color(0xFF1E40AF);

  String _email = '';
  String _telephone = '';
  String _adresse = '';
  String _dateNaiss = '';
  String _interets = '';
  String _bio = '';
  String _facebook = '';
  String _whatsapp = '';
  String _linkedin = '';

  bool _emailVisible = true;
  bool _telVisible = true;

  @override
  void initState() {
    super.initState();
    _email = widget.profile.email;
    _telephone = widget.profile.telephone;
    _adresse = widget.profile.adresse ?? '';
    _chargerProfil();
  }

  String get _initiales => '${widget.profile.prenoms.isNotEmpty ? widget.profile.prenoms[0] : ''}${widget.profile.nom.isNotEmpty ? widget.profile.nom[0] : ''}'.toUpperCase();

  // ── Lecture : tout vient de la base (GET /api/auth/me) ───────────────
  Future<void> _chargerProfil() async {
    try {
      final headers = await ApiService.getHeaders();
      final res = await http.get(Uri.parse('${ApiService.baseUrl}/auth/me'), headers: headers);
      debugPrint('[profil] /auth/me -> ${res.statusCode} ${res.body}');
      if (res.statusCode != 200) return;
      final d = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      String t(String k) => (d[k] ?? '').toString();
      if (!mounted) return;
      setState(() {
        if (t('email').isNotEmpty) _email = t('email');
        if (t('tel').isNotEmpty) _telephone = t('tel');
        _adresse = t('adresse');
        _dateNaiss = _formaterNaissance(t('date_naissance'));
        _bio = t('biographie');
        _interets = t('centres_interet');
        _facebook = t('facebook');
        _whatsapp = t('whatsapp');
        _linkedin = t('linkedin');
        _emailVisible = d['masquer_email'] != true;
        _telVisible = d['masquer_tel'] != true;
      });
    } catch (e) {
      debugPrint('[profil] erreur: $e'); // hors-ligne : on garde le profil de connexion
    }
  }

  /// "2003-05-14…" ou "14/05/2003" → "14/05/2003 (22 ans)"
  String _formaterNaissance(String brut) {
    if (brut.trim().isEmpty) return '';
    DateTime? d;
    final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(brut);
    final fr = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})').firstMatch(brut);
    if (iso != null) {
      d = DateTime(int.parse(iso.group(1)!), int.parse(iso.group(2)!), int.parse(iso.group(3)!));
    } else if (fr != null) {
      d = DateTime(int.parse(fr.group(3)!), int.parse(fr.group(2)!), int.parse(fr.group(1)!));
    }
    if (d == null) return brut;
    final now = DateTime.now();
    int age = now.year - d.year;
    if (now.month < d.month || (now.month == d.month && now.day < d.day)) age--;
    final jj = d.day.toString().padLeft(2, '0'), mm = d.month.toString().padLeft(2, '0');
    return '$jj/$mm/${d.year}${age >= 0 && age < 120 ? ' ($age ans)' : ''}';
  }

  // ── Écriture : PATCH /api/auth/profil, puis mise à jour de l'écran ───
  Future<void> _enregistrer(Map<String, dynamic> champs, VoidCallback appliquer) async {
    try {
      final headers = await ApiService.getHeaders();
      final res = await http.patch(
        Uri.parse('${ApiService.baseUrl}/auth/profil'),
        headers: headers,
        body: jsonEncode(champs),
      );
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      if (!mounted) return;
      if (res.statusCode == 200 && body['success'] == true) {
        setState(appliquer);
        return;
      }
      _snack(body['message']?.toString() ?? 'Échec de l\'enregistrement.');
    } catch (_) {
      if (mounted) _snack('Serveur injoignable. Réessayez.');
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

  void _editer({
    required String titre, required String valeur, required String hint,
    int maxLength = 200, int maxLines = 1, required void Function(String) onSave,
  }) {
    final ctrl = TextEditingController(text: valeur);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Text(titre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textMain, letterSpacing: -0.5)),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(color: _bgGlobal, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
                child: TextField(
                  controller: ctrl, maxLength: maxLength, maxLines: maxLines, autofocus: true,
                  style: const TextStyle(fontSize: 15, color: _textMain),
                  decoration: InputDecoration(
                    hintText: hint, hintStyle: const TextStyle(color: _textMuted, fontSize: 14),
                    border: InputBorder.none, contentPadding: const EdgeInsets.all(16),
                    counterStyle: const TextStyle(color: _textMuted, fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Annuler', style: TextStyle(fontSize: 15, color: _textMuted, fontWeight: FontWeight.w600)),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () { onSave(ctrl.text.trim()); Navigator.of(context).pop(); },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _textMain, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Enregistrer', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                )),
              ]),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGlobal,
      appBar: AppBar(
        backgroundColor: _bgGlobal,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Profil Étudiant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textMain)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _textMain),
          tooltip: 'Retour',
          onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          
          // ── BENTO BLOCK 1 : COVER + AVATAR PREMIUM ───────────────────────
          ProfileHeaderCover(
            matricule: widget.profile.matricule,
            nomComplet: '${widget.profile.prenoms} ${widget.profile.nom}',
            roleLabel: widget.profile.filiere.isNotEmpty
                ? widget.profile.filiere
                : 'Étudiant(e)',
            initiales: _initiales,
            badgeText: widget.profile.niveau.isNotEmpty ? widget.profile.niveau : null,
            accentColor: _brandBlue,
            bannerGradient: const [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            initialPhotoUrl: widget.profile.photoUrl,
            initialCoverUrl: widget.profile.coverUrl,
            onMediaChanged: widget.onPhotoChanged,
          ),

          const SizedBox(height: 16),

          // ── BENTO BLOCK 2 : BIOGRAPHIE ÉPURÉE ──────────────────────────────
          _bentoCard(
            titre: 'Biographie', icon: Icons.text_snippet_outlined, color: Colors.indigo,
            child: GestureDetector(
              onTap: () => _editer(titre: 'Ma Biographie', valeur: _bio, hint: 'Décrivez vos ambitions ou projets...', maxLength: 300, maxLines: 4, onSave: (v) => _enregistrer({'biographie': v}, () => _bio = v)),
              child: Container(
                width: double.infinity, padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: _bgGlobal, borderRadius: BorderRadius.circular(16)),
                child: Text(
                  _bio.isEmpty ? 'Ajoutez une courte présentation pour vos professeurs et camarades...' : _bio,
                  style: TextStyle(fontSize: 14, height: 1.5, color: _bio.isEmpty ? _textMuted : _textMain, fontStyle: _bio.isEmpty ? FontStyle.italic : FontStyle.normal),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── BENTO BLOCK 3 : CONTACTS & INFOS PERSO ─────────────────────────
_bentoCard(
  titre: 'Informations de Contact', icon: Icons.alternate_email_rounded, color: Colors.blue,
  child: Column(children: [
    _interactiveRow(Icons.mail_outline_rounded, 'Adresse Email', _emailVisible ? _email : '••••••@•••.••', () => _editer(titre: 'Email', valeur: _email, hint: 'ex: nom@gmail.com', onSave: (v) {
      if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)) { _snack('Adresse email invalide.'); return; }
      _enregistrer({'email': v}, () => _email = v);
    })),
    _customDivider(),
    _immutableRow(Icons.phone_iphone_rounded, 'Numéro de Mobile', _telephone.isEmpty ? 'Non renseigné' : (_telVisible ? _telephone : '••••••••')),
    _customDivider(),
    _immutableRow(Icons.location_on_outlined, 'Ville / Résidence', _adresse.isEmpty ? 'Non renseignée' : _adresse),
    _customDivider(),
    _immutableRow(Icons.cake_outlined, 'Date de naissance', _dateNaiss.isEmpty ? 'Non renseignée' : _dateNaiss),
    _customDivider(),
    _interactiveRow(Icons.local_activity_outlined, "Centres d'intérêt", _interets.isEmpty ? 'Ajouter des tags' : _interets, () => _editer(titre: "Centres d'intérêt", valeur: _interets, hint: 'Ex: Réseaux, Cyber, Foot', onSave: (v) => _enregistrer({'centres_interet': v}, () => _interets = v))),
  ]),
),

          const SizedBox(height: 16),

          // ── BENTO BLOCK 4 : DONNÉES SÉCURISÉES DE L'ADMIN ──────────────────
          _bentoCard(
            titre: 'Renseignements Académiques', icon: Icons.verified_user_outlined, color: Colors.amber,
            badge: '🔒 Certifié',
            child: Column(children: [
              _immutableRow(Icons.fingerprint_rounded, 'Numéro Matricule', widget.profile.matricule),
              _customDivider(),
              _immutableRow(Icons.school_outlined, 'Filière', widget.profile.filiere.isEmpty ? 'Non renseignée' : widget.profile.filiere),
              _customDivider(),
              _immutableRow(Icons.layers_outlined, 'Niveau', widget.profile.niveau.isEmpty ? 'Non renseigné' : widget.profile.niveau),
            ]),
          ),

          const SizedBox(height: 16),

          // ── BENTO BLOCK 5 : RÉSEAUX PROFESSIONNELS ─────────────────────────
          _bentoCard(
            titre: 'Écosystème Numérique', icon: Icons.hub_outlined, color: Colors.teal,
            child: Column(children: [
              _interactiveRow(Icons.facebook, 'Lien Facebook', _facebook.isEmpty ? 'Non associé' : _facebook, () => _editer(titre: 'Facebook', valeur: _facebook, hint: 'facebook.com/username', onSave: (v) => _enregistrer({'facebook': v}, () => _facebook = v))),
              _customDivider(),
              _interactiveRow(Icons.chat_bubble_outline_rounded, 'WhatsApp Direct', _whatsapp.isEmpty ? 'Non associé' : _whatsapp, () => _editer(titre: 'WhatsApp', valeur: _whatsapp, hint: 'Lien ou numéro', onSave: (v) => _enregistrer({'whatsapp': v}, () => _whatsapp = v))),
              _customDivider(),
              _interactiveRow(Icons.work_outline_rounded, 'Profil LinkedIn', _linkedin.isEmpty ? 'Non associé' : _linkedin, () => _editer(titre: 'LinkedIn', valeur: _linkedin, hint: 'linkedin.com/in/username', onSave: (v) => _enregistrer({'linkedin': v}, () => _linkedin = v))),
            ]),
          ),

          const SizedBox(height: 16),

          // ── BENTO BLOCK 6 : SÉCURITÉ & VISIBILITÉ ──────────────────────────
          _bentoCard(
            titre: 'Paramètres de Confidentialité', icon: Icons.shield_outlined, color: Colors.deepPurple,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: _bgGlobal, borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                _switchRow('Masquer mon adresse email', !_emailVisible, (v) => _enregistrer({'masquer_email': v}, () => _emailVisible = !v)),
                _switchRow('Masquer mon numéro de téléphone', !_telVisible, (v) => _enregistrer({'masquer_tel': v}, () => _telVisible = !v)),
              ]),
            ),
          ),

          const SizedBox(height: 32),

          // ── EXCLUSION / DISCONNECT (ACTION ULTRA CLEAN FLUIDE) ─────────────
          SizedBox(
            width: double.infinity, height: 54,
            child: TextButton.icon(
              onPressed: _confirmerDeconnexion,
              icon: const Icon(Icons.power_settings_new_rounded, color: Color(0xFFEF4444), size: 20),
              label: const Text('Mettre fin à la session', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFEF2F2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFFEE2E2))),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // Composant Bento de base
  Widget _bentoCard({required String titre, required IconData icon, required Color color, required Widget child, String? badge}) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha:0.08), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(titre, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textMain))),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: _bgGlobal, borderRadius: BorderRadius.circular(8)),
              child: Text(badge, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textMuted)),
            )
        ]),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }

  Widget _interactiveRow(IconData icon, String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(children: [
          Icon(icon, size: 18, color: _textMuted),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 11, color: _textMuted, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textMain), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: _textMuted),
        ]),
      ),
    );
  }

  Widget _immutableRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(children: [
        Icon(icon, size: 18, color: _textMuted),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: _textMuted, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textMain)),
        ])),
        const Icon(Icons.lock_outline_rounded, size: 14, color: _textMuted),
      ]),
    );
  }

  Widget _customDivider() => const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0));

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _textMain)),
        Switch(value: value, onChanged: onChanged, activeThumbColor: _brandBlue, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
      ]),
    );
  }

  void _confirmerDeconnexion() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Fermer la session ?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textMain)),
        content: const Text('Vos modifications locales non enregistrées sur le cloud centralisé de l\'institut pourraient ne pas être synchronisées.', style: TextStyle(fontSize: 14, color: _textMuted, height: 1.4)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Rester connecté', style: TextStyle(color: _textMuted, fontWeight: FontWeight.w600))),
          ElevatedButton(
            onPressed: () { Navigator.of(context).pop(); Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const SplashScreen()), (_) => false); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Déconnexion', style: TextStyle(fontWeight: FontWeight.w600)),
          )
        ],
      ),
    );
  }
}