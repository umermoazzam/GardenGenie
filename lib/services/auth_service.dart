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

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up with email and password
  Future<User?> signup({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Create user account
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      // Update user profile with display name
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.reload();

        try {
          // Create user document in Firestore
          await _firestore.collection('users').doc(user.uid).set({
            'email': email,
            'displayName': displayName,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } catch (firestoreError) {
          // Log the error but don't fail signup
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

  /// Login with email and password
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

  /// Login with Google
  Future<User?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Verify we have the tokens
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw 'Failed to obtain authentication tokens from Google';
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken!,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      final User? user = userCredential.user;

      // Create or update user document in Firestore
      if (user != null) {
        try {
          // Wait for the auth token to be fully propagated
          await user.getIdToken(true);

          final userDoc = await _firestore
              .collection('users')
              .doc(user.uid)
              .get();

          if (!userDoc.exists) {
            // New user, create document
            await _firestore.collection('users').doc(user.uid).set({
              'email': user.email,
              'displayName': user.displayName,
              'createdAt': FieldValue.serverTimestamp(),
              'authProvider': 'google',
            });
          }
        } catch (firestoreError) {
          // Log the Firestore error but don't fail the sign-in
          // The user is authenticated even if Firestore write fails
          print(
            'Warning: Could not create user document in Firestore: $firestoreError',
          );
          // The user can still use the app, we'll try to create the document later if needed
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // Provide more specific error messages
      if (e.toString().contains('sign_in_failed')) {
        throw 'Google Sign-In failed. Please ensure:\n'
            '1. SHA-1 certificate is added to Firebase\n'
            '2. Google Sign-In is enabled in Firebase Console\n'
            '3. google-services.json is up to date';
      }
      throw 'An error occurred during Google sign-in: ${e.toString()}';
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Ensure user document exists in Firestore
  /// This is a helper method to create user document if it doesn't exist
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
      // Don't throw error, just log it
    }
  }

  /// Handle Firebase Auth exceptions
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
