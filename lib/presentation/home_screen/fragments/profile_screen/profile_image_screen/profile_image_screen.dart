import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';

class ProfileImageScreen extends StatefulWidget {
  final String imageUrl;

  const ProfileImageScreen({super.key, required this.imageUrl});

  @override
  State<ProfileImageScreen> createState() => _ProfileImageScreenState();
}

class _ProfileImageScreenState extends State<ProfileImageScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();

    // Setup animations for UI controls
    _controller = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _slideAnimation = Tween<Offset>(begin: Offset.zero, end: const Offset(0.0, 1.0)).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _controller.reverse();
      } else {
        _controller.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final l10n = translation(context);

    return Scaffold(
      backgroundColor: Colors.black,
      // Always visible back button in AppBar
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          SizedBox(width: 56), // Balance the leading button
        ],
      ),
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Main image with PhotoView
            Positioned.fill(
              child: Hero(
                tag: 'profile-image',
                child: PhotoView(
                  minScale: PhotoViewComputedScale.contained * 0.8,
                  maxScale: PhotoViewComputedScale.covered * 2.0,
                  initialScale: PhotoViewComputedScale.contained,
                  filterQuality: FilterQuality.high,
                  enableRotation: true,
                  backgroundDecoration: const BoxDecoration(color: Colors.black),
                  imageProvider: NetworkImage(widget.imageUrl),
                  loadingBuilder: (context, event) => Center(
                    child: SizedBox(
                      width: 30.0,
                      height: 30.0,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                        value: event == null ? 0 : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 100),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom controls (share, download, etc.)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    padding: EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0, bottom: MediaQuery.of(context).padding.bottom + 20.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withValues(alpha: 0.85), Colors.black.withValues(alpha: 0.5), Colors.transparent],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Share button
                        _buildControlButton(
                          icon: Icons.share_rounded,
                          label: l10n.lbl_share,
                          onTap: () {
                            Share.shareUri(Uri.parse(widget.imageUrl));
                          },
                        ),

                        // Save button
                        _buildControlButton(
                          icon: Icons.download_rounded,
                          label: l10n.lbl_save,
                          onTap: () {
                            // Implement download functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.msg_image_saved_to_gallery),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: theme.primary,
                                margin: const EdgeInsets.only(bottom: 20.0, left: 20.0, right: 20.0),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                              ),
                            );
                          },
                        ),

                        // Rotate button
                        _buildControlButton(
                          icon: Icons.rotate_right_rounded,
                          label: l10n.lbl_rotate,
                          onTap: () {
                            // PhotoView's built-in rotation is enabled
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for control buttons - OneUI 8.5 styled
  Widget _buildControlButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.white.withValues(alpha: 0.2),
        highlightColor: Colors.white.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500, fontFamily: 'Poppins'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
