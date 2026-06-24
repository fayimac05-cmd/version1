import 'package:flutter/material.dart';
import '../theme/app_palette.dart';
import 'auth_page.dart';

// ════════════════════════════════════════════════════════════════════════════
class Etablissement {
  final String nom;
  final String abreviation;
  final String ville;
  final String campus;
  final bool disponible;

  const Etablissement({
    required this.nom,
    required this.abreviation,
    required this.ville,
    this.campus = '',
    this.disponible = true,
  });
}

const List<Etablissement> kEtablissements = [
  Etablissement(
    nom: 'Institut Supérieur de Technologies',
    abreviation: 'IST',
    ville: 'Ouagadougou',
    campus: 'Campus Ouaga 2000',
    disponible: true,
  ),
  Etablissement(nom: 'Université de Ouagadougou', abreviation: 'UO',
      ville: 'Ouagadougou', disponible: false),
  Etablissement(nom: 'Institut Burkinabè de Technologie', abreviation: 'IBT',
      ville: 'Ouagadougou', disponible: false),
  Etablissement(nom: 'Université Saint Thomas d\'Aquin', abreviation: 'USTA',
      ville: 'Ouagadougou', disponible: false),
  Etablissement(nom: 'École Supérieure de Commerce', abreviation: 'ESC',
      ville: 'Bobo-Dioulasso', disponible: false),
  Etablissement(nom: 'Université Nazi Boni', abreviation: 'UNB',
      ville: 'Bobo-Dioulasso', disponible: false),
  Etablissement(nom: 'Institut Supérieur de Gestion', abreviation: 'ISG',
      ville: 'Ouagadougou', disponible: false),
];

// ════════════════════════════════════════════════════════════════════════════
class ChooseSchoolPage extends StatefulWidget {
  const ChooseSchoolPage({super.key});

  @override
  State<ChooseSchoolPage> createState() => _ChooseSchoolPageState();
}

class _ChooseSchoolPageState extends State<ChooseSchoolPage> {
  Etablissement? _selected;
  String _query = '';
  final TextEditingController _searchCtrl = TextEditingController();

  List<Etablissement> get _filtered => kEtablissements
      .where((e) =>
          e.nom.toLowerCase().contains(_query.toLowerCase()) ||
          e.abreviation.toLowerCase().contains(_query.toLowerCase()) ||
          e.ville.toLowerCase().contains(_query.toLowerCase()))
      .toList();

  void _continuer() {
    if (_selected == null || !_selected!.disponible) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => AuthPage(etablissement: _selected!),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOut)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                const SizedBox(height: 8),

                Row(children: [
                  Container(width: 50, height: 50,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: AppPalette.blue),
                      child: const Icon(Icons.school_rounded,
                          color: Colors.white, size: 28)),
                  const SizedBox(width: 14),
                  const Text('ScolarHub', style: TextStyle(fontSize: 26,
                      fontWeight: FontWeight.bold, color: AppPalette.blue,
                      letterSpacing: -0.3)),
                ]),

                const SizedBox(height: 32),

                const Text('Choisissez votre\nétablissement',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A), height: 1.25, letterSpacing: -0.4)),
                const SizedBox(height: 10),
                const Text('Sélectionnez l\'école ou l\'université où vous êtes inscrit.',
                    style: TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.55)),

                const SizedBox(height: 24),

                Container(
                  decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                          blurRadius: 8, offset: const Offset(0, 2))]),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un établissement...',
                      hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 15),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 22),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                              onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); })
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(child: Text('Aucun établissement trouvé.',
                          style: TextStyle(fontSize: 15, color: Color(0xFF64748B))))
                      : ListView.separated(
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _ecolCard(_filtered[i]),
                        ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    onPressed: (_selected != null && _selected!.disponible) ? _continuer : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.blue,
                      disabledBackgroundColor: const Color(0xFFE2E8F0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Flexible(child: Text(
                        _selected != null
                            ? 'Continuer avec ${_selected!.abreviation}'
                            : 'Sélectionnez un établissement',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      )),
                      if (_selected != null && _selected!.disponible) ...[
                        const SizedBox(width: 10),
                        const Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ]),
                  ),
                ),
                const SizedBox(height: 8),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ecolCard(Etablissement e) {
    final isSelected = _selected?.abreviation == e.abreviation;
    final dispo      = e.disponible;

    return GestureDetector(
      onTap: () {
        if (!dispo) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${e.abreviation} — Bientôt disponible'),
            backgroundColor: const Color(0xFF64748B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ));
          return;
        }
        setState(() => _selected = e);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? AppPalette.lightBlue : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppPalette.blue : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(width: 52, height: 52,
            decoration: BoxDecoration(
              color: isSelected ? AppPalette.blue
                  : dispo ? AppPalette.lightBlue : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(child: Text(e.abreviation,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white
                        : dispo ? AppPalette.blue : const Color(0xFF94A3B8))))),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.nom, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                color: isSelected ? AppPalette.blue
                    : dispo ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                height: 1.3),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 5),
            Row(children: [
              Icon(Icons.location_on_outlined, size: 14,
                  color: dispo ? const Color(0xFF64748B) : const Color(0xFFCBD5E1)),
              const SizedBox(width: 4),
              Flexible(child: Text(
                  e.campus.isNotEmpty ? '${e.ville} · ${e.campus}' : e.ville,
                  style: TextStyle(fontSize: 12,
                      color: dispo ? const Color(0xFF64748B) : const Color(0xFFCBD5E1)),
                  overflow: TextOverflow.ellipsis)),
            ]),
            if (!dispo) ...[
              const SizedBox(height: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6)),
                child: const Text('Bientôt disponible', style: TextStyle(
                    fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600))),
            ],
          ])),
          if (isSelected)
            const Icon(Icons.check_circle_rounded, color: AppPalette.blue, size: 26)
          else if (!dispo)
            const Icon(Icons.lock_outline, color: Color(0xFFCBD5E1), size: 20),
        ]),
      ),
    );
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }
}
