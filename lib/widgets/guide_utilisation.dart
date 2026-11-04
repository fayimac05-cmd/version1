import 'package:flutter/material.dart';

/// Guide d'utilisation de ScolarHub — un contenu par espace.
/// Chaque espace n'ouvre que SON guide : l'étudiant ne voit jamais les
/// procédures du professeur ou de l'administration (et inversement).
enum GuideRole { admin, professeur, etudiant }

class GuideSection {
  const GuideSection({
    required this.icone,
    required this.titre,
    required this.resume,
    required this.etapes,
    this.astuce,
    this.menu, // admin : indice de l'entrée de menu (filtre selon les droits)
  });
  final IconData icone;
  final String titre;
  final String resume;
  final List<String> etapes;
  final String? astuce;
  final int? menu;
}

class GuideUtilisationPage extends StatefulWidget {
  const GuideUtilisationPage({super.key, required this.role, this.peutVoir});
  final GuideRole role;

  /// Admin : indique si l'entrée de menu [i] est accessible à ce membre.
  final bool Function(int)? peutVoir;

  @override
  State<GuideUtilisationPage> createState() => _GuideUtilisationPageState();
}

class _GuideUtilisationPageState extends State<GuideUtilisationPage> {
  static const _bleu = Color(0xFF0A3D91);
  String _q = '';

  String get _titre => switch (widget.role) {
        GuideRole.admin => "Guide de l'administration",
        GuideRole.professeur => 'Guide du professeur',
        GuideRole.etudiant => "Guide de l'étudiant",
      };

  List<GuideSection> get _sections {
    final base = switch (widget.role) {
      GuideRole.admin => _guideAdmin,
      GuideRole.professeur => _guideProfesseur,
      GuideRole.etudiant => _guideEtudiant,
    };
    final visibles = base.where((s) {
      if (widget.role != GuideRole.admin || s.menu == null || widget.peutVoir == null) return true;
      return widget.peutVoir!(s.menu!);
    }).toList();
    final q = _q.trim().toLowerCase();
    if (q.isEmpty) return visibles;
    return visibles
        .where((s) =>
            s.titre.toLowerCase().contains(q) ||
            s.resume.toLowerCase().contains(q) ||
            s.etapes.any((e) => e.toLowerCase().contains(q)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: _bleu,
        foregroundColor: Colors.white,
        title: Text(_titre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(children: [
                  Icon(Icons.menu_book_rounded, color: _bleu, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Touchez une rubrique pour voir ce que vous pouvez faire et comment le faire. '
                      'Vous pouvez aussi chercher un mot (ex. « mot de passe », « note »).',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF1E3A8A), height: 1.4),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (v) => setState(() => _q = v),
                decoration: InputDecoration(
                  hintText: 'Rechercher dans le guide…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              if (sections.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Aucun résultat.', style: TextStyle(color: Color(0xFF64748B)))),
                ),
              for (final s in sections) _carte(s),
              const SizedBox(height: 8),
              const Center(
                child: Text("Une question ? Contactez l'administration de votre établissement.",
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _carte(GuideSection s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey('${widget.role.name}_${s.titre}_$_q'),
          initiallyExpanded: _q.trim().isNotEmpty,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: _bleu.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(11)),
            child: Icon(s.icone, color: _bleu, size: 20),
          ),
          title: Text(s.titre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          subtitle: Text(s.resume, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
          children: [
            for (var i = 0; i < s.etapes.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: _bleu, shape: BoxShape.circle),
                    child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(s.etapes[i], style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF1E293B))),
                  ),
                ]),
              ),
            if (s.astuce != null)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFFF7E0), borderRadius: BorderRadius.circular(10)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.lightbulb_outline_rounded, size: 16, color: Color(0xFFB7791F)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(s.astuce!, style: const TextStyle(fontSize: 12, color: Color(0xFF7A5200), height: 1.35))),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  ÉTUDIANT
// ═════════════════════════════════════════════════════════════════════════════
const _guideEtudiant = <GuideSection>[
  GuideSection(
    icone: Icons.login_rounded,
    titre: 'Se connecter et gérer son compte',
    resume: 'Première connexion, mot de passe, déconnexion',
    etapes: [
      "Ouvrez l'application, choisissez votre établissement puis connectez-vous avec le matricule et le mot de passe remis par l'administration.",
      "Pour changer votre mot de passe : ouvrez le menu (en haut à gauche) puis « Changer mon mot de passe », ou rendez-vous dans l'onglet « Profil ».",
      'Si vous avez oublié votre mot de passe, demandez à l\'administration de le réinitialiser : un nouveau mot de passe provisoire vous sera donné.',
      'Pour quitter : menu → « Se déconnecter ».',
    ],
    astuce: 'Changez le mot de passe provisoire dès votre première connexion et ne le communiquez à personne.',
  ),
  GuideSection(
    icone: Icons.lock_clock_rounded,
    titre: 'Rester connecté (session)',
    resume: "Entrer directement dans l'application sans ressaisir vos informations",
    etapes: [
      "Par défaut, une fois connecté vous restez connecté 30 jours : en rouvrant l'application, vous entrez directement dans votre espace.",
      "Si vous touchez « Se déconnecter », vous devrez saisir de nouveau vos informations à la prochaine connexion.",
      "Pour changer ce comportement : menu (≡) → « Session et sécurité », puis choisissez « Rester connecté 30 jours », « Déconnexion après 10 minutes d'inactivité » ou « Toujours demander mes informations ».",
      "Après 30 jours, ou si votre mot de passe est réinitialisé, vous devez vous reconnecter.",
    ],
    astuce: "Si vous prêtez votre téléphone, choisissez « Toujours demander mes informations » ou la déconnexion après 10 minutes.",
  ),
  GuideSection(
    icone: Icons.home_rounded,
    titre: "L'accueil",
    resume: 'Prochain cours, accès rapides, nouveautés',
    etapes: [
      'La carte « Prochain cours » affiche votre prochain cours de la journée ; « Voir le planning » ouvre votre emploi du temps.',
      "Les « Accès rapides » donnent accès à vos notes et résultats, à la présence, aux cours, aux bulletins et au planning.",
      'Un petit compteur (pastille) sur un accès rapide signale une nouveauté : nouveau cours publié, nouvel emploi du temps, nouveau bulletin, nouvelles notes.',
      'Le compteur disparaît dès que vous ouvrez la rubrique concernée.',
    ],
  ),
  GuideSection(
    icone: Icons.menu_book_rounded,
    titre: 'Cours',
    resume: 'Retrouver les supports publiés par vos professeurs',
    etapes: [
      "Sur l'accueil, touchez « Cours ».",
      'Parcourez les supports publiés pour votre filière et votre niveau, puis ouvrez-en un pour le lire ou le télécharger.',
    ],
  ),
  GuideSection(
    icone: Icons.calendar_month_rounded,
    titre: 'Planning (emploi du temps)',
    resume: 'Voir vos cours de la semaine',
    etapes: [
      "Touchez « Planning » sur l'accueil ou « Voir le planning » sur la carte du prochain cours.",
      "Consultez les cours par jour : matière, horaires, salle et professeur.",
      "Quand l'administration envoie un nouvel emploi du temps, un compteur apparaît sur « Planning ».",
    ],
  ),
  GuideSection(
    icone: Icons.fact_check_rounded,
    titre: 'Notes, résultats et bulletins',
    resume: 'Consulter vos notes et télécharger vos bulletins',
    etapes: [
      "Touchez « Notes » ou « Résultats » pour voir vos notes par module une fois qu'elles ont été publiées par l'administration.",
      'Touchez « Bulletins » pour consulter ou télécharger un bulletin publié.',
      'Si vous pensez qu\'une note est erronée, faites une réclamation (voir la rubrique suivante).',
    ],
    astuce: 'Les notes apparaissent seulement après leur publication par l\'administration.',
  ),
  GuideSection(
    icone: Icons.rate_review_outlined,
    titre: 'Faire une réclamation',
    resume: 'Contester une note',
    etapes: [
      'Ouvrez vos notes et choisissez le module concerné.',
      'Lancez la réclamation, expliquez votre demande et joignez une preuve (image) si nécessaire.',
      'Suivez la réponse dans « Mes réclamations » : elle est acceptée, rejetée ou transmise au professeur.',
    ],
  ),
  GuideSection(
    icone: Icons.forum_rounded,
    titre: 'Canaux et messages',
    resume: 'Groupe de classe, discussions et messages privés',
    etapes: [
      "Ouvrez l'onglet « Canaux » : vous y trouvez le groupe de votre filière et vos discussions.",
      'Touchez un canal pour lire les messages et répondre ; vous pouvez aussi envoyer des fichiers.',
      'Un compteur sur « Canaux » indique les messages non lus ; il baisse dès que vous ouvrez la discussion.',
    ],
  ),
  GuideSection(
    icone: Icons.smart_toy_outlined,
    titre: 'Chat IA et révisions',
    resume: "Un assistant pour vous aider à réviser",
    etapes: [
      "Onglet « Chat IA » : posez vos questions sur vos cours.",
      "Menu → « Révisions IA » : générez des exercices ou fiches de révision pour préparer vos examens.",
    ],
  ),
  GuideSection(
    icone: Icons.confirmation_number_outlined,
    titre: 'Tickets et évaluation des professeurs',
    resume: 'Signaler un problème, donner votre avis',
    etapes: [
      "Menu → « Tickets » pour contacter l'administration (problème, demande).",
      "Menu → « Évaluer mes profs » pour noter vos professeurs lorsque l'évaluation est ouverte.",
    ],
  ),
  GuideSection(
    icone: Icons.person_rounded,
    titre: 'Mon profil',
    resume: 'Vos informations et votre photo',
    etapes: [
      "Touchez votre nom en haut du menu, ou l'onglet « Profil ».",
      'Consultez vos informations (matricule, filière, niveau), modifiez votre photo et vos préférences.',
      'Le bouton « Changer mon mot de passe » est disponible dans le profil.',
    ],
  ),
];

// ═════════════════════════════════════════════════════════════════════════════
//  PROFESSEUR
// ═════════════════════════════════════════════════════════════════════════════
const _guideProfesseur = <GuideSection>[
  GuideSection(
    icone: Icons.login_rounded,
    titre: 'Se connecter et gérer son compte',
    resume: 'Première connexion, mot de passe, déconnexion',
    etapes: [
      "Connectez-vous avec le nom et le numéro de téléphone communiqués par l'administration, puis votre mot de passe provisoire.",
      "Changez votre mot de passe : onglet « Profil » → « Changer mon mot de passe » (ou « Plus » → mot de passe sur téléphone).",
      'Pour quitter : « Se déconnecter » dans le Profil, dans la barre latérale ou dans le menu « Plus » sur téléphone.',
    ],
    astuce: 'Changez le mot de passe provisoire dès la première connexion.',
  ),
  GuideSection(
    icone: Icons.lock_clock_rounded,
    titre: 'Session et sécurité',
    resume: "Choisir si l'application redemande vos informations",
    etapes: [
      "Par défaut, vos informations de connexion sont redemandées à chaque ouverture de l'application.",
      "Pour changer : onglet « Profil » → « Préférences » → « Session et sécurité ».",
      "Choisissez « Toujours demander mes informations » (par défaut), « Déconnexion après 10 minutes d'inactivité » ou « Rester connecté 7 jours ».",
      "Le bouton « Se déconnecter » met toujours fin à la session.",
    ],
    astuce: "Ce réglage est enregistré sur l'appareil : il faut le refaire sur un autre téléphone ou ordinateur.",
  ),
  GuideSection(
    icone: Icons.dashboard_rounded,
    titre: "L'accueil",
    resume: 'Chiffres clés, programme du jour, actions rapides',
    etapes: [
      'Les cartes du haut résument vos classes, cours publiés, étudiants et notes à compléter ; touchez-en une pour y accéder.',
      "La carte « Aujourd'hui » fait défiler vos cours du jour. S'il n'y en a plus, elle affiche le programme du jour suivant.",
      '« Ma semaine » affiche tout votre programme de la semaine, tel que programmé par l\'administration.',
      "Les « Actions rapides » mènent à l'appel, à la saisie des notes et à la publication d'un cours.",
    ],
  ),
  GuideSection(
    icone: Icons.event_available_rounded,
    titre: 'Transmettre mes heures libres',
    resume: "Aider l'administration à construire l'emploi du temps",
    etapes: [
      "Ouvrez l'onglet « Profil » puis « Mon programme / heures libres ».",
      'Touchez les créneaux où vous êtes LIBRE (ils deviennent verts), jour par jour.',
      'Appuyez sur « Transmettre mes heures libres » : l\'administration les reçoit aussitôt.',
      "Un rappel apparaît sur l'accueil à partir du jeudi, tant que vous n'avez pas transmis vos heures de la semaine suivante.",
      "L'administration peut aussi vous demander vos heures libres à tout moment : le même rappel s'affiche alors.",
    ],
    astuce: "Si tous vos modules sont « à venir » ou « terminés », vous ne recevez pas le rappel du jeudi.",
  ),
  GuideSection(
    icone: Icons.menu_book_rounded,
    titre: 'Mes modules (en cours, à venir, terminé)',
    resume: 'Suivre vos modules et marquer un module terminé',
    etapes: [
      "Ouvrez « Profil » puis « Mes modules » pour voir les modules qui vous sont affectés.",
      "Un module « à venir » sera lancé par l'administration quand son cours sera programmé.",
      "Quand vous avez fini un module, touchez « Terminé » puis confirmez. « Rouvrir » le remet en cours.",
    ],
  ),
  GuideSection(
    icone: Icons.groups_rounded,
    titre: 'Classes',
    resume: 'Vos classes et leurs étudiants',
    etapes: [
      "Ouvrez l'onglet « Classes » puis touchez une classe.",
      "Consultez la liste des étudiants ; « Liste des étudiants (PDF) » la télécharge pour l'imprimer.",
    ],
  ),
  GuideSection(
    icone: Icons.upload_file_rounded,
    titre: 'Publier un cours',
    resume: 'Partager un support avec vos étudiants',
    etapes: [
      "Onglet « Cours » → « Nouveau cours » (ou « Publier un cours » sur l'accueil).",
      'Renseignez le titre, une description (facultative), choisissez la classe puis le module (seuls vos modules de cette classe sont proposés).',
      'Sélectionnez le fichier (PDF, Word, PowerPoint) puis appuyez sur « Publier ».',
      'Les étudiants de la classe reçoivent une nouveauté sur « Cours ».',
    ],
  ),
  GuideSection(
    icone: Icons.how_to_reg_rounded,
    titre: "Faire l'appel",
    resume: 'Enregistrer les présences',
    etapes: [
      "Onglet « Appel » (ou « Faire l'appel » sur l'accueil).",
      'Choisissez la classe et le module, puis marquez chaque étudiant présent, absent ou en retard.',
      "Vous pouvez aussi ouvrir une session par QR code : les étudiants scannent le code, et vous corrigez à la main si besoin avant de clôturer.",
    ],
  ),
  GuideSection(
    icone: Icons.fact_check_rounded,
    titre: 'Saisir et envoyer les notes',
    resume: 'Sessions de notes par classe et module',
    etapes: [
      "Onglet « Notes » (ou « Saisir les notes » sur l'accueil) → créez une session pour la classe et le module.",
      'Saisissez les notes des étudiants et enregistrez ; vous pouvez reprendre plus tard.',
      "Envoyez la session à l'administration : elle valide puis publie les notes aux étudiants.",
    ],
  ),
  GuideSection(
    icone: Icons.report_gmailerrorred_rounded,
    titre: 'Réclamations',
    resume: 'Répondre aux contestations de notes',
    etapes: [
      "Onglet « Réclamations » : l'administration vous transmet les réclamations qui concernent vos modules.",
      'Ouvrez-en une, vérifiez la note, puis répondez. Un compteur signale les nouvelles réclamations.',
    ],
  ),
  GuideSection(
    icone: Icons.replay_circle_filled_rounded,
    titre: 'Rattrapage',
    resume: 'Gérer les sessions de rattrapage',
    etapes: [
      "Onglet « Rattrapage » : consultez les étudiants concernés et saisissez les résultats du rattrapage.",
    ],
  ),
  GuideSection(
    icone: Icons.forum_rounded,
    titre: 'Messages',
    resume: 'Groupes, délégués et messages privés',
    etapes: [
      "Onglet « Messages » : retrouvez vos discussions et les groupes « Professeurs & Délégués » de vos classes.",
      'Touchez une discussion pour lire et écrire. Un compteur indique les messages non lus.',
    ],
  ),
  GuideSection(
    icone: Icons.person_rounded,
    titre: 'Mon profil',
    resume: 'Informations, photo, attestation de service',
    etapes: [
      "Onglet « Profil » : consultez vos informations, vos modules enseignés et vos classes.",
      'Modifiez votre photo ; « Ajouter mon attestation de service » permet de joindre le document.',
      'Les préférences (langue, notifications) se règlent aussi dans le profil.',
    ],
  ),
];

// ═════════════════════════════════════════════════════════════════════════════
//  ADMINISTRATION  (chaque rubrique n'apparaît que si le membre y a accès)
// ═════════════════════════════════════════════════════════════════════════════
const _guideAdmin = <GuideSection>[
  GuideSection(
    icone: Icons.manage_accounts_rounded,
    titre: 'Mon compte et mes accès',
    resume: 'Mot de passe, déconnexion, ce que vous voyez dans le menu',
    etapes: [
      'Le menu de gauche (ou « Plus » sur téléphone) liste uniquement les rubriques auxquelles votre rôle donne accès.',
      "Les accès sont réglés par le Super Admin dans « Membres & Rôles » : si une rubrique manque, demandez-lui de l'activer.",
      'Changer votre mot de passe et vous déconnecter se font depuis le menu (en bas de la barre latérale, ou « Plus » sur téléphone).',
      "Par défaut, vos informations sont redemandées à chaque ouverture. Pour changer : ouvrez votre profil (votre nom dans la barre latérale ou le menu) → « Session et sécurité », puis choisissez « Toujours demander », « Déconnexion après 10 minutes d'inactivité » ou « Rester connecté 7 jours ».",
    ],
  ),
  GuideSection(
    icone: Icons.grid_view_rounded,
    titre: 'Tableau de bord',
    resume: "Vue d'ensemble de l'établissement",
    etapes: [
      "Le tableau de bord résume l'activité de l'établissement : effectifs, nouveautés, raccourcis.",
      'Les pastilles de couleur du menu signalent ce qui attend une action (réclamations à traiter, sessions de notes en attente, messages non lus, nouvelles heures libres de professeurs).',
    ],
  ),
  GuideSection(
    icone: Icons.campaign_rounded,
    titre: 'Envoyer une annonce',
    resume: 'Informer étudiants, professeurs ou parents',
    menu: 1,
    etapes: [
      'Menu → « Annonces ».',
      "Rédigez votre annonce, choisissez à qui elle s'adresse si l'option est proposée, puis publiez-la.",
      'Les destinataires la voient dans leur espace.',
    ],
  ),
  GuideSection(
    icone: Icons.account_tree_rounded,
    titre: 'Filières et modules',
    resume: 'Créer une filière, ajouter un module et lui attribuer un professeur',
    menu: 2,
    etapes: [
      'Menu → « Filières & Modules ».',
      'Créez la filière (nom, abréviation, niveau, domaine, année académique) ; un groupe de messagerie est créé automatiquement pour elle.',
      "Ouvrez la filière puis « Ajouter un module » : nom, coefficient, volume horaire, semestre.",
      "Choisissez le professeur dans « Professeur (attribution) » (facultatif : vous pourrez l'attribuer plus tard depuis la fiche du professeur).",
    ],
    astuce: "Un module attribué est « à venir » : le professeur ne reçoit pas de rappel d'heures libres tant que vous ne le passez pas « En cours ».",
  ),
  GuideSection(
    icone: Icons.calendar_today_rounded,
    titre: 'Emplois du temps',
    resume: 'Créer, valider et envoyer un emploi du temps',
    menu: 3,
    etapes: [
      "Menu → « Emplois du Temps » → « Créer un emploi du temps » : choisissez la filière et le niveau.",
      "« Ajouter un créneau » : jour, horaires, module, professeur, salle, puis « Valider ».",
      '« Envoyer aux étudiants » publie l\'emploi du temps : un compteur « Planning » apparaît chez les étudiants.',
      'Pour choisir les horaires, consultez d\'abord « Disponibilités profs ».',
    ],
  ),
  GuideSection(
    icone: Icons.event_available_rounded,
    titre: 'Disponibilités des professeurs',
    resume: 'Voir les heures libres que les professeurs vous envoient',
    menu: 24,
    etapes: [
      'Menu → « Disponibilités profs » : la liste des professeurs ayant transmis leurs heures libres, avec la date de transmission.',
      'Ouvrez un professeur pour voir ses créneaux jour par jour ; ⟳ actualise la liste.',
      "Une pastille avec un chiffre indique les professeurs dont les heures sont nouvelles ou modifiées depuis votre dernière visite.",
      "Pour solliciter un professeur, ouvrez sa fiche (menu « Professeurs ») et appuyez sur « Demander les heures libres ».",
    ],
  ),
  GuideSection(
    icone: Icons.task_rounded,
    titre: 'Notes et moyennes',
    resume: 'Recevoir, contrôler et transférer les notes',
    menu: 4,
    etapes: [
      'Menu → « Notes & Moyennes » : les sessions envoyées par les professeurs apparaissent avec leur statut.',
      "Ouvrez une session pour la contrôler ; vous pouvez la rejeter (avec un motif), la stocker ou la transférer.",
      '« Saisie directe » permet de saisir des notes sans passer par le professeur.',
      '« Envoyer aux étudiants » (moyennes provisoires) publie les résultats ; confirmez dans la fenêtre.',
    ],
  ),
  GuideSection(
    icone: Icons.workspace_premium_rounded,
    titre: 'Bulletins',
    resume: 'Générer et publier les bulletins',
    menu: 17,
    etapes: [
      "Menu → « Bulletins » : choisissez la filière et le semestre puis « Charger les résultats ».",
      "Contrôlez les moyennes (« Règles de validation » rappelle les seuils) et corrigez une moyenne si besoin.",
      '« Enregistrer sans publier » garde le travail ; « Publier les bulletins sélectionnés » les rend visibles aux étudiants.',
      '« Exporter PDF » produit les bulletins à imprimer.',
    ],
  ),
  GuideSection(
    icone: Icons.rate_review_rounded,
    titre: 'Réclamations',
    resume: 'Traiter les contestations de notes',
    menu: 5,
    etapes: [
      'Menu → « Réclamations » : la liste des réclamations en attente (un compteur reste affiché tant qu\'elles ne sont pas traitées).',
      'Ouvrez-en une pour voir la demande et la preuve jointe.',
      "« Répondre à la réclamation », la rejeter (avec un motif) ou la « Transférer au professeur ».",
    ],
  ),
  GuideSection(
    icone: Icons.school_rounded,
    titre: 'Étudiants',
    resume: 'Inscrire, modifier, réinitialiser un mot de passe',
    menu: 6,
    etapes: [
      'Menu → « Étudiants » : recherchez un étudiant par nom ou matricule.',
      "Pour inscrire un étudiant, renseignez ses informations ; le matricule peut être « Générer automatiquement ». Un tuteur/parent peut être renseigné (facultatif) : un compte parent est alors créé ou lié.",
      'Sur la fiche d\'un étudiant : « Modifier les informations », « Générer la carte » (PDF), « Réinitialiser le mot de passe ».',
      "« Inscription en ligne ouverte » : traitez les demandes d'inscription reçues (acceptation ou refus).",
    ],
  ),
  GuideSection(
    icone: Icons.supervisor_account_rounded,
    titre: 'Professeurs',
    resume: 'Créer un professeur, gérer ses affectations et ses modules',
    menu: 7,
    etapes: [
      "Menu → « Professeurs » : ajoutez un professeur (nom, prénoms, téléphone, filières et niveaux).",
      "Ouvrez la fiche (icône œil) pour voir ses informations, affectations et modules.",
      "Touchez un module pour changer son statut : « À venir », « En cours » ou « Terminé ». Le rappel des heures libres du jeudi ne concerne que les modules « En cours ».",
      '« Demander les heures libres » envoie une demande ponctuelle au professeur.',
      'Vous pouvez réinitialiser son mot de passe depuis sa fiche.',
    ],
  ),
  GuideSection(
    icone: Icons.family_restroom_rounded,
    titre: 'Parents',
    resume: 'Associer un parent à un étudiant',
    menu: 8,
    etapes: [
      "Menu → « Parents » : recherchez un parent ou un enfant.",
      "« Lier maintenant » associe le parent à l'étudiant ; « Retirer ce lien » le supprime.",
      'Si un tuteur est déjà assigné, vous pouvez le « Remplacer ».',
    ],
  ),
  GuideSection(
    icone: Icons.shield_rounded,
    titre: 'Membres et rôles',
    resume: "Ajouter des membres de l'administration et régler leurs accès",
    menu: 9,
    etapes: [
      'Menu → « Membres & Rôles » → « Nouveau membre » : nom, rôle (scolarité, examens, secrétariat, communication, etc.).',
      'Réglez les interrupteurs d\'autorisation pour accorder ou retirer l\'accès à une rubrique.',
      '« Suspendre » bloque un compte sans le supprimer ; « Réactiver » le rétablit ; « Supprimer » le retire définitivement.',
    ],
  ),
  GuideSection(
    icone: Icons.forum_rounded,
    titre: 'Groupes et messages',
    resume: 'Suivre les groupes et échanger',
    menu: 10,
    etapes: [
      "Menu → « Groupes & Messages » : les groupes de filière, les canaux professeurs/délégués et les messages privés.",
      "Ouvrez une conversation pour lire et répondre ; vous pouvez rechercher dans la discussion, créer un sondage (anonyme, choix multiple, date de clôture) ou partager sur WhatsApp.",
      'Le compteur du menu baisse quand vous lisez les discussions.',
    ],
  ),
  GuideSection(
    icone: Icons.groups_2_rounded,
    titre: 'Délégués, BDE et événements',
    resume: 'Nommer les délégués, gérer le bureau des étudiants',
    menu: 18,
    etapes: [
      'Menu → « Délégués » pour nommer les délégué(e)s et adjoint(e)s de chaque classe.',
      "« Bureau des Étudiants » et « BDE & Événements » servent à nommer le bureau et à gérer les événements.",
    ],
  ),
  GuideSection(
    icone: Icons.replay_circle_filled_rounded,
    titre: "Rattrapage, fin d'année et réinscriptions",
    resume: "Clôturer l'année et préparer la suivante",
    menu: 21,
    etapes: [
      "« Rattrapage » : suivez les sessions de rattrapage.",
      "« Fin d'année » : finalisez les résultats de l'année (ne clôturez qu'une fois tout publié).",
      "« Réinscriptions » : gérez les passages et réinscriptions des étudiants.",
    ],
    astuce: "Ne clôturez pas une année avant d'avoir publié tous les bulletins.",
  ),
  GuideSection(
    icone: Icons.bar_chart_rounded,
    titre: 'Statistiques et rapports',
    resume: 'Statistiques, évaluation des professeurs, élèves à risque',
    menu: 12,
    etapes: [
      '« Statistiques » : effectifs et résultats.',
      '« Éval. Professeurs » : synthèse des évaluations faites par les étudiants.',
      '« Élèves à risque » : étudiants en difficulté à suivre de près.',
    ],
  ),
  GuideSection(
    icone: Icons.restaurant_menu_rounded,
    titre: 'Cantine',
    resume: 'Publier le menu',
    menu: 19,
    etapes: [
      "Menu → « Cantine » : la personne responsable publie le menu ; il s'affiche aux utilisateurs concernés.",
    ],
  ),
];