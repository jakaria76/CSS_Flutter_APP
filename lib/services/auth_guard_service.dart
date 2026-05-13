import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'session_service.dart';

/// Global auth guard — call [AuthGuardService.init()] once after login.
///
/// Watches THREE things:
///   1. Supabase auth state  → server-side session revoke
///   2. profiles table       → admin block / delete
///   3. user_sessions table  → remote revoke from another device
class AuthGuardService {
  AuthGuardService._();

  static final _supabase = Supabase.instance.client;
  static RealtimeChannel? _profileChannel;
  static RealtimeChannel? _sessionChannel;
  static StreamSubscription<AuthState>? _authSub;
  static bool _initialized = false;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Login success এর পরে একবার call করুন।
  /// OtpVerifyPage, MFALoginVerifyPage, এবং app reopen এ।
  static void init(BuildContext context) {
    if (_initialized) return;
    _initialized = true;

    // ১. Supabase auth state watch — server-side session revoke
    _authSub = _supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut ||
          data.event == AuthChangeEvent.userDeleted) {
        _cleanup();
        _forceLogout(context, reason: 'deleted');
      }
    });

    // ২. profiles table watch — admin block/delete
    _listenToProfile(context);

    // ৩. user_sessions table watch — remote revoke
    _listenToSession(context);
  }

  /// Manual logout এর আগে call করুন।
  /// CustomDrawer logout button এ।
  static void dispose() {
    _cleanup();
  }

  // ── Profile Listener ───────────────────────────────────────────────────────

  static void _listenToProfile(BuildContext context) {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;

    _profileChannel = _supabase
        .channel('profile_guard_$uid')
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'profiles',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: uid,
      ),
      callback: (payload) {
        final status =
            payload.newRecord['account_status']?.toString() ?? 'active';
        if (status == 'blocked') {
          _cleanup();
          _forceLogout(context, reason: 'blocked');
        }
      },
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'profiles',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: uid,
      ),
      callback: (_) {
        _cleanup();
        _forceLogout(context, reason: 'deleted');
      },
    )
        .subscribe();
  }

  // ── Session Listener ───────────────────────────────────────────────────────

  static void _listenToSession(BuildContext context) {
    final uid = _supabase.auth.currentUser?.id;
    final currentKey = SessionService.getCurrentSessionKey();
    if (uid == null || currentKey == null) return;

    _sessionChannel = _supabase
        .channel('session_guard_${uid}_$currentKey')
        .onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'user_sessions',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: uid,
      ),
      callback: (payload) {
        final deletedKey =
            payload.oldRecord['session_key']?.toString() ?? '';
        if (deletedKey == currentKey) {
          _cleanup();
          _forceLogout(context, reason: 'revoked');
        }
      },
    )
        .subscribe();
  }

  // ── Cleanup ────────────────────────────────────────────────────────────────

  static void _cleanup() {
    _initialized = false;
    _profileChannel?.unsubscribe();
    _profileChannel = null;
    _sessionChannel?.unsubscribe();
    _sessionChannel = null;
    _authSub?.cancel();
    _authSub = null;
  }

  // ── Force Logout ───────────────────────────────────────────────────────────

  static Future<void> _forceLogout(
      BuildContext context, {
        required String reason,
      }) async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {}

    if (!context.mounted) return;

    Navigator.of(context, rootNavigator: true)
        .pushNamedAndRemoveUntil('/welcome', (route) => false);

    await Future.delayed(const Duration(milliseconds: 400));
    if (!context.mounted) return;
    _showForcedLogoutDialog(context, reason: reason);
  }

  // ── Dialog ─────────────────────────────────────────────────────────────────

  static void _showForcedLogoutDialog(
      BuildContext context, {
        required String reason,
      }) {
    final Color color;
    final IconData icon;
    final String title;
    final String message;

    switch (reason) {
      case 'blocked':
        color = const Color(0xFFFF8A65);
        icon = Icons.block_rounded;
        title = 'Account Blocked';
        message =
        'Your account has been blocked by an administrator. You cannot log in with this account.';
        break;
      case 'revoked':
        color = const Color(0xFFFFCA28);
        icon = Icons.logout_rounded;
        title = 'Session Ended';
        message =
        'This session was signed out from another device. Please log in again to continue.';
        break;
      default: // deleted
        color = const Color(0xFFEF5350);
        icon = Icons.delete_forever_rounded;
        title = 'Account Deleted';
        message =
        'Your account has been permanently deleted by an administrator. You have been logged out.';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (_) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1E2E),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                      color: color.withOpacity(0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.15),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Icon ────────────────────────────────────────
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withOpacity(0.12),
                        border: Border.all(
                            color: color.withOpacity(0.35), width: 1.5),
                      ),
                      child: Icon(icon, size: 40, color: color),
                    ),
                    const SizedBox(height: 24),

                    // ── Title ───────────────────────────────────────
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Message ─────────────────────────────────────
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 14,
                        height: 1.65,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── OK Button ───────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          padding:
                          const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'OK',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: 0.5,
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
  }
}