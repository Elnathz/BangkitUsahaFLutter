import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _user;
  bool _isLoading = true;
  bool _isSetupComplete = false;
  Map<String, dynamic>? _userData;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isSetupComplete => _isSetupComplete;
  Map<String, dynamic>? get userData => _userData;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        await _checkSetupStatus();
      } else {
        _isSetupComplete = false;
        _userData = null;
        _isLoading = false;
      }
      notifyListeners();
    });
  }

  Future<void> _checkSetupStatus() async {
    if (_user == null) return;
    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        _userData = doc.data();
        _isSetupComplete = _userData?['isSetupComplete'] ?? false;
      } else {
        _isSetupComplete = false;
      }
    } catch (e) {
      debugPrint('Error checking setup status: $e');
      _isSetupComplete = false;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error signing in: $e');
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error signing in with Google: $e');
      return false;
    }
  }

  Future<bool> completeBusinessSetup({
    required String storeName,
    required String ownerName,
    String? phoneNumber,
  }) async {
    if (_user == null) return false;
    try {
      await _firestore.collection('users').doc(_user!.uid).set({
        'uid': _user!.uid,
        'email': _user!.email,
        'storeName': storeName,
        'ownerName': ownerName,
        'phoneNumber': phoneNumber ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'isSetupComplete': true,
      });
      _isSetupComplete = true;
      await _checkSetupStatus();
      return true;
    } catch (e) {
      debugPrint('Error completing setup: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    _user = null;
    _isSetupComplete = false;
    _userData = null;
    notifyListeners();
  }
}
