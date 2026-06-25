import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';

import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../models/notification_model.dart';
import 'edit_profile_screen.dart';
import 'role_selection.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final Color themeColor = const Color(0xFFB56F76);
  final ImagePicker _picker = ImagePicker();
  bool isUploading = false;

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
    final String userRole = user.role.toString().toLowerCase();
    final bool isViewingNgoProfile =
        userRole == 'ngo' && currentUserId.isNotEmpty && currentUserId != user.uid;

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
                    // Profile Card
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
                                  child: isUploading
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
                                        : SizedBox(
                                            width: 140,
                                            child: ElevatedButton(
                                              onPressed: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => const EditProfileScreen(),
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: themeColor,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(30),
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
                                          if (snapshot.hasData && snapshot.data!.exists) {
                                            final data = snapshot.data!.data() as Map<String, dynamic>?;
                                            favorites = data?['favorites'] ?? [];
                                          }
                                          bool isFav = favorites.contains(user.uid);
                                          return IconButton(
                                            icon: Icon(
                                              isFav ? Icons.favorite : Icons.favorite_border,
                                            ),
                                            color: isFav ? Colors.red : themeColor,
                                            iconSize: 28,
                                            onPressed: () => _toggleFavoriteNgo(
                                              currentUserId,
                                              user.uid,
                                              isFav,
                                            ),
                                          );
                                        },
                                      ),
                                    ]
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          userRole == 'ngo' ? "My Requests" : "My Donations",
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (userRole == 'ngo')
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('volunteer_requests')
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
                                () => _showRecentRequestsSheet(context, user.uid),
                              );
                            },
                          )
                        else
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('donations')
                                .where('donorId', isEqualTo: currentUserId)
                                .snapshots(),
                            builder: (context, snapshot) {
                              String count = "0";
                              if (snapshot.hasData) {
                                count = snapshot.data!.docs.length.toString();
                              }
                              return _buildStatCard(
                                "Total Donations",
                                count,
                                () => _showMyDonationsSheet(context),
                              );
                            },
                          )
                      ],
                    ),
                    const SizedBox(height: 25),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 1)
                        ],
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.logout_rounded, color: Colors.red),
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
                                builder: (context) => const RoleSelectionScreen(),
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

  Widget _buildInfoTile(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  // ============================================================================
  // UPDATED DONATION SHEET METHOD
  // ============================================================================
  // ============================================================================
  // UPDATED DONATION SHEET METHOD (WITH AGGREGATION)
  // ============================================================================
  Future<void> _showMyDonationsSheet(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUserModel;
    final String currentUserId = authProvider.currentFirebaseUser?.uid ?? '';

    if (user == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFDF7F8),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: themeColor,
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: currentUserId.isEmpty
                  ? const Center(child: Text("Unable to load donation history."))
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('donations')
                          .where('donorId', isEqualTo: currentUserId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(child: Text("Error: ${snapshot.error}"));
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator(color: themeColor));
                        }

                        var allDocs = snapshot.data!.docs;
                        Map<String, Map<String, dynamic>> groupedDonations = {};

                        // --- AGGREGATION LOGIC ---
                        // This groups multiple donations to the same listing into ONE card
                        // and adds the quantities together.
                        for (var doc in allDocs) {
                          var data = doc.data() as Map<String, dynamic>;
                          String listingId = data['listingId'] ?? doc.id;
                          
                          // Extract raw quantity and parse to integer (once you fix your DB!)
                          String rawQty = data['quantity']?.toString() ?? 
                                          data['qty']?.toString() ?? 
                                          data['donatedAmount']?.toString() ?? '0';
                          String cleanQty = rawQty.replaceAll(RegExp(r'[^0-9]'), '');
                          int mathQty = int.tryParse(cleanQty.isEmpty ? '0' : cleanQty) ?? 0;

                          if (groupedDonations.containsKey(listingId)) {
                            // User donated again! Add the new quantity to the total.
                            groupedDonations[listingId]!['aggregatedQty'] = 
                                (groupedDonations[listingId]!['aggregatedQty'] as int) + mathQty;
                            
                            // Keep the latest date and status active
                            var existingTime = groupedDonations[listingId]!['createdAt'];
                            var thisTime = data['createdAt'];
                            DateTime existingDate = existingTime is Timestamp ? existingTime.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
                            DateTime thisDate = thisTime is Timestamp ? thisTime.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
                            
                            if (thisDate.isAfter(existingDate)) {
                               groupedDonations[listingId]!['createdAt'] = data['createdAt'];
                               groupedDonations[listingId]!['status'] = data['status'];
                               groupedDonations[listingId]!['docId'] = doc.id; // Target newest doc for cancel
                            }
                          } else {
                            // First time this listing is processed
                            data['aggregatedQty'] = mathQty;
                            data['docId'] = doc.id;
                            groupedDonations[listingId] = Map<String, dynamic>.from(data);
                          }
                        }

                        var donations = groupedDonations.values.toList();
                        
                        // Sort newest first
                        donations.sort((a, b) {
                          var aTime = a['createdAt'];
                          var bTime = b['createdAt'];
                          DateTime aDate = aTime is Timestamp ? aTime.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
                          DateTime bDate = bTime is Timestamp ? bTime.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
                          return bDate.compareTo(aDate);
                        });

                        if (donations.isEmpty) {
                          return const Center(child: Text("No donation history found."));
                        }

                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: donations.length,
                          itemBuilder: (context, index) {
                            var donation = donations[index];

                            final createdAt = donation['createdAt'];
                            String dateText = 'Unknown date';
                            DateTime? createdDate;
                            if (createdAt is Timestamp) {
                              createdDate = createdAt.toDate();
                              dateText = '${createdDate.day}/${createdDate.month}/${createdDate.year}';
                            }

                            String ngoName = donation['ngoName'] ?? 'NGO Partner';
                            String itemName = donation['items'] ?? donation['itemName'] ?? 'Item';
                            
                            // Get the summed-up quantity
                            int donatedQty = donation['aggregatedQty'] as int;
                            String rawDisplayQty = donatedQty.toString();

                            String status = donation['status']?.toString().trim().toLowerCase() ?? 'pending';
                            String ngoId = donation['ngoId'] ?? donation['ngold'] ?? '';
                            String listingId = donation['listingId'] ?? '';
                            String targetDocId = donation['docId'] ?? ''; 

                            final bool isCancelled = status == 'cancelled';
                            final bool canCancel = status == 'pending' &&
                                createdDate != null &&
                                DateTime.now().difference(createdDate).inHours < 24;

                            return FutureBuilder<List<DocumentSnapshot?>>(
                              future: () async {
                                final ngoDoc = ngoId.isNotEmpty
                                    ? await FirebaseFirestore.instance.collection('users').doc(ngoId).get()
                                    : null;
                                DocumentSnapshot? listingDoc;
                                if (listingId.isNotEmpty) {
                                  listingDoc = await FirebaseFirestore.instance.collection('ngo_listings').doc(listingId).get();
                                }
                                return [ngoDoc, listingDoc];
                              }(),
                              builder: (context, combinedSnapshot) {
                                if (combinedSnapshot.connectionState == ConnectionState.waiting) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }

                                int totalQty = donatedQty;
                                int fulfilledQty = donatedQty;
                                String unit = '';
                                String type = 'PRODUCT';

                                if (combinedSnapshot.hasData && combinedSnapshot.data != null) {
                                  final ngoSnapshot = combinedSnapshot.data![0];
                                  if (ngoSnapshot != null && ngoSnapshot.exists) {
                                    var userData = ngoSnapshot.data() as Map<String, dynamic>?;
                                    ngoName = userData?['name'] ?? ngoName;
                                  }

                                  if (combinedSnapshot.data!.length > 1 && combinedSnapshot.data![1] != null) {
                                    final listingSnapshot = combinedSnapshot.data![1]!;
                                    if (listingSnapshot.exists) {
                                      var listingData = listingSnapshot.data() as Map<String, dynamic>?;
                                      if (listingData != null) {
                                        if (listingData['type'] == 'food' || listingData['type'] == 'FOOD') {
                                          itemName = listingData['foodType'] ?? itemName;
                                          type = 'FOOD';
                                        } else {
                                          itemName = listingData['productName'] ?? itemName;
                                          type = (listingData['type'] ?? 'PRODUCT').toString().toUpperCase();
                                        }

                                        unit = listingData['unit'] ?? '';
                                        totalQty = int.tryParse(listingData['quantity']?.toString() ?? '0') ?? donatedQty;
                                        fulfilledQty = int.tryParse(listingData['fulfilledQuantity']?.toString() ?? '0') ?? donatedQty;
                                      }
                                    }
                                  }
                                }

                                int remainingQty = totalQty - fulfilledQty;
                                if (remainingQty < 0) remainingQty = 0;

                                return EnhancedDonationHistoryCard(
                                  ngoName: ngoName,
                                  itemName: itemName,
                                  displayDonatedQty: rawDisplayQty,
                                  mathDonatedQty: donatedQty,
                                  totalQty: totalQty,
                                  fulfilledQty: fulfilledQty,
                                  remainingQty: remainingQty,
                                  unit: unit,
                                  type: type,
                                  dateText: dateText,
                                  isCancelled: isCancelled,
                                  canCancel: canCancel,
                                  themeColor: themeColor,
                                  onCancel: () async {
                                    bool stepOne = await _showCancelStepDialog(
                                      context,
                                      'Step 1 of 3',
                                      'Do you really want to cancel this donation?',
                                    );
                                    if (!stepOne) return;

                                    if (!context.mounted) return;
                                    bool stepTwo = await _showCancelStepDialog(
                                      context,
                                      'Step 2 of 3',
                                      'This action cannot be undone. Are you sure?',
                                    );
                                    if (!stepTwo) return;

                                    if (!context.mounted) return;
                                    String? reason = await showCancelReasonDialog(context);
                                    if (reason == null || reason.trim().isEmpty) return;

                                    try {
                                      // 1. Update the donation status to cancelled
                                      await FirebaseFirestore.instance
                                          .collection('donations')
                                          .doc(targetDocId)
                                          .update({
                                        'status': 'cancelled',
                                        'cancelReason': reason.trim(),
                                        'cancelledAt': Timestamp.now(),
                                      });

                                      // 2. Send Notification to NGO IMMEDIATELY (Guaranteed to run)
                                      if (ngoId.isNotEmpty) {
                                        String notificationId = FirebaseFirestore.instance.collection('notifications').doc().id;
                                        NotificationModel notification = NotificationModel(
                                          id: notificationId,
                                          receiverId: ngoId,
                                          senderId: currentUserId,
                                          senderName: user.name,
                                          title: 'Donation Cancelled',
                                          message: '${user.name} cancelled the donation for $itemName. Reason: "${reason.trim()}". Phone: ${user.phone}',
                                          type: 'donation_cancelled',
                                          relatedItemId: targetDocId,
                                          createdAt: DateTime.now(),
                                          isRead: false,
                                        );
                                        await FirestoreService().sendNotification(notification);
                                      }

                                      // 3. OPTION B: Auto-Restore the Quantity to the Browse Requests Page!
                                      if (listingId.isNotEmpty) {
                                        DocumentReference listingRef = FirebaseFirestore.instance.collection('ngo_listings').doc(listingId);
                                        
                                        await FirebaseFirestore.instance.runTransaction((transaction) async {
                                          DocumentSnapshot listingSnap = await transaction.get(listingRef);
                                          if (listingSnap.exists) {
                                            var lData = listingSnap.data() as Map<String, dynamic>;
                                            
                                            int currentFulfilled = (lData['fulfilledQuantity'] as num? ?? 0).toInt();
                                            int totalNeeded = (lData['quantity'] as num? ?? 0).toInt();
                                            
                                            int newFulfilled = currentFulfilled - donatedQty;
                                            if (newFulfilled < 0) newFulfilled = 0;
                                            
                                            String newStatus = lData['status'] ?? 'open';
                                            if (newFulfilled < totalNeeded && newStatus == 'closed') {
                                              newStatus = 'open';
                                            }
                                            
                                            transaction.update(listingRef, {
                                              'fulfilledQuantity': newFulfilled,
                                              'status': newStatus,
                                            });
                                          }
                                        });
                                      }

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Donation cancelled. NGO notified and quantity restored!')),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Failed to cancel donation.')),
                                        );
                                      }
                                    }
                                  },
                                );
                              },
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

  // ===== OTHER METHODS =====
  Future<bool> _showCancelStepDialog(BuildContext context, String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Yes', style: TextStyle(color: themeColor)),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<String?> showCancelReasonDialog(BuildContext context) async {
    final TextEditingController reasonController = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Step 3 of 3'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for cancellation'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Reason',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, reasonController.text),
            child: Text('Submit', style: TextStyle(color: themeColor)),
          ),
        ],
      ),
    );
    return result?.trim().isEmpty == true ? null : result?.trim();
  }

  Future<void> _toggleFavoriteNgo(String donorId, String ngoId, bool isFav) async {
    if (donorId.isEmpty || ngoId.isEmpty) return;
    final docRef = FirebaseFirestore.instance.collection('users').doc(donorId);
    if (isFav) {
      await docRef.update({
        'favorites': FieldValue.arrayRemove([ngoId])
      });
    } else {
      await docRef.update({
        'favorites': FieldValue.arrayUnion([ngoId])
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => isUploading = true);
    final url = await StorageService().uploadImage(File(picked.path), null);
    if (url != null && mounted) {
      await Provider.of<AuthProvider>(context, listen: false).updateProfile(profileImage: url);
    }
    setState(() => isUploading = false);
  }

  // ============================================================================
  // UPGRADED NGO REQUESTS SHEET
  // ============================================================================
 // ============================================================================
  // UPGRADED NGO REQUESTS SHEET (FIXED FIREBASE INDEX ERROR)
  // ============================================================================
  Future<void> _showRecentRequestsSheet(BuildContext context, String ngoId) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFDF7F8),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
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
              "Your Donation Requests",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: themeColor,
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('ngo_listings')
                    .where('ngoId', isEqualTo: ngoId)
                    // REMOVED .orderBy HERE TO FIX THE FIREBASE INDEX ERROR
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: themeColor));
                  }

                  // ADDED LOCAL SORTING HERE INSTEAD
                  var requests = snapshot.data!.docs.toList();
                  requests.sort((a, b) {
                    var aData = a.data() as Map<String, dynamic>;
                    var bData = b.data() as Map<String, dynamic>;

                    var aTime = aData['createdAt'];
                    var bTime = bData['createdAt'];

                    DateTime aDate = aTime is Timestamp
                        ? aTime.toDate()
                        : (aTime is DateTime ? aTime : DateTime.fromMillisecondsSinceEpoch(0));
                    DateTime bDate = bTime is Timestamp
                        ? bTime.toDate()
                        : (bTime is DateTime ? bTime : DateTime.fromMillisecondsSinceEpoch(0));

                    return bDate.compareTo(aDate); // Sorts newest to oldest
                  });

                  if (requests.isEmpty) {
                    return const Center(child: Text("You haven't made any requests yet."));
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      var data = requests[index].data() as Map<String, dynamic>;
                      
                      // Extracting data safely
                      String type = (data['type'] ?? 'PRODUCT').toString().toUpperCase();
                      bool isFood = type == 'FOOD';
                      String itemName = isFood ? (data['foodType'] ?? 'Food') : (data['productName'] ?? 'Product');
                      
                      int totalQty = int.tryParse(data['quantity']?.toString() ?? '0') ?? 0;
                      int fulfilledQty = int.tryParse(data['fulfilledQuantity']?.toString() ?? '0') ?? 0;
                      int remainingQty = totalQty - fulfilledQty;
                      if (remainingQty < 0) remainingQty = 0;
                      
                      String unit = data['unit'] ?? '';
                      double progress = totalQty > 0 ? (fulfilledQty / totalQty) : 0.0;
                      
                      Timestamp? ts = data['createdAt'] as Timestamp?;
                      String dateText = ts != null ? "${ts.toDate().day}-${ts.toDate().month}-${ts.toDate().year}" : "Unknown Date";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  itemName,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    type,
                                    style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            if (!isFood) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "$fulfilledQty donated out of $totalQty",
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    "$remainingQty needed",
                                    style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                                ),
                              ),
                            ] else ...[
                              Text(
                                "Quantity Requested: $totalQty $unit",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                            
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(dateText, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                const SizedBox(width: 16),
                                Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    data['ngoLocation'] ?? '',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareOption(BuildContext context, String label, IconData icon, String urlScheme) {
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

// ============================================================================
// NEW ENHANCED HISTORY CARD (STATEFUL NATIVE CAPTURE)
// ============================================================================

class EnhancedDonationHistoryCard extends StatefulWidget {
  final String ngoName;
  final String itemName;
  final String displayDonatedQty;
  final int mathDonatedQty;
  final int totalQty;
  final int fulfilledQty;
  final int remainingQty;
  final String unit;
  final String type;
  final String dateText;
  final bool isCancelled;
  final bool canCancel;
  final Color themeColor;
  final VoidCallback onCancel;

  const EnhancedDonationHistoryCard({
    Key? key,
    required this.ngoName,
    required this.itemName,
    required this.displayDonatedQty,
    required this.mathDonatedQty,
    required this.totalQty,
    required this.fulfilledQty,
    required this.remainingQty,
    required this.unit,
    required this.type,
    required this.dateText,
    required this.isCancelled,
    required this.canCancel,
    required this.themeColor,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<EnhancedDonationHistoryCard> createState() => _EnhancedDonationHistoryCardState();
}

class _EnhancedDonationHistoryCardState extends State<EnhancedDonationHistoryCard> {
  final GlobalKey _shareKey = GlobalKey();

  Future<void> _shareDonationCard(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator(color: widget.themeColor)),
    );

    try {
      await Future.delayed(const Duration(milliseconds: 150));

      RenderRepaintBoundary boundary = _shareKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0); 
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      if (context.mounted) Navigator.pop(context);

      String formattedQty = widget.displayDonatedQty;
      if (!formattedQty.toLowerCase().contains(RegExp(r'[a-z]')) && widget.unit.isNotEmpty) {
        formattedQty = '$formattedQty ${widget.unit}';
      }

      // Inside _shareDonationCard in _EnhancedDonationHistoryCardState
String shareMessage = "I just donated ${widget.displayDonatedQty} of ${widget.itemName} to ${widget.ngoName} through Charitey! ❤️\n\n";

if (widget.remainingQty > 0 && widget.type.toUpperCase() != 'FOOD') {
  shareMessage += "They still need ${widget.remainingQty} ${widget.unit}. Every contribution helps change lives.\n\n";
}
shareMessage += "Join me in helping families in need. Download Charitey and make an impact today! ✨\n\n#Charitey #Donate #SocialImpact";

      final xFile = XFile.fromData(
        pngBytes,
        mimeType: 'image/png',
        name: 'charitey_impact.png',
      );

      await Share.shareXFiles(
        [xFile],
        text: shareMessage,
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = widget.totalQty > 0 ? (widget.fulfilledQty / widget.totalQty) : 0.0;
    bool isFood = widget.type.toUpperCase() == 'FOOD';

    // NEW LOGIC: If cancelled, force the display quantity to "0"
    String formattedQty = widget.isCancelled ? "0" : widget.displayDonatedQty;
    
    if (!formattedQty.toLowerCase().contains(RegExp(r'[a-z]')) && widget.unit.isNotEmpty) {
      formattedQty = '$formattedQty ${widget.unit}';
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // FIXED HUGE GAP: Wrapped hidden widget in Positioned so it takes 0 layout space
        Positioned(
          left: -5000,
          top: -5000,
          child: RepaintBoundary(
            key: _shareKey,
            child: Material(
              color: Colors.transparent,
              child: DonationShareTemplate(
                ngoName: widget.ngoName,
                itemName: widget.itemName,
                formattedDonatedQty: formattedQty,
                remainingQty: widget.remainingQty,
                unit: widget.unit,
                totalQty: widget.totalQty,
                fulfilledQty: widget.fulfilledQty,
                type: widget.type,
                themeColor: widget.themeColor,
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: widget.themeColor.withOpacity(0.1),
                    child: Text(
                      widget.ngoName.isNotEmpty ? widget.ngoName[0].toUpperCase() : 'N',
                      style: TextStyle(color: widget.themeColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.ngoName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.verified, color: Colors.green, size: 14),
                            const SizedBox(width: 4),
                            Text("Verified Organization", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.itemName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.themeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.volunteer_activism, size: 16, color: widget.themeColor),
                        const SizedBox(width: 6),
                        Text(
                          "You donated $formattedQty",
                          style: TextStyle(color: widget.themeColor, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.type,
                      style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (!isFood) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${widget.fulfilledQty} collected out of ${widget.totalQty}",
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      "${widget.remainingQty} needed",
                      style: TextStyle(color: widget.themeColor, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(widget.themeColor),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(widget.dateText, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.isCancelled)
                    const Text('Cancelled by you', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13))
                  else if (widget.canCancel)
                    TextButton(
                      onPressed: widget.onCancel,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      child: Text('Cancel Request', style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.bold)),
                    )
                  else
                    TextButton(
                      onPressed: null,
                      child: Text('24h Expired', style: TextStyle(color: Colors.grey.shade400)),
                    ),

                  if (!widget.isCancelled)
                    ElevatedButton.icon(
                      onPressed: () => _shareDonationCard(context),
                      icon: const Icon(Icons.share, size: 18, color: Colors.white),
                      label: const Text("Share Impact", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.themeColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// BACKGROUND WIDGET: THIS GENERATES THE INSTAGRAM-STYLE IMAGE
// ============================================================================
class DonationShareTemplate extends StatelessWidget {
  final String ngoName;
  final String itemName;
  final String formattedDonatedQty;
  final int remainingQty;
  final String unit;
  final int totalQty;
  final int fulfilledQty;
  final String type;
  final Color themeColor;

  const DonationShareTemplate({
    Key? key,
    required this.ngoName,
    required this.itemName,
    required this.formattedDonatedQty,
    required this.remainingQty,
    required this.unit,
    required this.totalQty,
    required this.fulfilledQty,
    required this.type,
    required this.themeColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double progress = totalQty > 0 ? (fulfilledQty / totalQty) : 0.0;
    bool isFood = type.toUpperCase() == 'FOOD';

    return Container(
      width: 400, 
      padding: const EdgeInsets.all(30),
      decoration: const BoxDecoration(
        color: Color(0xFFFDF7F8),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.volunteer_activism, color: themeColor, size: 28),
                const SizedBox(width: 10),
                Text("CHARITEY", style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 1.5)),
              ],
            ),
            const SizedBox(height: 25),
            Text("I supported", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(ngoName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(width: 5),
                const Icon(Icons.verified, color: Colors.green, size: 18),
              ],
            ),
            const SizedBox(height: 25),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(color: themeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Text("🎁 I Donated", style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 5),
                  Text("$formattedDonatedQty of $itemName", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                ],
              ),
            ),
            const SizedBox(height: 25),
            
            if (!isFood) ...[
              if (remainingQty > 0) ...[
                Text("Still Needed: $remainingQty $unit", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.redAccent)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                  ),
                ),
                const SizedBox(height: 8),
                Text("$fulfilledQty / $totalQty collected", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              ] else ...[
                const Text("🎉 Goal Fully Reached! 🎉", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
              ],
            ] else ...[
               Text("Providing essential food relief.", style: TextStyle(color: Colors.grey.shade700, fontSize: 16, fontStyle: FontStyle.italic)),
            ],
            
            const SizedBox(height: 30),
            const Text("Every donation changes lives.", style: TextStyle(fontStyle: FontStyle.italic, fontSize: 16)),
            const SizedBox(height: 5),
            Text("Join me and support families in need.", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            const SizedBox(height: 20),
            Text("#Charitey", style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}