import 'dart:ui';
import 'package:flutter/material.dart';

class RegistrationTile extends StatelessWidget {
  final Map<String, dynamic> data;

  const RegistrationTile({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final img = data['user_image_url'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(img),
                const SizedBox(width: 16),
                Expanded(child: _buildInfo()),
                // একটি ছোট অ্যারো আইকন যা ডিটেইলস দেখার ইঙ্গিত দেয়
                Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.2), size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String? url) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withValues(alpha: 0.1),
            blurRadius: 8,
            spreadRadius: 1,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: url != null && url.isNotEmpty
            ? Image.network(
          url,
          width: 70,
          height: 70,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _avatarPlaceholder(),
        )
            : _avatarPlaceholder(),
      ),
    );
  }

  Widget _avatarPlaceholder() {
    return Container(
      width: 70,
      height: 70,
      color: Colors.white.withValues(alpha: 0.05),
      child: const Center(
        child: Icon(Icons.person_outline, color: Colors.cyanAccent, size: 30),
      ),
    );
  }

  Widget _buildInfo() {
    final fullName = (data['full_name'] ?? 'Unknown User').toString().toUpperCase();
    final mobile = data['mobile'] ?? 'No Mobile';
    final email = data['email'];
    final institute = data['institute_name'] ?? 'No Institute';
    final className = data['class_name'] ?? '';
    final payment = data['payment_method'] ?? 'FREE';
    final isVolunteer = data['will_volunteer'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fullName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),

        Row(
          children: [
            Icon(Icons.phone_android, size: 12, color: Colors.white.withValues(alpha: 0.5)),
            const SizedBox(width: 4),
            Text(
              mobile,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
            ),
          ],
        ),

        if (email != null && email.toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              email.toString(),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
            ),
          ),

        const SizedBox(height: 6),

        Text(
          '$institute ${className.isNotEmpty ? '• $className' : ''}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.cyanAccent.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w500),
        ),

        const SizedBox(height: 10),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _badge(payment.toUpperCase(), Colors.orange),
            if (isVolunteer)
              _badge('VOLUNTEER', Colors.greenAccent),
          ],
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            Icon(Icons.access_time, size: 12, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(width: 4),
            Text(
              _formatDate(data['registered_at']),
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.3),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 10,
          letterSpacing: 1,
        ),
      ),
    );
  }

  String _formatDate(String? dt) {
    if (dt == null) return 'DATE N/A';
    try {
      final d = DateTime.parse(dt).toLocal();
      final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
      return '${d.day} ${months[d.month - 1]} ${d.year} • ${d.hour % 12 == 0 ? 12 : d.hour % 12}:${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'PM' : 'AM'}';
    } catch (_) {
      return 'INVALID DATE';
    }
  }
}