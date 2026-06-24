class PeriodeEvaluation {
  String id;
  String filiere;
  String dateDebut;
  String dateFin;
  bool ouverte;
  Map<String, List<double>> resultats;

  PeriodeEvaluation({
    required this.id,
    required this.filiere,
    required this.dateDebut,
    required this.dateFin,
    this.ouverte = false,
    required this.resultats,
  });
}

// Liste globale pour accéder aux évaluations partout
List<PeriodeEvaluation> adminEvaluations = [
  PeriodeEvaluation(
    id: 'EV001', filiere: 'Réseaux Informatiques et Télécom',
    dateDebut: '01/05/2025', dateFin: '10/05/2025', ouverte: true,
    resultats: {
      'OUÉDRAOGO Mamadou': [4.0, 4.5, 3.5, 4.2, 4.8],
      'SAWADOGO Issa': [4.5, 5.0, 4.0, 4.5, 4.2],
    }),
];