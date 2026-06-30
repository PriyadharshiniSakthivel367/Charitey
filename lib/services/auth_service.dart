import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ================= SIGN UP =================

  Future<UserModel?> signUpWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
    required String location,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        UserModel newUser = UserModel(
          uid: user.uid,
          name: name,
          phone: phone,
          email: email,
          role: role,
          location: location,
          profileImage: '',
          createdAt: DateTime.now(),
        );

        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        return newUser;
      }
    } catch (e) {
      debugPrint('Error signing up: $e');
    }
    return null;
  }

  // ================= SIGN IN =================

  Future<UserModel?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(user.uid).get();

        if (doc.exists) {
          return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }
      }
    } catch (e) {
      debugPrint('Error signing in: $e');
    }
    return null;
  }

  // ================= GOOGLE SIGN IN =================
  // Pass [assignRole] when registering via Google so new users get
  // the correct role. For login screens pass null — existing role is kept.

  Future<UserModel?> signInWithGoogle({String? assignRole}) async {
  try {
    if (kIsWeb) {
      return await _signInWithGoogleWeb(assignRole: assignRole);
    } else {
      return await _signInWithGoogleMobile(assignRole: assignRole);
    }
  } catch (e) {
    debugPrint('Google Sign In Error: $e');
    return null;
  }
}

Future<UserModel?> _signInWithGoogleMobile({String? assignRole}) async {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  await googleSignIn.signOut();

  final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
  if (googleUser == null) {
    debugPrint('Google Sign In: User cancelled.');
    return null;
  }

  final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
  final AuthCredential credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  return await _completeSignIn(credential, assignRole);
}

Future<UserModel?> _signInWithGoogleWeb({String? assignRole}) async {
  // On web, use FirebaseAuth's built-in popup provider instead of google_sign_in's signIn()
  GoogleAuthProvider googleProvider = GoogleAuthProvider();
  googleProvider.addScope('email');
  googleProvider.addScope('profile');

  UserCredential userCredential = await _auth.signInWithPopup(googleProvider);
  User? user = userCredential.user;

  if (user == null) return null;
  return await _saveOrFetchUser(user, assignRole);
}

Future<UserModel?> _completeSignIn(AuthCredential credential, String? assignRole) async {
  UserCredential result = await _auth.signInWithCredential(credential);
  User? user = result.user;
  if (user == null) return null;
  return await _saveOrFetchUser(user, assignRole);
}

Future<UserModel?> _saveOrFetchUser(User user, String? assignRole) async {
  final docRef = _firestore.collection('users').doc(user.uid);
  final doc = await docRef.get();

  if (!doc.exists) {
    final role = assignRole ?? 'user';
    UserModel newUser = UserModel(
      uid: user.uid,
      name: user.displayName ?? '',
      phone: '',
      email: user.email ?? '',
      role: role,
      location: '',
      profileImage: user.photoURL ?? '',
      createdAt: DateTime.now(),
    );
    await docRef.set(newUser.toMap());
    return newUser;
  } else {
    if (assignRole != null) {
      await docRef.update({'role': assignRole});
    }
    final updatedDoc = await docRef.get();
    return UserModel.fromMap(
      updatedDoc.data() as Map<String, dynamic>,
      updatedDoc.id,
    );
  }
}

  // ================= FORGOT PASSWORD =================
  // The Cloudflare Worker handles everything:
  // 1. Calls Firebase REST API to generate a real oobCode reset link
  // 2. Sends that real link inside the branded Brevo email
  // Flutter just fires the request and handles the response.

  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse('https://charitey-password-reset.charitey12.workers.dev'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim()}),
      );

      final data = jsonDecode(response.body);

      // Worker returns firebaseError if the email doesn't exist or is invalid
      if (data['firebaseError'] != null) {
        final String code = data['firebaseError'];
        switch (code) {
          case 'EMAIL_NOT_FOUND':
            return 'No account found with this email address.';
          case 'INVALID_EMAIL':
            return 'The email address is not valid.';
          case 'TOO_MANY_ATTEMPTS_TRY_LATER':
            return 'Too many attempts. Please try again later.';
          case 'RESET_PASSWORD_EXCEED_LIMIT':
            return 'Too many reset attempts. Please wait an hour and try again.';
          default:
            return 'Firebase Error: $code';
        }
      }

      if (response.statusCode == 200 && data['success'] == true) {
        return null; // success
      }

      // Temporary: show full response for debugging
      return 'Status: ${response.statusCode} | ${response.body}';
    } catch (e) {
      return 'ERROR: $e';
    }
  }

  // ================= SIGN OUT =================

  Future<void> signOut() async {
  try {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  } catch (e) {
    debugPrint('Error signing out: $e');
  }
}

  // ================= GET PROFILE =================

  Future<UserModel?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
    return null;
  }
}