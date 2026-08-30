import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/student_profile.dart';
import '../theme/app_palette.dart';
import '../services/api_service.dart';
const String _baseUrl = 'http://localhost:5000/api';

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
          
          // Déduire le domaine de la filière pour le filtrage
          bool estMemeDomaineFiliere(String filiereNom) {
            final f = filiereNom.toLowerCase();
            final estGestion = f.contains('marketing') || f.contains('gestion') || f.contains('finance') || f.contains('comptab');
            final domaineFiliere = estGestion ? 'Sciences de Gestion' : 'Sciences & Technologies';
            return domaineFiliere == df;
          }

          _filieres = allFilieres
              .where((f) => estMemeDomaineFiliere(f['nom'] ?? ''))
              .cast<Map<String, dynamic>>()
              .toList();
          _professeurs = allProfs
              .where((p) => (p['domaine'] ?? '').toString().toLowerCase() == df.toLowerCase())
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
        filieres: _filieres,
        prof: prof,
        onSave: (data, filieresSelectionnees) async {
          await _sauvegarder(data, filieresSelectionnees, prof?['id']);
        },
      ),
    );
  }

  Future<void> _sauvegarder(
    Map<String, dynamic> data,
    List<String> filieresIds,
    String? id,
  ) async {
    try {
      final headers = await ApiService.getHeaders();
      http.Response res;
      if (id == null) {
        res = await http.post(
          Uri.parse('${ApiService.baseUrl}/professeurs'),
          headers: headers,
          body: jsonEncode({...data, 'filieres_ids': filieresIds}),
        );
      } else {
        res = await http.put(
          Uri.parse('${ApiService.baseUrl}/professeurs/$id'),
          headers: headers,
          body: jsonEncode({...data, 'filieres_ids': filieresIds}),
        );
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body);
        Navigator.pop(context);
        await _charger();
        if (id == null && body['identifiants'] != null) {
          _afficherIdentifiants(body['identifiants'], body['professeur']);
        } else {
          _snack('Professeur mis à jour avec succès.', success: true);
        }
      } else {
        final err = jsonDecode(res.body);
        _snack(err['error'] ?? 'Erreur lors de la sauvegarde.', success: false);
      }
    } catch (e) {
      _snack('Erreur: $e', success: false);
    }
  }
  void _afficherIdentifiants(Map<String, dynamic> ids, Map<String, dynamic> prof) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 10),
          Text('Professeur créé !', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${prof['prenoms']} ${prof['nom']} a été ajouté avec succès.',
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            const Text('Identifiants de connexion :', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _ligneInfo('Matricule', ids['matricule'] ?? ''),
            _ligneInfo('Mot de passe', ids['motDePasse'] ?? ''),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Text(
                ids['info'] ?? '',
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _ligneInfo(String label, String valeur) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Text('$label : ', style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Expanded(child: Text(valeur,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
      ]),
    );
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
        final res = await http.delete(Uri.parse('$_baseUrl/professeurs/$id'));
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
    if (prof['filieres'] == null) return 'Aucune filière';
    final List filieres = prof['filieres'] as List;
    if (filieres.isEmpty) return 'Aucune filière';
    return filieres.map((f) => f['nom']).join(', ');
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
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: AppPalette.blue.withOpacity(0.15),
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
          Text('Matricule : ${prof['matricule'] ?? 'Non défini'}',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text('Tél : ${prof['tel'] ?? '-'}',
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
  final List<Map<String, dynamic>> filieres;
  final Map<String, dynamic>? prof;
  final Future<void> Function(Map<String, dynamic>, List<String>) onSave;

  const _FormulaireProf({
    required this.profile,
    required this.filieres,
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
  final _domaineCtrl = TextEditingController();

  // Filières sélectionnées (multi-sélection)
  final Set<String> _filieresSelectionnees = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.prof != null) {
      _nomCtrl.text     = widget.prof!['nom'] ?? '';
      _prenomsCtrl.text = widget.prof!['prenoms'] ?? '';
      _telCtrl.text     = widget.prof!['tel'] ?? '';
      _emailCtrl.text   = widget.prof!['email'] ?? '';
      _domaineCtrl.text = widget.prof!['domaine'] ?? '';

      // Pré-sélectionner les filières déjà assignées
      if (widget.prof!['filieres'] != null) {
        final List filieres = widget.prof!['filieres'] as List;
        for (final f in filieres) {
          _filieresSelectionnees.add(f['id'].toString());
        }
      }
    } else {
      if (widget.profile.filtreParDomaine) {
        _domaineCtrl.text = widget.profile.domaineAdmin;
      }
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose(); _prenomsCtrl.dispose();
    _telCtrl.dispose(); _emailCtrl.dispose();
    _domaineCtrl.dispose();
    super.dispose();
  }

  Future<void> _soumettre() async {
    if (_nomCtrl.text.isEmpty || _prenomsCtrl.text.isEmpty || _telCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Nom, prénom et téléphone sont obligatoires.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _saving = true);
    await widget.onSave(
      {
        'nom':     _nomCtrl.text.trim().toUpperCase(),
        'prenoms': _prenomsCtrl.text.trim(),
        'tel':     _telCtrl.text.trim(),
        'email':   _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        'domaine': _domaineCtrl.text.trim().isEmpty ? null : _domaineCtrl.text.trim(),
      },
      _filieresSelectionnees.toList(),
    );
    setState(() => _saving = false);
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(isEdit ? 'Modifier le professeur' : 'Ajouter un professeur',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close)),
            ]),
            const SizedBox(height: 16),

            // Info matricule auto
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
                    'Un matricule PROF-XXXX sera généré automatiquement. '
                    'Le mot de passe par défaut sera le numéro de téléphone.',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  )),
                ]),
              ),
              const SizedBox(height: 16),
            ],

            // Champs texte
            _champ(_nomCtrl, 'Nom de famille *', Icons.person_outline),
            const SizedBox(height: 12),
            _champ(_prenomsCtrl, 'Prénom(s) *', Icons.person_outline),
            const SizedBox(height: 12),
            _champ(_telCtrl, 'Numéro de téléphone *', Icons.phone_outlined,
                type: TextInputType.phone),
            const SizedBox(height: 12),
            _champ(_emailCtrl, 'Adresse email', Icons.email_outlined,
                type: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _champ(_domaineCtrl, 'Domaine / Spécialité', Icons.school_outlined,
                readOnly: widget.profile.filtreParDomaine),
            const SizedBox(height: 20),

            // Sélection multiple des filières
            const Text('Filières assignées',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A))),
            const SizedBox(height: 4),
            const Text('Sélectionnez une ou plusieurs filières',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),

            widget.filieres.isEmpty
                ? const Text('Aucune filière disponible.',
                    style: TextStyle(color: Colors.grey))
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.filieres.map((f) {
                      final id = f['id'].toString();
                      final nom = f['nom'] ?? '';
                      final selected = _filieresSelectionnees.contains(id);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (selected) {
                              _filieresSelectionnees.remove(id);
                            } else {
                              _filieresSelectionnees.add(id);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppPalette.blue
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? AppPalette.blue
                                  : const Color(0xFFE2E8F0),
                              width: selected ? 2 : 1,
                            ),
                            boxShadow: selected
                                ? [BoxShadow(
                                    color: AppPalette.blue.withOpacity(0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2))]
                                : [],
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            if (selected) ...[
                              const Icon(Icons.check, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                            ],
                            Text(nom,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: selected
                                      ? FontWeight.bold : FontWeight.normal,
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                )),
                          ]),
                        ),
                      );
                    }).toList(),
                  ),

            // Résumé sélection
            if (_filieresSelectionnees.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                '${_filieresSelectionnees.length} filière(s) sélectionnée(s)',
                style: TextStyle(
                    fontSize: 12,
                    color: AppPalette.blue,
                    fontWeight: FontWeight.w600),
              ),
            ],

            const SizedBox(height: 24),

            // Bouton soumettre
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _soumettre,
                icon: _saving
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Icon(isEdit ? Icons.save : Icons.add),
                label: Text(
                  _saving
                      ? 'Enregistrement...'
                      : (isEdit ? 'Enregistrer' : 'Ajouter le professeur'),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _champ(TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text, bool readOnly = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      readOnly: readOnly,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: readOnly ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: readOnly ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0)),
        ),
      ),
    );
  }
}
