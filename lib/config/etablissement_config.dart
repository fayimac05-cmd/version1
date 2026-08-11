// ============================================================
// etablissement_config.dart — Configuration multi-établissement
//
// Chaque client (un lycée seul, un collège-lycée, une école
// supérieure, un complexe scolaire…) a un TYPE d'établissement.
// Ce type détermine :
//   - les sections d'enseignement actives (primaire / secondaire / supérieur)
//   - les options disponibles (cantine, bus, BDE…)
//   - le vocabulaire de l'interface (étudiant / élève / écolier…)
//
// Toute l'app se construit à partir de cette config, chargée au
// démarrage et persistée dans SharedPreferences (en attendant la
// table `etablissements` côté backend).
// ============================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════
// Sections d'enseignement
// ═══════════════════════════════════════════════════════════════

enum SectionEnseignement { primaire, secondaire, superieur }

// ═══════════════════════════════════════════════════════════════
// Types d'établissement (le choix du client)
// ═══════════════════════════════════════════════════════════════

enum TypeEtablissement {
  primaire,
  college,
  lycee,
  collegeLycee,
  superieur,
  complexe,
}

extension TypeEtablissementInfos on TypeEtablissement {
  String get label {
    switch (this) {
      case TypeEtablissement.primaire:
        return 'École primaire';
      case TypeEtablissement.college:
        return 'Collège';
      case TypeEtablissement.lycee:
        return 'Lycée';
      case TypeEtablissement.collegeLycee:
        return 'Collège & Lycée';
      case TypeEtablissement.superieur:
        return 'École supérieure / Université';
      case TypeEtablissement.complexe:
        return 'Complexe scolaire';
    }
  }

  String get description {
    switch (this) {
      case TypeEtablissement.primaire:
        return 'Classes du CP1 au CM2, maîtres titulaires, cantine.';
      case TypeEtablissement.college:
        return 'Classes de la 6e à la 3e, enseignants par matière.';
      case TypeEtablissement.lycee:
        return 'Classes de la 2nde à la Tle, séries et conseils de classe.';
      case TypeEtablissement.collegeLycee:
        return 'Tout le secondaire, de la 6e à la Tle, géré ensemble.';
      case TypeEtablissement.superieur:
        return 'Filières, modules, semestres, BDE et vie étudiante.';
      case TypeEtablissement.complexe:
        return 'Plusieurs sections : primaire, secondaire et/ou supérieur.';
    }
  }

  IconData get icon {
    switch (this) {
      case TypeEtablissement.primaire:
        return Icons.auto_stories_rounded;
      case TypeEtablissement.college:
        return Icons.apartment_rounded;
      case TypeEtablissement.lycee:
        return Icons.account_balance_rounded;
      case TypeEtablissement.collegeLycee:
        return Icons.domain_rounded;
      case TypeEtablissement.superieur:
        return Icons.school_rounded;
      case TypeEtablissement.complexe:
        return Icons.holiday_village_rounded;
    }
  }

  /// Sections d'enseignement couvertes par ce type d'établissement.
  Set<SectionEnseignement> get sections {
    switch (this) {
      case TypeEtablissement.primaire:
        return {SectionEnseignement.primaire};
      case TypeEtablissement.college:
      case TypeEtablissement.lycee:
      case TypeEtablissement.collegeLycee:
        return {SectionEnseignement.secondaire};
      case TypeEtablissement.superieur:
        return {SectionEnseignement.superieur};
      case TypeEtablissement.complexe:
        return {
          SectionEnseignement.primaire,
          SectionEnseignement.secondaire,
          SectionEnseignement.superieur,
        };
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// Options / feature flags
// ═══════════════════════════════════════════════════════════════

class EtablissementOptions {
  bool cantine;
  bool bus;
  bool bde;
  bool paiementMobile;

  EtablissementOptions({
    this.cantine = true,
    this.bus = true,
    this.bde = true,
    this.paiementMobile = true,
  });

  /// Options par défaut selon le type d'établissement.
  factory EtablissementOptions.pourType(TypeEtablissement type) {
    switch (type) {
      case TypeEtablissement.primaire:
        return EtablissementOptions(bde: false);
      case TypeEtablissement.college:
      case TypeEtablissement.lycee:
      case TypeEtablissement.collegeLycee:
        return EtablissementOptions(bde: false);
      case TypeEtablissement.superieur:
        return EtablissementOptions(cantine: false, bus: false);
      case TypeEtablissement.complexe:
        return EtablissementOptions();
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// Configuration globale (singleton)
// ═══════════════════════════════════════════════════════════════

class EtablissementConfig extends ChangeNotifier {
  EtablissementConfig._();
  static final EtablissementConfig instance = EtablissementConfig._();

  TypeEtablissement _type = TypeEtablissement.superieur;
  EtablissementOptions _options =
      EtablissementOptions.pourType(TypeEtablissement.superieur);

  TypeEtablissement get type => _type;
  EtablissementOptions get options => _options;
  Set<SectionEnseignement> get sectionsActives => _type.sections;

  bool sectionActive(SectionEnseignement s) => sectionsActives.contains(s);
  bool get aPlusieursSections => sectionsActives.length > 1;

  /// Applique un type d'établissement (choix du client) et persiste.
  Future<void> appliquerType(TypeEtablissement type) async {
    _type = type;
    _options = EtablissementOptions.pourType(type);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('etablissement_type', type.name);
  }

  /// Recharge la config persistée (à appeler au démarrage).
  Future<void> charger() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('etablissement_type');
    if (saved != null) {
      _type = TypeEtablissement.values.firstWhere(
        (t) => t.name == saved,
        orElse: () => TypeEtablissement.superieur,
      );
      _options = EtablissementOptions.pourType(_type);
      notifyListeners();
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// Vocabulaire dynamique selon le type d'établissement
// ═══════════════════════════════════════════════════════════════

class Vocab {
  Vocab._();

  static TypeEtablissement get _type => EtablissementConfig.instance.type;

  /// « étudiant » / « élève » / « écolier »
  static String get apprenant {
    switch (_type) {
      case TypeEtablissement.primaire:
        return 'écolier';
      case TypeEtablissement.college:
      case TypeEtablissement.lycee:
      case TypeEtablissement.collegeLycee:
        return 'élève';
      case TypeEtablissement.superieur:
      case TypeEtablissement.complexe:
        return 'étudiant';
    }
  }

  static String get apprenants => '${apprenant}s';

  /// « filière » / « classe »
  static String get groupe =>
      _type == TypeEtablissement.superieur ? 'filière' : 'classe';

  /// « semestre » / « trimestre »
  static String get periode =>
      _type == TypeEtablissement.superieur ? 'semestre' : 'trimestre';

  /// « professeur » / « enseignant » / « maître »
  static String get enseignant {
    switch (_type) {
      case TypeEtablissement.primaire:
        return 'maître';
      case TypeEtablissement.superieur:
        return 'professeur';
      default:
        return 'enseignant';
    }
  }
}
