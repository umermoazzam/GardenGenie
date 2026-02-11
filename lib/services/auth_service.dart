import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '190765752610-ifkpd06qotkppbks3pkradm2eh0eu8np.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signup({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.reload();

        try {
          await _firestore.collection('users').doc(user.uid).set({
            'email': email,
            'displayName': displayName,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } catch (firestoreError) {
          print(
            'Warning: Could not create user document in Firestore: $firestoreError',
          );
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<User?> login({required String email, required String password}) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw 'Failed to obtain authentication tokens from Google';
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken!,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      final User? user = userCredential.user;

      if (user != null) {
        try {
          await user.getIdToken(true);

          final userDoc = await _firestore
              .collection('users')
              .doc(user.uid)
              .get();

          if (!userDoc.exists) {
            await _firestore.collection('users').doc(user.uid).set({
              'email': user.email,
              'displayName': user.displayName,
              'createdAt': FieldValue.serverTimestamp(),
              'authProvider': 'google',
            });
          }
        } catch (firestoreError) {
          print(
            'Warning: Could not create user document in Firestore: $firestoreError',
          );
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e.toString().contains('sign_in_failed')) {
        throw 'Google Sign-In failed. Please ensure:\n'
            '1. SHA-1 certificate is added to Firebase\n'
            '2. Google Sign-In is enabled in Firebase Console\n'
            '3. google-services.json is up to date';
      }
      throw 'An error occurred during Google sign-in: ${e.toString()}';
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> ensureUserDocumentExists() async {
    final user = currentUser;
    if (user == null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'displayName': user.displayName,
          'createdAt': FieldValue.serverTimestamp(),
          'authProvider': user.providerData.isNotEmpty
              ? user.providerData.first.providerId
              : 'email',
        });
      }
    } catch (e) {
      print('Could not ensure user document exists: $e');
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists with that email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'operation-not-allowed':
        return 'Operation not allowed.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}
