import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BiometricAuthService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _keyEnabled      = 'fingerprint_enabled';
  static const String _keyRefreshToken = 'biometric_refresh_token';

  static StreamSubscription<AuthState>? _authSub;
  static bool _listenerAttached = false;

  // ── Initialize ────────────────────────────────────────────────────────────
  static void initialize() {
    if (_listenerAttached) return;
    _listenerAttached = true;

    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen(
          (data) async {
        final event   = data.event;
        final session = data.session;
        if (session?.refreshToken == null) return;

        if (event == AuthChangeEvent.tokenRefreshed ||
            event == AuthChangeEvent.signedIn ||
            event == AuthChangeEvent.initialSession) {
          final enabled = await isFingerprintEnabled();
          if (enabled) {
            await _storage.write(
                key: _keyRefreshToken, value: session!.refreshToken!);
            _log('auto-sync: token updated via $event');
          }
        }
      },
      onError: (e) => _log('auth listener error: $e'),
    );
    _log('initialize: listener attached ✅');
  }

  static void disposeListener() {
    _authSub?.cancel();
    _authSub = null;
    _listenerAttached = false;
  }

  // ── Device check ──────────────────────────────────────────────────────────

  static Future<bool> isBiometricAvailable() async {
    try {
      final canCheck    = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      if (!canCheck || !isSupported) return false;
      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } on PlatformException catch (e) {
      _log('isBiometricAvailable error: ${e.message}');
      return false;
    }
  }

  // ── Enable ────────────────────────────────────────────────────────────────

  static Future<bool> enableFingerprint() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        _log('enableFingerprint: not available');
        return false;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: 'Scan your fingerprint to enable biometric login',
      );
      if (!authenticated) {
        _log('enableFingerprint: cancelled');
        return false;
      }

      final session = Supabase.instance.client.auth.currentSession;
      final token   = session?.refreshToken;

      if (token == null || token.isEmpty) {
        _log('enableFingerprint: no refresh token in session');
        return false;
      }

      await _storage.write(key: _keyRefreshToken, value: token);
      await _storage.write(key: _keyEnabled, value: 'true');
      _log('enableFingerprint: success ✅');
      return true;
    } on PlatformException catch (e) {
      _log('enableFingerprint PlatformException: ${e.message}');
      return false;
    } catch (e) {
      _log('enableFingerprint error: $e');
      return false;
    }
  }

  // ── Disable ───────────────────────────────────────────────────────────────

  static Future<void> disableFingerprint() async {
    await _storage.delete(key: _keyEnabled);
    await _storage.delete(key: _keyRefreshToken);
    _log('disableFingerprint: done');
  }

  // ── Status checks ─────────────────────────────────────────────────────────

  static Future<bool> isFingerprintEnabled() async {
    try {
      return await _storage.read(key: _keyEnabled) == 'true';
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasStoredToken() async {
    try {
      final t = await _storage.read(key: _keyRefreshToken);
      return t != null && t.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ── Login with fingerprint ────────────────────────────────────────────────

  static Future<AuthResponse?> loginWithFingerprint() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        _log('loginWithFingerprint: not available');
        return null;
      }

      final token = await _storage.read(key: _keyRefreshToken);
      if (token == null || token.isEmpty) {
        _log('loginWithFingerprint: no stored token, disabling');
        await disableFingerprint();
        return null;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: 'Scan your fingerprint to login',
      );
      if (!authenticated) {
        _log('loginWithFingerprint: cancelled/mismatch');
        return null;
      }

      _log('loginWithFingerprint: fingerprint matched!');

      // ✅ FIX: App Lock Pattern - চেক করছি সেশন আগে থেকেই অ্যাক্টিভ আছে কিনা
      final currentSession = Supabase.instance.client.auth.currentSession;

      if (currentSession != null) {
        _log('loginWithFingerprint: session already active, refreshing...');
        // সেশন অ্যাক্টিভ থাকলে শুধু refresh করে ভেরিফাই করে নিচ্ছি
        final response = await Supabase.instance.client.auth.refreshSession();
        if (response.session != null && response.session!.refreshToken != null) {
          await _storage.write(key: _keyRefreshToken, value: response.session!.refreshToken!);
        }
        return AuthResponse(session: response.session, user: response.user);
      }

      // যদি মেমরি থেকে সেশন ক্লিয়ার হয়ে গিয়ে থাকে, তবে সেভ করা টোকেন দিয়ে রিস্টোর হবে
      _log('loginWithFingerprint: restoring session from token...');
      final response = await Supabase.instance.client.auth
          .setSession(token)
          .timeout(const Duration(seconds: 15));

      if (response.session == null || response.user == null) {
        _log('loginWithFingerprint: null session, disabling');
        await disableFingerprint();
        return null;
      }

      // Rotated token save
      final newToken = response.session!.refreshToken;
      if (newToken != null && newToken.isNotEmpty) {
        await _storage.write(key: _keyRefreshToken, value: newToken);
        _log('loginWithFingerprint: success, rotated token saved ✅');
      }

      return response;

    } on AuthException catch (e) {
      _log('loginWithFingerprint AuthException: ${e.message}');

      final msg = e.message.toLowerCase();
      final isInvalid =
          msg.contains('refresh_token_not_found') ||
              msg.contains('refresh_token_already_used') ||
              msg.contains('token_not_found') ||
              msg.contains('invalid_grant') ||
              msg.contains('invalid refresh token') ||
              (msg.contains('refresh') && msg.contains('not found')) ||
              (msg.contains('token') && msg.contains('revoked')) ||
              msg.contains('session_not_found') ||
              msg.contains('user_not_found');

      if (isInvalid) {
        _log('loginWithFingerprint: invalid token, disabling');
        await disableFingerprint();
      }
      return null;

    } on PlatformException catch (e) {
      _log('loginWithFingerprint PlatformException: ${e.message}');
      return null;
    } on TimeoutException {
      _log('loginWithFingerprint: timeout, keeping token for retry');
      return null;
    } catch (e) {
      _log('loginWithFingerprint error: $e');
      return null;
    }
  }

  // ── Email/OTP/MFA login সফল হলে token refresh ────────────────────────────

  static Future<void> refreshStoredToken() async {
    final enabled = await isFingerprintEnabled();
    if (!enabled) return;
    final token = Supabase.instance.client.auth.currentSession?.refreshToken;
    if (token != null) {
      await _storage.write(key: _keyRefreshToken, value: token);
      _log('refreshStoredToken: updated ✅');
    }
  }

  static void _log(String msg) {
    if (kDebugMode) debugPrint('[BiometricAuthService] $msg');
  }
}