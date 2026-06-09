import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: themeColor)),
      );
    }

    final String currentUserId = authProvider.currentFirebaseUser?.uid ?? '';
    final String userRole = (user.role ?? 'donor').toString().toLowerCase();
    final bool isViewingNgoProfile =
        userRole == 'ngo' &&
        currentUserId.isNotEmpty &&
        currentUserId != user.uid;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFDF7F8), Color(0xFFEEDAE0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.1, 1.0],
        ),
      ),
      child: Scaffold(
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
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
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
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Transform.translate(
                            offset: const Offset(0, -40),
                            child: GestureDetector(
                              onTap: _pickAndUploadImage,
                              child: CircleAvatar(
                                radius: 54,
                                backgroundColor: Colors.white,
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: themeColor.withOpacity(0.1),
                                  backgroundImage: user.profileImage.isNotEmpty
                                      ? NetworkImage(user.profileImage)
                                      : null,
                                  child: _isUploading
                                      ? const CircularProgressIndicator()
                                      : (user.profileImage.isEmpty
                                            ? Icon(
                                                Icons.person_rounded,
                                                size: 50,
                                                color: themeColor,
                                              )
                                            : null),
                                ),
                              ),
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(0, -20),
                            child: Column(
                              children: [
                                Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (user.username.isNotEmpty)
                                  Text(
                                    "@${user.username}",
                                    style: TextStyle(
                                      color: themeColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                Text(
                                  user.email,
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                                const SizedBox(height: 12),
                                if (user.phone.isNotEmpty)
                                  _buildInfoTile(
                                    Icons.phone_android_rounded,
                                    user.phone,
                                  ),
                                if (user.location.isNotEmpty)
                                  _buildInfoTile(
                                    Icons.location_on_rounded,
                                    user.location,
                                  ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Navigator.canPop(context)
                                        ? const SizedBox.shrink()
                                        : const SizedBox.shrink(),
                                    SizedBox(
                                      width: 140,
                                      child: ElevatedButton(
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const EditProfileScreen(),
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: themeColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          "Edit Profile",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ),
                                    if (isViewingNgoProfile) ...[
                                      const SizedBox(width: 10),
                                      StreamBuilder<DocumentSnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(currentUserId)
                                            .snapshots(),
                                        builder: (context, snapshot) {
                                          List<dynamic> favorites = [];
                                          if (snapshot.hasData &&
                                              snapshot.data!.exists) {
                                            final data =
                                                snapshot.data!.data()
                                                    as Map<String, dynamic>?;
                                            favorites =
                                                data?['favorites'] ?? [];
                                          }
                                          bool isFav = favorites.contains(
                                            user.uid,
                                          );
                                          return IconButton(
                                            icon: Icon(
                                              isFav
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: isFav
                                                  ? Colors.red
                                                  : themeColor,
                                              size: 28,
                                            ),
                                            onPressed: () => _toggleFavoriteNgo(
                                              currentUserId,
                                              user.uid,
                                              isFav,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ],
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
                        _buildActionButton(
                          userRole == 'ngo' ? "Requests" : "Donations",
                          Icons.history,
                          () => userRole == 'ngo'
                              ? _showRecentRequestsSheet(context, user.uid)
                              : _showMyDonationsSheet(context),
                        ),
                        _buildActionButton(
                          "Share",
                          Icons.share,
                          () => _shareApp(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // --- 4. STATS (DYNAMIC REAL-TIME COUNTS) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (userRole == 'ngo')
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('requests')
                                .where('ngoId', isEqualTo: user.uid)
                                .snapshots(),
                            builder: (context, snapshot) {
                              String count = "0";
                              if (snapshot.hasData) {
                                count = snapshot.data!.docs.length.toString();
                              }
                              return _buildStatCard(
                                "Total Requests",
                                count,
                                () =>
                                    _showRecentRequestsSheet(context, user.uid),
                              );
                            },
                          )
                        else
                          _buildStatCard(
                            "Total Donations",
                            (user.donationsCount ?? 0).toString(),
                            () {},
                          ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // --- 5. LOGOUT ---
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 5),
                        ],
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.logout_rounded,
                          color: Colors.red,
                        ),
                        title: const Text(
                          "Logout",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () async {
                          await authProvider.signOut();
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const RoleSelectionScreen(),
                              ),
                              (route) => false,
                            );
                          }
                        },
                      ),
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8),
              ],
            ),
            child: Icon(icon, color: themeColor, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
          ),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityTile(String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: themeColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: themeColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    IconData icon,
    String text, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: isHighlight ? themeColor : Colors.grey),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  // --- REAL-TIME INTEGRATED LOGIC METHODS ---
  Future<void> _toggleFavoriteNgo(
    String donorId,
    String ngoId,
    bool isFav,
  ) async {
    if (donorId.isEmpty || ngoId.isEmpty) return;
    final docRef = FirebaseFirestore.instance.collection('users').doc(donorId);
    if (isFav) {
      await docRef.update({
        'favorites': FieldValue.arrayRemove([ngoId]),
      });
    } else {
      await docRef.update({
        'favorites': FieldValue.arrayUnion([ngoId]),
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _isUploading = true);
    final url = await StorageService().uploadImage(File(picked.path), null);
    if (url != null && mounted) {
      await Provider.of<AuthProvider>(
        context,
        listen: false,
      ).updateProfile(profileImage: url);
    }
    setState(() => _isUploading = false);
  }

  Future<void> _showMyDonationsSheet(BuildContext context) async {
    final String currentUserId =
        Provider.of<AuthProvider>(
          context,
          listen: false,
        ).currentFirebaseUser?.uid ??
        '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Recent Donation History",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeColor,
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: currentUserId.isEmpty
                  ? const Center(
                      child: Text("Unable to load donation history."),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('donations')
                          .where('donorId', isEqualTo: currentUserId)
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        var donations = snapshot.data!.docs;
                        if (donations.isEmpty) {
                          return const Center(
                            child: Text("No donation history found."),
                          );
                        }

                        return ListView.builder(
                          itemCount: donations.length,
                          itemBuilder: (context, index) {
                            var donation =
                                donations[index].data() as Map<String, dynamic>;
                            final createdAt = donation['createdAt'];
                            String dateText = 'Unknown date';
                            if (createdAt is Timestamp) {
                              dateText =
                                  '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}';
                            }
                            return _buildActivityTile(
                              donation['ngoId'] ?? 'NGO',
                              '${donation['status'] ?? 'Pending'} • $dateText',
                              Icons.volunteer_activism,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRecentRequestsSheet(
    BuildContext context,
    String ngoId,
  ) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Recent Donation Requests",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeColor,
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('requests')
                    .where('ngoId', isEqualTo: ngoId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var requests = snapshot.data!.docs;
                  if (requests.isEmpty) {
                    return const Center(child: Text("No requests found."));
                  }

                  return ListView.builder(
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      var request =
                          requests[index].data() as Map<String, dynamic>;
                      return _buildActivityTile(
                        request['title'] ?? 'Need Items',
                        request['description'] ?? 'No description provided',
                        Icons.campaign,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareApp(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Share App Via",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildShareOption(
                    sheetContext,
                    "WhatsApp",
                    Icons.chat_bubble_outline,
                    "whatsapp://send?text=Check out Charitey App: https://charitey.app",
                  ),
                  _buildShareOption(
                    sheetContext,
                    "Facebook",
                    Icons.facebook,
                    "https://www.facebook.com/sharer/sharer.php?u=https://charitey.app",
                  ),
                  _buildShareOption(
                    sheetContext,
                    "Instagram",
                    Icons.camera_alt_outlined,
                    "https://www.instagram.com",
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareOption(
    BuildContext context,
    String label,
    IconData icon,
    String urlScheme,
  ) {
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);
        final Uri url = Uri.parse(urlScheme);
        try {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } catch (e) {
          await launchUrl(
            Uri.parse("https://charitey.app"),
            mode: LaunchMode.platformDefault,
          );
        }
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: themeColor.withOpacity(0.1),
            child: Icon(icon, color: themeColor, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}