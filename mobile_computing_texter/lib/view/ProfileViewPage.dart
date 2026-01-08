import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileViewPage extends StatelessWidget {
  final Map<String, dynamic> userData;
  final double? distance;

  const ProfileViewPage({
    Key? key,
    required this.userData,
    this.distance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = const Color(0xFF00B09B);
    final Color secondaryGreen = const Color(0xFF96C93D);

    String genderRaw = (userData['gender'] ?? '').toLowerCase();
    String gender = genderRaw.contains('femmina') ? 'Donna' : genderRaw.contains('maschio') ? 'Uomo' : 'N/D';
    String imagePath = gender == 'Donna' ? 'assets/images/female.png' : 'assets/images/male.png';
    String name = (userData['name'] ?? 'N/D').isNotEmpty 
        ? userData['name'][0].toUpperCase() + userData['name'].substring(1) 
        : 'N/D';
    String zodiac = userData['zodiacSign'] ?? 'N/D';
    String relationship = userData['relationshipStatus'] ?? 'N/D';
    String description = userData['description'] ?? 'Nessuna descrizione.';
    String age = userData['age']?.toString() ?? 'N/D';

    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryGreen, secondaryGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Column(
                        children: [
                          Transform.translate(
                            offset: const Offset(0, -60),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    backgroundImage: AssetImage(imagePath),
                                    radius: 70,
                                    backgroundColor: Colors.grey.shade200,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '$name, $age',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (distance != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: primaryGreen.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.location_on, size: 16, color: primaryGreen),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${distance!.toStringAsFixed(1)} km',
                                            style: GoogleFonts.montserrat(
                                              color: primaryGreen,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          
                          Transform.translate(
                            offset: const Offset(0, -30),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildStatItem(Icons.wc, 'Genere', gender, primaryGreen),
                                    _buildStatItem(Icons.auto_awesome, 'Segno', zodiac, secondaryGreen),
                                    _buildStatItem(Icons.favorite, 'Status', relationship, Colors.redAccent),
                                  ],
                                ),
                                const SizedBox(height: 30),
                                Text(
                                  'Informazioni su di me',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FA),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Text(
                                    description,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 15,
                                      color: Colors.grey.shade700,
                                      height: 1.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}