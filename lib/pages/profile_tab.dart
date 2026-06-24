import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/student_profile.dart';
import '../theme/app_palette.dart';
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
  const ProfileTab({super.key, required this.profile, required this.onLogout});
  final StudentProfile profile;
  final VoidCallback onLogout;

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
  String _ville = 'Ouagadougou, Burkina Faso';
  String _dateNaiss = '';
  String _interets = '';
  String _bio = '';
  String _facebook = '';
  String _whatsapp = '';
  String _linkedin = '';

  bool _emailVisible = true;
  bool _telVisible = true;
  File? _photoFile;

  OverlayEntry? _overlayEntry;
  bool _panelOuvert = false;
  final GlobalKey _clochKey = GlobalKey();

  final List<AppNotification> _notifs = [
    AppNotification(id: '1', type: NotifType.examen, titre: 'Examen de mi-parcours', corps: 'Algorithmes & Structures de données – dans 48h', temps: 'Il y a 12 min'),
    AppNotification(id: '2', type: NotifType.note, titre: 'Note publiée', corps: 'Analyse numérique : 16.5/20', temps: 'Il y a 2h'),
    AppNotification(id: '3', type: NotifType.cours, titre: 'Nouveau cours disponible', corps: 'Pr. Koanda a posté un nouveau cours – Réseaux informatiques', temps: 'Il y a 5h'),
    AppNotification(id: '4', type: NotifType.inscription, titre: 'Inscription validée', corps: 'Votre inscription en Master 2 Génie Logiciel a été validée', temps: 'Hier, 14:30', lu: true),
  ];

  int get _nonLus => _notifs.where((n) => !n.lu).length;

  @override
  void initState() {
    super.initState();
    _email = widget.profile.email.isNotEmpty ? widget.profile.email : '${widget.profile.prenoms.toLowerCase()}.${widget.profile.nom.toLowerCase()}@ist.bf';
    _telephone = widget.profile.telephone;
  }

  @override
  void dispose() {
    _fermerPanel(isDisposing: true);
    super.dispose();
  }

  String get _initiales => '${widget.profile.prenoms.isNotEmpty ? widget.profile.prenoms[0] : ''}${widget.profile.nom.isNotEmpty ? widget.profile.nom[0] : ''}'.toUpperCase();

  void _togglePanel() => _panelOuvert ? _fermerPanel() : _ouvrirPanel();

  void _ouvrirPanel() {
    final RenderBox? renderBox = _clochKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final Offset position = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;
    setState(() => _panelOuvert = true);
    _overlayEntry = OverlayEntry(
      builder: (context) => _NotifPanel(
        top: position.dy + size.height + 8,
        right: MediaQuery.of(context).size.width - position.dx - size.width,
        notifs: _notifs,
        onLu: (id) {
          setState(() => _notifs.firstWhere((n) => n.id == id).lu = true);
          _overlayEntry?.markNeedsBuild();
        },
        onToutLu: () {
          setState(() { for (final n in _notifs) n.lu = true; });
          _overlayEntry?.markNeedsBuild();
        },
        onFermer: _fermerPanel,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _fermerPanel({bool isDisposing = false}) {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (isDisposing) {
      _panelOuvert = false;
    } else {
      if (mounted) setState(() => _panelOuvert = false);
    }
  }

  Future<void> _choisirPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _photoFile = File(picked.path));
    }
  }

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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              key: _clochKey, onTap: _togglePanel,
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _panelOuvert ? _brandBlue.withOpacity(0.3) : _border),
                ),
                child: Stack(alignment: Alignment.center, children: [
                  Icon(_panelOuvert ? Icons.notifications_rounded : Icons.notifications_none_rounded, color: _panelOuvert ? _brandBlue : _textMain, size: 20),
                  if (_nonLus > 0) Positioned(top: 10, right: 11, child: _BadgePulse(count: _nonLus)),
                ]),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          
          // ── BENTO BLOCK 1 : L'AVATAR & L'IDENTITÉ PREMIUM ──────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _border),
            ),
            child: Column(children: [
              Stack(alignment: Alignment.bottomRight, children: [
                Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, border: Border.all(color: _bgGlobal, width: 4),
                    color: _brandBlue.withOpacity(0.08),
                  ),
                  child: _photoFile != null
                      ? ClipOval(child: Image.file(_photoFile!, width: 96, height: 96, fit: BoxFit.cover))
                      : Center(child: Text(_initiales, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _brandBlue, letterSpacing: -0.5))),
                ),
                GestureDetector(
                  onTap: _choisirPhoto,
                  child: Container(
                    width: 30, height: 30,
                    decoration: const BoxDecoration(color: _textMain, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                  ),
                )
              ]),
              const SizedBox(height: 16),
              Text('${widget.profile.prenoms} ${widget.profile.nom}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _textMain, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text(widget.profile.matricule, style: const TextStyle(fontSize: 13, color: _textMuted, fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFDCFCE7))),
                child: Text(widget.profile.filiere.isNotEmpty ? widget.profile.filiere.toUpperCase() : 'CURSUS NON SPÉCIFIÉ',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF16A34A), letterSpacing: 0.3), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ]),
          ),

          const SizedBox(height: 16),

          // ── BENTO BLOCK 2 : BIOGRAPHIE ÉPURÉE ──────────────────────────────
          _bentoCard(
            titre: 'Biographie', icon: Icons.text_snippet_outlined, color: Colors.indigo,
            child: GestureDetector(
              onTap: () => _editer(titre: 'Ma Biographie', valeur: _bio, hint: 'Décrivez vos ambitions ou projets...', maxLength: 300, maxLines: 4, onSave: (v) => setState(() => _bio = v)),
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
    _interactiveRow(Icons.mail_outline_rounded, 'Adresse Email', _emailVisible ? _email : '••••••@•••.••', () => _editer(titre: 'Email', valeur: _email, hint: 'ex: etudiant@ist.bf', onSave: (v) => setState(() => _email = v))),
    _customDivider(),
    _interactiveRow(Icons.phone_iphone_rounded, 'Numéro de Mobile', _telVisible ? _telephone : '••••••••', () => _editer(titre: 'Téléphone', valeur: _telephone, hint: '+226 XX XX XX XX', onSave: (v) => setState(() => _telephone = v))),
    _customDivider(),
    // LIGNE CORRIGÉE ICI : Icons.location_on_outlined au lieu de Icons.map_outlines
    _interactiveRow(Icons.location_on_outlined, 'Ville / Résidence', _ville, () => _editer(titre: 'Ville actuelle', valeur: _ville, hint: 'Ex: Ouagadougou', onSave: (v) => setState(() => _ville = v))),
    _customDivider(),
    _interactiveRow(Icons.cake_outlined, 'Date de naissance', _dateNaiss.isEmpty ? 'Non renseignée' : _dateNaiss, () => _editer(titre: 'Date de naissance', valeur: _dateNaiss, hint: 'JJ/MM/AAAA', onSave: (v) => setState(() => _dateNaiss = v))),
    _customDivider(),
    _interactiveRow(Icons.local_activity_outlined, "Centres d'intérêt", _interets.isEmpty ? 'Ajouter des tags' : _interets, () => _editer(titre: "Centres d'intérêt", valeur: _interets, hint: 'Ex: Réseaux, Cyber, Foot', onSave: (v) => setState(() => _interets = v))),
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
              _immutableRow(Icons.account_balance_outlined, 'Établissement', 'Institut Supérieur de Technologies (IST)'),
              _customDivider(),
              _immutableRow(Icons.layers_outlined, 'Statut d\'inscription', 'Inscrit en Année Académique'),
            ]),
          ),

          const SizedBox(height: 16),

          // ── BENTO BLOCK 5 : RÉSEAUX PROFESSIONNELS ─────────────────────────
          _bentoCard(
            titre: 'Écosystème Numérique', icon: Icons.hub_outlined, color: Colors.teal,
            child: Column(children: [
              _interactiveRow(Icons.facebook, 'Lien Facebook', _facebook.isEmpty ? 'Non associé' : _facebook, () => _editer(titre: 'Facebook', valeur: _facebook, hint: 'facebook.com/username', onSave: (v) => setState(() => _facebook = v))),
              _customDivider(),
              _interactiveRow(Icons.chat_bubble_outline_rounded, 'WhatsApp Direct', _whatsapp.isEmpty ? 'Non associé' : _whatsapp, () => _editer(titre: 'WhatsApp', valeur: _whatsapp, hint: 'Lien ou numéro', onSave: (v) => setState(() => _whatsapp = v))),
              _customDivider(),
              _interactiveRow(Icons.work_outline_rounded, 'Profil LinkedIn', _linkedin.isEmpty ? 'Non associé' : _linkedin, () => _editer(titre: 'LinkedIn', valeur: _linkedin, hint: 'linkedin.com/in/username', onSave: (v) => setState(() => _linkedin = v))),
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
                _switchRow('Masquer mon adresse email', !_emailVisible, (v) => setState(() => _emailVisible = !v)),
                _switchRow('Masquer mon numéro de téléphone', !_telVisible, (v) => setState(() => _telVisible = !v)),
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
            decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
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

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _textMain)),
        Switch(value: value, onChanged: onChanged, activeColor: _brandBlue, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
      ]),
    );
  }

  Widget _customDivider() => const Divider(height: 12, thickness: 1, color: Color(0xFFF1F5F9));

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

class _BadgePulse extends StatefulWidget {
  const _BadgePulse({required this.count});
  final int count;
  @override
  State<_BadgePulse> createState() => _BadgePulseState();
}

class _BadgePulseState extends State<_BadgePulse> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.4).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)));
  }
}

class _NotifPanel extends StatelessWidget {
  const _NotifPanel({required this.top, required this.right, required this.notifs, required this.onLu, required this.onToutLu, required this.onFermer});
  final double top, right;
  final List<AppNotification> notifs;
  final void Function(String id) onLu;
  final VoidCallback onToutLu, onFermer;

  @override
  Widget build(BuildContext context) {
    final nonLus = notifs.where((n) => !n.lu).length;
    return Stack(children: [
      Positioned.fill(child: GestureDetector(onTap: onFermer, behavior: HitTestBehavior.opaque, child: const ColoredBox(color: Colors.transparent))),
      Positioned(top: top, right: right, child: Material(
        elevation: 16, borderRadius: BorderRadius.circular(20), shadowColor: Colors.black.withOpacity(0.08),
        child: Container(
          width: 320, constraints: const BoxConstraints(maxHeight: 400),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(padding: const EdgeInsets.all(16), child: Row(children: [
              const Expanded(child: Text('Alertes & Mises à jour', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)))),
              if (nonLus > 0) TextButton(onPressed: onToutLu, style: TextButton.styleFrom(minimumSize: Size.zero, padding: EdgeInsets.zero), child: const Text('Tout marquer lu', style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), fontWeight: FontWeight.w600))),
            ])),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Flexible(child: ListView.separated(
              padding: EdgeInsets.zero, shrinkWrap: true, itemCount: notifs.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (_, i) => _NotifItem(notif: notifs[i], onTap: () => onLu(notifs[i].id)),
            )),
          ]),
        ),
      )),
    ]);
  }
}

class _NotifItem extends StatelessWidget {
  const _NotifItem({required this.notif, required this.onTap});
  final AppNotification notif;
  final VoidCallback onTap;

  IconData get _icone {
    switch (notif.type) {
      case NotifType.examen: return Icons.crisis_alert_rounded;
      case NotifType.note: return Icons.assignment_turned_in_outlined;
      case NotifType.cours: return Icons.import_contacts_rounded;
      case NotifType.inscription: return Icons.verified_rounded;
      case NotifType.message: return Icons.forum_outlined;
    }
  }

  Color get _color {
    switch (notif.type) {
      case NotifType.examen: return const Color(0xFFEF4444);
      case NotifType.note: return const Color(0xFFF59E0B);
      case NotifType.cours: return const Color(0xFF3B82F6);
      case NotifType.inscription: return const Color(0xFF10B981);
      case NotifType.message: return const Color(0xFF6366F1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: notif.lu ? null : onTap,
      child: Container(
        color: notif.lu ? Colors.transparent : const Color(0xFFF8FAFC),
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: _color.withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(_icone, color: _color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(notif.titre, style: TextStyle(fontSize: 13, fontWeight: notif.lu ? FontWeight.w500 : FontWeight.w700, color: const Color(0xFF0F172A))),
            const SizedBox(height: 2),
            Text(notif.corps, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(notif.temps, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
          ])),
        ]),
      ),
    );
  }
}