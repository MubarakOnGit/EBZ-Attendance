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
        return await _firestoreService.getUser(user.uid);
      }
      return null;
    } catch (e) {
      print('Error in signIn: $e');
      return null;
    }
  }

  // Register a new user (usually called by admin)
  Future<UserAccount?> registerMember(UserAccount member, String password) async {
    try {
      // Note: Admin registering a member might sign the admin out if using standard createUserWithEmailAndPassword.
      // In a real app, this should be done via Cloud Functions to avoid session swapping,
      // or by using a secondary Firebase app instance.
      // For MVP, we'll assume the admin is adding them.
      
      UserCredential result = await _auth.createUserWithEmailAndPassword(
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
        );
        await _firestoreService.saveUser(newMember);
        return newMember;
      }
      return null;
    } catch (e) {
      print('Error in registerMember: $e');
      return null;
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
