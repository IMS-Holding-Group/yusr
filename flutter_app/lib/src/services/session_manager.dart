import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userPhoneKey = 'user_phone';
  static const String _userNameKey = 'user_name';

  /// حفظ حالة تسجيل الدخول
  static Future<void> saveSession({
    required int userId,
    String? email,
    String? phone,
    String? name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setInt(_userIdKey, userId);
    if (email != null) await prefs.setString(_userEmailKey, email);
    if (phone != null) await prefs.setString(_userPhoneKey, phone);
    if (name != null) await prefs.setString(_userNameKey, name);
  }

  /// التحقق من حالة تسجيل الدخول
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  /// الحصول على معرف المستخدم المحفوظ
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_userIdKey);
    return userId;
  }

  /// الحصول على البريد الإلكتروني المحفوظ
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  /// الحصول على رقم الهاتف المحفوظ
  static Future<String?> getUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userPhoneKey);
  }

  /// الحصول على اسم المستخدم المحفوظ
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  /// مسح الجلسة (تسجيل الخروج)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userPhoneKey);
    await prefs.remove(_userNameKey);
  }

  /// الحصول على جميع بيانات المستخدم المحفوظة
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    
    if (!isLoggedIn) return null;
    
    return {
      'user_id': prefs.getInt(_userIdKey),
      'email': prefs.getString(_userEmailKey),
      'phone': prefs.getString(_userPhoneKey),
      'name': prefs.getString(_userNameKey),
    };
  }
}

