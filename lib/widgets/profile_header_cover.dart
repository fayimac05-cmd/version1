import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/profile_media_service.dart';
import 'image_viewer_dialog.dart';

/// Composant Premium unifié affichant la Bannière de Couverture et la Photo de Profil
/// avec gestion interactive complète (Modification, Prise de vue, Galerie, Plein écran, Suppression).
class ProfileHeaderCover extends StatefulWidget {
  const ProfileHeaderCover({
    super.key,
    required this.matricule,
    required this.nomComplet,
    required this.roleLabel,
    required this.initiales,
    this.badgeText,
    this.badgeColor,
    this.accentColor = const Color(0xFF1E40AF),
    this.bannerGradient = const [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF3B82F6)],
    this.canEdit = true,
    this.onMediaChanged,
  });

  final String matricule;
  final String nomComplet;
  final String roleLabel;
  final String initiales;
  final String? badgeText;
  final Color? badgeColor;
  final Color accentColor;
  final List<Color> bannerGradient;
  final bool canEdit;
  final VoidCallback? onMediaChanged;

  @override
  State<ProfileHeaderCover> createState() => _ProfileHeaderCoverState();
}

class _ProfileHeaderCoverState extends State<ProfileHeaderCover> {
  String? _profilePhotoPath;
  String? _coverPhotoPath;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _chargerPhotos();
    ProfileMediaService.mediaNotifier.addListener(_onMediaNotifier);
  }

  @override
  void didUpdateWidget(ProfileHeaderCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.matricule != widget.matricule) {
      _chargerPhotos();
    }
  }

  @override
  void dispose() {
    ProfileMediaService.mediaNotifier.removeListener(_onMediaNotifier);
    super.dispose();
  }

  void _onMediaNotifier() {
    if (mounted) _chargerPhotos();
  }

  Future<void> _chargerPhotos() async {
    final avatar =
        await ProfileMediaService.instance.getProfilePhotoPath(widget.matricule);
    final cover =
        await ProfileMediaService.instance.getCoverPhotoPath(widget.matricule);
    if (mounted) {
      setState(() {
        _profilePhotoPath = avatar;
        _coverPhotoPath = cover;
      });
    }
  }

  Widget _buildInitialsAvatar() {
    return Container(
      color: widget.accentColor.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          widget.initiales,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: widget.accentColor,
          ),
        ),
      ),
    );
  }

  void _showCoverOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Photo de Couverture',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              if (_coverPhotoPath != null && _coverPhotoPath!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.fullscreen_rounded, color: Color(0xFF1E40AF)),
                  title: const Text('Voir en grand'),
                  onTap: () {
                    Navigator.pop(ctx);
                    ImageViewerDialog.show(
                      context,
                      imagePathOrUrl: _coverPhotoPath!,
                      title: 'Photo de couverture',
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF2563EB)),
                title: const Text('Choisir dans la galerie'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickCover(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF059669)),
                title: const Text('Prendre une photo'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickCover(ImageSource.camera);
                },
              ),
              if (_coverPhotoPath != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
                  title: const Text('Supprimer la couverture', style: TextStyle(color: Color(0xFFDC2626))),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ProfileMediaService.instance.deleteCoverPhoto(widget.matricule);
                    _chargerPhotos();
                    widget.onMediaChanged?.call();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickCover(ImageSource source) async {
    setState(() => _loading = true);
    try {
      final path = await ProfileMediaService.instance
          .pickAndSaveCoverPhoto(widget.matricule, source: source);
      if (path != null && mounted) {
        setState(() => _coverPhotoPath = path);
        widget.onMediaChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo de couverture mise à jour !'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      debugPrint('[ProfileHeaderCover] _pickCover error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'importer la couverture: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Actions Photo de Profil ──────────────────────────────────────────────

  void _showProfileOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Photo de Profil',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              if (_profilePhotoPath != null && _profilePhotoPath!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.fullscreen_rounded, color: Color(0xFF1E40AF)),
                  title: const Text('Voir en grand'),
                  onTap: () {
                    Navigator.pop(ctx);
                    ImageViewerDialog.show(
                      context,
                      imagePathOrUrl: _profilePhotoPath!,
                      title: 'Photo de profil',
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF2563EB)),
                title: const Text('Choisir dans la galerie'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickProfile(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF059669)),
                title: const Text('Prendre un selfie / photo'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickProfile(ImageSource.camera);
                },
              ),
              if (_profilePhotoPath != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
                  title: const Text('Supprimer la photo', style: TextStyle(color: Color(0xFFDC2626))),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ProfileMediaService.instance.deleteProfilePhoto(widget.matricule);
                    _chargerPhotos();
                    widget.onMediaChanged?.call();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickProfile(ImageSource source) async {
    setState(() => _loading = true);
    try {
      final path = await ProfileMediaService.instance
          .pickAndSaveProfilePhoto(widget.matricule, source: source);
      if (path != null && mounted) {
        setState(() => _profilePhotoPath = path);
        widget.onMediaChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo de profil mise à jour !'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      debugPrint('[ProfileHeaderCover] _pickProfile error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'importer la photo: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build Widget ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const double bannerHeight = 150.0;
    const double avatarRadius = 48.0;

    final hasCover = _coverPhotoPath != null && _coverPhotoPath!.isNotEmpty;
    final isCoverNetwork = hasCover &&
        (kIsWeb ||
         _coverPhotoPath!.startsWith('http://') ||
         _coverPhotoPath!.startsWith('https://') ||
         _coverPhotoPath!.startsWith('data:') ||
         _coverPhotoPath!.startsWith('blob:'));

    final hasAvatar = _profilePhotoPath != null && _profilePhotoPath!.isNotEmpty;
    final isAvatarNetwork = hasAvatar &&
        (kIsWeb ||
         _profilePhotoPath!.startsWith('http://') ||
         _profilePhotoPath!.startsWith('https://') ||
         _profilePhotoPath!.startsWith('data:') ||
         _profilePhotoPath!.startsWith('blob:'));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── BANNIÈRE DE COUVERTURE AVEC AVATAR SUPERPOSÉ ──────────────────
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Bannière
              GestureDetector(
                onTap: widget.canEdit
                    ? _showCoverOptions
                    : (hasCover
                        ? () => ImageViewerDialog.show(
                              context,
                              imagePathOrUrl: _coverPhotoPath!,
                              title: 'Photo de couverture',
                            )
                        : null),
                child: Container(
                  height: bannerHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
                    gradient: hasCover ? null : LinearGradient(colors: widget.bannerGradient),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (hasCover)
                          isCoverNetwork
                              ? Image.network(
                                  _coverPhotoPath!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => CustomPaint(painter: _BannerPatternPainter()),
                                )
                              : Image.file(
                                  File(_coverPhotoPath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => CustomPaint(painter: _BannerPatternPainter()),
                                )
                        else
                          // Motif abstrait moderne
                          CustomPaint(
                            painter: _BannerPatternPainter(),
                          ),
                        // Dégradé pour lisibilité
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.15),
                                Colors.black.withValues(alpha: 0.45),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Indicateur de chargement sur la bannière
              if (_loading)
                Positioned(
                  top: 0, left: 0, right: 0,
                  height: 150,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.35),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      ),
                    ),
                  ),
                ),

              // Bouton Modifier Couverture
              if (widget.canEdit)
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: _showCoverOptions,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt_outlined, color: Colors.white, size: 14),
                          SizedBox(width: 5),
                          Text(
                            'Couverture',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── AVATAR CENTRAL SUPERPOSÉ ──────────────────────────────────
              Positioned(
                bottom: -avatarRadius,
                left: 0,
                right: 0,
                child: Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      GestureDetector(
                        onTap: widget.canEdit
                            ? _showProfileOptions
                            : (hasAvatar
                                ? () => ImageViewerDialog.show(
                                      context,
                                      imagePathOrUrl: _profilePhotoPath!,
                                      title: 'Photo de profil',
                                    )
                                : null),
                        child: Container(
                          width: avatarRadius * 2,
                          height: avatarRadius * 2,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: hasAvatar
                                ? (isAvatarNetwork
                                    ? Image.network(
                                        _profilePhotoPath!,
                                        fit: BoxFit.cover,
                                        width: avatarRadius * 2,
                                        height: avatarRadius * 2,
                                        errorBuilder: (_, __, ___) => _buildInitialsAvatar(),
                                      )
                                    : Image.file(
                                        File(_profilePhotoPath!),
                                        fit: BoxFit.cover,
                                        width: avatarRadius * 2,
                                        height: avatarRadius * 2,
                                        errorBuilder: (_, __, ___) => _buildInitialsAvatar(),
                                      ))
                                : _buildInitialsAvatar(),
                          ),
                        ),
                      ),

                      // Badge caméra pour modifier l'avatar
                      if (widget.canEdit)
                        GestureDetector(
                          onTap: _showProfileOptions,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 15,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Espace pour compenser le débordement de l'avatar
          const SizedBox(height: avatarRadius + 14),

          // ── INFORMATIONS IDENTITÉ & BADGES ────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text(
                  widget.nomComplet,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.matricule,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (widget.badgeColor ?? widget.accentColor).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: (widget.badgeColor ?? widget.accentColor).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        widget.roleLabel.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: widget.badgeColor ?? widget.accentColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (widget.badgeText != null && widget.badgeText!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          widget.badgeText!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _BannerPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.3), 60, paint);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.7), 90, paint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 1.1), 80, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
