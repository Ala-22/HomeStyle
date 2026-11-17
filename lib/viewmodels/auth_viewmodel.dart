import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  UserModel? user;

  bool isLoading = false;
  String? errorMessage;

  bool get isLoggedIn => user != null;

  // =========================
  // LOGIN
  // =========================

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    setLoading(true);
    errorMessage = null;

    try {
      final result = await _apiService.login(
        email: email,
        password: password,
      );

      if (result['success'] == true) {
        user = UserModel.fromJson(result['user']);
        errorMessage = null;

        setLoading(false);
        return true;
      } else {
        errorMessage = result['message'] ?? 'Login failed';

        setLoading(false);
        return false;
      }
    } catch (e) {
      errorMessage = 'Unable to connect to server';

      setLoading(false);
      return false;
    }
  }

  // =========================
  // REGISTER
  // =========================

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    setLoading(true);
    errorMessage = null;

    try {
      final result = await _apiService.register(
        name: name,
        email: email,
        password: password,
      );

      if (result['success'] == true) {
        errorMessage = null;

        setLoading(false);
        return true;
      } else {
        errorMessage = result['message'] ?? 'Registration failed';

        setLoading(false);
        return false;
      }
    } catch (e) {
      errorMessage = 'Unable to connect to server';

      setLoading(false);
      return false;
    }
  }

  // =========================
  // LOADING
  // =========================

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  // =========================
  // SET USER
  // =========================

  void setUser(UserModel newUser) {
    user = newUser;
    errorMessage = null;
    notifyListeners();
  }

  // =========================
  // LOGOUT
  // =========================

  void logout() {
    user = null;
    errorMessage = null;
    notifyListeners();
  }
}