import 'package:firebase_auth/firebase_auth.dart';
import 'package:brew_crew/models/user_model.dart' as app_user;
import 'package:brew_crew/services/database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // create a user obj based on firebase obj
  app_user.User? _userFromFirebaseUser(User? user) {
    return user != null
        ? app_user.User(uid: user.uid, name: "", email: "", role: "")
        : null;
  }

  // create a Stream that will tell's us the stat of our users
  Stream<app_user.User?> get user {
    return _auth.authStateChanges().map(
      (User? user) => _userFromFirebaseUser(user),
    );
  }

  // sign in anon
  Future<app_user.User?> signInAnon() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      User? user = result.user;
      return _userFromFirebaseUser(user);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // sign with email and pass
  Future<app_user.User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      return _userFromFirebaseUser(user);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // register with email & password
  Future<app_user.User?> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      if (user != null) {
        // Extract name from email (before @)
        final nameFromEmail = email.split('@')[0];
        await DatabaseService(
          uid: user.uid,
        ).createUser(name: nameFromEmail, email: email, role: 'caregiver');
      }
      return _userFromFirebaseUser(user);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // sign out
  Future signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Future<Object?> createUserWithEmailAndPassword(String email, String password) async {}
}
