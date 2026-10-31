import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/etablissement_config.dart';
import '../theme/app_palette.dart';
import '../services/api_service.dart';
import 'auth_page.dart';
import '../widgets/scolarhub_logo.dart';

// ════════════════════════════════════════════════════════════════════════════
class Etablissement {
  final int? id;
  final String code;
  final String modeleMatricule;
  final String nom;
  final String abreviation;
  final String ville;
  final String campus;
  final String logoUrl;

  /// Photo d'accueil (page de bienvenue après le code) — distincte du logo officiel.
  final String photoAccueilUrl;
  final bool disponible;

  /// Type d'établissement — détermine les sections, options et le
  /// vocabulaire de l'app (voir EtablissementConfig).
  final TypeEtablissement type;

  const Etablissement({
    this.id,
    this.code = '',
    this.modeleMatricule = '',
    required this.nom,
    required this.abreviation,
    required this.ville,
    this.campus = '',
    this.logoUrl = '',
    this.photoAccueilUrl = '',
    this.disponible = true,
    this.type = TypeEtablissement.superieur,
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
// Saisie du code d'établissement : remplace l'ancienne liste publique des
// écoles. Le code est donné par l'établissement (affichage, lien, QR code…).
class ChooseSchoolPage extends StatefulWidget {
  const ChooseSchoolPage({super.key});

  @override
  State<ChooseSchoolPage> createState() => _ChooseSchoolPageState();
}

class _ChooseSchoolPageState extends State<ChooseSchoolPage> {
  final TextEditingController _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  // Établissement reconnu : on affiche son logo avant de passer à l'étape suivante.
  Etablissement? _trouve;

  @override
  void initState() {
    super.initState();
    // Pré-remplit avec le dernier code utilisé sur cet appareil.
    SharedPreferences.getInstance().then((p) {
      final saved = p.getString('etablissement_code') ?? '';
      if (mounted && saved.isNotEmpty && _codeCtrl.text.isEmpty) {
        setState(() => _codeCtrl.text = saved);
      }
    }).catchError((_) {});
  }

  TypeEtablissement _typeDepuis(String? t) {
    final v = (t ?? '').toLowerCase().replaceAll('_', '').replaceAll('-', '');
    for (final x in TypeEtablissement.values) {
      if (x.name.toLowerCase() == v) return x;
    }
    return TypeEtablissement.superieur;
  }

  Future<void> _continuer() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _error = "Saisissez le code de votre établissement.");
      return;
    }
    setState(() { _loading = true; _error = null; });

    final res = await ApiService.getEtablissementParCode(code);
    if (!mounted) return;
    if (res['success'] != true) {
      setState(() {
        _loading = false;
        _error = res['error']?.toString() ?? "Code d'établissement inconnu.";
      });
      return;
    }

    final e = Map<String, dynamic>.from(res['etablissement'] as Map);
    final type = _typeDepuis(e['type']?.toString());
    final etab = Etablissement(
      id: e['id'] is int ? e['id'] as int : int.tryParse('${e['id']}'),
      code: code.toUpperCase(),
      modeleMatricule: (e['modele_matricule'] ?? '').toString(),
      nom: (e['nom'] ?? '').toString(),
      abreviation: (e['sigle'] ?? '').toString().isNotEmpty
          ? e['sigle'].toString()
          : (e['nom'] ?? '').toString(),
      ville: (e['ville'] ?? '').toString(),
      campus: (e['campus'] ?? '').toString(),
      logoUrl: (e['logo_url'] ?? '').toString(),
      photoAccueilUrl: (e['photo_accueil_url'] ?? '').toString(),
      type: type,
    );

    // L'app s'adapte à l'établissement (nom, logo, type, sections, vocabulaire)
    // et retient son code pour toutes les requêtes suivantes.
    await EtablissementConfig.instance.appliquerEtablissement(
      id: etab.id,
      nom: etab.nom,
      sigle: etab.abreviation,
      ville: etab.ville,
      campus: etab.campus,
      code: etab.code,
      modeleMatricule: etab.modeleMatricule,
      inscriptionOuverte: e['inscription_ouverte'] == true,
      logoUrl: etab.logoUrl,
      type: etab.type,
    );
    if (!mounted) return;
    setState(() { _loading = false; _trouve = etab; });
  }

  void _allerConnexion() {
    final etab = _trouve;
    if (etab == null) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => AuthPage(etablissement: etab),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOut)),
          child: child,
        ),
      ),
    );
  }

  /// Initiales de l'école, affichées quand elle n'a pas de photo d'accueil.
  Widget _initiales(Etablissement e) {
    final t = (e.abreviation.isNotEmpty ? e.abreviation : e.nom).trim();
    final ini = t.length <= 4 ? t.toUpperCase() : t.substring(0, 3).toUpperCase();
    return Container(
      color: AppPalette.blue,
      alignment: Alignment.center,
      child: Text(ini, style: const TextStyle(color: Colors.white, fontSize: 30,
          fontWeight: FontWeight.bold, letterSpacing: 1)),
    );
  }

  // Étape intermédiaire : logo + nom de l'école, avant le matricule / mot de passe.
  // Avec photo d'accueil : la photo remplit l'écran (floutée en fond) et s'affiche en grand,
  // entière, au-dessus du nom de l'école.
  Widget _buildTrouvePhoto(Etablissement e) {
    final h = MediaQuery.of(context).size.height;
    final lieu = [e.ville, e.campus].where((x) => x.trim().isNotEmpty).join(' · ');
    return Scaffold(
      backgroundColor: const Color(0xFF0B1E4D),
      body: Stack(fit: StackFit.expand, children: [
        Image.network(e.photoAccueilUrl, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF0B1E4D))),
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
            child: Container(color: Colors.black.withValues(alpha: 0.5)),
          ),
        ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  builder: (_, v, child) => Opacity(
                    opacity: v,
                    child: Transform.translate(offset: Offset(0, 18 * (1 - v)), child: child),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    // La photo garde ses proportions : le cadre épouse l'image (pas de bandes
                    // vides sur les côtés), avec coins arrondis, fin liseré blanc et ombre douce.
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 36, offset: const Offset(0, 14)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.network(
                          e.photoAccueilUrl,
                          height: (h * 0.58).clamp(240.0, 620.0),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => SizedBox(
                              width: 240, height: 240, child: _initiales(e)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text('Bienvenue à', style: TextStyle(fontSize: 14, color: Colors.white70)),
                    const SizedBox(height: 6),
                    Text(e.nom, textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
                            color: Colors.white, height: 1.25, letterSpacing: -0.3)),
                    if (lieu.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(lieu, textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: Colors.white70)),
                    ],
                    const SizedBox(height: 24),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: SizedBox(
                        width: double.infinity, height: 56,
                        child: ElevatedButton(
                          onPressed: _allerConnexion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppPalette.blue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text('Continuer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(width: 10),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() => _trouve = null),
                      child: const Text("Ce n'est pas mon établissement",
                          style: TextStyle(color: Colors.white70)),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildTrouve(Etablissement e) {
    if (e.photoAccueilUrl.isNotEmpty) return _buildTrouvePhoto(e);
    final lieu = [e.ville, e.campus].where((x) => x.trim().isNotEmpty).join(' · ');
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOut,
                builder: (_, v, child) => Opacity(
                  opacity: v,
                  child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: child),
                ),
                child: Column(children: [
                  // Sans photo d'accueil : initiales de l'école (le logo officiel est réservé aux documents).
                  Container(
                      width: 132, height: 132,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 18, offset: const Offset(0, 6))],
                      ),
                      child: _initiales(e),
                    ),
                  const SizedBox(height: 24),
                  const Text('Bienvenue à', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  Text(e.nom, textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A), height: 1.25, letterSpacing: -0.3)),
                  if (lieu.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(lieu, textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton(
                      onPressed: _allerConnexion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('Continuer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(width: 10),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() => _trouve = null),
                    child: const Text("Ce n'est pas mon établissement",
                        style: TextStyle(color: Color(0xFF64748B))),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_trouve != null) return _buildTrouve(_trouve!);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 8),
                Row(children: [
                  ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: const ScolarHubLogo(size: 56)),
                  const SizedBox(width: 14),
                  const Text('ScolarHub', style: TextStyle(fontSize: 26,
                      fontWeight: FontWeight.bold, color: AppPalette.blue,
                      letterSpacing: -0.3)),
                ]),
                const SizedBox(height: 32),
                const Text('Code de votre\nétablissement',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A), height: 1.25, letterSpacing: -0.4)),
                const SizedBox(height: 10),
                const Text(
                    "Saisissez le code donné par votre école ou université pour accéder à votre espace.",
                    style: TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.55)),
                const SizedBox(height: 28),
                Container(
                  decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8, offset: const Offset(0, 2))]),
                  child: TextField(
                    controller: _codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) { if (_error != null) setState(() => _error = null); },
                    onSubmitted: (_) { if (!_loading) _continuer(); },
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A), letterSpacing: 1.2),
                    decoration: const InputDecoration(
                      hintText: 'Ex : IST2026',
                      hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 15,
                          fontWeight: FontWeight.w400, letterSpacing: 0),
                      prefixIcon: Icon(Icons.vpn_key_outlined, color: Color(0xFF64748B), size: 22),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEF9A9A)),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.error_outline, color: Color(0xFFC62828), size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_error!, style: const TextStyle(
                          fontSize: 14, color: Color(0xFFC62828), height: 1.4))),
                    ]),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _continuer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.blue,
                      disabledBackgroundColor: const Color(0xFFE2E8F0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text('Continuer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(width: 10),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ]),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text("Vous n'avez pas de code ? Demandez-le à l'administration de votre établissement.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.5)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() { _codeCtrl.dispose(); super.dispose(); }
}