import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart'; // আপনার পাথ নিশ্চিত করুন

class RegistrationTile extends StatelessWidget {
  final Map<String, dynamic> data;

  const RegistrationTile({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    // থিম এবং ভাষা পরিবর্তনের জন্য লিসেনার
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (context, _, __) => ValueListenableBuilder<String>(
        valueListenable: SC.languageNotifier,
        builder: (context, __, ___) => _buildTile(context),
      ),
    );
  }

  Widget _buildTile(BuildContext context) {
    final isDark = SC.isDark;
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05);
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
              color: isDark ? cardBg : cardBg.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
              boxShadow: isDark ? [] : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(img, isDark),
                const SizedBox(width: 16),
                Expanded(child: _buildInfo(isDark)),
                Icon(
                    Icons.arrow_forward_ios,
                    color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.2),
                    size: 14
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String? url, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: SC.cyan.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: SC.cyan.withValues(alpha: 0.1),
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
          errorBuilder: (_, __, ___) => _avatarPlaceholder(isDark),
        )
            : _avatarPlaceholder(isDark),
      ),
    );
  }

  Widget _avatarPlaceholder(bool isDark) {
    return Container(
      width: 70,
      height: 70,
      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
      child: Center(
        child: Icon(Icons.person_outline, color: SC.cyan, size: 30),
      ),
    );
  }

  Widget _buildInfo(bool isDark) {
    final fullName = (data['full_name'] ?? SC.tr('unknown_user')).toString().toUpperCase();
    final mobile = data['mobile'] ?? SC.tr('no_mobile');
    final email = data['email'];
    final institute = data['institute_name'] ?? SC.tr('no_institute');
    final className = data['class_name'] ?? '';
    final payment = data['payment_method'] ?? 'FREE';
    final isVolunteer = data['will_volunteer'] == true;

    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final subTextColor = isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF4A5568);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fullName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: textColor,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),

        Row(
          children: [
            Icon(Icons.phone_android, size: 12, color: subTextColor),
            const SizedBox(width: 4),
            Text(
              mobile,
              style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 13),
            ),
          ],
        ),

        if (email != null && email.toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              email.toString(),
              style: TextStyle(color: subTextColor, fontSize: 12),
            ),
          ),

        const SizedBox(height: 6),

        Text(
          '$institute ${className.isNotEmpty ? '• $className' : ''}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: SC.cyan.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500
          ),
        ),

        const SizedBox(height: 10),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _badge(payment.toUpperCase(), SC.orange),
            if (isVolunteer)
              _badge(SC.tr('volunteer_badge'), SC.green),
          ],
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            Icon(Icons.access_time, size: 12, color: subTextColor.withValues(alpha: 0.6)),
            const SizedBox(width: 4),
            Text(
              _formatDate(data['registered_at']),
              style: TextStyle(
                fontSize: 11,
                color: subTextColor.withValues(alpha: 0.6),
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
    if (dt == null) return SC.tr('date_na');
    try {
      final d = DateTime.parse(dt).toLocal();
      final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
      return '${d.day} ${months[d.month - 1]} ${d.year} • ${d.hour % 12 == 0 ? 12 : d.hour % 12}:${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'PM' : 'AM'}';
    } catch (_) {
      return SC.tr('invalid_date');
    }
  }
}