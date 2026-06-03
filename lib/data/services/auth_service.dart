import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Listen to Firebase authentication changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> getCurrentUserData() async {
    // Get currently logged-in Firebase user.
    final User? user = _auth.currentUser;

    // Return null if no user is logged in.
    if (user == null) return null;

    // Get user profile data from Firestore.
    final doc = await _firestore.collection('users').doc(user.uid).get();

    // Return null if Firestore user document does not exist.
    if (!doc.exists) return null;

    // Convert Firestore document into UserModel.
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  Future<UserModel?> signIn(String email, String password) async {
    // Sign in using Firebase Authentication.
    final UserCredential result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Return null if Firebase user is missing.
    if (result.user == null) return null;

    // Get user profile data from Firestore.
    final doc = await _firestore.collection('users').doc(result.user!.uid).get();

    // Return null if user profile document does not exist.
    if (!doc.exists) return null;

    // Convert Firestore data into UserModel.
    final userModel = UserModel.fromMap(doc.data()!, doc.id);

    // Block login if account is deactivated.
    if (!userModel.isActive) {
      await _auth.signOut();
      throw Exception('Your account is deactivated. Please contact support.');
    }

    return userModel;
  }

  Future<UserModel?> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? companyName,
  }) async {
    // Create new user account in Firebase Authentication.
    final UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Return null if Firebase user is missing.
    if (result.user == null) return null;

    // Create local user model for Firestore.
    final userModel = UserModel(
      uid: result.user!.uid,
      name: name,
      email: email,
      role: role,
      companyName: companyName,
      isActive: true,
      favoriteExhibitionIds: [],
      createdAt: DateTime.now(),
    );

    // Save user profile data into Firestore.
    await _firestore.collection('users').doc(result.user!.uid).set(
          userModel.toMap(),
        );

    return userModel;
  }

  Future<void> signOut() async {
    // Sign out current Firebase user.
    await _auth.signOut();
  }
}