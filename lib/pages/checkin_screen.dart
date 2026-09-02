import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';

/// Check-in de présence : l'étudiant peut soit saisir le code à 6 chiffres,
/// soit utiliser le QR code généré par le professeur.
class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  bool _success = false;
  String? _error;

  String? _normalizeCode(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return null;
    return cleaned.length == 6 ? cleaned : cleaned;
  }

  Future<void> _pointer() async {
    final raw = _codeCtrl.text.trim();
    final code = _normalizeCode(raw);
    if (code == null || code.length < 6) {
      setState(() => _error = 'Entrez le code à 6 chiffres ou scannez le QR affiché par le professeur.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ApiService.checkinAppel(code);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _success = true;
      } else {
        _error = result['error'];
      }
    });
  }

  void _scanQr() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Scanner le QR de présence'),
            backgroundColor: AppPalette.blue,
            foregroundColor: Colors.white,
          ),
          body: MobileScanner(
            onDetect: (capture) {
              final barcode = capture.barcodes.firstOrNull?.rawValue;
              if (barcode == null || !mounted) return;
              final code = barcode.trim();
              if (code.isEmpty) return;
              _codeCtrl.text = code;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('QR détecté. Vérification de votre présence...'),
                  backgroundColor: AppPalette.blue,
                ),
              );
              _pointer();
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Pointer ma présence',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppPalette.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: _success ? _vueSucces() : _vueSaisie(),
        ),
      ),
    );
  }

  Widget _vueSucces() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 100, height: 100,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF10B981)),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 54),
      ),
      const SizedBox(height: 22),
      const Text('Présence enregistrée !',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF15803D))),
      const SizedBox(height: 8),
      const Text('Bonne séance 👋',
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
      const SizedBox(height: 28),
      SizedBox(
        width: double.infinity, height: 50,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppPalette.blue, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Fermer', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      ),
    ]);
  }

  Widget _vueSaisie() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 90, height: 90,
        decoration: BoxDecoration(
          color: AppPalette.lightBlue,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.qr_code_scanner_rounded, color: AppPalette.blue, size: 44),
      ),
      const SizedBox(height: 22),
      const Text('Code de séance',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
      const SizedBox(height: 8),
      const Text(
        'Saisis le code à 6 chiffres ou scanne le QR affiché par ton professeur pour marquer ta présence.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
      ),
      const SizedBox(height: 26),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _scanQr,
          icon: const Icon(Icons.qr_code_scanner_rounded),
          label: const Text('Scanner le QR code', style: TextStyle(fontWeight: FontWeight.w700)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppPalette.blue,
            side: const BorderSide(color: AppPalette.blue, width: 1.4),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      const SizedBox(height: 18),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: TextField(
          controller: _codeCtrl,
          keyboardType: TextInputType.text,
          maxLength: 36,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          decoration: const InputDecoration(
            hintText: 'Code QR ou 6 chiffres',
            hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(16),
            counterText: '',
          ),
          onSubmitted: (_) => _pointer(),
        ),
      ),
      if (_error != null) ...[
        const SizedBox(height: 12),
        Text(_error!, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626))),
      ],
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity, height: 52,
        child: ElevatedButton.icon(
          onPressed: _loading ? null : _pointer,
          icon: _loading
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : const Icon(Icons.fact_check_rounded),
          label: Text(_loading ? 'Vérification...' : 'Je suis présent(e)',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    ]);
  }
}
