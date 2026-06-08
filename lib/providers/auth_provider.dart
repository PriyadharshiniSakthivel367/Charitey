import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUserModel;
  bool _isLoading = false;

  UserModel? get currentUserModel => _currentUserModel;
  bool get isLoading => _isLoading;

  User? get currentFirebaseUser => FirebaseAuth.instance.currentUser;

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

  // ================= SIGN IN =================

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    UserModel? user =
        await _authService.signInWithEmailAndPassword(
      email,
      password,
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

  // ================= SIGN UP =================

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
    required String location,
    String username = '',
  }) async {
    _isLoading = true;
    notifyListeners();

    UserModel? user =
        await _authService.signUpWithEmailAndPassword(
      name: name,
      email: email,
      password: password,
      phone: phone,
      role: role,
      location: location,
    );

    _isLoading = false;

    if (user != null) {
      // Save username
      if (username.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'username': username,
        });
      }

      await _fetchUserData(user.uid);

      notifyListeners();
      return true;
    }

    notifyListeners();
    return false;
  }

  // ================= GOOGLE SIGN IN =================

  Future<bool> signInWithGoogle({
    String role = 'user',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      UserModel? user =
          await _authService.signInWithGoogle();

      if (user != null) {
        if (role != 'user') {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'role': role,
          });
        }

        await _fetchUserData(user.uid);

        _isLoading = false;
        notifyListeners();

        return true;
      }
    } catch (e) {
      debugPrint("Google Sign In Error: $e");
    }

    _isLoading = false;
    notifyListeners();

    return false;
  }

  // ================= SIGN OUT =================

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();

      _currentUserModel = null;

      notifyListeners();
    } catch (e) {
      debugPrint("Sign out error: $e");
    }
  }

  // ================= UPDATE PROFILE =================

  Future<bool> updateProfile({
    String? name,
    String? username,
    String? phone,
    String? location,
    String? profileImage,
    String? license,
  }) async {
    if (_currentUserModel == null) {
      return false;
    }

    try {
      Map<String, dynamic> data = {};

      if (name != null) {
        data['name'] = name;
      }

      if (username != null) {
        data['username'] = username;
      }

      if (phone != null) {
        data['phone'] = phone;
      }

      if (location != null) {
        data['location'] = location;
      }

      if (profileImage != null) {
        data['profileImage'] = profileImage;
      }

      if (license != null) {
        data['license'] = license;
      }

      if (data.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserModel!.uid)
            .update(data);

        await _fetchUserData(_currentUserModel!.uid);
      }

      return true;
    } catch (e) {
      debugPrint("Update Profile Error: $e");
      return false;
    }
  }
}