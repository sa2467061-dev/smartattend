import 'package:shared_preferences/shared_preferences.dart';

/// Handles saving, reading, and clearing the locally persisted login session.
/// This survives app swipe-away, force-stop, and phone restarts — it only
/// gets cleared by an explicit logout or a full app uninstall.
class SessionManager {
  static const _keyUserId = 'session_user_id';
  static const _keyUserRole = 'session_user_role';

  /// Call this right after a successful login.
  static Future<void> saveSession({
    required String userId,
    required String userRole, // 'student' or 'lecturer'
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyUserRole, userRole);
  }

  /// Returns {'userId': ..., 'userRole': ...} if a session is saved, else null.
  static Future<Map<String, String>?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_keyUserId);
    final userRole = prefs.getString(_keyUserRole);

    if (userId == null || userRole == null) return null;
    return {'userId': userId, 'userRole': userRole};
  }

  /// Call this on logout to fully clear the saved session.
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserRole);
  }
}