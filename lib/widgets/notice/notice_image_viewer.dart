import 'package:flutter/material.dart';

/// Full-screen in-app image viewer with pinch-to-zoom support.
class NoticeImageViewer extends StatefulWidget {
  final String imageUrl;

  const NoticeImageViewer({super.key, required this.imageUrl});

  @override
  State<NoticeImageViewer> createState() => _NoticeImageViewerState();
}

class _NoticeImageViewerState extends State<NoticeImageViewer>
    with SingleTickerProviderStateMixin {
  late AnimationController _bgAnim;
  final _transformCtrl = TransformationController();

  @override
  void initState() {
    super.initState();
    _bgAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _bgAnim.dispose();
    _transformCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FadeTransition(
        opacity: _bgAnim,
        child: Container(
          color: Colors.black.withOpacity(0.93),
          child: Stack(children: [
            // Zoomable image
            Center(
              child: InteractiveViewer(
                transformationController: _transformCtrl,
                minScale: 0.5,
                maxScale: 6.0,
                child: Image.network(
                  widget.imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    final percent = progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                        : null;
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 52,
                            height: 52,
                            child: CircularProgressIndicator(
                              value: percent,
                              color: const Color(0xFF00FFFF),
                              backgroundColor:
                              const Color(0xFF00FFFF).withOpacity(0.1),
                              strokeWidth: 2.5,
                            ),
                          ),
                          if (percent != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              '${(percent * 100).toInt()}%',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image_rounded,
                          color: Colors.white30, size: 64),
                      SizedBox(height: 12),
                      Text(
                        'ছবি লোড করা যায়নি',
                        style:
                        TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Close button (top-left)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border:
                      Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),

            // Zoom-reset button (top-right)
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: () =>
                    _transformCtrl.value = Matrix4.identity(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.18)),
                      ),
                      child: const Icon(Icons.zoom_out_rounded,
                          color: Colors.white70, size: 20),
                    ),
                  ),
                ),
              ),
            ),

            // Hint label (bottom)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.12)),
                    ),
                    child: const Text(
                      'Pinch to zoom • Double tap to reset',
                      style:
                      TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}