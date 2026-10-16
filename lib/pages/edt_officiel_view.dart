import 'package:flutter/material.dart';

/// Emploi du temps au format « programme officiel de l'école » — même rendu
/// que l'aperçu côté administration (en-tête avec logo et établissement,
/// tableau Horaires × Jours avec colonnes COURS / SALLE, ligne PAUSE,
/// légende, notes N.B et signature).
///
/// Tout est piloté par les données de l'étudiant : établissement (nom + logo),
/// département, filière, niveau, année académique et dates de la semaine.
/// Rien n'est écrit en dur pour un établissement ou une filière précise.
class EdtOfficielView extends StatelessWidget {
  const EdtOfficielView({
    super.key,
    required this.creneaux,
    this.etabNom = '',
    this.etabLogo = '',
    this.departement = '',
    this.filiereNom = '',
    this.niveau = '',
    this.annee = '',
    this.dateDebut,
    this.dateFin,
    this.responsable = '',
  });

  final List<Map<String, dynamic>> creneaux;
  final String etabNom, etabLogo, departement, filiereNom, niveau, annee, responsable;
  final DateTime? dateDebut, dateFin;

  static const List<String> _jours = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];
  static const List<String> _moisLongs = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
  ];
  // Pause par défaut (identique à l'administration) : 12:30 → 13:30
  static const int _pause0 = 750, _pause1 = 810;

  static const Color _noir = Color(0xFF111111);
  static const BorderSide _trait = BorderSide(color: Color(0xFF333333), width: 0.8);

  // ── Outils horaires ──────────────────────────────────────────────────────
  static int? _min(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final p = raw.split(':');
    if (p.length < 2) return null;
    final h = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  static String _hhmm(int m) =>
      '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

  static String _s(Map<String, dynamic> c, String k) => (c[k] ?? '').toString();

  /// Découpe d'affichage d'un créneau (la donnée enregistrée reste inchangée) :
  /// la pause est retirée si le cours la traverse ; la partie du matin de plus
  /// de 3 h est coupée en deux (07:30-12:30 → 07:30-10:30 puis 10:30-12:30).
  List<_Seg> _segments(Map<String, dynamic> c) {
    final d = _s(c, 'heureDebut'), f = _s(c, 'heureFin');
    final a = _min(d), b = _min(f);
    if (a == null || b == null || b <= a) return [_Seg(d, f, c)];

    final parts = <List<int>>[];
    if (a < _pause0 && b > _pause1) {
      parts..add([a, _pause0])..add([_pause1, b]);
    } else if (a < _pause0 && b > _pause0) {
      parts.add([a, _pause0]);
    } else if (a >= _pause0 && a < _pause1 && b > _pause1) {
      parts.add([_pause1, b]);
    } else {
      parts.add([a, b]);
    }

    final out = <_Seg>[];
    for (final p in parts) {
      final debut = p[0], fin = p[1];
      if (debut < _pause0 && fin - debut > 180) {
        out..add(_Seg(_hhmm(debut), _hhmm(debut + 180), c))..add(_Seg(_hhmm(debut + 180), _hhmm(fin), c));
      } else {
        out.add(_Seg(_hhmm(debut), _hhmm(fin), c));
      }
    }
    return out;
  }

  List<_Slot> _slots(List<_Seg> segs) {
    final map = <String, _Slot>{};
    for (final g in segs) {
      if (g.debut.isEmpty || g.fin.isEmpty) continue;
      map['${g.debut}-${g.fin}'] = _Slot(g.debut, g.fin);
    }
    // Case de l'après-midi par défaut tant qu'aucun cours n'y est programmé.
    final aApresMidi = map.values.any((s) => (_min(s.debut) ?? 0) >= _pause0);
    if (!aApresMidi) map['14:00-18:00'] = const _Slot('14:00', '18:00');
    final l = map.values.toList()
      ..sort((a, b) {
        final x = a.debut.compareTo(b.debut);
        return x != 0 ? x : a.fin.compareTo(b.fin);
      });
    return l;
  }

  Color? _fondType(String type) {
    switch (type.toLowerCase()) {
      case 'td':
        return const Color(0xFF8B5CF6).withValues(alpha: 0.22);
      case 'tp':
        return const Color(0xFF10B981).withValues(alpha: 0.22);
      case 'examen':
        return const Color(0xFFE53935).withValues(alpha: 0.22);
      case 'devoir':
        return const Color(0xFFF59E0B).withValues(alpha: 0.28);
      default:
        return null; // cours = blanc
    }
  }

  // ── Libellés d'en-tête ───────────────────────────────────────────────────
  String _anneeLabel() {
    if (niveau.startsWith('Licence')) {
      final k = niveau.replaceAll(RegExp(r'[^0-9]'), '');
      return '${k.isEmpty ? '' : k}${k == '1' ? 'ère' : 'ème'} Année';
    }
    return niveau; // Master 1 / Master 2…
  }

  String _semaineLabel() {
    final a = dateDebut, b = dateFin;
    if (a == null || b == null) return '';
    final m1 = _moisLongs[a.month - 1].toUpperCase(), m2 = _moisLongs[b.month - 1].toUpperCase();
    if (a.year == b.year && a.month == b.month) return 'SEMAINE DU ${a.day} AU ${b.day} $m2 ${b.year}';
    return 'SEMAINE DU ${a.day} $m1${a.year == b.year ? '' : ' ${a.year}'} AU ${b.day} $m2 ${b.year}';
  }

  Widget _entete() {
    TextStyle st({bool b = false}) =>
        TextStyle(fontSize: 11.5, color: _noir, fontWeight: b ? FontWeight.w800 : FontWeight.w600);
    final dept = departement.trim();
    final fil = filiereNom.toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(children: [
        if (_semaineLabel().isNotEmpty)
          Center(
            child: Text(_semaineLabel(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w900, color: _noir, decoration: TextDecoration.underline)),
          ),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (dept.isNotEmpty) Text('Département $dept', style: st()),
              const SizedBox(height: 4),
              if (annee.isNotEmpty) Text('ANNEE ACADEMIQUE $annee', style: st(b: true)),
              const SizedBox(height: 4),
              Text('PROGRAMME de la ${_anneeLabel()} $fil'.trim(), style: st(b: true)),
            ]),
          ),
          if (etabNom.isNotEmpty || etabLogo.isNotEmpty)
            Row(mainAxisSize: MainAxisSize.min, children: [
              if (etabLogo.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Image.network(etabLogo, height: 44, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                ),
              if (etabNom.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(etabNom,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1565E0))),
                ),
            ]),
        ]),
      ]),
    );
  }

  // ── Construction ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, c) => _tableau(c.maxWidth.isFinite ? c.maxWidth - 26 : 900));
  }

  Widget _tableau(double dispo) {
    const double hW = 88;
    // Largeur « de conception » : le tableau est dessiné sur au moins 860 px,
    // puis réduit pour tenir EXACTEMENT dans la largeur disponible (plus de
    // défilement horizontal). Sur un écran très étroit (téléphone), la
    // réduction rendrait le texte illisible : on garde alors le défilement.
    const double largeurMini = 860;
    final double largeurConception = dispo < largeurMini ? largeurMini : dispo;
    final jourW = ((largeurConception - hW) / _jours.length).floorToDouble().clamp(120.0, 400.0);
    final double cW = (jourW * 0.68).floorToDouble();
    final double sW = jourW - cW;
    final segs = [for (final c in creneaux) ..._segments(c)];
    final slots = _slots(segs);
    final largeur = hW + (cW + sW) * _jours.length;

    Widget boite(double w, Widget child, {Color? bg, double? h, double minH = 0}) => Container(
          width: w,
          height: h,
          constraints: BoxConstraints(minHeight: minH),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: bg, border: const Border.fromBorderSide(_trait)),
          child: child,
        );
    TextStyle gras(double t, {Color c = _noir}) =>
        TextStyle(fontSize: t, fontWeight: FontWeight.w800, color: c, height: 1.25);
    String hh(String t) => t.replaceAll(':', 'H').toUpperCase();

    final lignes = <Widget>[
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        boite(hW, Text('HORAIRES', style: gras(11)), h: 52),
        for (final j in _jours)
          Column(children: [
            boite(cW + sW, Text(j.toUpperCase(), style: gras(11)), h: 26),
            Row(children: [
              boite(cW, Text('COURS', style: gras(10)), h: 26),
              boite(sW, Text('SALLE', style: gras(10)), h: 26),
            ]),
          ]),
      ]),
    ];

    for (var i = 0; i < slots.length; i++) {
      final sl = slots[i];
      if (i > 0) {
        final prevFin = _min(slots[i - 1].fin) ?? 0;
        final debut = _min(sl.debut) ?? 0;
        if (prevFin <= _pause0 && debut >= _pause1) {
          lignes.add(Container(
            width: largeur,
            height: 18,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Color(0xFFA6A6A6), border: Border.fromBorderSide(_trait)),
            child: Text('PAUSE', style: gras(10)),
          ));
        }
      }
      lignes.add(IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          boite(hW, Text('${hh(sl.debut)}-${hh(sl.fin)}', style: gras(10.5, c: const Color(0xFFD00000))),
              bg: const Color(0xFF00B0F0), minH: 96),
          for (final j in _jours) ...[
            () {
              final cs = segs
                  .where((g) => _s(g.src, 'jour') == j && g.debut == sl.debut && g.fin == sl.fin)
                  .map((g) => g.src)
                  .toList();
              return boite(
                cW,
                cs.isEmpty
                    ? const SizedBox()
                    : Column(mainAxisSize: MainAxisSize.min, children: [
                        for (final c in cs)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Text(_s(c, 'matiere'), textAlign: TextAlign.center, style: gras(11.5)),
                              if (_s(c, 'prof').isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text('Prof : ${_s(c, 'prof')}',
                                    textAlign: TextAlign.center, style: gras(10.5, c: const Color(0xFF1D4ED8))),
                              ],
                            ]),
                          ),
                      ]),
                bg: cs.isEmpty ? null : _fondType(_s(cs.first, 'type')),
              );
            }(),
            () {
              final cs = segs
                  .where((g) => _s(g.src, 'jour') == j && g.debut == sl.debut && g.fin == sl.fin)
                  .map((g) => g.src)
                  .toList();
              return boite(
                sW,
                cs.isEmpty
                    ? const SizedBox()
                    : Column(mainAxisSize: MainAxisSize.min, children: [
                        for (final c in cs)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Text(_s(c, 'salle'), textAlign: TextAlign.center, style: gras(10.5)),
                          ),
                      ]),
                bg: cs.isEmpty ? null : _fondType(_s(cs.first, 'type')),
              );
            }(),
          ],
        ]),
      ));
    }

    final n = DateTime.now();
    const legende = <List<dynamic>>[
      ['Cours', null],
      ['TD', Color(0xFF8B5CF6)],
      ['TP', Color(0xFF10B981)],
      ['Examen', Color(0xFFE53935)],
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _entete(),
        if (largeur <= dispo)
          SizedBox(width: largeur, child: Column(children: lignes))
        else if (dispo / largeur >= 0.6)
          // Réduit proportionnellement : tout le programme reste visible.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topLeft,
            child: SizedBox(width: largeur, child: Column(children: lignes)),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: largeur, child: Column(children: lignes)),
          ),
        const SizedBox(height: 10),
        Wrap(spacing: 14, runSpacing: 6, children: [
          for (final t in legende)
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: t[1] == null ? Colors.white : (t[1] as Color).withValues(alpha: 0.22),
                  border: Border.all(color: t[1] == null ? const Color(0xFF94A3B8) : t[1] as Color),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text(t[0] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
            ]),
        ]),
        const SizedBox(height: 12),
        const Text(
            "N.B1: Chaque professeur est tenu de respecter le présent calendrier, toute modification doit être initiée par l'administration",
            style: TextStyle(fontSize: 10.5, color: _noir)),
        const Text(
            "N.B2: Aucune modification n'est permise sans autorisation expresse du responsable pédagogique",
            style: TextStyle(fontSize: 10.5, color: _noir)),
        const Text(
            "N.B3: Toute modification du présent programme vous sera communiquée à l'avance par le responsable pédagogique",
            style: TextStyle(fontSize: 10.5, color: _noir)),
        const Text('Enfin, cet emploi du temps peut être modifié à tout moment',
            style: TextStyle(fontSize: 10.5, color: _noir)),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text('Fait à Ouagadougou, le ${n.day} ${_moisLongs[n.month - 1]} ${n.year}',
              style: const TextStyle(fontSize: 11, color: _noir)),
        ),
        if (responsable.isNotEmpty) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text('Le Responsable Pédagogique : $responsable',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _noir)),
          ),
        ],
      ]),
    );
  }
}

class _Slot {
  final String debut, fin;
  const _Slot(this.debut, this.fin);
}

class _Seg {
  final String debut, fin;
  final Map<String, dynamic> src;
  const _Seg(this.debut, this.fin, this.src);
}