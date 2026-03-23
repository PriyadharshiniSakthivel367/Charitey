import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'role_selection.dart';
import 'edit_profile_screen.dart'; // <--- NOW CONNECTED

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  final Color themeColor = const Color(0xFFB56F76);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUserModel;

    if (user == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator(color: themeColor)));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Stack(
        children: [
          // --- 1. HERO HEADER ---
          Container(
            height: 240,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [themeColor, themeColor.withOpacity(0.7)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // --- 2. PROFILE CARD ---
                  Container(
                    margin: const EdgeInsets.only(top: 40),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))],
                    ),
                    child: Column(
                      children: [
                        Transform.translate(
                          offset: const Offset(0, -40),
                          child: CircleAvatar(
                            radius: 54,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: themeColor.withOpacity(0.1),
                              backgroundImage: user.profileImage.isNotEmpty ? NetworkImage(user.profileImage) : null,
                              child: user.profileImage.isEmpty ? Icon(Icons.person_rounded, size: 50, color: themeColor) : null,
                            ),
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(0, -20),
                          child: Column(
                            children: [
                              Text(user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                              Text(user.email, style: TextStyle(color: Colors.grey.shade500)),
                              const SizedBox(height: 12),
                              
                              if (user.phone.isNotEmpty) _buildInfoTile(Icons.phone_android_rounded, user.phone),
                              if (user.location.isNotEmpty) _buildInfoTile(Icons.location_on_rounded, user.location),
                              if (user.role != 'user' && user.license.isNotEmpty) 
                                _buildInfoTile(Icons.verified_user_rounded, "ID: ${user.license}", isHighlight: true),

                              const SizedBox(height: 20),
                              
                              // WORKING EDIT PROFILE BUTTON
                              SizedBox(
                                width: 180,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: themeColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  ),
                                  child: const Text("Edit Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 25),
                  
                  // --- 3. RESTORED OLD STATS LOGIC ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (user.role == 'user') ...[
                        _buildStatCard("Total Donations", user.donationsCount.toString()),
                        _buildStatCard("Impact", "Tier 1"),
                      ] else if (user.role == 'ngo') ...[
                        _buildStatCard("Donations Received", user.donationsCount.toString()),
                        _buildStatCard("Total Posts", user.postsCount.toString()),
                      ] else if (user.role == 'travel_agency') ...[
                        _buildStatCard("Deliveries Completed", "0"),
                        _buildStatCard("Rating", "5.0"),
                      ],
                    ],
                  ),

                  const SizedBox(height: 25),

                  // Menu Items
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        _buildMenuTile(Icons.settings_outlined, "Settings"),
                        _buildMenuTile(Icons.help_outline_rounded, "Help Center"),
                        ListTile(
                          leading: const Icon(Icons.logout_rounded, color: Colors.red),
                          title: const Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          onTap: () async {
                            await authProvider.signOut();
                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const RoleSelectionScreen()), (route) => false);
                            }
                          },
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)]),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: themeColor)),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String text, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: isHighlight ? themeColor : Colors.grey),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: isHighlight ? themeColor : Colors.grey.shade700, fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {},
    );
  }
}