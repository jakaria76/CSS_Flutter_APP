import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool center;

  const SectionTitle({
    super.key,
    required this.icon,
    required this.title,
    this.center = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
      center ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue, size: 26),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xff003c8f),
          ),
        ),
      ],
    );
  }
}
