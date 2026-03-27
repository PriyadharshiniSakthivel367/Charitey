import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/notification_model.dart';
import 'chat_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  // --- SMART UNIFIED POPUP ---
  void _showRichDetailsPopup(BuildContext context, NotificationModel notif, Color themeColor, bool isDonationOffer) {
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
          content: FutureBuilder<DocumentSnapshot>(
            future: isDonationOffer 
                ? FirebaseFirestore.instance.collection('donations').doc(notif.relatedItemId).get()
                : FirebaseFirestore.instance.collection('notifications').doc(notif.id).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: themeColor)));
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Text("Details no longer available.");
              }
              
              var data = snapshot.data!.data() as Map<String, dynamic>;
              
              // --- SMART LABEL LOGIC ---
              bool isSenderNGO = false;
              bool isSenderTravelAgency = false;
              
              if (!isDonationOffer) {
                 isSenderNGO = data['senderRole'] == 'ngo';
                 isSenderTravelAgency = data['senderRole'] == 'travel_agency'; // <-- Added check
              }

              // Determine correct labels based on role
              String nameLabel = "Donor Name";
              String locationLabel = "Donor Location";
              
              if (isSenderNGO) {
                nameLabel = "Organization Name";
                locationLabel = "Organization Location";
              } else if (isSenderTravelAgency) {
                nameLabel = "Travel Agency Name";
                locationLabel = "Agency Location";
              }

              // Map the actual data
              String contactName = isDonationOffer ? (data['donorName'] ?? notif.senderName) : notif.senderName;
              String contactPhone = isDonationOffer ? (data['donorPhone'] ?? 'Unknown') : (data['senderPhone'] ?? 'Unknown');
              String contactLocation = isDonationOffer ? (data['donorLocation'] ?? 'Unknown') : (data['senderLocation'] ?? 'Unknown');
              
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  
                  // Use the Smart Labels!
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
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              otherUserId: notif.senderId,
                              otherUserName: contactName,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_rounded),
                      label: Text(
                        isDonationOffer ? "Start Chat with Donor" : "Open Chat", 
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

  // Helper widget for the rows
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
      ]
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
                      isMessage ? Icons.message_rounded : Icons.volunteer_activism, 
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
                    
                    _showRichDetailsPopup(context, notif, themeColor, notif.type == 'donation_offer');
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