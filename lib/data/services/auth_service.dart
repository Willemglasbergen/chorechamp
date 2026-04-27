import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chorechamp2/data/models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<AppUser?> signInWithEmailPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (credential.user == null) return null;
      
      final doc = await _firestore.collection('users').doc(credential.user!.uid).get();
      if (!doc.exists) return null;
      
      return AppUser.fromJson({'id': doc.id, ...doc.data()!});
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<AppUser> signUpWithEmailPassword(String email, String password, String name) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      if (credential.user == null) {
        throw Exception('Failed to create user');
      }

      final now = DateTime.now();
      final user = AppUser(
        id: credential.user!.uid,
        name: name,
        email: email.trim(),
        pinCode: '1234',
        createdAt: now,
        updatedAt: now,
      );

      await _firestore.collection('users').doc(user.id).set(user.toJson());
      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<AppUser?> getCurrentAppUser() async {
    final user = currentUser;
    if (user == null) return null;
    
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    
    return AppUser.fromJson({'id': doc.id, ...doc.data()!});
  }

  Future<void> updateUserProfile(String userId, {String? name, String? pinCode}) async {
    final updates = <String, dynamic>{
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (name != null) updates['name'] = name;
    if (pinCode != null) updates['pinCode'] = pinCode;
    
    await _firestore.collection('users').doc(userId).update(updates);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Geen account gevonden met dit e-mailadres.';
      case 'wrong-password':
        return 'Verkeerd wachtwoord.';
      case 'email-already-in-use':
        return 'Dit e-mailadres is al in gebruik.';
      case 'weak-password':
        return 'Wachtwoord moet minimaal 6 tekens bevatten.';
      case 'invalid-email':
        return 'Ongeldig e-mailadres.';
      default:
        return 'Authenticatiefout: ${e.message}';
    }
  }
}
