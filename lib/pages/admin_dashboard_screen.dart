import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_palette.dart';
import '../models/student_profile.dart'; // Just in case we need generic profile usage

class AdminDashboardScreen extends StatefulWidget {
  final StudentProfile profile; // Can be reused for admin profile
  const AdminDashboardScreen({super.key, required this.profile});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  String _tauxReussite = "0%";
  double _moyennePromo = 0.0;
  Map<String, dynamic> _mentions = {
    "TB": 0, "B": 0, "AB": 0, "P": 0, "F": 0
  };

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/statistiques/notes'),
        headers: { 'Authorization': 'Bearer $token' },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _tauxReussite = data['taux_reussite'] ?? "0%";
          _moyennePromo = (data['moyenne_promo'] as num?)?.toDouble() ?? 0.0;
          if (data['repartition_mentions'] != null) {
            _mentions = data['repartition_mentions'];
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Erreur lors de la récupération des statistiques.'),
            backgroundColor: Color(0xFFC62828),
          ));
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur serveur: $e'),
          backgroundColor: const Color(0xFFC62828),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Dashboard Admin', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        backgroundColor: AppPalette.blue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppPalette.blue))
          : RefreshIndicator(
              onRefresh: _fetchStats,
              color: AppPalette.blue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Aperçu Global', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('Taux de réussite', _tauxReussite, Icons.trending_up, const Color(0xFF10B981))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildStatCard('Moyenne Promo', '$_moyennePromo', Icons.school, AppPalette.blue)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text('Répartition des Mentions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 24),
                    _buildPieChartSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha:0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color, letterSpacing: -1)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPieChartSection() {
    int tb = _mentions['TB'] ?? 0;
    int b = _mentions['B'] ?? 0;
    int ab = _mentions['AB'] ?? 0;
    int p = _mentions['P'] ?? 0;
    int f = _mentions['F'] ?? 0;

    int total = tb + b + ab + p + f;
    if (total == 0) {
      return const Center(child: Text("Aucune donnée disponible", style: TextStyle(color: Color(0xFF64748B))));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  _createSection(tb, total, const Color(0xFF10B981), 'TB'),
                  _createSection(b, total, const Color(0xFF3B82F6), 'B'),
                  _createSection(ab, total, const Color(0xFFF59E0B), 'AB'),
                  _createSection(p, total, const Color(0xFF8B5CF6), 'P'),
                  _createSection(f, total, const Color(0xFFEF4444), 'F'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _buildLegend('Très Bien (TB)', const Color(0xFF10B981), tb),
              _buildLegend('Bien (B)', const Color(0xFF3B82F6), b),
              _buildLegend('Assez Bien (AB)', const Color(0xFFF59E0B), ab),
              _buildLegend('Passable (P)', const Color(0xFF8B5CF6), p),
              _buildLegend('Insuffisant (F)', const Color(0xFFEF4444), f),
            ],
          )
        ],
      ),
    );
  }

  PieChartSectionData _createSection(int value, int total, Color color, String title) {
    final double percentage = (value / total) * 100;
    return PieChartSectionData(
      color: color,
      value: value.toDouble(),
      title: '${percentage.toStringAsFixed(0)}%',
      radius: 50,
      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      showTitle: value > 0,
    );
  }

  Widget _buildLegend(String title, Color color, int value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$title ($value)', style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w500)),
      ],
    );
  }
}
