import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PlanningTab extends StatefulWidget {
  const PlanningTab({super.key});

  @override
  State<PlanningTab> createState() => _PlanningTabState();
}

class _PlanningTabState extends State<PlanningTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Color _bgGlobal = Color(0xFFF8FAFC);
  static const Color _textMain = Color(0xFF0F172A);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _brandBlue = Color(0xFF1E40AF);

  // 1. STRUCTURE DE L'EMPLOI DU TEMPS HEBDOMADAIRE (Corrigé ici : sans espace !)
  final List<String> _joursSemaine = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];
  
  final List<Map<String, dynamic>> _coursSemaine = [
    {'jour': 'Lundi', 'heure': '08h00 - 10h00', 'matiere': 'Administration Réseau Linux', 'salle': 'Salle A102', 'type': 'CM', 'prof': 'Prof Ouédraogo'},
    {'jour': 'Lundi', 'heure': '10h15 - 12h15', 'matiere': 'Téléphonie sur IP (Asterisk)', 'salle': 'Labo Télécom', 'type': 'TP', 'prof': 'Prof Traoré'},
    {'jour': 'Mardi', 'heure': '08h00 - 11h00', 'matiere': 'Bases de Données Relationnelles', 'salle': 'Salle B204', 'type': 'TD', 'prof': 'Prof Sawadogo'},
    {'jour': 'Mercredi', 'heure': '14h00 - 17h00', 'matiere': 'Développement Web', 'salle': 'Amphi C', 'type': 'CM', 'prof': 'Prof Kaboré'},
    {'jour': 'Jeudi', 'heure': '10h15 - 12h15', 'matiere': 'Anglais Technique', 'salle': 'Salle A05', 'type': 'CM', 'prof': 'Prof Johnson'},
    {'jour': 'Vendredi', 'heure': '08h00 - 12h15', 'matiere': 'Interconnexion LAN/WAN', 'salle': 'Labo Cisco', 'type': 'TP', 'prof': 'Prof Ouédraogo'},
  ];

  // 2. EVENEMENTS ANNUELS
  static const List<Map<String, String>> _events = [
    {'titre': 'Rentrée académique 2024-2025', 'date': '15 septembre 2024', 'description': 'Début officiel de l\'année.', 'type': 'Académique'},
    {'titre': 'Début des examens S3', 'date': '04 Nov. → 15 Nov. 2024', 'description': 'Examens écrits de fin de semestre.', 'type': 'Examens'},
    {'titre': 'Délibérations S3', 'date': '25 novembre 2024', 'description': 'Publication des résultats du S3.', 'type': 'Résultats'},
    {'titre': 'Vacances académiques', 'date': '23 Déc. 2024 → 05 Jan. 2025', 'description': 'Vacances de fin d\'année.', 'type': 'Vacances'},
    {'titre': 'Inscriptions pédagogiques S4', 'date': 'Avant le 05 Mai 2026', 'description': 'Régularisation administrative obligatoire.', 'type': 'Urgent'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'CM': return const Color(0xFF3B82F6);
      case 'TP': return const Color(0xFF10B981);
      case 'TD': return const Color(0xFFF59E0B);
      case 'Examens': return const Color(0xFFEF4444);
      case 'Urgent': return const Color(0xFFDC2626);
      default: return _brandBlue;
    }
  }

  Future<void> _genererEtTelechargerPDF(BuildContext context) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('INSTITUT SUPÉRIEUR DE TECHNOLOGIES (IST)', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Département Réseaux & Télécommunications', style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                    pw.Text('Emploi du Temps Officiel — L2', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 16),
                
                pw.Center(
                  child: pw.Text('PLANNING HEBDOMADAIRE DES ENSEIGNEMENTS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF1E40AF))),
                ),
                pw.SizedBox(height: 16),

                pw.TableHelper.fromTextArray(
                  headers: ['Jour', 'Horaire', 'Intitulé du Cours / Module', 'Type', 'Salle / Labo', 'Enseignant'],
                  data: _coursSemaine.map((c) => [c['jour']!, c['heure']!, c['matiere']!, c['type']!, c['salle']!, c['prof']!]).toList(),
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                  headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E40AF)),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellPadding: const pw.EdgeInsets.all(6),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                ),
                pw.Spacer(),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text('Document numérique certifié scolarité — Génération ScolarHub', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                )
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'Emploi_du_Temps_L2.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGlobal,
      body: SafeArea(
        child: Column(children: [
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: _border)),
            ),
            child: Column(children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: _brandBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.date_range_rounded, color: _brandBlue, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Planning & Salles', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _textMain, letterSpacing: -0.5)),
                    SizedBox(height: 2),
                    Text('Filière : Réseaux & Télécommunications (L2)', style: TextStyle(fontSize: 12, color: _textMuted, fontWeight: FontWeight.w500)),
                  ],
                )),
                
                IconButton(
                  onPressed: () => _genererEtTelechargerPDF(context),
                  icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444)),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFFEF2F2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.all(10)
                  ),
                )
              ]),
              const SizedBox(height: 16),
              
              TabBar(
                controller: _tabController,
                labelColor: _brandBlue,
                unselectedLabelColor: _textMuted,
                indicatorColor: _brandBlue,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                tabs: const [
                  Tab(text: 'Grille Hebdomadaire'),
                  Tab(text: 'Dates Importantes'),
                ],
              ),
            ]),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                
                // ONGLET 1 : GRILLE HORAIRE NATIVE
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _joursSemaine.length,
                  itemBuilder: (context, jIdx) {
                    final jour = _joursSemaine[jIdx];
                    final coursDuJour = _coursSemaine.where((c) => c['jour'] == jour).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, top: 8, bottom: 10),
                          child: Text(
                            jour.toUpperCase(),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _brandBlue, letterSpacing: 0.6),
                          ),
                        ),
                        
                        if (coursDuJour.isEmpty)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
                            child: const Text('Aucun cours programmé', style: TextStyle(fontSize: 13, color: _textMuted, fontStyle: FontStyle.italic)),
                          )
                        else
                          ...coursDuJour.map((cours) {
                            final Color typeColor = _getTypeColor(cours['type']!);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: _border),
                              ),
                              child: IntrinsicHeight(
                                child: Row(children: [
                                  Container(
                                    width: 6,
                                    decoration: BoxDecoration(
                                      color: typeColor,
                                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), bottomLeft: Radius.circular(18)),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                            Row(children: [
                                              const Icon(Icons.access_time_filled_rounded, size: 14, color: _textMuted),
                                              const SizedBox(width: 4),
                                              Text(cours['heure']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textMain)),
                                            ]),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(color: typeColor.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                                              child: Text(cours['type']!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: typeColor)),
                                            ),
                                          ]),
                                          const SizedBox(height: 6),
                                          Text(cours['matiere']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textMain)),
                                          const SizedBox(height: 8),
                                          Row(children: [
                                            const Icon(Icons.room_rounded, size: 14, color: _brandBlue),
                                            const SizedBox(width: 4),
                                            Text(cours['salle']!, style: const TextStyle(fontSize: 12, color: _brandBlue, fontWeight: FontWeight.w600)),
                                            const SizedBox(width: 14),
                                            const Icon(Icons.person, size: 14, color: _textMuted),
                                            const SizedBox(width: 4),
                                            Text(cours['prof']!, style: const TextStyle(fontSize: 12, color: _textMuted)),
                                          ])
                                        ],
                                      ),
                                    ),
                                  )
                                ]),
                              ),
                            );
                          }).toList(),
                      ],
                    );
                  },
                ),

                // ONGLET 2 : DATES IMPORTANTES
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    final item = _events[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
                      child: Row(children: [
                        // CORRECTION 2 : Le mot-clé 'const' a été retiré de BoxDecoration pour accepter '_brandBlue'
                        Container(width: 4, height: 40, decoration: BoxDecoration(color: _brandBlue, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text(item['titre']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textMain)),
                            Text(item['date']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textMuted)),
                          ]),
                          const SizedBox(height: 4),
                          Text(item['description']!, style: const TextStyle(fontSize: 12, color: _textMuted)),
                        ]))
                      ]),
                    );
                  },
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}