import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/committee_member_model.dart';
import '../pages/Profile/profile_page.dart';

class CommitteeCard extends StatefulWidget {
  final CommitteeMember member;
  final VoidCallback? onViewProfile;

  const CommitteeCard({
    super.key,
    required this.member,
    this.onViewProfile,
  });

  @override
  State<CommitteeCard> createState() => _CommitteeCardState();
}

class _CommitteeCardState extends State<CommitteeCard> with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );

    _glowAnimation = Tween<double>(begin: 0.05, end: 0.15).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _handleViewProfile() {
    // Haptic feedback
    HapticFeedback.lightImpact();

    if (widget.onViewProfile != null) {
      widget.onViewProfile!();
    } else {
      // সরাসরি ProfilePage এ নেভিগেট করা
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfilePage(id: widget.member.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // মেম্বার টাইপ অনুযায়ী কালার থিম
    final bool isTopLeader = widget.member.category == 'Top';
    final Color primaryColor = isTopLeader ? const Color(0xFFFFD700) : const Color(0xFF00D4FF);
    final Color secondaryColor = isTopLeader ? const Color(0xFFFF8C00) : const Color(0xFF0099CC);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() {
        _isHovered = true;
        _hoverController.forward();
      }),
      onExit: (_) => setState(() {
        _isHovered = false;
        _hoverController.reverse();
      }),
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.12),
                    Colors.white.withOpacity(0.03),
                  ],
                ),
                border: Border.all(
                  color: primaryColor.withOpacity(_isHovered ? 0.4 : 0.2),
                  width: _isHovered ? 2.0 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(_glowAnimation.value),
                    blurRadius: _isHovered ? 30 : 20,
                    offset: const Offset(0, 10),
                    spreadRadius: _isHovered ? 5 : 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryColor.withOpacity(0.05),
                          Colors.transparent,
                          secondaryColor.withOpacity(0.03),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Profile Image Section with Error/Loading Handling
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(_isHovered ? 0.3 : 0.15),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              CircleAvatar(
                                radius: 42,
                                backgroundColor: primaryColor.withOpacity(0.3),
                                child: ClipOval(
                                  child: Container(
                                    width: 76,
                                    height: 76,
                                    color: const Color(0xFF132D46),
                                    child: widget.member.imagePath != null && widget.member.imagePath!.isNotEmpty
                                        ? Image.network(
                                      widget.member.imagePath!,
                                      fit: BoxFit.cover,
                                      // ইমেজ লোড হওয়ার সময় লোডার দেখাবে
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                          ),
                                        );
                                      },
                                      // ইমেজ এরর (যেমন 400 Bad Request) হলে ডিফল্ট আইকন দেখাবে
                                      errorBuilder: (context, error, stackTrace) => Icon(
                                        Icons.person_rounded,
                                        size: 40,
                                        color: primaryColor.withOpacity(0.5),
                                      ),
                                    )
                                        : Icon(
                                      Icons.person_rounded,
                                      size: 40,
                                      color: primaryColor.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ),
                              if (isTopLeader)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [primaryColor, secondaryColor]),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF132D46), width: 2),
                                    ),
                                    child: const Icon(Icons.star, size: 12, color: Color(0xFF0F2027)),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Name Section
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: _isHovered ? [primaryColor, secondaryColor] : [Colors.white, Colors.white],
                            ).createShader(bounds),
                            child: Text(
                              widget.member.fullName,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Position Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: primaryColor.withOpacity(0.3)),
                            ),
                            child: Text(
                              widget.member.position,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: primaryColor,
                              ),
                            ),
                          ),

                          const Spacer(),

                          // View Profile Button
                          Container(
                            width: double.infinity,
                            height: 38,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(colors: [primaryColor, secondaryColor]),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _handleViewProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                "VIEW PROFILE",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: isTopLeader ? const Color(0xFF0F2027) : Colors.white,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}