import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'ProfileSetupPage.dart';

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  final Color primaryGreen = Color(0xFF00B09B);
  final Color secondaryGreen = Color(0xFF96C93D);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

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

  bool _isPasswordValid(String password) {
    final RegExp regex = RegExp(r'^(?=.*[A-Z])(?=.*[!@#\$&*?+])[A-Za-z\d!@#\$&*?+]{8,}$');
    return regex.hasMatch(password);
  }

  Future<bool> isEmailReallyExisting(String email) async {
    final apiKey = 'c548eaef55954a4d87cced7b3d53a43f';
    final Uri url = Uri.parse(
        'https://emailvalidation.abstractapi.com/v1/?api_key=$apiKey&email=$email');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final deliverability = data['deliverability'];
        return deliverability != 'UNDELIVERABLE';
      } else {
        return false;
      }
    } catch (_) {
      return false;
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
                          'Crea Account',
                          style: GoogleFonts.montserrat(
                            fontSize: 32,
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
                      SizedBox(height: 5),
                      Center(
                        child: Text(
                          'Registrati per iniziare',
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
                            SizedBox(height: 20),
                            TextField(
                              controller: confirmPasswordController,
                              obscureText: true,
                              style: GoogleFonts.montserrat(color: Color(0xFF333333)),
                              decoration: InputDecoration(
                                labelText: 'Conferma Password',
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
                                onPressed: _isLoading ? null : _proceedToProfileSetup,
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
                                        'CONTINUA',
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

  Future<void> _proceedToProfileSetup() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar('Per favore, compila tutti i campi.');
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar('Le password non corrispondono.');
      return;
    }

    if (!_isPasswordValid(password)) {
      _showSnackBar(
          'La password deve contenere almeno 8 caratteri, una lettera maiuscola e un carattere speciale.');
      return;
    }

    setState(() => _isLoading = true);

    bool isValid = await isEmailReallyExisting(email);

    setState(() => _isLoading = false);

    if (!isValid) {
      _showSnackBar('Email non valida');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileSetupPage(
          email: email,
          password: password,
        ),
      ),
    );
  }
}