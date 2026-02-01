import 'package:flutter/material.dart';

class BackgroundOrbs extends StatelessWidget {
  const BackgroundOrbs({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 200,
          left: -50,
          child: _orb(300, Colors.cyanAccent.withOpacity(0.05)),
        ),
        Positioned(
          bottom: 100,
          right: -50,
          child: _orb(400, Colors.purpleAccent.withOpacity(0.05)),
        ),
      ],
    );
  }

  Widget _orb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 100,
            spreadRadius: 50,
          )
        ],
      ),
    );
  }
}