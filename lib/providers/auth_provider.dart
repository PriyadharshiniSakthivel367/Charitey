import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _currentUserModel;
  bool _isLoading = false;

  UserModel? get currentUserModel => _currentUserModel;
  bool get isLoading => _isLoading;
  User? get currentFirebaseUser => _authService.currentUser;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _authService.authStateChanges.listen((User? user) async {
       if (user != null) {
          await _fetchUserData(user.uid);
       } else {
         _currentUserModel = null;
         notifyListeners();
         
       }
    });
  }

  Future<void> _fetchUserData(String uid) async {
    _isLoading = true;
    notifyListeners();
    
    _currentUserModel = await _authService.getUserProfile(uid);
    
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    UserModel? user = await _authService.signInWithEmailAndPassword(email, password);

    _isLoading = false;
    if (user != null) {
      _currentUserModel = user;
      notifyListeners();
      return true;
    }
    notifyListeners();
    return false;
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
    required String location,
  }) async {
    _isLoading = true;
    notifyListeners();

    UserModel? user = await _authService.signUpWithEmailAndPassword(
      name: name,
      email: email,
      password: password,
      phone: phone,
      role: role,
      location: location,
    );

    _isLoading = false;
    if (user != null) {
      _currentUserModel = user;
      notifyListeners();
      return true;
    }
    notifyListeners();
    return false;
  }
  Future<bool> signInWithGoogle() async {
  _isLoading = true;
  notifyListeners();

  UserModel? user = await _authService.signInWithGoogle();

  _isLoading = false;

  if (user != null) {
    _currentUserModel = user;
    notifyListeners();
    return true;
  }

  notifyListeners();
  return false;
}

  Future<void> signOut() async {
    await _authService.signOut();
  }
}
