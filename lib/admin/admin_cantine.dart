import 'package:flutter/material.dart';
import '../admin/admin_theme.dart';
import '../services/api_service.dart';

class AdminCantine extends StatefulWidget {
  const AdminCantine({super.key});
  @override
  State<AdminCantine> createState() => _AdminCantineState();
}

const _repasOptions = [
  {'val': 'petit_dejeuner', 'label': 'Petit-déjeuner', 'icon': Icons.free_breakfast_rounded},
  {'val': 'dejeuner', 'label': 'Déjeuner', 'icon': Icons.lunch_dining_rounded},
  {'val': 'diner', 'label': 'Dîner', 'icon': Icons.dinner_dining_rounded},
];

class _Plat {
  String nom;
  int prix;
  _Plat({required this.nom, required this.prix});
}

class _AdminCantineState extends State<AdminCantine> {
  DateTime _date = DateTime.now();
  bool _loading = true;
  String? _error;

  // Pour chaque repas : la liste de plats en cours d'édition + son état publié.
  final Map<String, List<_Plat>> _platsParRepas = {
    'petit_dejeuner': [],
    'dejeuner': [],
    'diner': [],
  };
  final Map<String, bool> _publieParRepas = {
    'petit_dejeuner': false,
    'dejeuner': false,
    'diner': false,
  };
  final Set<String> _publicationEnCours = {};

  String get _dateIso => '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() { _loading = true; _error = null; });
    final result = await ApiService.getCantineJour(_dateIso);
    if (!mounted) return;
    if (result['success'] == true) {
      for (final repas in _platsParRepas.keys) {
        _platsParRepas[repas] = [];
        _publieParRepas[repas] = false;
      }
      for (final row in (result['data'] as List<dynamic>)) {
        final repas = row['repas']?.toString() ?? '';
        if (!_platsParRepas.containsKey(repas)) continue;
        final plats = (row['plats'] as List<dynamic>? ?? [])
            .map((p) => _Plat(nom: p['nom']?.toString() ?? '', prix: (p['prix'] as num?)?.toInt() ?? 0))
            .toList();
        _platsParRepas[repas] = plats;
        _publieParRepas[repas] = row['publie'] == true;
      }
      setState(() => _loading = false);
    } else {
      setState(() {
        _error = result['error'] as String?;
        _loading = false;
      });
    }
  }

  Future<void> _choisirDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (d != null) {
      setState(() => _date = d);
      _charger();
    }
  }

  void _ajouterPlat(String repas) {
    final nomCtrl = TextEditingController();
    final prixCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ajouter un plat', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomCtrl,
              decoration: InputDecoration(labelText: 'Nom du plat', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: prixCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Prix (FCFA)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final nom = nomCtrl.text.trim();
              final prix = int.tryParse(prixCtrl.text.trim());
              if (nom.isEmpty || prix == null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('⚠️ Nom et prix valides requis.'), backgroundColor: Colors.redAccent),
                );
                return;
              }
              setState(() => _platsParRepas[repas]!.add(_Plat(nom: nom, prix: prix)));
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.iconBgAlt),
            child: const Text('Ajouter', style: TextStyle(color: AdminTheme.iconFgAlt)),
          ),
        ],
      ),
    );
  }

  Future<void> _publier(String repas) async {
    final plats = _platsParRepas[repas]!;
    if (plats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Ajoutez au moins un plat avant de publier.'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    setState(() => _publicationEnCours.add(repas));
    final result = await ApiService.publierMenuCantine(
      date: _dateIso,
      repas: repas,
      plats: plats.map((p) => {'nom': p.nom, 'prix': p.prix}).toList(),
    );
    if (!mounted) return;
    setState(() => _publicationEnCours.remove(repas));
    if (result['success'] == true) {
      setState(() => _publieParRepas[repas] = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] as String? ?? 'Menu publié.'), backgroundColor: const Color(0xFF1E293B)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] as String? ?? 'Erreur lors de la publication.'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(children: [
        _buildHeader(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildErrorState()
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: _repasOptions.map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _carteRepas(r['val'] as String, r['label'] as String, r['icon'] as IconData),
                          )).toList(),
                    ),
        ),
      ]),
    );
  }

  Widget _buildErrorState() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 32),
          const SizedBox(height: 12),
          Text(_error ?? 'Erreur', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _charger, child: const Text('Réessayer')),
        ]),
      );

  Widget _buildHeader() => Container(
        padding: const EdgeInsets.all(24),
        color: Colors.white,
        child: Row(children: [
          const Text('Menu de la cantine', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const Spacer(),
          GestureDetector(
            onTap: _choisirDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded, size: 15, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Text('$_dateIso', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
              ]),
            ),
          ),
        ]),
      );

  Widget _carteRepas(String repas, String label, IconData icon) {
    final plats = _platsParRepas[repas]!;
    final publie = _publieParRepas[repas]!;
    final enCours = _publicationEnCours.contains(repas);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AdminTheme.iconBg.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: AdminTheme.iconBg, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
              if (publie)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AdminTheme.successLight, borderRadius: BorderRadius.circular(20)),
                  child: const Text('✅ Publié', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AdminTheme.success)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AdminTheme.warningLight, borderRadius: BorderRadius.circular(20)),
                  child: const Text('⏳ Non publié', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AdminTheme.warning)),
                ),
            ]),
            const SizedBox(height: 14),
            if (plats.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Aucun plat ajouté.', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF), fontStyle: FontStyle.italic)),
              )
            else
              ...plats.asMap().entries.map((entry) {
                final i = entry.key;
                final plat = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Expanded(child: Text(plat.nom, style: const TextStyle(fontSize: 13))),
                    Text('${plat.prix} FCFA', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AdminTheme.iconBgAlt)),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16, color: Colors.redAccent),
                      onPressed: () => setState(() => plats.removeAt(i)),
                    ),
                  ]),
                );
              }),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _ajouterPlat(repas),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Ajouter un plat'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: enCours ? null : () => _publier(repas),
                  icon: enCours
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                  label: Text(publie ? 'Mettre à jour' : 'Publier', style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.iconBgAlt, padding: const EdgeInsets.symmetric(vertical: 10)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
