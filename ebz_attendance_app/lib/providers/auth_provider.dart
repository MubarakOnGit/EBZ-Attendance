import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_account.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserAccount? _currentUser;
  bool _isLoading = true;

  UserAccount? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _authService.user.listen((User? user) async {
      if (user != null) {
        _currentUser = await _authService.getCurrentUser();
      } else {
        _currentUser = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  // Reload user data
  Future<void> refreshUser() async {
    if (_currentUser != null) {
      // Logic to refetch user data from Firestore
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    _currentUser = await _authService.signIn(email, password);
    _isLoading = false;
    notifyListeners();
    return _currentUser != null;
  }

  Future<void> logout() async {
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }
}
