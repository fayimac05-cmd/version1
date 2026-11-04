import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

/// Fenêtre « Changer mon mot de passe » commune à l'étudiant, au professeur
/// et à l'administration. Appelle POST /auth/change-password.
Future<void> showChangePasswordSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ChangePasswordSheet(),
  );
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();
  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _ancien = TextEditingController();
  final _nouveau = TextEditingController();
  final _confirm = TextEditingController();
  bool _voirAncien = false;
  bool _voirNouveau = false;
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _ancien.dispose();
    _nouveau.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    final a = _ancien.text;
    final n = _nouveau.text;
    if (a.isEmpty || n.isEmpty || _confirm.text.isEmpty) {
      setState(() => _erreur = 'Remplis tous les champs.');
      return;
    }
    if (n.length < 8) {
      setState(() => _erreur = 'Le nouveau mot de passe doit contenir au moins 8 caractères.');
      return;
    }
    if (n != _confirm.text) {
      setState(() => _erreur = 'La confirmation ne correspond pas.');
      return;
    }
    if (n == a) {
      setState(() => _erreur = "Le nouveau mot de passe doit être différent de l'ancien.");
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      final res = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/auth/change-password'),
            headers: await ApiService.getHeaders(),
            body: jsonEncode({'ancienMotDePasse': a, 'nouveauMotDePasse': n}),
          )
          .timeout(const Duration(seconds: 20));
      Map body = {};
      try {
        body = jsonDecode(utf8.decode(res.bodyBytes)) as Map;
      } catch (_) {}
      if (!mounted) return;
      if (res.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mot de passe modifié avec succès.'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      } else {
        setState(() {
          _envoi = false;
          _erreur = (body['message'] ?? 'Impossible de changer le mot de passe.').toString();
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _envoi = false;
        _erreur = 'Connexion impossible. Réessaie.';
      });
    }
  }

  InputDecoration _deco(String label, {Widget? suffixe}) => InputDecoration(
        labelText: label,
        suffixIcon: suffixe,
        filled: true,
        fillColor: const Color(0xFFF5F7FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Changer mon mot de passe',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF172033))),
                const SizedBox(height: 4),
                const Text('8 caractères minimum.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 16),
                TextField(
                  controller: _ancien,
                  obscureText: !_voirAncien,
                  decoration: _deco(
                    'Ancien mot de passe',
                    suffixe: IconButton(
                      icon: Icon(_voirAncien ? Icons.visibility_off : Icons.visibility, size: 20),
                      onPressed: () => setState(() => _voirAncien = !_voirAncien),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nouveau,
                  obscureText: !_voirNouveau,
                  decoration: _deco(
                    'Nouveau mot de passe',
                    suffixe: IconButton(
                      icon: Icon(_voirNouveau ? Icons.visibility_off : Icons.visibility, size: 20),
                      onPressed: () => setState(() => _voirNouveau = !_voirNouveau),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirm,
                  obscureText: !_voirNouveau,
                  decoration: _deco('Confirmer le nouveau mot de passe'),
                  onSubmitted: (_) => _valider(),
                ),
                if (_erreur != null) ...[
                  const SizedBox(height: 10),
                  Text(_erreur!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12.5, fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _envoi ? null : _valider,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A4DA2),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _envoi
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
