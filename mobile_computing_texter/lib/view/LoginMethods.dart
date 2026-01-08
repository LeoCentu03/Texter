import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'EmailVerifier.dart';

class LoginMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final EmailVerifier emailVerifier = EmailVerifier();

  Future<User?> loginWithEmailPassword({
    required String email,
    required String password,
    required BuildContext context,
    required bool mounted, 
  }) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
      return null;
    }
  }

  Future<void> registerWithEmailPassword({
    required String email,
    required String password,
    required BuildContext context,
    required bool mounted, 
  }) async {
    bool isValid = await emailVerifier.isEmailDomainValid(email);

    if (isValid) {
      try {
        final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await userCredential.user?.sendEmailVerification();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Email di verifica inviata!')),
          );
        }
      } on FirebaseAuthException catch (e) {
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.message}')),
          );
        }
      }
    } else {
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email con dominio inesistente!')),
        );
      }
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
