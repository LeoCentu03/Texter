import 'package:flutter/material.dart';
import 'package:dating_app/view/LoginMethods.dart';
import 'package:dating_app/view/SwipePage.dart';
import 'package:dating_app/view/EmailVerifier.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final LoginMethods _loginMethods = LoginMethods();
  final EmailVerifier emailVerifier = EmailVerifier();
  bool _isLoading = false;

  final Color primaryGreen = Color(0xFF00B09B);
  final Color secondaryGreen = Color(0xFF96C93D);

  void _showSnackBar(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.montserrat()),
        backgroundColor: color ?? Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(10),
      ),
    );
  }

  Future<void> setOnlineStatus(bool online) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isOnline': online,
        'lastOnline': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryGreen, secondaryGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: -50,
            left: -50,
            child: _buildDecorativeCircle(Colors.white.withOpacity(0.1), 200),
          ),
          Positioned(
            bottom: 100,
            right: -30,
            child: _buildDecorativeCircle(Colors.white.withOpacity(0.1), 150),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),
                      SizedBox(height: 10),
                      Center(
                        child: Text(
                          'Benvenuto!',
                          style: GoogleFonts.montserrat(
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 4),
                                blurRadius: 10.0,
                                color: Colors.black.withOpacity(0.2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Center(
                        child: Text(
                          'Accedi per continuare',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    padding: EdgeInsets.only(bottom: bottomPadding),
                    alignment: Alignment.center,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: GoogleFonts.montserrat(color: Color(0xFF333333)),
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle: GoogleFonts.montserrat(color: Colors.grey[600]),
                                prefixIcon: Icon(Icons.email_outlined, color: primaryGreen),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                              ),
                            ),
                            SizedBox(height: 20),
                            TextField(
                              controller: passwordController,
                              obscureText: true,
                              style: GoogleFonts.montserrat(color: Color(0xFF333333)),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: GoogleFonts.montserrat(color: Colors.grey[600]),
                                prefixIcon: Icon(Icons.lock_outline, color: primaryGreen),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                              ),
                            ),
                            SizedBox(height: 40),
                            Container(
                              width: double.infinity,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () async {
                                        final email = emailController.text.trim();
                                        final password = passwordController.text.trim();

                                        if (email.isEmpty || password.isEmpty) {
                                          _showSnackBar('Inserisci email e password');
                                          return;
                                        }

                                        setState(() => _isLoading = true);

                                        bool isValid = await emailVerifier.isEmailDomainValid(email);
                                        if (!isValid) {
                                          _showSnackBar('Email con dominio non valido!');
                                          setState(() => _isLoading = false);
                                          return;
                                        }

                                        final querySnapshot = await FirebaseFirestore.instance
                                            .collection('users')
                                            .where('email', isEqualTo: email)
                                            .limit(1)
                                            .get();

                                        if (querySnapshot.docs.isNotEmpty) {
                                          final userData = querySnapshot.docs.first.data();
                                          final isOnline = userData['isOnline'] ?? false;
                                          if (isOnline) {
                                            _showSnackBar(
                                                'Questo account è già online da un altro dispositivo!');
                                            setState(() => _isLoading = false);
                                            return;
                                          }
                                        }

                                        final user = await _loginMethods.loginWithEmailPassword(
                                          email: email,
                                          password: password,
                                          context: context,
                                          mounted: mounted,
                                        );

                                        setState(() => _isLoading = false);

                                        if (user != null) {
                                          await setOnlineStatus(true);
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(builder: (context) => SwipePage()),
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: primaryGreen,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: primaryGreen,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : Text(
                                        'ACCEDI',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorativeCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}