import 'package:flutter/material.dart';
import '../models/student_profile.dart';
import '../theme/app_palette.dart';

// ════════════════════════════════════════════════════════════════════════════
// MODÈLE
// ════════════════════════════════════════════════════════════════════════════
class _Evenement {
  final String id, titre, date, heure, lieu, type, description, emoji;
  final int prix, placesTotal, placesRestantes;

  const _Evenement({
    required this.id, required this.titre, required this.date,
    required this.heure, required this.lieu, required this.type,
    required this.description, required this.emoji,
    required this.prix, required this.placesTotal, required this.placesRestantes,
  });

  double get tauxRemplissage => 1 - (placesRestantes / placesTotal);
  bool get complet  => placesRestantes == 0;
  bool get urgent   => placesRestantes <= 15 && !complet;
}

// ════════════════════════════════════════════════════════════════════════════
// PAGE
// ════════════════════════════════════════════════════════════════════════════
class TicketsScreen extends StatefulWidget {
  final StudentProfile profile;
  const TicketsScreen({super.key, required this.profile});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabCtrl;
  final List<Map<String, dynamic>> _mesTickets = [];

  static const List<_Evenement> _evenements = [
    _Evenement(id: 'E001', titre: 'Soirée Étudiante BDE', emoji: '🎵',
        date: 'Vendredi 02 Mai 2026', heure: '20h00',
        lieu: 'Campus IST, Salle des fêtes', type: 'Soirée', prix: 500,
        placesTotal: 200, placesRestantes: 47,
        description: 'Grande soirée organisée par le BDE. Musique, danse et bonne ambiance !'),
    _Evenement(id: 'E002', titre: 'Journée Traditionnelle IST', emoji: '🎭',
        date: 'Samedi 10 Mai 2026', heure: '09h00',
        lieu: 'Campus IST, Terrain principal', type: 'Culturel', prix: 300,
        placesTotal: 500, placesRestantes: 230,
        description: 'Célébration des cultures du Burkina Faso. Tenues traditionnelles, danses, plats locaux.'),
    _Evenement(id: 'E003', titre: 'Cérémonie Remise de Diplômes', emoji: '🎓',
        date: 'Samedi 03 Mai 2026', heure: '10h00',
        lieu: 'Salle des fêtes IST', type: 'Académique', prix: 1000,
        placesTotal: 150, placesRestantes: 12,
        description: 'Cérémonie officielle de la promotion 2023-2024. Tenue de cérémonie obligatoire.'),
    _Evenement(id: 'E004', titre: 'Visite Entreprise Sonabel', emoji: '🏢',
        date: 'Mercredi 30 Avril 2026', heure: '08h00',
        lieu: 'Siège Sonabel, Ouagadougou', type: 'Pédagogique', prix: 0,
        placesTotal: 40, placesRestantes: 8,
        description: 'Visite pédagogique pour les étudiants ST. Transport inclus. Inscription obligatoire.'),
    _Evenement(id: 'E005', titre: 'Tournoi Sportif Inter-Filières', emoji: '⚽',
        date: 'Jeudi 01 Mai 2026', heure: '08h00',
        lieu: 'Terrain universitaire', type: 'Sport', prix: 0,
        placesTotal: 100, placesRestantes: 55,
        description: 'Foot, basket, athlétisme. Inscriptions par filière auprès du BDE.'),
  ];

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(children: [

      // ── Header simple ─────────────────────────────────────────────
      Container(
        color: AppPalette.blue,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(children: [
          Row(children: [
            Container(width: 46, height: 46,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.confirmation_number_outlined,
                  color: Colors.white, size: 24)),
            const SizedBox(width: 14),
            const Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Tickets & Événements',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                      color: Colors.white, letterSpacing: -0.3)),
              SizedBox(height: 2),
              Text('Paiement sécurisé via Orange Money',
                  style: TextStyle(fontSize: 13, color: Colors.white70)),
            ])),
          ]),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabCtrl,
            indicatorColor: AppPalette.yellow,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            tabs: [
              const Tab(text: 'Événements'),
              Tab(text: 'Mes tickets (${_mesTickets.length})'),
            ],
          ),
        ]),
      ),

      Expanded(child: TabBarView(controller: _tabCtrl, children: [
        _listeEvenements(),
        _mesTicketsView(),
      ])),
    ]);
  }

  // ── Liste événements ──────────────────────────────────────────────────
  Widget _listeEvenements() => ListView.separated(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
    itemCount: _evenements.length,
    separatorBuilder: (_, __) => const SizedBox(height: 12),
    itemBuilder: (_, i) => _carteEvenement(_evenements[i]),
  );

  Widget _carteEvenement(_Evenement e) {
    final aTicket = _mesTickets.any((t) => t['eventId'] == e.id);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [

        // En-tête — fond très léger
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Row(children: [
            Text(e.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(e.titre, style: const TextStyle(fontSize: 15,
                  fontWeight: FontWeight.bold, color: Color(0xFF0F172A),
                  letterSpacing: -0.2)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(e.type, style: const TextStyle(fontSize: 11,
                    color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              ),
            ])),
            // Prix — sobre
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(e.prix == 0 ? 'Gratuit' : '${e.prix} FCFA',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
                      color: e.prix == 0
                          ? const Color(0xFF15803D)
                          : const Color(0xFF0F172A))),
              if (e.prix > 0)
                const Text('Orange Money', style: TextStyle(fontSize: 10,
                    color: Color(0xFF64748B))),
            ]),
          ]),
        ),

        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // Détails
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.calendar_today_outlined, size: 13,
                  color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text('${e.date} à ${e.heure}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            ]),
            const SizedBox(height: 5),
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 13,
                  color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Flexible(child: Text(e.lieu,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 8),
            Text(e.description, style: const TextStyle(fontSize: 13,
                color: Color(0xFF64748B), height: 1.45)),
            const SizedBox(height: 12),

            // Jauge places — simple
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(
                e.complet ? '🔴 Complet'
                    : e.urgent ? '🟠 Plus que ${e.placesRestantes} places !'
                    : '🟢 ${e.placesRestantes} places disponibles',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                    color: e.complet ? const Color(0xFFC62828)
                        : e.urgent ? const Color(0xFFD97706)
                        : const Color(0xFF15803D)),
              ),
              Text('${e.placesTotal - e.placesRestantes}/${e.placesTotal}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ]),
            const SizedBox(height: 6),
            ClipRRect(borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: e.tauxRemplissage,
                backgroundColor: const Color(0xFFE2E8F0),
                color: e.complet ? const Color(0xFFC62828)
                    : e.urgent ? const Color(0xFFD97706)
                    : AppPalette.blue,
                minHeight: 6,
              )),
            const SizedBox(height: 14),

            // Bouton — orange uniquement si payant
            SizedBox(width: double.infinity, height: 46,
              child: ElevatedButton.icon(
                onPressed: (e.complet || aTicket) ? null : () => _acheter(e),
                icon: Icon(aTicket ? Icons.check_circle_outline
                    : e.complet ? Icons.block_outlined
                    : e.prix == 0 ? Icons.how_to_reg_outlined
                    : Icons.payment_outlined, size: 18),
                label: Text(
                  aTicket ? 'Ticket obtenu ✓'
                      : e.complet ? 'Complet'
                      : e.prix == 0 ? 'S\'inscrire gratuitement'
                      : 'Payer ${e.prix} FCFA via Orange Money',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: aTicket
                      ? const Color(0xFF15803D)
                      : e.complet
                          ? const Color(0xFFE2E8F0)
                          : e.prix == 0
                              ? AppPalette.blue
                              : const Color(0xFFFF6B00), // orange UNIQUEMENT si payant
                  disabledBackgroundColor: const Color(0xFFE2E8F0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Mes tickets ───────────────────────────────────────────────────────
  Widget _mesTicketsView() {
    if (_mesTickets.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 76, height: 76,
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.confirmation_number_outlined,
                size: 40, color: Color(0xFF64748B))),
          const SizedBox(height: 20),
          const Text('Aucun ticket pour l\'instant',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          const Text('Achetez des tickets depuis la liste des événements.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B),
                  height: 1.5)),
        ]),
      ));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _mesTickets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _carteTicket(_mesTickets[i]),
    );
  }

  Widget _carteTicket(Map<String, dynamic> t) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
          blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(children: [
      // En-tête
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Text(t['emoji'], style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(t['titre'], style: const TextStyle(fontSize: 15,
                fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 3),
            Text(t['date'], style: const TextStyle(fontSize: 12,
                color: Color(0xFF64748B))),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF86EFAC))),
            child: const Row(children: [
              Icon(Icons.check_circle_rounded,
                  color: Color(0xFF15803D), size: 14),
              SizedBox(width: 4),
              Text('Confirmé', style: TextStyle(fontSize: 12,
                  color: Color(0xFF15803D), fontWeight: FontWeight.bold)),
            ]),
          ),
        ]),
      ),
      const Divider(height: 1, color: Color(0xFFE2E8F0)),

      // QR Code
      Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const Text('QR Code d\'entrée', style: TextStyle(fontSize: 14,
              fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 14),
          Container(width: 160, height: 160,
            decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
                    blurRadius: 10)]),
            child: CustomPaint(painter: _QRPainter())),
          const SizedBox(height: 12),
          Text(t['codeTicket'], style: const TextStyle(fontSize: 13,
              fontWeight: FontWeight.bold, color: AppPalette.blue,
              fontFamily: 'monospace', letterSpacing: 2)),
          const SizedBox(height: 6),
          Text('${t['nbTickets']} ticket(s) · ${t['prix'] == 0 ? 'Gratuit' : '${t['prix']} FCFA'}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A))),
            child: const Row(children: [
              Icon(Icons.info_outline, color: Color(0xFFD97706), size: 15),
              SizedBox(width: 8),
              Expanded(child: Text(
                'Présentez ce QR Code à l\'entrée. L\'agent BDE le scannera.',
                style: TextStyle(fontSize: 12, color: Color(0xFFD97706), height: 1.4),
              )),
            ]),
          ),
        ]),
      ),
    ]),
  );

  // ── Achat ─────────────────────────────────────────────────────────────
  void _acheter(_Evenement e) {
    int nb = 1;
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setSt) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24), topRight: Radius.circular(24))),
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(children: [
              Text(e.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(e.titre, style: const TextStyle(fontSize: 16,
                    fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                Text(e.date, style: const TextStyle(fontSize: 13,
                    color: Color(0xFF64748B))),
              ])),
            ]),
            const SizedBox(height: 20),
            if (e.prix > 0) ...[
              const Text('Nombre de tickets', style: TextStyle(fontSize: 15,
                  fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
              const SizedBox(height: 10),
              Row(children: [
                _btnQte(Icons.remove, () { if (nb > 1) setSt(() => nb--); }),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('$nb', style: const TextStyle(fontSize: 22,
                      fontWeight: FontWeight.bold))),
                _btnQte(Icons.add, () { if (nb < 4) setSt(() => nb++); }),
                const Spacer(),
                Text('${e.prix * nb} FCFA', style: const TextStyle(fontSize: 20,
                    fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ]),
              const SizedBox(height: 20),
            ],
            SizedBox(width: double.infinity, height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _paiement(e, nb);
                },
                icon: Text(e.prix == 0 ? '✅' : '🟠',
                    style: const TextStyle(fontSize: 18)),
                label: Text(e.prix == 0
                    ? 'Confirmer l\'inscription'
                    : 'Payer ${e.prix * nb} FCFA',
                    style: const TextStyle(fontSize: 15,
                        fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: e.prix == 0
                      ? AppPalette.blue : const Color(0xFFFF6B00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      )),
    );
  }

  Widget _btnQte(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(width: 38, height: 38,
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Icon(icon, size: 18, color: const Color(0xFF0F172A))),
  );

  // ── Paiement Orange Money ─────────────────────────────────────────────
  void _paiement(_Evenement e, int nb) {
    final telCtrl  = TextEditingController();
    final codeCtrl = TextEditingController();
    bool loading   = false;
    bool codeStep  = false;
    bool success   = false;

    showDialog(context: context, builder: (_) => StatefulBuilder(
      builder: (ctx, setSt) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(mainAxisSize: MainAxisSize.min, children: [

          if (success) ...[
            Container(width: 68, height: 68,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xFF1DB954)),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 38)),
            const SizedBox(height: 16),
            const Text('Paiement réussi !', style: TextStyle(fontSize: 19,
                fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
            const SizedBox(height: 8),
            const Text('Ticket enregistré.\nConsultez "Mes tickets".',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5)),

          ] else if (codeStep) ...[
            const Text('Code SMS de confirmation', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 6),
            const Text('Entrez le code reçu par SMS.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0))),
              child: TextField(controller: codeCtrl,
                keyboardType: TextInputType.number, maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
                    letterSpacing: 8),
                decoration: const InputDecoration(
                  hintText: '- - - - - -',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(14), counterText: '',
                )),
            ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  setSt(() => loading = true);
                  await Future.delayed(const Duration(seconds: 2));
                  final code = 'IST-${e.id}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
                  setState(() => _mesTickets.add({
                    'eventId': e.id, 'titre': e.titre, 'date': e.date,
                    'emoji': e.emoji, 'prix': e.prix * nb,
                    'nbTickets': nb, 'codeTicket': code,
                  }));
                  setSt(() { loading = false; success = true; });
                  await Future.delayed(const Duration(seconds: 2));
                  if (ctx.mounted) { Navigator.of(ctx).pop(); _tabCtrl.animateTo(1); }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)), elevation: 0),
                child: loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text('Confirmer', style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),

          ] else ...[
            // Récapitulatif sobre
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Column(children: [
                _recap('Événement', e.titre),
                const SizedBox(height: 6),
                _recap('Date', e.date),
                const SizedBox(height: 6),
                _recap('Tickets', '$nb ticket(s)'),
                const SizedBox(height: 6),
                _recap('Montant', e.prix == 0 ? 'Gratuit' : '${e.prix * nb} FCFA',
                    gras: true),
              ]),
            ),
            const SizedBox(height: 16),
            if (e.prix > 0) ...[
              const Align(alignment: Alignment.centerLeft,
                child: Text('Numéro Orange Money', style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A)))),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0))),
                child: TextField(controller: telCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A)),
                  decoration: const InputDecoration(
                    hintText: '7X XX XX XX',
                    hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                    prefixIcon: Icon(Icons.phone_outlined,
                        color: Color(0xFF64748B), size: 20),
                    prefixText: '+226 ',
                    prefixStyle: TextStyle(color: Color(0xFF64748B), fontSize: 15),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  )),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  setSt(() => loading = true);
                  await Future.delayed(const Duration(seconds: 1));
                  if (e.prix == 0) {
                    final code = 'IST-${e.id}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
                    setState(() => _mesTickets.add({
                      'eventId': e.id, 'titre': e.titre, 'date': e.date,
                      'emoji': e.emoji, 'prix': 0,
                      'nbTickets': nb, 'codeTicket': code,
                    }));
                    setSt(() { loading = false; success = true; });
                    await Future.delayed(const Duration(seconds: 2));
                    if (ctx.mounted) { Navigator.of(ctx).pop(); _tabCtrl.animateTo(1); }
                  } else {
                    setSt(() { loading = false; codeStep = true; });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: e.prix == 0
                      ? AppPalette.blue : const Color(0xFFFF6B00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)), elevation: 0),
                child: loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Text(e.prix == 0 ? 'Confirmer' : 'Recevoir le code SMS',
                        style: const TextStyle(fontSize: 15,
                            fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ]),
      ),
    ));
  }

  Widget _recap(String l, String v, {bool gras = false}) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(l, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        Text(v, style: TextStyle(fontSize: 13, color: const Color(0xFF0F172A),
            fontWeight: gras ? FontWeight.bold : FontWeight.w500)),
      ]);
}

// ── QR Code ───────────────────────────────────────────────────────────────
class _QRPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF0A4DA2);
    final cell  = size.width / 21;
    const p = [
      [1,1,1,1,1,1,1,0,1,0,1,0,1,0,1,1,1,1,1,1,1],
      [1,0,0,0,0,0,1,0,0,1,0,1,0,0,1,0,0,0,0,0,1],
      [1,0,1,1,1,0,1,0,1,0,1,0,1,0,1,0,1,1,1,0,1],
      [1,0,1,1,1,0,1,0,0,1,1,0,0,1,1,0,1,1,1,0,1],
      [1,0,1,1,1,0,1,0,1,0,1,1,1,0,1,0,1,1,1,0,1],
      [1,0,0,0,0,0,1,0,0,1,0,0,1,0,1,0,0,0,0,0,1],
      [1,1,1,1,1,1,1,0,1,0,1,0,1,0,1,1,1,1,1,1,1],
      [0,0,0,0,0,0,0,0,0,1,0,1,0,1,0,0,0,0,0,0,0],
      [1,0,1,1,0,1,1,1,0,0,1,0,1,1,0,1,0,1,1,0,1],
      [0,1,0,0,1,0,0,0,1,0,0,1,0,0,1,0,1,0,0,1,0],
      [1,0,1,0,1,1,1,0,0,1,1,0,1,1,0,1,0,1,0,1,0],
      [0,1,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,1,1,0,0],
      [1,1,0,0,1,1,1,0,1,0,1,0,1,0,1,0,1,0,1,1,1],
      [0,0,0,0,0,0,0,0,1,1,0,1,0,1,0,0,0,1,0,0,0],
      [1,1,1,1,1,1,1,0,0,0,1,0,1,0,1,0,1,0,0,1,0],
      [1,0,0,0,0,0,1,0,1,0,0,1,0,1,0,1,0,0,1,0,0],
      [1,0,1,1,1,0,1,0,0,1,1,0,1,0,1,0,1,0,0,1,0],
      [1,0,1,1,1,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,1],
      [1,0,1,1,1,0,1,0,1,1,0,0,1,0,1,1,0,1,0,1,0],
      [1,0,0,0,0,0,1,0,0,0,1,0,0,1,0,0,1,0,1,0,0],
      [1,1,1,1,1,1,1,0,1,0,1,1,0,0,1,0,1,1,0,1,0],
    ];
    for (int r = 0; r < p.length; r++) {
      for (int c = 0; c < p[r].length; c++) {
        if (p[r][c] == 1) {
          canvas.drawRect(
            Rect.fromLTWH(c * cell + 1, r * cell + 1, cell - 1, cell - 1),
            paint);
        }
      }
    }
  }
  @override bool shouldRepaint(_) => false;
}
