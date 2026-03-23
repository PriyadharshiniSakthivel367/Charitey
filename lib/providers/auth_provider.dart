import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart'; 
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
      name: name, email: email, password: password, phone: phone, role: role, location: location,
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

  Future<bool> signInWithGoogle({String role = 'user'}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await GoogleSignIn().signOut();
    } catch (e) {}

    UserModel? user = await _authService.signInWithGoogle();
    if (user != null) {
      if (role != 'user') {
        try {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'role': role});
          await _fetchUserData(user.uid);
          return true;
        } catch (e) {
          debugPrint("Failed to update Google User role: $e");
        }
      }
      _currentUserModel = user;
      _isLoading = false;
      notifyListeners();
      return true;
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (e) {}
    await _authService.signOut();
  }

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? location,
    String? profileImage,
    String? license,
  }) async {
    if (_currentUserModel == null) return false;

    // We keep isLoading false here to prevent the AuthWrapper from 
    // switching to a loading spinner and then back to Setup while saving.
    _isLoading = true; 
    notifyListeners();

    Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (phone != null) data['phone'] = phone;
    if (location != null) data['location'] = location;
    if (profileImage != null) data['profileImage'] = profileImage;
    if (license != null) data['license'] = license;

    if (data.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(_currentUserModel!.uid).update(data);
        
        // Manually update local model so the UI refreshes instantly
        _currentUserModel = UserModel(
          uid: _currentUserModel!.uid,
          name: name ?? _currentUserModel!.name,
          phone: phone ?? _currentUserModel!.phone,
          email: _currentUserModel!.email,
          role: _currentUserModel!.role,
          location: location ?? _currentUserModel!.location,
          profileImage: profileImage ?? _currentUserModel!.profileImage,
          createdAt: _currentUserModel!.createdAt,
          donationsCount: _currentUserModel!.donationsCount,
          postsCount: _currentUserModel!.postsCount,
          license: license ?? _currentUserModel!.license,
        );
        
        _isLoading = false;
        notifyListeners();
        return true;
      } catch (e) {
        debugPrint("Update error: $e");
        _isLoading = false;
        notifyListeners();
        return false;
      }
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }
}