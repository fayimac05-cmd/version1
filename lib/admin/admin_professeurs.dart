import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/student_profile.dart';
import '../theme/app_palette.dart';
import '../services/api_service.dart';

const List<String> kDomaines = ['Sciences & Technologies', 'Sciences de Gestion'];
const List<String> kNiveaux = ['Licence 1', 'Licence 2', 'Licence 3', 'Master 1', 'Master 2'];

class AdminProfesseurs extends StatefulWidget {
  final StudentProfile profile;
  const AdminProfesseurs({super.key, required this.profile});

  @override
  State<AdminProfesseurs> createState() => _AdminProfesseursState();
}

class _AdminProfesseursState extends State<AdminProfesseurs> {
  List<Map<String, dynamic>> _professeurs = [];
  List<Map<String, dynamic>> _filieres    = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  String _domaineDeFiliere(String filiereNom) {
    final f = filiereNom.toLowerCase();
    final estGestion = f.contains('marketing') || f.contains('gestion') || f.contains('finance') || f.contains('comptab');
    return estGestion ? 'Sciences de Gestion' : 'Sciences & Technologies';
  }

  Future<void> _charger() async {
    setState(() { _loading = true; _error = null; });
    try {
      final resFils = await ApiService.getFilieres();
      final resProfs = await ApiService.getProfesseurs();

      setState(() {
        final allFilieres = resFils['success'] == true
            ? List<Map<String, dynamic>>.from(resFils['data'])
            : <Map<String, dynamic>>[];
        final allProfs = resProfs['success'] == true
            ? List<Map<String, dynamic>>.from(resProfs['data'])
            : <Map<String, dynamic>>[];

        if (widget.profile.filtreParDomaine) {
          final String df = widget.profile.domaineAdmin;

          _filieres = allFilieres
              .where((f) => _domaineDeFiliere(f['nom'] ?? '') == df)
              .cast<Map<String, dynamic>>()
              .toList();
          _professeurs = allProfs
              .where((p) => (p['domaine'] ?? '').toString().toLowerCase().contains(df.toLowerCase()))
              .cast<Map<String, dynamic>>()
              .toList();
        } else {
          _filieres = allFilieres;
          _professeurs = allProfs;
        }

        _loading = false;
        _error = (_filieres.isEmpty && _professeurs.isEmpty) ? 'Erreur de chargement.' : null;
      });
    } catch (e) {
      setState(() { _error = 'Serveur injoignable.'; _loading = false; });
    }
  }

  void _ouvrirFormulaire({Map<String, dynamic>? prof}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FormulaireProf(
        profile: widget.profile,
        allFilieres: _filieres,
        domaineDeFiliere: _domaineDeFiliere,
        prof: prof,
        onSave: (data, affectations) async {
          await _sauvegarder(data, affectations, prof?['id']);
        },
      ),
    );
  }

  Future<void> _sauvegarder(
    Map<String, dynamic> data,
    List<Map<String, String>> affectations,
    String? id,
  ) async {
    try {
      final headers = await ApiService.getHeaders();
      http.Response res;
      if (id == null) {
        res = await http.post(
          Uri.parse('${ApiService.baseUrl}/professeurs'),
          headers: headers,
          body: jsonEncode({...data, 'affectations': affectations}),
        );
      } else {
        res = await http.put(
          Uri.parse('${ApiService.baseUrl}/professeurs/$id'),
          headers: headers,
          body: jsonEncode({...data, 'affectations': affectations}),
        );
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (!mounted) return;
        final nav = Navigator.of(context);
        await _charger();
        nav.pop();
        _snack(
          id == null
              ? 'Professeur créé. Il pourra se connecter avec son nom, prénom et téléphone.'
              : 'Professeur mis à jour avec succès.',
          success: true,
        );
      } else {
        final err = jsonDecode(res.body);
        _snack(err['error'] ?? 'Erreur lors de la sauvegarde.', success: false);
      }
    } catch (e) {
      _snack('Erreur: $e', success: false);
    }
  }

  Future<void> _supprimer(String id, String nom) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer le prof. $nom ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final headers = await ApiService.getHeaders();
        final res = await http.delete(
          Uri.parse('${ApiService.baseUrl}/professeurs/$id'),
          headers: headers,
        );
        if (res.statusCode == 200) {
          _snack('Professeur supprimé.', success: true);
          await _charger();
        } else {
          _snack('Erreur lors de la suppression.', success: false);
        }
      } catch (e) {
        _snack('Serveur injoignable.', success: false);
      }
    }
  }

  void _snack(String msg, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? Colors.green : Colors.red,
    ));
  }

  String _nomsFilieresProf(Map<String, dynamic> prof) {
    final affectations = prof['affectations'];
    if (affectations == null || (affectations as List).isEmpty) return 'Aucune filière';
    final Map<String, List<String>> parFiliere = {};
    for (final a in affectations) {
      final nom = a['filiere_nom']?.toString() ?? '';
      final niveau = a['niveau']?.toString() ?? '';
      parFiliere.putIfAbsent(nom, () => []).add(niveau);
    }
    return parFiliere.entries.map((e) => '${e.key} (${e.value.join(', ')})').join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Gestion des Professeurs',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(onPressed: _charger, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _ouvrirFormulaire(),
        backgroundColor: AppPalette.blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _charger, child: const Text('Réessayer')),
                ]))
              : _professeurs.isEmpty
                  ? const Center(
                      child: Text('Aucun professeur enregistré.',
                          style: TextStyle(color: Colors.grey, fontSize: 16)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _professeurs.length,
                      itemBuilder: (_, i) => _CarteProfesseur(
                        prof: _professeurs[i],
                        nomsFileres: _nomsFilieresProf(_professeurs[i]),
                        onEdit: () => _ouvrirFormulaire(prof: _professeurs[i]),
                        onDelete: () => _supprimer(
                          _professeurs[i]['id'].toString(),
                          '${_professeurs[i]['prenoms']} ${_professeurs[i]['nom']}',
                        ),
                      ),
                    ),
    );
  }
}

// ── Carte professeur ──────────────────────────────────────────────────────────
class _CarteProfesseur extends StatelessWidget {
  final Map<String, dynamic> prof;
  final String nomsFileres;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CarteProfesseur({
    required this.prof,
    required this.nomsFileres,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: AppPalette.blue.withValues(alpha: 0.15),
          child: Text(
            '${prof['prenoms']?[0] ?? ''}${prof['nom']?[0] ?? ''}',
            style: const TextStyle(fontSize: 16,
                fontWeight: FontWeight.bold, color: AppPalette.blue),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${prof['prenoms']} ${prof['nom']}',
              style: const TextStyle(fontSize: 15,
                  fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text('Tél : ${prof['tel'] ?? '-'}',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text('Domaine(s) : ${(prof['domaine'] ?? '').toString().isEmpty ? 'Non défini' : prof['domaine']}',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text('Filières : $nomsFileres',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: prof['statut'] == 'actif'
                  ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(prof['statut'] ?? 'actif',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                    color: prof['statut'] == 'actif'
                        ? Colors.green.shade700 : Colors.red.shade700)),
          ),
        ])),
        Column(children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppPalette.blue, size: 22),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
            onPressed: onDelete,
          ),
        ]),
      ]),
    );
  }
}

// ── Formulaire ajout/modification professeur ──────────────────────────────────
class _FormulaireProf extends StatefulWidget {
  final StudentProfile profile;
  final List<Map<String, dynamic>> allFilieres;
  final String Function(String) domaineDeFiliere;
  final Map<String, dynamic>? prof;
  // (data professeur, liste d'affectations [{filiere_id, niveau}])
  final Future<void> Function(Map<String, dynamic>, List<Map<String, String>>) onSave;

  const _FormulaireProf({
    required this.profile,
    required this.allFilieres,
    required this.domaineDeFiliere,
    required this.onSave,
    this.prof,
  });

  @override
  State<_FormulaireProf> createState() => _FormulaireProfState();
}

class _FormulaireProfState extends State<_FormulaireProf> {
  final _nomCtrl     = TextEditingController();
  final _prenomsCtrl = TextEditingController();
  final _telCtrl     = TextEditingController();
  final _emailCtrl   = TextEditingController();

  final Set<String> _domainesSelectionnes = {};
  // Clé = id de filière ; valeur = ensemble des niveaux choisis POUR CETTE filière.
  final Map<String, Set<String>> _affectationsParFiliere = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.prof != null) {
      _nomCtrl.text     = widget.prof!['nom'] ?? '';
      _prenomsCtrl.text = widget.prof!['prenoms'] ?? '';
      _telCtrl.text     = widget.prof!['tel'] ?? '';
      _emailCtrl.text   = widget.prof!['email'] ?? '';

      final domaineStr = (widget.prof!['domaine'] ?? '').toString();
      if (domaineStr.isNotEmpty) {
        for (final d in domaineStr.split(',').map((s) => s.trim())) {
          if (kDomaines.contains(d)) _domainesSelectionnes.add(d);
        }
      }

      final affectations = widget.prof!['affectations'];
      if (affectations != null) {
        for (final a in (affectations as List)) {
          final fid = a['filiere_id']?.toString();
          final niv = a['niveau']?.toString();
          if (fid == null) continue;
          _affectationsParFiliere.putIfAbsent(fid, () => {});
          if (niv != null) _affectationsParFiliere[fid]!.add(niv);
        }
      }
    } else if (widget.profile.filtreParDomaine) {
      _domainesSelectionnes.add(widget.profile.domaineAdmin);
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose(); _prenomsCtrl.dispose();
    _telCtrl.dispose(); _emailCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filieresFiltrees {
    if (_domainesSelectionnes.isEmpty) return [];
    return widget.allFilieres.where((f) {
      final d = widget.domaineDeFiliere(f['nom'] ?? '');
      return _domainesSelectionnes.contains(d);
    }).toList();
  }

  Future<void> _soumettre() async {
    if (_nomCtrl.text.isEmpty || _prenomsCtrl.text.isEmpty || _telCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Nom, prénom et téléphone sont obligatoires.'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    if (_domainesSelectionnes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Sélectionnez au moins un domaine.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final List<Map<String, String>> affectations = [];
    _affectationsParFiliere.forEach((fid, niveaux) {
      for (final niv in niveaux) {
        affectations.add({'filiere_id': fid, 'niveau': niv});
      }
    });

    setState(() => _saving = true);
    await widget.onSave(
      {
        'nom':      _nomCtrl.text.trim().toUpperCase(),
        'prenoms':  _prenomsCtrl.text.trim(),
        'tel':      _telCtrl.text.trim(),
        'email':    _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        'domaines': _domainesSelectionnes.toList(),
      },
      affectations,
    );
    setState(() => _saving = false);
  }

  Widget _champ(TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
    );
  }

  Widget _chipDomaine(String d, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppPalette.blue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppPalette.blue : const Color(0xFFE2E8F0), width: selected ? 2 : 1),
          boxShadow: selected
              ? [BoxShadow(color: AppPalette.blue.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (selected) ...[const Icon(Icons.check, color: Colors.white, size: 14), const SizedBox(width: 4)],
          Text(d, style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? Colors.white : const Color(0xFF0F172A),
          )),
        ]),
      ),
    );
  }

  Widget _chipNiveau(String niveau, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppPalette.blue.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppPalette.blue : const Color(0xFFE2E8F0)),
        ),
        child: Text(niveau, style: TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? AppPalette.blue : const Color(0xFF64748B),
        )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.prof != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: StatefulBuilder(
          builder: (context, setModalState) {
            void toggleDomaine(String d) {
              setModalState(() {
                if (_domainesSelectionnes.contains(d)) {
                  _domainesSelectionnes.remove(d);
                  _affectationsParFiliere.removeWhere((fid, _) {
                    final f = widget.allFilieres.firstWhere(
                      (x) => x['id'].toString() == fid,
                      orElse: () => {},
                    );
                    if (f.isEmpty) return false;
                    return !_domainesSelectionnes.contains(widget.domaineDeFiliere(f['nom'] ?? ''));
                  });
                } else {
                  _domainesSelectionnes.add(d);
                }
              });
            }

            void toggleFiliere(String fid) {
              setModalState(() {
                if (_affectationsParFiliere.containsKey(fid)) {
                  _affectationsParFiliere.remove(fid);
                } else {
                  _affectationsParFiliere[fid] = {};
                }
              });
            }

            void toggleNiveauPourFiliere(String fid, String niveau) {
              setModalState(() {
                final set = _affectationsParFiliere[fid];
                if (set == null) return;
                set.contains(niveau) ? set.remove(niveau) : set.add(niveau);
              });
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(isEdit ? 'Modifier le professeur' : 'Ajouter un professeur',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ]),
                const SizedBox(height: 16),

                if (!isEdit) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: const Row(children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 18),
                      SizedBox(width: 8),
                      Expanded(child: Text(
                        'Le professeur se connectera avec son nom, prénom et numéro de '
                        'téléphone, et définira son mot de passe lors de sa première connexion.',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      )),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],

                _champ(_nomCtrl, 'Nom de famille *', Icons.person_outline),
                const SizedBox(height: 12),
                _champ(_prenomsCtrl, 'Prénom(s) *', Icons.person_outline),
                const SizedBox(height: 12),
                _champ(_telCtrl, 'Numéro de téléphone *', Icons.phone_outlined, type: TextInputType.phone),
                const SizedBox(height: 12),
                _champ(_emailCtrl, 'Adresse email', Icons.email_outlined, type: TextInputType.emailAddress),
                const SizedBox(height: 20),

                const Text('Domaine(s)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                const Text('Le professeur peut enseigner dans un ou les deux domaines',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kDomaines.map((d) => _chipDomaine(
                    d, _domainesSelectionnes.contains(d), () => toggleDomaine(d),
                  )).toList(),
                ),
                const SizedBox(height: 20),

                const Text('Filières et niveaux',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Text(
                  _domainesSelectionnes.isEmpty
                      ? 'Sélectionnez d\'abord un domaine'
                      : 'Cochez une filière, puis choisissez le(s) niveau(x) pour cette filière',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 10),

                if (_filieresFiltrees.isEmpty)
                  const Text('Aucune filière disponible.', style: TextStyle(color: Colors.grey))
                else
                  Column(
                    children: _filieresFiltrees.map((f) {
                      final fid = f['id'].toString();
                      final nom = f['nom'] ?? '';
                      final filiereSelectionnee = _affectationsParFiliere.containsKey(fid);
                      final niveauxChoisis = _affectationsParFiliere[fid] ?? {};

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: filiereSelectionnee ? AppPalette.blue.withValues(alpha: 0.04) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: filiereSelectionnee ? AppPalette.blue.withValues(alpha: 0.4) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => toggleFiliere(fid),
                              child: Row(children: [
                                Icon(
                                  filiereSelectionnee ? Icons.check_box : Icons.check_box_outline_blank,
                                  color: filiereSelectionnee ? AppPalette.blue : const Color(0xFF94A3B8),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(nom, style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: filiereSelectionnee ? FontWeight.bold : FontWeight.normal,
                                  color: const Color(0xFF0F172A),
                                ))),
                              ]),
                            ),
                            if (filiereSelectionnee) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: kNiveaux.map((niv) => _chipNiveau(
                                  niv, niveauxChoisis.contains(niv), () => toggleNiveauPourFiliere(fid, niv),
                                )).toList(),
                              ),
                              if (niveauxChoisis.isEmpty) ...[
                                const SizedBox(height: 6),
                                const Text('Choisissez au moins un niveau pour cette filière.',
                                    style: TextStyle(fontSize: 11, color: Colors.orange)),
                              ],
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _soumettre,
                    icon: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Icon(isEdit ? Icons.save : Icons.add),
                    label: Text(
                      _saving ? 'Enregistrement...' : (isEdit ? 'Enregistrer' : 'Ajouter le professeur'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
