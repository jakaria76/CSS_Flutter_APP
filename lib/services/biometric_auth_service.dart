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

  // ── Device capability check ───────────────────────────────────────────────

  static Future<bool> isBiometricAvailable() async {
    try {
      final canCheck    = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      if (!canCheck || !isSupported) return false;

      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  // ── Enable ────────────────────────────────────────────────────────────────

  static Future<bool> enableFingerprint() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) return false;

      final authenticated = await _auth.authenticate(
        localizedReason: 'Scan your fingerprint to enable biometric login',
      );
      if (!authenticated) return false;

      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return false;

      await _storage.write(key: _keyRefreshToken, value: session.refreshToken);
      await _storage.write(key: _keyEnabled, value: 'true');
      return true;
    } on PlatformException {
      return false;
    }
  }

  // ── Disable ───────────────────────────────────────────────────────────────

  static Future<void> disableFingerprint() async {
    await _storage.delete(key: _keyEnabled);
    await _storage.delete(key: _keyRefreshToken);
  }

  // ── Status ────────────────────────────────────────────────────────────────

  static Future<bool> isFingerprintEnabled() async {
    try {
      final val = await _storage.read(key: _keyEnabled);
      return val == 'true';
    } catch (_) {
      return false;
    }
  }

  // ── Login with fingerprint ────────────────────────────────────────────────

  static Future<AuthResponse?> loginWithFingerprint() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) return null;

      final token = await _storage.read(key: _keyRefreshToken);
      if (token == null) {
        await disableFingerprint();
        return null;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: 'Scan your fingerprint to login',
      );
      if (!authenticated) return null;

      final response = await Supabase.instance.client.auth.setSession(token);

      if (response.session?.refreshToken != null) {
        await _storage.write(
          key: _keyRefreshToken,
          value: response.session!.refreshToken,
        );
      }

      return response;
    } on AuthException {
      await disableFingerprint();
      return null;
    } on PlatformException {
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Refresh stored token after OTP login ──────────────────────────────────

  static Future<void> refreshStoredToken() async {
    final enabled = await isFingerprintEnabled();
    if (!enabled) return;
    final session = Supabase.instance.client.auth.currentSession;
    if (session?.refreshToken != null) {
      await _storage.write(
          key: _keyRefreshToken, value: session!.refreshToken);
    }
  }
}