import 'package:shared_preferences/shared_preferences.dart';



class PreferencesService {

  static const String _isLoggedInKey = 'isLoggedIn';

  static const String _userIdKey = 'userId';

  static const String _userNameKey = 'userName';

  static const String _userEmailKey = 'userEmail';



// حفظ بيانات المستخدم

  static Future<void> saveUser({

    required int userId,

    required String name,

    required String email,

  }) async {

    final prefs = await SharedPreferences.getInstance();



    await prefs.setBool(_isLoggedInKey, true);

    await prefs.setInt(_userIdKey, userId);

    await prefs.setString(_userNameKey, name);

    await prefs.setString(_userEmailKey, email);

  }



// معرفة هل المستخدم مسجل دخول

  static Future<bool> isLoggedIn() async {

    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_isLoggedInKey) ?? false;

  }



// الحصول على ID المستخدم

  static Future<int?> getUserId() async {

    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt(_userIdKey);

  }



// الحصول على اسم المستخدم

  static Future<String?> getUserName() async {

    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_userNameKey);

  }



// الحصول على الإيميل

  static Future<String?> getUserEmail() async {

    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_userEmailKey);

  }



// تسجيل الخروج ومسح البيانات

  static Future<void> logout() async {

    final prefs = await SharedPreferences.getInstance();



    await prefs.remove(_isLoggedInKey);

    await prefs.remove(_userIdKey);

    await prefs.remove(_userNameKey);

    await prefs.remove(_userEmailKey);

  }

}

