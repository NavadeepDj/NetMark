import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logger/logger.dart';

class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final Logger _logger = Logger();

  // Check if Firebase is available
  static bool get isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Simple offline authentication fallback
  static Future<bool> offlineSignIn({
    required String email,
    required String password,
  }) async {
    try {
      _logger.i('Attempting offline authentication for: $email');
      // This is a simple fallback - in a real app, you'd want to store
      // encrypted credentials locally and verify them
      _logger.w('Offline authentication not implemented - Firebase required');
      return false;
    } catch (e) {
      _logger.e('Offline authentication failed: $e');
      return false;
    }
  }

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Check if user is signed in
  static bool get isSignedIn => currentUser != null;

  // Sign up with email and password
  static Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (!isFirebaseAvailable) {
      throw Exception(
          'Unable to connect to authentication service. Please check your internet connection and try again.');
    }

    try {
      _logger.i('Starting sign up process for: $email');

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name if provided
      if (displayName != null && result.user != null) {
        await result.user!.updateDisplayName(displayName);
        await result.user!.reload();
      }

      _logger.i('Sign up successful for: $email');
      return result;
    } on FirebaseAuthException catch (e) {
      _logger.e('Sign up failed: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      _logger.e('Unexpected error during sign up: $e');
      // Handle Google Play Services errors gracefully
      if (e.toString().contains('GoogleApiManager') ||
          e.toString().contains('SecurityException')) {
        throw Exception(
            'Google Play Services error. Please check your internet connection and try again.');
      }
      throw Exception('An unexpected error occurred during sign up');
    }
  }

  // Sign in with email and password
  static Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (!isFirebaseAvailable) {
      throw Exception(
          'Unable to connect to authentication service. Please check your internet connection and try again.');
    }

    try {
      _logger.i('Starting sign in process for: $email');

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _logger.i('Sign in successful for: $email');
      return result;
    } on FirebaseAuthException catch (e) {
      _logger.e('Sign in failed: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      _logger.e('Unexpected error during sign in: $e');
      // Handle Google Play Services errors gracefully
      if (e.toString().contains('GoogleApiManager') ||
          e.toString().contains('SecurityException')) {
        throw Exception(
            'Google Play Services error. Please check your internet connection and try again.');
      }
      throw Exception('An unexpected error occurred during sign in');
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      _logger.i('Signing out user');
      await _auth.signOut();
      _logger.i('Sign out successful');
    } catch (e) {
      _logger.e('Error during sign out: $e');
      throw Exception('Failed to sign out');
    }
  }

  // Send password reset email
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      _logger.i('Sending password reset email to: $email');
      await _auth.sendPasswordResetEmail(email: email);
      _logger.i('Password reset email sent successfully');
    } on FirebaseAuthException catch (e) {
      _logger.e('Password reset failed: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      _logger.e('Unexpected error during password reset: $e');
      throw Exception(
          'An unexpected error occurred while sending password reset email');
    }
  }

  // Update user profile
  static Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      if (currentUser == null) {
        throw Exception('No user is currently signed in');
      }

      _logger.i('Updating user profile');

      if (displayName != null) {
        await currentUser!.updateDisplayName(displayName);
      }

      if (photoURL != null) {
        await currentUser!.updatePhotoURL(photoURL);
      }

      await currentUser!.reload();
      _logger.i('User profile updated successfully');
    } catch (e) {
      _logger.e('Error updating user profile: $e');
      throw Exception('Failed to update user profile');
    }
  }

  // Delete user account
  static Future<void> deleteUserAccount() async {
    try {
      if (currentUser == null) {
        throw Exception('No user is currently signed in');
      }

      _logger.i('Deleting user account');
      await currentUser!.delete();
      _logger.i('User account deleted successfully');
    } on FirebaseAuthException catch (e) {
      _logger.e('Account deletion failed: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      _logger.e('Unexpected error during account deletion: $e');
      throw Exception('An unexpected error occurred while deleting account');
    }
  }

  // Get user data
  static Map<String, dynamic>? getUserData() {
    if (currentUser == null) return null;

    return {
      'uid': currentUser!.uid,
      'email': currentUser!.email,
      'displayName': currentUser!.displayName,
      'photoURL': currentUser!.photoURL,
      'emailVerified': currentUser!.emailVerified,
      'creationTime': currentUser!.metadata.creationTime?.toIso8601String(),
      'lastSignInTime': currentUser!.metadata.lastSignInTime?.toIso8601String(),
    };
  }

  // Handle Firebase Auth exceptions
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials and try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Invalid email address. Please check your email format.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please sign in again.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }

  // Listen to auth state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get user ID
  static String? get userId => currentUser?.uid;

  // Get user email
  static String? get userEmail => currentUser?.email;

  // Get user display name
  static String? get userDisplayName => currentUser?.displayName;

  // Check if email is verified
  static bool get isEmailVerified => currentUser?.emailVerified ?? false;

  // Send email verification
  static Future<void> sendEmailVerification() async {
    try {
      if (currentUser == null) {
        throw Exception('No user is currently signed in');
      }

      _logger.i('Sending email verification');
      await currentUser!.sendEmailVerification();
      _logger.i('Email verification sent successfully');
    } catch (e) {
      _logger.e('Error sending email verification: $e');
      throw Exception('Failed to send email verification');
    }
  }

  // Clear all cached auth state (signs out and clears local tokens)
  // Note: This only clears local device state. The account still exists in Firebase Auth.
  // To fully delete an account, use Firebase Console or deleteUserAccount() while signed in.
  static Future<void> clearAuthState() async {
    try {
      _logger.i('Clearing all cached authentication state');
      await _auth.signOut();
      _logger.i('Auth state cleared successfully');
    } catch (e) {
      _logger.e('Error clearing auth state: $e');
      throw Exception('Failed to clear auth state');
    }
  }
}
