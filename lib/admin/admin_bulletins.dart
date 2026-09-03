import 'package:flutter/material.dart';
import '../admin/admin_theme.dart';
import '../admin/admin_annonces.dart' show istNiveaux;
import '../services/api_service.dart';
import '../utils/snackbar_helper.dart';
import '../models/student_profile.dart';

// ════════════════════════════════════════════════════════════════════════════
// MODÈLE — étudiant en préparation de bulletin
// ════════════════════════════════════════════════════════════════════════════
class EtudiantPreparation {
  final int etudiantId;
  final String matricule, nom, prenoms, filiereNom, niveau;
  final double? moyenneCalculee;
  final int nbNotes;
  final String? bulletinId;
  final String? bulletinStatut; // 'valide' | 'ajourne' | 'invalide' si déjà publié
  final bool bulletinPublie;
  final String? datePublication;

  EtudiantPreparation({
    required this.etudiantId, required this.matricule, required this.nom, required this.prenoms,
    required this.filiereNom, required this.niveau, this.moyenneCalculee, required this.nbNotes,
    this.bulletinId, this.bulletinStatut, required this.bulletinPublie, this.datePublication,
  });

  factory EtudiantPreparation.fromJson(Map<String, dynamic> j) => EtudiantPreparation(
        etudiantId: int.tryParse(j['etudiant_id'].toString()) ?? 0,
        matricule: j['matricule'] ?? '',
        nom: j['nom'] ?? '',
        prenoms: j['prenoms'] ?? '',
        filiereNom: j['filiere_nom'] ?? '',
        niveau: j['niveau'] ?? '',
        moyenneCalculee: j['moyenne_calculee'] != null ? double.tryParse(j['moyenne_calculee'].toString()) : null,
        nbNotes: int.tryParse(j['nb_notes'].toString()) ?? 0,
        bulletinId: j['bulletin_id']?.toString(),
        bulletinStatut: j['bulletin_statut'] as String?,
        bulletinPublie: j['bulletin_publie'] == true,
        datePublication: j['date_publication']?.toString(),
      );
}

const List<String> _semestresDisponibles = ['S1', 'S2', 'S3', 'S4', 'S5', 'S6'];

// Statuts du bulletin — cochés manuellement par l'admin, jamais déduits
// automatiquement d'un seuil numérique.
const Map<String, String> _statutsBulletin = {
  'valide': 'Validé',
  'ajourne': 'Ajourné',
  'invalide': 'Invalidé',
};

// ════════════════════════════════════════════════════════════════════════════
// PAGE — PUBLICATION DES BULLETINS
// ════════════════════════════════════════════════════════════════════════════
class AdminBulletins extends StatefulWidget {
  final StudentProfile profile;
  const AdminBulletins({super.key, required this.profile});
  @override State<AdminBulletins> createState() => _AdminBulletinsState();
}

class _AdminBulletinsState extends State<AdminBulletins> {
  List<Map<String, dynamic>> _filieres = [];
  String? _filiereId;
  String? _niveau;
  String? _semestre;
  final _anneeCtrl = TextEditingController(text: '${DateTime.now().year}-${DateTime.now().year + 1}');

  bool _isLoadingFilieres = true;
  bool _isLoadingPreparation = false;
  bool _isPublishing = false;
  String? _errorMessage;

  List<EtudiantPreparation> _etudiants = [];
  final Map<int, String> _selections = {}; // etudiant_id -> 'valide'/'ajourne'/'invalide'

  @override
  void initState() {
    super.initState();
    _chargerFilieres();
  }

  @override
  void dispose() {
    _anneeCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerFilieres() async {
    setState(() => _isLoadingFilieres = true);
    final result = await ApiService.getFilieres();
    if (!mounted) return;
    setState(() {
      _isLoadingFilieres = false;
      if (result['success'] == true) {
        final all = (result['data'] as List<dynamic>).cast<Map<String, dynamic>>();
        // Un admin restreint à un domaine ne voit que les filières de ce
        // domaine, en s'appuyant sur le vrai champ `domaine` de la table
        // filieres (pas de déduction par le texte du nom).
        _filieres = widget.profile.filtreParDomaine
            ? all.where((f) => (f['domaine'] as String?) == widget.profile.domaineAdmin).toList()
            : all;
        if (_filieres.isNotEmpty) _filiereId = _filieres.first['id'].toString();
      }
    });
  }

  Future<void> _chargerPreparation() async {
    if (_filiereId == null || _niveau == null || _semestre == null || _anneeCtrl.text.trim().isEmpty) {
      _snack('Sélectionne filière, niveau, semestre et année académique.', isError: true);
      return;
    }
    setState(() {
      _isLoadingPreparation = true;
      _errorMessage = null;
      _etudiants = [];
      _selections.clear();
    });
    final result = await ApiService.getPreparationBulletin(
      filiereId: _filiereId!,
      niveau: _niveau!,
      semestre: _semestre!,
      anneeAcademique: _anneeCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _isLoadingPreparation = false;
      if (result['success'] == true) {
        _etudiants = (result['data'] as List<dynamic>)
            .map((j) => EtudiantPreparation.fromJson(j as Map<String, dynamic>))
            .toList();
        // Pré-remplit la sélection avec le statut déjà publié, si existant,
        // pour que l'admin voie ce qui a déjà été décidé (et puisse le
        // corriger) plutôt que de repartir de zéro.
        for (final e in _etudiants) {
          if (e.bulletinStatut != null) _selections[e.etudiantId] = e.bulletinStatut!;
        }
      } else {
        _errorMessage = result['error'] as String?;
      }
    });
  }

  int get _nbSelectionnes => _selections.length;
  bool get _pretAPublier => _etudiants.isNotEmpty && _nbSelectionnes == _etudiants.length;

  Future<void> _publier() async {
    if (!_pretAPublier) {
      _snack('Coche un statut (Validé/Ajourné/Invalidé) pour chaque étudiant avant de publier.', isError: true);
      return;
    }

    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.send_rounded, color: AdminTheme.primary),
          SizedBox(width: 10),
          Text('Confirmer la publication', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'Publier le bulletin de $_semestre (${_anneeCtrl.text.trim()}) pour ${_etudiants.length} étudiant(s) ?',
            style: const TextStyle(fontSize: 14, color: AdminTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AdminTheme.primaryLight, borderRadius: BorderRadius.circular(8)),
            child: const Row(children: [
              Icon(Icons.security_rounded, color: AdminTheme.primary, size: 16),
              SizedBox(width: 8),
              Expanded(child: Text(
                'Chaque étudiant ne verra que son propre bulletin. La moyenne générale sera recalculée au moment de la publication.',
                style: TextStyle(fontSize: 12, color: AdminTheme.primary, fontWeight: FontWeight.w600),
              )),
            ]),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler', style: TextStyle(color: AdminTheme.textSecondary))),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Publier'),
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          ),
        ],
      ),
    );
    if (confirme != true) return;

    setState(() => _isPublishing = true);
    final resultats = _selections.entries.map((e) => {'etudiant_id': e.key, 'statut': e.value}).toList();
    final result = await ApiService.publierBulletins(
      filiereId: _filiereId!,
      niveau: _niveau!,
      semestre: _semestre!,
      anneeAcademique: _anneeCtrl.text.trim(),
      resultats: resultats,
    );
    if (!mounted) return;
    setState(() => _isPublishing = false);

    if (result['success'] == true) {
      _snack('✅ ${result['message'] ?? 'Bulletins publiés.'}');
      _chargerPreparation();
    } else {
      _snack(result['error'] as String? ?? 'Erreur lors de la publication.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.background,
      body: Column(children: [
        Container(
          color: AdminTheme.surface,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Publication des bulletins', style: AdminTheme.headingLarge),
                Text('Moyenne générale + statut du semestre — par filière/niveau', style: AdminTheme.bodyMedium),
              ])),
              if (_etudiants.isNotEmpty)
                IconButton(
                  onPressed: _isLoadingPreparation ? null : _chargerPreparation,
                  icon: const Icon(Icons.refresh_rounded, color: AdminTheme.textSecondary),
                  tooltip: 'Actualiser',
                ),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AdminTheme.infoLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: AdminTheme.info.withValues(alpha: 0.3))),
              child: const Row(children: [
                Icon(Icons.security_rounded, color: AdminTheme.info, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text(
                  '⚠️ Le statut (Validé/Ajourné/Invalidé) est coché manuellement pour chaque étudiant — jamais calculé automatiquement à partir d\'un seuil.',
                  style: TextStyle(fontSize: 11, color: AdminTheme.info, fontWeight: FontWeight.w600),
                )),
              ]),
            ),
            const SizedBox(height: 16),
            _isLoadingFilieres
                ? const SizedBox(height: 44, child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))))
                : Column(children: [
                    Row(children: [
                      Expanded(child: _dropField('Filière', _filiereId, _filieres.map((f) => f['id'].toString()).toList(),
                          _filieres.map((f) => f['nom'] as String).toList(), (v) => setState(() => _filiereId = v))),
                      const SizedBox(width: 12),
                      Expanded(child: _dropField('Niveau', _niveau, istNiveaux, istNiveaux, (v) => setState(() => _niveau = v))),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _dropField('Semestre', _semestre, _semestresDisponibles, _semestresDisponibles, (v) => setState(() => _semestre = v))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(AdminTheme.radiusButton), border: Border.all(color: AdminTheme.border)),
                          child: TextField(
                            controller: _anneeCtrl,
                            style: const TextStyle(fontSize: 13),
                            decoration: const InputDecoration(labelText: 'Année académique', labelStyle: TextStyle(fontSize: 12), border: InputBorder.none),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoadingPreparation ? null : _chargerPreparation,
                        icon: _isLoadingPreparation
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.calculate_rounded, size: 16),
                        label: const Text('Calculer les moyennes'),
                        style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusButton))),
                      ),
                    ),
                  ]),
          ]),
        ),
        const Divider(height: 1, color: AdminTheme.border),
        Expanded(child: _buildContenu()),
        if (_etudiants.isNotEmpty) _buildBarrePublication(),
      ]),
    );
  }

  Widget _buildContenu() {
    if (_isLoadingPreparation) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 32),
        const SizedBox(height: 12),
        Text(_errorMessage!, style: const TextStyle(fontSize: 13, color: AdminTheme.textSecondary)),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _chargerPreparation, child: const Text('Réessayer')),
      ]));
    }
    if (_etudiants.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 72, height: 72, decoration: BoxDecoration(color: AdminTheme.primaryLight, borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.description_outlined, color: AdminTheme.primary, size: 36)),
        const SizedBox(height: 16),
        Text('Aucune donnée chargée', style: AdminTheme.headingMedium),
        const SizedBox(height: 8),
        const Text('Choisis une filière, un niveau, un semestre et une année, puis clique sur "Calculer les moyennes".',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AdminTheme.textSecondary)),
      ]));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: _etudiants.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _carteEtudiant(_etudiants[i]),
    );
  }

  Widget _carteEtudiant(EtudiantPreparation e) {
    final selection = _selections[e.etudiantId];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        borderRadius: BorderRadius.circular(AdminTheme.radiusCard),
        border: Border.all(color: AdminTheme.border),
        boxShadow: AdminTheme.cardShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 38, height: 38, decoration: const BoxDecoration(color: AdminTheme.primaryLight, shape: BoxShape.circle),
              child: Center(child: Text('${e.prenoms.isNotEmpty ? e.prenoms[0] : "?"}${e.nom.isNotEmpty ? e.nom[0] : "?"}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AdminTheme.primary)))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${e.prenoms} ${e.nom}', style: AdminTheme.headingSmall),
            Text('${e.matricule} · ${e.nbNotes} note(s) prise(s) en compte', style: AdminTheme.caption),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              e.moyenneCalculee != null ? e.moyenneCalculee!.toStringAsFixed(2) : '—',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                  color: (e.moyenneCalculee ?? 0) >= 10 ? AdminTheme.primary : AdminTheme.danger),
            ),
            const Text('/20', style: TextStyle(fontSize: 10, color: AdminTheme.textMuted)),
          ]),
        ]),
        if (e.bulletinPublie) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AdminTheme.successLight, borderRadius: BorderRadius.circular(6)),
            child: Text(
              'Déjà publié${e.datePublication != null ? ' le ${e.datePublication!.split('T').first}' : ''} — corrige ci-dessous si besoin',
              style: const TextStyle(fontSize: 10, color: AdminTheme.success, fontWeight: FontWeight.w700),
            ),
          ),
        ],
        const SizedBox(height: 10),
        Row(children: _statutsBulletin.entries.map((entry) {
          final sel = selection == entry.key;
          final couleur = entry.key == 'valide' ? AdminTheme.success : entry.key == 'ajourne' ? AdminTheme.warning : AdminTheme.danger;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selections[e.etudiantId] = entry.key),
              child: Container(
                margin: EdgeInsets.only(right: entry.key != 'invalide' ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: sel ? couleur : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: couleur.withValues(alpha: sel ? 1 : 0.35)),
                ),
                child: Center(child: Text(entry.value,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: sel ? Colors.white : couleur))),
              ),
            ),
          );
        }).toList()),
      ]),
    );
  }

  Widget _buildBarrePublication() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Row(children: [
          Expanded(child: Text(
            '$_nbSelectionnes / ${_etudiants.length} étudiant(s) statué(s)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _pretAPublier ? AdminTheme.success : AdminTheme.textSecondary),
          )),
          ElevatedButton.icon(
            onPressed: (_pretAPublier && !_isPublishing) ? _publier : null,
            icon: _isPublishing
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded, size: 16),
            label: Text(_isPublishing ? 'Publication...' : 'Publier le bulletin'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AdminTheme.border,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusButton)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _dropField(String hint, String? value, List<String> ids, List<String> labels, ValueChanged<String?> onChanged) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(AdminTheme.radiusButton), border: Border.all(color: AdminTheme.border)),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(
          value: value, isExpanded: true, hint: Text(hint, style: const TextStyle(fontSize: 13)),
          style: AdminTheme.bodyLarge,
          items: List.generate(ids.length, (i) => DropdownMenuItem(value: ids[i], child: Text(labels[i], style: const TextStyle(fontSize: 13)))),
          onChanged: onChanged,
        )),
      );

  void _snack(String msg, {bool isError = false}) => showAppSnackBar(context, msg, backgroundColor: isError ? AdminTheme.danger : const Color(0xFF1A3C34));
}
