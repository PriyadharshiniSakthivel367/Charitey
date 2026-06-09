//auth_provider.dart
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
  UserModel? get user => _currentUserModel;
  bool get isLoading => _isLoading;

  User? get currentFirebaseUser => FirebaseAuth.instance.currentUser;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _authService.authStateChanges.listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        await _fetchUserData(firebaseUser.uid);
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

    UserModel? user = await _authService.signInWithEmailAndPassword(
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

  // ================= ROLE BASED EMAIL SIGN IN =================

  Future<bool> signInWithRole(
    String email,
    String password,
    String expectedRole,
  ) async {
    _isLoading = true;
    notifyListeners();

    UserModel? user = await _authService.signInWithEmailAndPassword(
      email,
      password,
    );

    _isLoading = false;

    if (user == null) {
      notifyListeners();
      return false;
    }

    if (user.role.toLowerCase() != expectedRole.toLowerCase()) {
      await FirebaseAuth.instance.signOut();
      notifyListeners();
      return false;
    }

    _currentUserModel = user;
    notifyListeners();
    return true;
  }

  // ================= GOOGLE SIGN IN =================
  //
  // LOGIN screens  → pass expectedRole only (no assignRole)
  //   signInWithGoogle(expectedRole: 'ngo')
  //   → new users blocked, existing users role-checked
  //
  // REGISTER screens → pass role only
  //   signInWithGoogle(role: 'ngo')
  //   → new users created with that role, existing users role updated

  Future<bool> signInWithGoogle({
    String? expectedRole, // used by LOGIN screens — validates existing role
    String? role,         // used by REGISTER screens — assigns role to new/existing user
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Register flow: pass the role down so new users get it saved correctly
      final String? assignRole = role;

      UserModel? googleUser =
          await _authService.signInWithGoogle(assignRole: assignRole);

      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // LOGIN screen role check — reject if role doesn't match
      if (expectedRole != null &&
          googleUser.role.toLowerCase() != expectedRole.toLowerCase()) {
        await FirebaseAuth.instance.signOut();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUserModel = googleUser;
      await _fetchUserData(googleUser.uid);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Google Sign In Error: $e');
    }

    _isLoading = false;
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
      if (username.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'username': username});
      }

      await _fetchUserData(user.uid);

      notifyListeners();
      return true;
    }

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
      debugPrint('Sign out error: $e');
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
    if (_currentUserModel == null) return false;

    try {
      Map<String, dynamic> data = {};

      if (name != null) data['name'] = name;
      if (username != null) data['username'] = username;
      if (phone != null) data['phone'] = phone;
      if (location != null) data['location'] = location;
      if (profileImage != null) data['profileImage'] = profileImage;
      if (license != null) data['license'] = license;

      if (data.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserModel!.uid)
            .update(data);

        await _fetchUserData(_currentUserModel!.uid);
      }

      return true;
    } catch (e) {
      debugPrint('Update Profile Error: $e');
      return false;
    }
  }
}