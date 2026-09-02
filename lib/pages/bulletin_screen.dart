import 'package:flutter/material.dart';
import '../widgets/app_bubble_bg.dart';
import '../widgets/reclamation_form_sheet.dart';

class BulletinScreen extends StatelessWidget {
  const BulletinScreen({super.key});

  static const List<Map<String, dynamic>> bulletins = [
    {
      'universite': 'INSTITUT SUPÉRIEUR DE TECHNOLOGIES',
      'sigle': 'IST',
      'domaine': 'Sciences et Technologies',
      'filiere': 'Réseaux et Télécommunications',
      'semestre': 'Semestre 3 (Licence 2)',
      'annee': '2024-2025',
      'moyenne_generale': 14.85,
      'mention': 'Bien',
      'statut': 'Admis',
      'signataire': 'Le Directeur Académique',
      'matieres': [
        {'nom': 'Administration Réseau & Linux', 'note': 15.5, 'credit': 5, 'coef': 3},
        {'nom': 'Téléphonie sur IP (SIP/Asterisk)', 'note': 16.0, 'credit': 4, 'coef': 2},
        {'nom': 'Bases de Données Relationnelles', 'note': 14.0, 'credit': 4, 'coef': 2},
        {'nom': 'Développement & Hébergement Web', 'note': 15.0, 'credit': 4, 'coef': 2},
        {'nom': 'Anglais Technique & Colloques', 'note': 12.5, 'credit': 3, 'coef': 1},
      ]
    },
    {
      'universite': 'INSTITUT SUPÉRIEUR DE TECHNOLOGIES',
      'sigle': 'IST',
      'domaine': 'Sciences et Technologies',
      'filiere': 'Réseaux et Télécommunications',
      'semestre': 'Semestre 4 (Licence 2)',
      'annee': '2024-2025',
      'moyenne_generale': 15.40,
      'mention': 'Bien',
      'statut': 'Admis',
      'signataire': 'Le Directeur Académique',
      'matieres': [
        {'nom': 'Routage et Commutation Avancés', 'note': 16.5, 'credit': 5, 'coef': 3},
        {'nom': 'Sécurité des Réseaux & Pare-feux', 'note': 14.5, 'credit': 4, 'coef': 2},
        {'nom': 'Gestion de Projets Informatiques', 'note': 15.0, 'credit': 3, 'coef': 1},
        {'nom': 'Interconnexion des Réseaux LAN/WAN', 'note': 15.5, 'credit': 4, 'coef': 2},
        {'nom': 'Projet de Fin de Cycle & Stage', 'note': 16.0, 'credit': 6, 'coef': 4},
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    const Color brandBlue = Color(0xFF1E40AF);
    const Color bgSlate = Color(0xFFF8FAFC);
    const Color textMain = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bgSlate,
      appBar: blueAppBar('Relevés de Notes', context: context),
      // CORRECTION 2 : Le Padding enveloppe maintenant le PageView.builder
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: PageView.builder(
          itemCount: bulletins.length,
          itemBuilder: (context, index) {
            final b = bulletins[index];

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha:0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    // 1. EN-TÊTE DE L'UNIVERSITÉ
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: brandBlue.withValues(alpha:0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.school_rounded, color: brandBlue, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b['universite'].toString(),
                                // CORRECTION 1 : Remplacement de extrabold par w800
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textMain, letterSpacing: -0.3),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Domaine : ${b['domaine']} • Filière : ${b['filiere']}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                              ),
                              Text(
                                'Année Académique : ${b['annee']}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
                    ),

                    // 2. TITRE DU SEMESTRE
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: brandBlue,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          b['semestre'].toString().toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 3. TABLEAU DES MATIÈRES
                    const Row(
                      children: [
                        Expanded(flex: 5, child: Text('INTITULÉ DE LA MATIÈRE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)))),
                        Expanded(flex: 2, child: Text('CRÉD.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)))),
                        Expanded(flex: 2, child: Text('COEF.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)))),
                        Expanded(flex: 2, child: Text('NOTE/20', textAlign: TextAlign.end, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    ...List.generate((b['matieres'] as List).length, (mIdx) {
                      final mat = b['matieres'][mIdx];
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                        ),
                        child: Row(
                          children: [
                            Expanded(flex: 5, child: Text(mat['nom'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textMain))),
                            Expanded(flex: 2, child: Text(mat['credit'].toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
                            Expanded(flex: 2, child: Text(mat['coef'].toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
                            Expanded(
                              flex: 2,
                              child: Text(
                                mat['note'].toStringAsFixed(1),
                                textAlign: TextAlign.end,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: mat['note'] >= 10 ? const Color(0xFF10B981) : Colors.red),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.report_problem_outlined,
                                  size: 18, color: brandBlue.withValues(alpha: 0.7)),
                              tooltip: 'Réclamation',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              onPressed: () => showBulletinReclamationSheet(
                                context,
                                bulletin: bulletinContextFromMap(b),
                                matierePrefill: Map<String, dynamic>.from(mat),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    
                    const SizedBox(height: 24),

                    // 4. RÉCAPITULATIF DES PERFORMANCES
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStat('MOYENNE', '${b['moyenne_generale']}/20', brandBlue),
                          _buildStat('MENTION', b['mention'], const Color(0xFFD97706)),
                          _buildStat('RÉSULTAT', b['statut'], const Color(0xFF10B981)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => showBulletinReclamationSheet(
                              context,
                              bulletin: bulletinContextFromMap(b),
                            ),
                            icon: const Icon(Icons.report_problem_outlined, size: 18),
                            label: const Text('Réclamation note'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: brandBlue,
                              side: BorderSide(color: brandBlue.withValues(alpha: 0.4)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => showBulletinReclamationSheet(
                              context,
                              bulletin: bulletinContextFromMap(b),
                              contestMoyenne: true,
                            ),
                            icon: const Icon(Icons.balance_outlined, size: 18),
                            label: const Text('Contester moyenne'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brandBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // 5. CACHET OFFICIEL & SIGNATURE
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b['signataire'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textMain)),
                            const SizedBox(height: 4),
                            const Text('Fait à Ouagadougou', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                          ],
                        ),
                        
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: brandBlue.withValues(alpha:0.4), width: 2),
                            borderRadius: BorderRadius.circular(12),
                            color: brandBlue.withValues(alpha:0.02),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.verified_user_rounded, color: brandBlue.withValues(alpha:0.6), size: 24),
                              const SizedBox(height: 2),
                              Text(
                                'CERTIFIÉ ${b['sigle']}',
                                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: brandBlue.withValues(alpha:0.7), letterSpacing: 0.5),
                              ),
                              Text(
                                'SECURE RECORD',
                                style: TextStyle(fontSize: 7, fontWeight: FontWeight.w500, color: brandBlue.withValues(alpha:0.5)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
        const SizedBox(height: 4),
        // CORRECTION 3 : Remplacement de extrabold par w800 ici aussi
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}