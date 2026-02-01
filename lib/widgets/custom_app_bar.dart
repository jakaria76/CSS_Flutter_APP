import 'package:flutter/material.dart';
import 'dart:async';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  final List<String> _titles = [
    'সচেতন ছাত্র সমাজ',
    'Conscious Student Society',
    'সমাজ সেবায় নিবেদিত',
    'Sochetona Chatro Shomaj',
  ];

  int _currentIndex = 0;
  String _displayedText = '';
  bool _isDeleting = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTypewriter();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTypewriter() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        final currentTitle = _titles[_currentIndex];

        if (!_isDeleting) {
          // Typing
          if (_displayedText.length < currentTitle.length) {
            _displayedText = currentTitle.substring(0, _displayedText.length + 1);
          } else {
            // Pause before deleting
            timer.cancel();
            Future.delayed(const Duration(seconds: 2), () {
              _isDeleting = true;
              _startTypewriter();
            });
          }
        } else {
          // Deleting
          if (_displayedText.isNotEmpty) {
            _displayedText = _displayedText.substring(0, _displayedText.length - 1);
          } else {
            // Move to next title
            _isDeleting = false;
            _currentIndex = (_currentIndex + 1) % _titles.length;
            timer.cancel();
            Future.delayed(const Duration(milliseconds: 500), () {
              _startTypewriter();
            });
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF132D46),
      elevation: 0,
      centerTitle: true,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: const Icon(Icons.menu_rounded, color: Colors.cyanAccent, size: 22),
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.white, Colors.cyanAccent],
              ).createShader(bounds),
              child: Text(
                _displayedText,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                  fontSize: 18,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
          // Blinking cursor
          AnimatedOpacity(
            opacity: _isDeleting ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 500),
            child: Container(
              width: 2,
              height: 18,
              margin: const EdgeInsets.only(left: 2),
              decoration: BoxDecoration(
                color: Colors.cyanAccent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}