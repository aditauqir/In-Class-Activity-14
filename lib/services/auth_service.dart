import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // Constructor with optional injection for testing, defaulting to standard singletons
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ??
            (Firebase.apps.any((app) => app.name == 'inclass13')
                ? FirebaseAuth.instanceFor(app: Firebase.app('inclass13'))
                : FirebaseAuth.instance),
        _firestore = firestore ?? FirebaseFirestore.instance;

  // Cached stable stream of auth state changes
  late final Stream<User?> authStateChanges = _auth.authStateChanges();

  // Current user getter
  User? get currentUser => _auth.currentUser;

  // Register with email and password
  Future<UserCredential> register(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (credential.user != null) {
      final user = credential.user!;
      if (user.email != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }}
    return credential;
  }

  // Sign in with email and password
  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Sign out
  Future<void> signOut() {
    return _auth.signOut();
  }

  // Change password directly
  Future<void> changePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('A signed-in user is required to change a password.');
    } else {
      await user.updatePassword(newPassword);
    }}

  // Reauthenticate and update password when requires-recent-login is caught
  Future<void> reauthenticateAndChangePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw StateError('A signed-in user with an email is required for re-authentication.');
    } else {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    }}

  // Update user bio in Firestore users/{uid} for Data Warden badge
  Future<void> updateUserBio(String bio) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Must be signed in to update user profile data.');
    } else {
      if (bio.isNotEmpty) {
        await _firestore.collection('users').doc(user.uid).set({
          'bio': bio,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }}}

  // Stream user data from users/{uid} (Data Warden real-time stream)
  Stream<DocumentSnapshot<Map<String, dynamic>>>? getUserDataStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    } else {
      return _firestore.collection('users').doc(user.uid).snapshots();
    }}
}
