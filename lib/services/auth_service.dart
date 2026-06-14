//auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
      print('Error signing up: $e');
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
      print('Error signing in: $e');
    }
    return null;
  }

  // ================= GOOGLE SIGN IN =================
  // Pass [assignRole] when registering via Google so new users get
  // the correct role. For login screens pass null — existing role is kept.

  Future<UserModel?> signInWithGoogle({String? assignRole}) async {
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn();

    await googleSignIn.signOut();

    final GoogleSignInAccount? googleUser =
        await googleSignIn.signIn();

    if (googleUser == null) {
      return null;
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final AuthCredential credential =
        GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    UserCredential result =
        await _auth.signInWithCredential(credential);

    User? user = result.user;

    if (user != null) {
      final docRef =
          _firestore.collection('users').doc(user.uid);

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
  } catch (e) {
    print('Google Sign In Error: $e');
  }

  return null;
}
  // ================= SIGN OUT =================

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
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
      print('Error fetching user profile: $e');
    }
    return null;
  }
}