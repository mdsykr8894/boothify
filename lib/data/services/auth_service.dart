import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of Auth user changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get current user data from Firestore.
  Future<UserModel?> getCurrentUserData() async {
    final User? user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    return UserModel.fromMap(doc.data()!, doc.id);
  }

  /// Sign in with email and password.
  Future<UserModel?> signIn(String email, String password) async {
    final UserCredential result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (result.user == null) return null;

    final doc = await _firestore.collection('users').doc(result.user!.uid).get();
    if (!doc.exists) return null;

    final userModel = UserModel.fromMap(doc.data()!, doc.id);

    // If user is inactive, sign out and throw error
    if (!userModel.isActive) {
      await _auth.signOut();
      throw Exception('Your account is deactivated. Please contact support.');
    }

    return userModel;
  }

  /// Register a new user.
  Future<UserModel?> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? companyName,
  }) async {
    final UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (result.user == null) return null;

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

    await _firestore.collection('users').doc(result.user!.uid).set(userModel.toMap());

    return userModel;
  }

  /// Sign out.
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
