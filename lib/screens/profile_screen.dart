import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';
import '../services/storage_service.dart';
import 'edit_profile_screen.dart';
import 'role_selection.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Color themeColor = const Color(0xFFB56F76);
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUserModel;

    if (user == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator(color: themeColor)));
    }

    return Container(
      // --- THE ELEGANT DUSKY ROSE GRADIENT BACKGROUND ---
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFDF7F8), // Very soft, almost white top-left
            Color(0xFFEEDAE0), // Elegant dusky rose shade bottom-right
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.1, 1.0],
        ),
      ),
      child: Scaffold(
        // Make scaffold transparent so the gradient shines through
        backgroundColor: Colors.transparent,
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
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
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
                            child: GestureDetector(
                              onTap: _pickAndUploadImage,
                              child: CircleAvatar(
                                radius: 54, backgroundColor: Colors.white,
                                child: CircleAvatar(
                                  radius: 50, backgroundColor: themeColor.withOpacity(0.1),
                                  backgroundImage: user.profileImage.isNotEmpty ? NetworkImage(user.profileImage) : null,
                                  child: _isUploading 
                                    ? const CircularProgressIndicator()
                                    : (user.profileImage.isEmpty ? Icon(Icons.person_rounded, size: 50, color: themeColor) : null),
                                ),
                              ),
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(0, -20),
                            child: Column(
                              children: [
                                Text(user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                if (user.username.isNotEmpty) Text("@${user.username}", style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
                                Text(user.email, style: TextStyle(color: Colors.grey.shade500)),
                                const SizedBox(height: 12),
                                if (user.phone.isNotEmpty) _buildInfoTile(Icons.phone_android_rounded, user.phone),
                                if (user.location.isNotEmpty) _buildInfoTile(Icons.location_on_rounded, user.location),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: 180,
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                                    style: ElevatedButton.styleFrom(backgroundColor: themeColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                                    child: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- 3. QUICK ACTIONS ROW ---
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton("Donations", Icons.history, () => _showMyDonationsSheet(context)),
                        _buildActionButton("Favorites", Icons.favorite_border, () => _showFavoriteNgosSheet(context)),
                        _buildActionButton("Share", Icons.share, () => _shareApp(context)),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // --- 4. STATS ---
                    Row(
                      children: [
                        _buildStatCard("Donations", user.donationsCount.toString()),
                        _buildStatCard("Impact", "Tier 1"),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // --- 5. RECENT ACTIVITY ---
                    _buildSectionTitle("Recent Activity"),
                    const SizedBox(height: 12),
                    _buildActivityTile("Donated to Aishwaryam NGO", "2 days ago"),
                    _buildActivityTile("Donated surplus clothes", "5 days ago"),
                    
                    ListTile(
                      leading: const Icon(Icons.logout_rounded, color: Colors.red),
                      title: const Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      onTap: () async {
                        await authProvider.signOut();
                        if (context.mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const RoleSelectionScreen()), (route) => false);
                      },
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- BUILDER HELPERS ---
  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Column(children: [Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)]), child: Icon(icon, color: themeColor, size: 26)), const SizedBox(height: 8), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))]));
  }

  Widget _buildStatCard(String label, String value) {
    return Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 8), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)]), child: Column(children: [Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: themeColor)), Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11))])));
  }

  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Align(alignment: Alignment.centerLeft, child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))));

  Widget _buildActivityTile(String title, String time) {
    return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: themeColor.withOpacity(0.1))), child: Row(children: [const Icon(Icons.volunteer_activism, color: Color(0xFFB56F76)), const SizedBox(width: 12), Expanded(child: Text(title)), Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey))]));
  }

  Widget _buildInfoTile(IconData icon, String text, {bool isHighlight = false}) {
    return Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 16, color: isHighlight ? themeColor : Colors.grey), const SizedBox(width: 8), Text(text)]));
  }

  // --- INTEGRATED LOGIC METHODS ---
  Future<void> _pickAndUploadImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _isUploading = true);
    final url = await StorageService().uploadImage(File(picked.path), null);
    if (url != null) await Provider.of<AuthProvider>(context, listen: false).updateProfile(profileImage: url);
    setState(() => _isUploading = false);
  }

  Future<void> _showMyDonationsSheet(BuildContext context) async { showModalBottomSheet(context: context, builder: (_) => Container(height: 200, child: const Center(child: Text("Donation History")))); }
  Future<void> _showFavoriteNgosSheet(BuildContext context) async { showModalBottomSheet(context: context, builder: (_) => Container(height: 200, child: const Center(child: Text("Favorites")))); }
  Future<void> _shareApp(BuildContext context) async { await launchUrl(Uri.parse("https://charitey.app")); }
}