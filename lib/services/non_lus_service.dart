import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_service.dart';

/// Compteurs de messages non lus par canal (page « Canaux »).
///
/// - [total] alimente le badge rouge de l'icône « Canaux » de la barre du bas.
/// - [pour] donne le compteur d'un canal précis (badge rouge de sa carte).
/// Le serveur est interrogé toutes les 20 s, à l'ouverture de l'app et au
/// retour au premier plan. Ouvrir un canal le remet à zéro.
class NonLusService extends ChangeNotifier {
  NonLusService._();
  static final NonLusService instance = NonLusService._();

  Map<String, int> _parCanal = {};
  int _total = 0;
  int _prives = 0;
  int _reclamations = 0;
  int _cours = 0;
  int _planning = 0;
  int _bulletins = 0;
  String? _canalOuvert;
  Timer? _timer;
  bool _enCours = false;

  int get total => _total;

  /// Messages privés non lus (professeurs).
  int get prives => _prives;

  /// Réclamations à traiter par le professeur.
  int get reclamations => _reclamations;

  /// Nouveaux supports de cours / nouvel emploi du temps (étudiants).
  int get cours => _cours;
  int get planning => _planning;
  int get bulletins => _bulletins;

  /// À appeler à l'ouverture de « Cours » ou « Planning » : remet le marqueur à 0.
  Future<void> sectionVue(String section) async {
    if (section == 'cours' && _cours > 0) { _cours = 0; notifyListeners(); }
    if (section == 'planning' && _planning > 0) { _planning = 0; notifyListeners(); }
    if (section == 'bulletins' && _bulletins > 0) { _bulletins = 0; notifyListeners(); }
    try {
      await http
          .post(
            Uri.parse('${ApiService.baseUrl}/messages/sections/$section/vu'),
            headers: await ApiService.getHeaders(),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('[NonLusService] section vue: $e');
    }
  }

  /// Canaux + messages privés : marqueur de l'onglet « Messages » du professeur.
  int get totalMessages => _total + _prives;
  int pour(String? canalId) =>
      (canalId == null || canalId.isEmpty) ? 0 : (_parCanal[canalId] ?? 0);

  void demarrer() {
    _timer?.cancel();
    rafraichir();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => rafraichir());
  }

  /// À l'arrêt (déconnexion) : pas de notification, l'écran est déjà démonté.
  void arreter() {
    _timer?.cancel();
    _timer = null;
    _parCanal = {};
    _total = 0;
    _prives = 0;
    _reclamations = 0;
    _cours = 0;
    _planning = 0;
    _bulletins = 0;
    _canalOuvert = null;
  }

  Future<void> rafraichir() async {
    if (_enCours) return;
    _enCours = true;
    try {
      final res = await http
          .get(
            Uri.parse('${ApiService.baseUrl}/messages/canaux/non-lus'),
            headers: await ApiService.getHeaders(),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return;
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      final data = body is Map ? body['data'] : null;
      if (data is! Map) return;
      final nouveau = <String, int>{
        for (final e in data.entries)
          e.key.toString(): int.tryParse('${e.value}') ?? 0,
      };
      // Le canal actuellement ouvert est en train d'être lu : jamais « non lu ».
      final ouvert = _canalOuvert;
      if (ouvert != null && (nouveau[ouvert] ?? 0) > 0) {
        nouveau[ouvert] = 0;
        _envoyerLu(ouvert);
      }
      _parCanal = nouveau;
      _total = nouveau.values.fold<int>(0, (a, b) => a + b);
      _prives = int.tryParse('${(body as Map)['prives'] ?? 0}') ?? 0;
      _reclamations = int.tryParse('${body['reclamations'] ?? 0}') ?? 0;
      _cours = int.tryParse('${body['cours'] ?? 0}') ?? 0;
      _planning = int.tryParse('${body['planning'] ?? 0}') ?? 0;
      _bulletins = int.tryParse('${body['bulletins'] ?? 0}') ?? 0;
      notifyListeners();
    } catch (e) {
      debugPrint('[NonLusService] $e');
    } finally {
      _enCours = false;
    }
  }

  /// À appeler à l'entrée dans un canal.
  void canalOuvert(String canalId) {
    _canalOuvert = canalId;
    marquerLu(canalId);
  }

  /// À appeler à la sortie d'un canal.
  Future<void> canalFerme(String canalId) async {
    if (_canalOuvert == canalId) _canalOuvert = null;
    await marquerLu(canalId);
    await rafraichir();
  }

  Future<void> marquerLu(String canalId) async {
    if ((_parCanal[canalId] ?? 0) > 0) {
      _parCanal = {..._parCanal, canalId: 0};
      _total = _parCanal.values.fold<int>(0, (a, b) => a + b);
      notifyListeners();
    }
    await _envoyerLu(canalId);
  }

  Future<void> _envoyerLu(String canalId) async {
    try {
      await http
          .post(
            Uri.parse('${ApiService.baseUrl}/messages/canaux/$canalId/lu'),
            headers: await ApiService.getHeaders(),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('[NonLusService] marquer lu: $e');
    }
  }
}