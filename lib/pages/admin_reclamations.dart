import 'package:flutter/material.dart';
import '../pages/admin_data.dart';
import '../theme/app_palette.dart';

class AdminReclamations extends StatefulWidget {
  const AdminReclamations({super.key});

  @override
  State<AdminReclamations> createState() => _AdminReclamationsState();
}

class _AdminReclamationsState extends State<AdminReclamations> {
  String _filtre = 'tous';

  List<AdminReclamation> get _filtrees {
    if (_filtre == 'tous') return adminReclamations;
    return adminReclamations.where((r) => r.statut == _filtre).toList();
  }

  @override
  Widget build(BuildContext context) {
    final liste = _filtrees;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Réclamations',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A))),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      body: Column(children: [
        // ── Filtres ───────────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _chip('tous', 'Toutes'),
              const SizedBox(width: 8),
              _chip('en_attente', '🔴 En attente'),
              const SizedBox(width: 8),
              _chip('transmise_prof', '🟡 Transmises'),
              const SizedBox(width: 8),
              _chip('resolue', '🟢 Résolues'),
              const SizedBox(width: 8),
              _chip('rejetee', '⚫ Rejetées'),
            ]),
          ),
        ),
        Container(height: 1, color: const Color(0xFFE2E8F0)),

        // ── Liste ─────────────────────────────────────────────────────────
        Expanded(
          child: liste.isEmpty
              ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle_outline, size: 48, color: Color(0xFFCBD5E1)),
                  SizedBox(height: 12),
                  Text('Aucune réclamation dans cette catégorie',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
                ]))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: liste.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _carteReclamation(liste[i]),
                ),
        ),
      ]),
    );
  }

  Widget _chip(String val, String label) {
    final active = _filtre == val;
    return GestureDetector(
      onTap: () => setState(() => _filtre = val),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppPalette.blue : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: active ? Colors.white : const Color(0xFF64748B),
        )),
      ),
    );
  }

  Widget _carteReclamation(AdminReclamation r) {
    Color sc; String sl; Color sbg; IconData sIcon;
    switch (r.statut) {
      case 'en_attente':
        sc = const Color(0xFFDC2626); sl = 'En attente';
        sbg = const Color(0xFFFEE2E2); sIcon = Icons.schedule;
        break;
      case 'transmise_prof':
        sc = const Color(0xFFD97706); sl = 'Transmise au prof';
        sbg = const Color(0xFFFEF3C7); sIcon = Icons.send_outlined;
        break;
      case 'resolue':
        sc = const Color(0xFF15803D); sl = 'Résolue';
        sbg = const Color(0xFFF0FDF4); sIcon = Icons.check_circle_outline;
        break;
      default:
        sc = const Color(0xFF64748B); sl = 'Rejetée';
        sbg = const Color(0xFFF1F5F9); sIcon = Icons.cancel_outlined;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppPalette.blue.withOpacity(0.1), shape: BoxShape.circle),
              child: const Center(child: Icon(Icons.person_outline,
                  color: AppPalette.blue, size: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.etudiantNom, style: const TextStyle(fontSize: 14,
                  fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Text(r.etudiantMatricule,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B),
                      fontFamily: 'monospace')),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: sbg, borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(sIcon, size: 12, color: sc),
                const SizedBox(width: 4),
                Text(sl, style: TextStyle(fontSize: 11,
                    fontWeight: FontWeight.bold, color: sc)),
              ]),
            ),
          ]),
        ),

        Container(height: 1, color: const Color(0xFFF1F5F9)),

        // ── Contenu ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _tag(r.type == 'note' ? 'Réclamation Note' : 'Réclamation Moyenne',
                  r.type == 'note' ? AppPalette.blue : const Color(0xFF7C3AED)),
              const SizedBox(width: 8),
              Text(r.dateCreation,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ]),
            const SizedBox(height: 8),
            Text(r.module, style: const TextStyle(fontSize: 13,
                fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            const SizedBox(height: 2),
            Text(r.filiere, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(r.description,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF374151),
                      height: 1.5)),
            ),
            if (r.reponse != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF15803D).withOpacity(0.2)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.reply, color: Color(0xFF15803D), size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(r.reponse!,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF15803D),
                          height: 1.4))),
                ]),
              ),
            ],
          ]),
        ),

        // ── Actions ──────────────────────────────────────────────────────
        if (r.statut == 'en_attente') ...[
          Container(height: 1, color: const Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () => _dialogRepondre(r),
                icon: const Icon(Icons.reply, size: 16),
                label: const Text('Répondre', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF15803D),
                  side: const BorderSide(color: Color(0xFF15803D)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              )),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton.icon(
                onPressed: () => _transmettreAuProf(r),
                icon: const Icon(Icons.send, size: 16),
                label: const Text('→ Prof', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              )),
            ]),
          ),
        ],
        if (r.statut == 'transmise_prof') ...[
          Container(height: 1, color: const Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _dialogRepondre(r),
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('Marquer comme résolue', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF15803D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 11,
          fontWeight: FontWeight.bold, color: color)),
    );
  }

  void _transmettreAuProf(AdminReclamation r) {
    setState(() {
      r.statut = 'transmise_prof';
      r.reponse = 'Transmis au professeur responsable du module "${r.module}" pour vérification.';
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Réclamation transmise au professeur.'),
      backgroundColor: Color(0xFFD97706),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _dialogRepondre(AdminReclamation r) {
    final ctrl = TextEditingController(text: r.reponse ?? '');
    final isResolving = r.statut == 'transmise_prof';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(isResolving ? Icons.check_circle_outline : Icons.reply,
              color: isResolving ? const Color(0xFF15803D) : AppPalette.blue),
          const SizedBox(width: 10),
          Text(isResolving ? 'Résoudre la réclamation' : 'Répondre à la réclamation',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${r.etudiantNom} — ${r.module}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: ctrl,
              maxLines: 4,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Votre réponse / décision...',
                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: Color(0xFF64748B)))),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              setState(() {
                r.reponse = ctrl.text.trim();
                r.statut = isResolving ? 'resolue' : r.statut;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(isResolving ? 'Réclamation marquée comme résolue.' : 'Réponse enregistrée.'),
                backgroundColor: const Color(0xFF15803D),
                behavior: SnackBarBehavior.floating,
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isResolving ? const Color(0xFF15803D) : AppPalette.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(isResolving ? 'Résoudre' : 'Envoyer'),
          ),
        ],
      ),
    );
  }
}
