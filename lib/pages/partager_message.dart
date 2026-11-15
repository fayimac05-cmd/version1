import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Partage le texte d'un message VERS L'EXTÉRIEUR de l'application
/// (WhatsApp, e-mail) ou le copie. Rien n'est envoyé dans la discussion
/// en cours : il n'y a donc aucun contournement des droits d'écriture.
Future<void> partagerMessage(BuildContext context, String texte) async {
  var contenu = texte.trim();
  if (contenu.startsWith('[GIF]')) contenu = contenu.substring(5).trim();
  if (contenu.startsWith('[STICKER]')) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ce type de message ne peut pas être partagé.')));
    return;
  }
  if (contenu.isEmpty) return;

  Future<void> ouvrir(Uri uri, String erreur) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erreur)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erreur)));
      }
    }
  }

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) {
      Widget option(IconData icon, Color color, String titre, VoidCallback onTap) {
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Text(titre,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          onTap: () {
            Navigator.pop(sheetCtx);
            onTap();
          },
        );
      }

      return Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Partager via',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Le message ne sera pas renvoyé dans cette discussion.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ),
            ),
            const Divider(height: 1),
            option(Icons.chat_rounded, const Color(0xFF25D366), 'WhatsApp', () {
              ouvrir(
                Uri.parse('https://wa.me/?text=${Uri.encodeComponent(contenu)}'),
                'Impossible d\'ouvrir WhatsApp.',
              );
            }),
            option(Icons.mail_outline_rounded, const Color(0xFF0A4DA2), 'E-mail', () {
              ouvrir(
                Uri.parse(
                    'mailto:?subject=${Uri.encodeComponent('Message ScolarHub')}&body=${Uri.encodeComponent(contenu)}'),
                'Impossible d\'ouvrir l\'application e-mail.',
              );
            }),
            option(Icons.copy_rounded, const Color(0xFF64748B), 'Copier le texte', () {
              Clipboard.setData(ClipboardData(text: contenu));
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Texte copié')));
              }
            }),
            const SizedBox(height: 8),
          ]),
        ),
      );
    },
  );
}
