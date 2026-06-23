import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/notification_model.dart';
import 'chat_screen.dart';
import 'home_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  // --- PRIVATE HELPER TO FETCH REAL TIME DATA DYNAMICALLY ---
  // This function fetches the specific request/donation data and joins the correct NGO or sender profiles from the 'users' collection.
  Future<Map<String, dynamic>> _fetchDetailsData(NotificationModel notif, bool isDonationOffer, bool amINGO) async {
    Map<String, dynamic> result = {};

    try {
      if (isDonationOffer) {
        // 1. Fetch the specific donation request document
        DocumentSnapshot donationSnap = await FirebaseFirestore.instance
            .collection('donations')
            .doc(notif.relatedItemId)
            .get();

        if (donationSnap.exists && donationSnap.data() != null) {
          var donationData = donationSnap.data() as Map<String, dynamic>;
          result['donationData'] = donationData;

          // 2. If current user is the donor, fetch the specific requested NGO's profile
          if (!amINGO) {
            String? ngoId = donationData['ngoId'] ?? notif.receiverId;
            if (ngoId != null && ngoId.isNotEmpty) {
              DocumentSnapshot ngoSnap = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(ngoId)
                  .get();
              if (ngoSnap.exists && ngoSnap.data() != null) {
                result['ngoProfileData'] = ngoSnap.data() as Map<String, dynamic>;
              }
            }
          }
        }
      } else {
        // 3. For messages/tags, fetch the real-time sender profile details to prevent random or missing data
        DocumentSnapshot senderSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(notif.senderId)
            .get();

        if (senderSnap.exists && senderSnap.data() != null) {
          result['senderProfileData'] = senderSnap.data() as Map<String, dynamic>;
        }

        DocumentSnapshot notifSnap = await FirebaseFirestore.instance
            .collection('notifications')
            .doc(notif.id)
            .get();
        if (notifSnap.exists && notifSnap.data() != null) {
          result['notifData'] = notifSnap.data() as Map<String, dynamic>;
        }
      }
    } catch (e) {
      print("Error fetching dynamic notification details: $e");
    }

    return result;
  }

  // --- SMART UNIFIED POPUP ---
  void _showRichDetailsPopup(BuildContext context, NotificationModel notif, Color themeColor, bool isDonationOffer) {
    final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUserModel;
    bool amINGO = currentUser?.role == 'ngo';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(isDonationOffer ? Icons.volunteer_activism : Icons.message_rounded, color: themeColor),
              const SizedBox(width: 10),
              Text(
                isDonationOffer ? "Donation Details" : "Contact Details", 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
              ),
            ],
          ),
          content: FutureBuilder<Map<String, dynamic>>(
            future: _fetchDetailsData(notif, isDonationOffer, amINGO),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: themeColor)));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text("Details no longer available.");
              }
              
              var fetchedData = snapshot.data!;
              
              String displayTitle = "";
              String nameLabel = "";
              String locationLabel = "";
              String contactName = "";
              String contactPhone = "";
              String contactLocation = "";
              String targetChatId = ""; 

              if (isDonationOffer) {
                var donationData = fetchedData['donationData'] ?? {};
                if (amINGO) {
                  // NGO is looking at the offer -> Show Donor Details
                  displayTitle = "Offered By:";
                  nameLabel = "Donor Name";
                  locationLabel = "Pickup Location";
                  contactName = donationData['donorName'] ?? 'Unknown Donor';
                  contactPhone = donationData['donorPhone'] ?? 'Unknown Phone';
                  contactLocation = donationData['donorLocation'] ?? 'Unknown Location';
                  targetChatId = donationData['donorId'] ?? notif.senderId; 
                } else {
                  // Donor is looking at their receipt -> Show specific created NGO details
                  displayTitle = "Donating To:";
                  nameLabel = "Organization Name";
                  locationLabel = "Drop-off/NGO Location";
                  
                  var ngoProfile = fetchedData['ngoProfileData'] ?? {};
                  
                  // Dynamically resolves name, phone, and address from the exact NGO profile or fallback entries
                  contactName = ngoProfile['ngoName'] ?? ngoProfile['name'] ?? donationData['ngoName'] ?? 'Unknown NGO'; 
                  contactPhone = ngoProfile['phone'] ?? ngoProfile['ngoPhone'] ?? donationData['ngoPhone'] ?? 'Not Provided'; 
                  contactLocation = ngoProfile['address'] ?? ngoProfile['location'] ?? donationData['ngoLocation'] ?? 'Not Provided';
                  targetChatId = donationData['ngoId'] ?? notif.receiverId; 
                }
              } else {
                // Standard Message/Tag Notification Logic
                var senderProfile = fetchedData['senderProfileData'] ?? {};
                var notifData = fetchedData['notifData'] ?? {};
                
                nameLabel = "Sender Name";
                locationLabel = "Location";
                contactName = senderProfile['name'] ?? senderProfile['ngoName'] ?? notif.senderName;
                contactPhone = senderProfile['phone'] ?? notifData['senderPhone'] ?? 'Not Provided';
                contactLocation = senderProfile['address'] ?? senderProfile['location'] ?? notifData['senderLocation'] ?? 'Not Provided';
                targetChatId = notif.senderId;
              }
              
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (displayTitle.isNotEmpty) ...[
                    Text(displayTitle, style: TextStyle(fontWeight: FontWeight.bold, color: themeColor, fontSize: 14)),
                    const SizedBox(height: 8),
                  ],
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300)
                    ),
                    child: Text(
                      notif.message, 
                      style: TextStyle(color: Colors.grey.shade700, fontStyle: FontStyle.italic, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  _detailRow(Icons.person_outline, nameLabel, contactName, themeColor),
                  const SizedBox(height: 16),
                  _detailRow(Icons.phone_outlined, "Contact Number", contactPhone, themeColor),
                  const SizedBox(height: 16),
                  _detailRow(Icons.location_on_outlined, locationLabel, contactLocation, themeColor),
                  
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Close the popup
                        
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              otherUserId: targetChatId,
                              otherUserName: contactName,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_rounded),
                      label: Text(
                        isDonationOffer ? (amINGO ? "Accept & Chat with Donor" : "Chat with NGO") : "Open Chat", 
                        style: const TextStyle(fontWeight: FontWeight.bold)
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  )
                ],
              );
            }
          )
        );
      }
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color themeColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: themeColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUserModel;
    final firestoreService = FirestoreService();
    final Color themeColor = const Color(0xFFB56F76);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Notifications")),
        body: const Center(child: Text("Please log in to view notifications.")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: firestoreService.getUserNotifications(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: themeColor));
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error loading notifications."));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text("No new notifications", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              bool isMessage = notif.type == 'new_message';
              bool isTag = notif.type == 'tag'; 
              bool isDonationOffer = notif.type == 'donation_offer';

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: notif.isRead ? Colors.white : themeColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: notif.isRead ? Colors.grey.shade200 : themeColor.withValues(alpha: 0.3),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: CircleAvatar(
                    backgroundColor: themeColor.withValues(alpha: 0.1),
                    child: Icon(
                      isTag ? Icons.photo_library_rounded : (isMessage ? Icons.message_rounded : Icons.volunteer_activism), 
                      color: themeColor
                    ),
                  ),
                  title: Text(
                    notif.title,
                    style: TextStyle(
                      fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      notif.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade700, height: 1.3),
                    ),
                  ),
                  trailing: notif.isRead ? null : Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  ),
                  onTap: () {
                    if (!notif.isRead) {
                      firestoreService.markNotificationAsRead(notif.id);
                    }
                    
                    if (isTag) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomeScreen(
                            initialIndex: 1, 
                            targetPostId: notif.relatedItemId, 
                          ),
                        ),
                        (Route<dynamic> route) => false, 
                      );
                    } else {
                      _showRichDetailsPopup(context, notif, themeColor, isDonationOffer);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}