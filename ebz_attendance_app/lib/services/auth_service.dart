import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_account.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Stream of auth changes
  Stream<User?> get user => _auth.authStateChanges();

  // Get current user data
  Future<UserAccount?> getCurrentUser() async {
    User? user = _auth.currentUser;
    if (user != null) {
      return await _firestoreService.getUser(user.uid);
    }
    return null;
  }

  // Sign in with email and password
  Future<UserAccount?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      if (user != null) {
        UserAccount? account = await _firestoreService.getUser(user.uid);
        if (account == null) {
          throw Exception('User data not found in Firestore. Please ensure the document exists in the "users" collection with the correct UID: ${user.uid}');
        }
        return account;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Authentication failed');
    } catch (e) {
      throw e;
    }
  }

  // Register a new user (usually called by admin)
  Future<UserAccount?> registerMember(UserAccount member, String password) async {
    try {
      // Use a secondary app instance to create the user without signing out the admin
      FirebaseApp secondaryApp;
      try {
        secondaryApp = Firebase.app('secondary');
      } catch (e) {
        secondaryApp = await Firebase.initializeApp(
          name: 'secondary',
          options: Firebase.app().options,
        );
      }

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      UserCredential result = await secondaryAuth.createUserWithEmailAndPassword(
        email: member.email,
        password: password,
      );
      
      User? user = result.user;
      if (user != null) {
        UserAccount newMember = UserAccount(
          uid: user.uid,
          name: member.name,
          email: member.email,
          role: member.role,
          employeeId: member.employeeId,
          phoneNumber: member.phoneNumber,
          salaryType: member.salaryType,
          baseSalary: member.baseSalary,
          workingDays: member.workingDays,
          isActive: true,
          // Explicitly set isFirstLogin to true for new members so they change password
          isFirstLogin: true, 
        );
        // This saveUser call uses the DEFAULT app instance, which is still the Admin.
        // Therefore, it passes the 'isAdmin()' security rule.
        await _firestoreService.saveUser(newMember);
        
        // Sign out the secondary instance to be clean
        await secondaryAuth.signOut();
        
        return newMember;
      }
      return null;
    } catch (e) {
      print('Error in registerMember: $e');
      rethrow; 
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Password reset
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Update password and clear first login flag
  Future<bool> updatePassword(String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
        // Clear first login flag in Firestore
        await _firestoreService.updateFirstLoginFlag(user.uid, false);
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating password: $e');
      return false;
    }
  }
}
