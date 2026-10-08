import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  User? get user => _user;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        try {
          await FirebaseMessaging.instance.requestPermission();
          final fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null) {
            await _firestore.collection('users').doc(user.uid).set({
              'fcmToken': fcmToken,
            }, SetOptions(merge: true));
          }
          
          FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
            _firestore.collection('users').doc(user.uid).set({
              'fcmToken': newToken,
            }, SetOptions(merge: true));
          });
        } catch (e) {
          debugPrint('Error saving FCM token: $e');
        }
      }
      notifyListeners();
    });
  }

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signup(String name, String email, String password, {String? adminCode}) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String role = 'employee';
      if (adminCode != null) {
        if (adminCode.trim() == 'ADMIN2026') {
          role = 'super_admin';
        } else if (adminCode.trim() == 'MANAGER2026') {
          role = 'manager';
        }
      }

      // Create a user document in Firestore
      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'name': name,
          'email': email,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await credential.user!.updateDisplayName(name);
      }
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateProfilePicture(String base64Image) async {
    try {
      if (_user != null) {
        await _firestore.collection('users').doc(_user!.uid).set({
          'profilePic': base64Image,
        }, SetOptions(merge: true));
        notifyListeners();
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateProfile(String name, {String? dob}) async {
    try {
      if (_user != null) {
        await _user!.updateDisplayName(name);
        final Map<String, dynamic> updateData = {   
          'name': name,
          'email': _user!.email,
        };
        if (dob != null) {
          updateData['dob'] = dob;
        }
        await _firestore.collection('users').doc(_user!.uid).set(updateData, SetOptions(merge: true));
        notifyListeners();
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
