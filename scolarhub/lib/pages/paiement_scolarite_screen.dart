import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

class PaiementScolariteScreen extends StatefulWidget {
  const PaiementScolariteScreen({super.key});

  @override
  State<PaiementScolariteScreen> createState() =>
      _PaiementScolariteScreenState();
}

class _PaiementScolariteScreenState extends State<PaiementScolariteScreen> {
  // Données complètes
  final List<Map<String, dynamic>> frais = [
    {
      'libelle': 'Frais d\'inscription',
      'montant': 50000,
      'statut': 'non_payé',
      'date_limite': '30 Novembre 2024',
      'penalite': 5000,
    },
    {
      'libelle': 'Mensualité Janvier',
      'montant': 25000,
      'statut': 'payé',
      'date_limite': '31 Janvier 2024',
      'penalite': 2500,
    },
    {
      'libelle': 'Mensualité Février',
      'montant': 25000,
      'statut': 'non_payé',
      'date_limite': '28 Février 2024',
      'penalite': 2500,
    },
    {
      'libelle': 'Mensualité Mars',
      'montant': 25000,
      'statut': 'non_payé',
      'date_limite': '31 Mars 2024',
      'penalite': 2500,
    },
    {
      'libelle': 'Mensualité Avril',
      'montant': 25000,
      'statut': 'non_payé',
      'date_limite': '30 Avril 2024',
      'penalite': 2500,
    },
    {
      'libelle': 'Frais de bibliothèque',
      'montant': 10000,
      'statut': 'non_payé',
      'date_limite': '31 Décembre 2024',
      'penalite': 1000,
    },
  ];

  String _filter = 'tous'; // tous, payé, non_payé
  bool _isLoading = false;

  List<Map<String, dynamic>> get _filteredFrais {
    if (_filter == 'payé') {
      return frais.where((f) => f['statut'] == 'payé').toList();
    } else if (_filter == 'non_payé') {
      return frais.where((f) => f['statut'] == 'non_payé').toList();
    }
    return frais;
  }

  int get _totalPaye => frais
      .where((f) => f['statut'] == 'payé')
      .fold(0, (sum, f) => sum + (f['montant'] as int));

  int get _totalRestant => frais
      .where((f) => f['statut'] == 'non_payé')
      .fold(0, (sum, f) => sum + (f['montant'] as int));

  int get _totalGeneral =>
      frais.fold(0, (sum, f) => sum + (f['montant'] as int));

  Future<void> _payer(Map<String, dynamic> fraisItem) async {
    final montant = fraisItem['montant'] as int;
    final libelle = fraisItem['libelle'] as String;

    // Simuler un paiement Orange Money
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _PaymentBottomSheet(
        montant: montant,
        libelle: libelle,
        onConfirm: () async {
          Navigator.pop(context);
          setState(() => _isLoading = true);

          // Simuler appel API
          await Future.delayed(const Duration(seconds: 2));

          setState(() {
            fraisItem['statut'] = 'payé';
            _isLoading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Paiement réussi pour $libelle !',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Paiements Scolarité',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppPalette.blue, AppPalette.blue.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () => _showRecapDialog(),
            tooltip: 'Récapitulatif',
          ),
        ],
      ),
      body: Column(
        children: [
          // Cartes statistiques
          Container(
            margin: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total à payer',
                    '$_totalGeneral FCFA',
                    Icons.account_balance_wallet,
                    AppPalette.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Déjà payé',
                    '$_totalPaye FCFA',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Reste à payer',
                    '$_totalRestant FCFA',
                    Icons.warning_amber,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          // Barre de progression
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progression du paiement',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '${((_totalPaye / _totalGeneral) * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppPalette.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _totalPaye / _totalGeneral,
                    backgroundColor: Colors.grey[200],
                    color: AppPalette.blue,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Filtres
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('Tous', 'tous'),
                const SizedBox(width: 8),
                _buildFilterChip('Payés', 'payé'),
                const SizedBox(width: 8),
                _buildFilterChip('Non payés', 'non_payé'),
                const Spacer(),
                if (_filter != 'tous')
                  TextButton.icon(
                    onPressed: () => setState(() => _filter = 'tous'),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Effacer'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Liste des frais
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Traitement du paiement...'),
                      ],
                    ),
                  )
                : _filteredFrais.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _filter == 'non_payé'
                              ? 'Tous les frais sont payés !'
                              : 'Aucun élément trouvé',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredFrais.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final f = _filteredFrais[index];
                      return _buildFraisCard(f);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String filterValue) {
    return FilterChip(
      label: Text(label),
      selected: _filter == filterValue,
      onSelected: (selected) {
        setState(() => _filter = filterValue);
      },
      backgroundColor: Colors.white,
      selectedColor: AppPalette.blue.withOpacity(0.1),
      checkmarkColor: AppPalette.blue,
      labelStyle: TextStyle(
        color: _filter == filterValue ? AppPalette.blue : Colors.grey[700],
        fontWeight: _filter == filterValue
            ? FontWeight.w600
            : FontWeight.normal,
      ),
      side: BorderSide(
        color: _filter == filterValue ? AppPalette.blue : Colors.grey[300]!,
      ),
    );
  }

  Widget _buildFraisCard(Map<String, dynamic> f) {
    final isPaye = f['statut'] == 'payé';
    final montant = f['montant'] as int;
    final dateLimite = f['date_limite'] as String;
    final penalite = f['penalite'] as int;
    final isLate = !isPaye && _isDateDepasse(dateLimite);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isLate
            ? Border.all(color: Colors.red.withOpacity(0.3), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isPaye ? null : () => _payer(f),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isPaye
                            ? Colors.green.withOpacity(0.1)
                            : AppPalette.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isPaye ? Icons.check_circle : Icons.payment,
                        color: isPaye ? Colors.green : AppPalette.blue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f['libelle'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 12,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Date limite: $dateLimite',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isLate ? Colors.red : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$montant FCFA',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isPaye ? Colors.green : Colors.grey[800],
                          ),
                        ),
                        if (isLate && !isPaye)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '+$penalite FCFA pénalité',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                if (!isPaye) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _payer(f),
                          icon: const Icon(Icons.qr_code_scanner, size: 18),
                          label: const Text('Orange Money'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppPalette.blue,
                            side: BorderSide(color: AppPalette.blue),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _payer(f),
                          icon: const Icon(Icons.payment, size: 18),
                          label: const Text('Payer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppPalette.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isDateDepasse(String dateLimite) {
    // Simulation: considérer qu'on est en Mars 2024
    final aujourdhui = DateTime(2024, 3, 15);
    try {
      final moisMap = {
        'Janvier': 1,
        'Février': 2,
        'Mars': 3,
        'Avril': 4,
        'Mai': 5,
        'Juin': 6,
        'Juillet': 7,
        'Août': 8,
        'Septembre': 9,
        'Octobre': 10,
        'Novembre': 11,
        'Décembre': 12,
      };
      final parts = dateLimite.split(' ');
      final jour = int.parse(parts[0]);
      final mois = moisMap[parts[1]] ?? 1;
      final annee = int.parse(parts[2]);
      final date = DateTime(annee, mois, jour);
      return date.isBefore(aujourdhui);
    } catch (e) {
      return false;
    }
  }

  void _showRecapDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Récapitulatif des paiements'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRecapItem('Total général', _totalGeneral, AppPalette.blue),
            const Divider(),
            _buildRecapItem('Total payé', _totalPaye, Colors.green),
            _buildRecapItem('Reste à payer', _totalRestant, Colors.orange),
            const Divider(),
            _buildRecapItem(
              'Taux de paiement',
              ((_totalPaye / _totalGeneral) * 100).toInt(),
              AppPalette.blue,
              isPercent: true,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: AppPalette.blue, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Les paiements en retard sont sujets à des pénalités.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecapItem(
    String label,
    int value,
    Color color, {
    bool isPercent = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            isPercent ? '$value%' : '$value FCFA',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ========== BOTTOM SHEET PAIEMENT ==========
class _PaymentBottomSheet extends StatefulWidget {
  final int montant;
  final String libelle;
  final VoidCallback onConfirm;

  const _PaymentBottomSheet({
    required this.montant,
    required this.libelle,
    required this.onConfirm,
  });

  @override
  State<_PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<_PaymentBottomSheet> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  int _step = 1; // 1: numéro, 2: code

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Correction: Remplacé Icons.orange_money par Icons.attach_money
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.attach_money,
                  color: Colors.orange,
                  size: 28,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Orange Money',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Payer ${widget.montant} FCFA',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Text(
            widget.libelle,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          if (_step == 1) ...[
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Numéro Orange Money',
                hintText: 'Ex: 771234567',
                prefixIcon: Icon(
                  Icons.phone_android,
                  color: Colors.orange[700],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_phoneController.text.length >= 9) {
                    setState(() => _step = 2);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Numéro invalide'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Continuer'),
              ),
            ),
          ],
          if (_step == 2) ...[
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Code de confirmation',
                hintText: 'Entrez le code reçu par SMS',
                prefixIcon: Icon(Icons.lock, color: Colors.orange[700]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Un code de confirmation a été envoyé au ${_phoneController.text}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _step = 1),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Retour'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Confirmer'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
