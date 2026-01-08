import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class ProfileSetupPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final bool isReadOnly;
  final String? email;
  final String? password;

  ProfileSetupPage({
    this.userData,
    this.isReadOnly = false,
    this.email,
    this.password,
  });

  @override
  _ProfileSetupPageState createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  late TextEditingController nameController;
  late TextEditingController ageController;
  late TextEditingController descriptionController;

  String? selectedZodiacSign;
  String? selectedRelationshipStatus;
  String? selectedGender;

  final List<String> zodiacSigns = [
    'Ariete', 'Toro', 'Gemelli', 'Cancro', 'Leone', 'Vergine',
    'Bilancia', 'Scorpione', 'Sagittario', 'Capricorno', 'Acquario', 'Pesci'
  ];

  final List<String> relationshipStatuses = [
    'Single', 'Relazione'
  ];

  final List<String> genders = [
    'Maschio', 'Femmina'
  ];

  bool _isLoading = false;
  final Color primaryGreen = Color(0xFF00B09B);
  final Color secondaryGreen = Color(0xFF96C93D);

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.userData?['name'] ?? '');
    ageController = TextEditingController(text: widget.userData?['age']?.toString() ?? '');
    descriptionController = TextEditingController(text: widget.userData?['description'] ?? '');
    selectedZodiacSign = widget.userData?['zodiacSign'];
    selectedRelationshipStatus = widget.userData?['relationshipStatus'];
    selectedGender = widget.userData?['gender'];
  }

  Future<void> _saveAndRegister() async {
    final name = nameController.text.trim();
    final age = int.tryParse(ageController.text.trim());
    final description = descriptionController.text.trim();

    if (name.isEmpty ||
        age == null ||
        age < 18 ||
        description.isEmpty ||
        selectedZodiacSign == null ||
        selectedRelationshipStatus == null ||
        selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Per favore, compila tutti i campi e assicurati che l\'età sia almeno 18 anni')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user;
      
      if (widget.email != null && widget.password != null) {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: widget.email!,
          password: widget.password!,
        );
        user = userCredential.user;
        
        if (user != null) {
          await user.sendEmailVerification();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Email di verifica inviata a ${user.email}.')),
            );
          }
        }
      } else {
        user = FirebaseAuth.instance.currentUser;
      }

      if (user != null) {
        Map<String, dynamic> profileData = {
          'name': name,
          'age': age,
          'description': description,
          'zodiacSign': selectedZodiacSign,
          'relationshipStatus': selectedRelationshipStatus,
          'gender': selectedGender,
          'isOnline': true,
        };

        if (widget.email != null) {
          profileData['email'] = widget.email;
          profileData['createdAt'] = FieldValue.serverTimestamp();
        }

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(profileData, SetOptions(merge: true));

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/swipe', (route) => false);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
         String errorMessage = 'Si è verificato un errore.';
        if (e.code == 'weak-password') {
          errorMessage = 'La password è troppo debole.';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = 'L\'email è già in uso.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nel salvataggio del profilo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      if (Navigator.canPop(context))
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                        ),
                      SizedBox(height: 10),
                      Center(
                        child: Text(
                          widget.isReadOnly ? 'Profilo Utente' : 'Completa Profilo',
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
                          widget.isReadOnly ? 'Visualizza i dettagli' : 'Raccontaci di te',
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
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                    alignment: Alignment.center,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: EdgeInsets.all(30),
                        margin: EdgeInsets.symmetric(vertical: 20),
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
                            _buildTextField('Nome', nameController, Icons.person, readOnly: widget.isReadOnly),
                            _buildTextField('Età', ageController, Icons.cake, isNumber: true, readOnly: widget.isReadOnly),
                            _buildTextField('Descrizione', descriptionController, Icons.description, maxLines: 3, readOnly: widget.isReadOnly),
                            _buildDropdown('Segno Zodiacale', zodiacSigns, selectedZodiacSign, widget.isReadOnly ? null : (val) => setState(() => selectedZodiacSign = val)),
                            _buildDropdown('Stato Relazionale', relationshipStatuses, selectedRelationshipStatus, widget.isReadOnly ? null : (val) => setState(() => selectedRelationshipStatus = val)),
                            _buildDropdown('Genere', genders, selectedGender, widget.isReadOnly ? null : (val) => setState(() => selectedGender = val)),
                            SizedBox(height: 30),
                            if (!widget.isReadOnly)
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
                                  onPressed: _isLoading ? null : _saveAndRegister,
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
                                          widget.email != null ? 'COMPLETA REGISTRAZIONE' : 'SALVA PROFILO',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 14,
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

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isNumber = false, int maxLines = 1, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        readOnly: readOnly,
        style: GoogleFonts.montserrat(color: Color(0xFF333333)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.montserrat(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: primaryGreen),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? selectedValue, ValueChanged<String?>? onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        items: items.map((item) => DropdownMenuItem(
          value: item,
          child: Text(item, style: GoogleFonts.montserrat(color: Color(0xFF333333))),
        )).toList(),
        onChanged: onChanged,
        icon: Icon(Icons.arrow_drop_down, color: primaryGreen),
        style: GoogleFonts.montserrat(color: Color(0xFF333333)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.montserrat(color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
        disabledHint: selectedValue != null ? Text(selectedValue, style: GoogleFonts.montserrat(color: Colors.black54)) : null,
      ),
    );
  }
}