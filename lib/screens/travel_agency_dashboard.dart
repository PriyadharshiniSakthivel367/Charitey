import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'chat_screen.dart';

class TravelAgencyDashboard extends StatefulWidget {
  const TravelAgencyDashboard({Key? key}) : super(key: key);

  @override
  State<TravelAgencyDashboard> createState() => _TravelAgencyDashboardState();
}

class _TravelAgencyDashboardState extends State<TravelAgencyDashboard> {
  final Color themeColor = const Color(0xFF7D444C); 
  // --- NEW: Added ScrollController for the Scrollbar ---
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _acceptDelivery(String donationId, String travelAgencyId) async {
    try {
      await FirebaseFirestore.instance.collection('donations').doc(donationId).update({
        'status': 'delivery_accepted',
        'assignedAgencyId': travelAgencyId,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Delivery Accepted!', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept delivery: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUserModel;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('donations')
            .where('status', whereIn: ['pending', 'delivery_accepted'])
            .snapshots(),
        builder: (context, donationSnapshot) {
          if (donationSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: themeColor));
          }

          if (!donationSnapshot.hasData || donationSnapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          // Sort donations so newest is always at the top
          var donations = donationSnapshot.data!.docs.toList();
          donations.sort((a, b) {
            var aData = a.data() as Map<String, dynamic>;
            var bData = b.data() as Map<String, dynamic>;
            DateTime aTime = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
            DateTime bTime = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
            return bTime.compareTo(aTime); 
          });

          // --- NEW: Added Scrollbar Widget ---
          return Scrollbar(
            controller: _scrollController,
            thumbVisibility: true, // Makes scrollbar always visible
            thickness: 6.0,
            radius: const Radius.circular(10),
            child: ListView.builder(
              controller: _scrollController, // Connected controller
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80),
              itemCount: donations.length,
              itemBuilder: (context, index) {
                var donationDoc = donations[index];
                var donationData = donationDoc.data() as Map<String, dynamic>;
                var donationId = donationDoc.id;
                
                String listingId = donationData['listingId'] ?? '';
                String donorId = donationData['donorId'] ?? '';
                
                // Hide broken old data
                if (listingId.isEmpty || donorId.isEmpty) {
                  return const SizedBox.shrink(); 
                }

                String donorName = donationData['donorName'] ?? 'Unknown Donor';
                String donorLocation = donationData['donorLocation'] ?? 'Location unavailable';
                String donorPhone = donationData['donorPhone'] ?? 'Phone unavailable';
                String status = donationData['status'] ?? 'pending';
                String? assignedAgencyId = donationData['assignedAgencyId'];

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('ngo_listings').doc(listingId).get(),
                  builder: (context, listingSnapshot) {
                    if (!listingSnapshot.hasData || !listingSnapshot.data!.exists) {
                      return const SizedBox.shrink();
                    }

                    var listingData = listingSnapshot.data!.data() as Map<String, dynamic>;
                    bool? isVolunteerAvailable = listingData['isVolunteerAvailable'] as bool?;

                    // LOGIC: If NGO selected "Yes" for Volunteer, hide it
                    if (isVolunteerAvailable == true) {
                      return const SizedBox.shrink(); 
                    }

                    bool isAcceptedByMe = status == 'delivery_accepted' && assignedAgencyId == user.uid;

                    // If someone else accepted it, hide it from this agency
                    if (status == 'delivery_accepted' && !isAcceptedByMe) {
                      return const SizedBox.shrink();
                    }

                    String type = listingData['type'] ?? 'food';
                    String itemName = type == 'food' 
                        ? (listingData['foodType'] ?? "Food") 
                        : (listingData['productName'] ?? "Product");
                    
                    String quantityVal = listingData['quantity']?.toString() ?? '';
                    String unitVal = listingData['unit']?.toString() ?? '';
                    String quantity = quantityVal.isEmpty ? '1 Unit' : '$quantityVal $unitVal';
                    
                    String availability = listingData['availability'] ?? 'Time not specified';
                    String ngoName = listingData['ngoName'] ?? 'Unknown NGO';
                    String ngoLocation = listingData['ngoLocation'] ?? 'Location unavailable';
                    String ngoId = listingData['ngoId'] ?? ''; // Need this to fetch phone

                    // --- NEW: Fetch NGO's Real Phone Number from Users collection ---
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(ngoId).get(),
                      builder: (context, ngoUserSnapshot) {
                        String ngoPhone = 'Phone unavailable';
                        
                        if (ngoUserSnapshot.hasData && ngoUserSnapshot.data!.exists) {
                          var ngoUserData = ngoUserSnapshot.data!.data() as Map<String, dynamic>;
                          ngoPhone = ngoUserData['phone'] ?? 'Phone unavailable';
                        }

                        return _buildDeliveryCard(
                          donationId: donationId,
                          itemName: itemName,
                          quantity: quantity,
                          availability: availability,
                          ngoName: ngoName,
                          ngoLocation: ngoLocation,
                          ngoPhone: ngoPhone, // Passed fetched phone number
                          donorName: donorName,
                          donorLocation: donorLocation,
                          donorPhone: donorPhone,
                          donorId: donorId,
                          myId: user.uid,
                          isAcceptedByMe: isAcceptedByMe,
                        );
                      }
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  // --- NEATLY ALIGNED CARD DESIGN ---
  Widget _buildDeliveryCard({
    required String donationId,
    required String itemName,
    required String quantity,
    required String availability,
    required String ngoName,
    required String ngoLocation,
    required String ngoPhone,
    required String donorName,
    required String donorLocation,
    required String donorPhone,
    required String donorId,
    required String myId,
    required bool isAcceptedByMe,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TOP HEADER: Status & Quantity ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isAcceptedByMe ? Colors.green.shade50 : themeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isAcceptedByMe ? Colors.green.shade200 : Colors.transparent)
                  ),
                  child: Text(
                    isAcceptedByMe ? "✅ Delivery Accepted" : "Pickup Needed",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isAcceptedByMe ? Colors.green.shade700 : themeColor),
                  ),
                ),
                Text(quantity, style: TextStyle(fontWeight: FontWeight.bold, color: themeColor, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            
            // --- ITEM NAME ---
            Text(itemName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
            
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_month_outlined, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Expanded(child: Text("Required by: $availability", style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500))),
              ],
            ),

            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
            
            // --- NEATLY ALIGNED BOXES FOR DONOR & NGO DETAILS ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // DONOR DETAILS
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("PICKUP FROM (Donor)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: themeColor, letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        _buildDetailRow(Icons.person_outline, donorName),
                        const SizedBox(height: 4),
                        _buildDetailRow(Icons.phone_outlined, donorPhone),
                        const SizedBox(height: 4),
                        _buildDetailRow(Icons.location_on_outlined, donorLocation),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // NGO DETAILS
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("DELIVER TO (NGO)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: themeColor, letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        _buildDetailRow(Icons.account_balance_outlined, ngoName),
                        const SizedBox(height: 4),
                        _buildDetailRow(Icons.phone_outlined, ngoPhone),
                        const SizedBox(height: 4),
                        _buildDetailRow(Icons.location_on_outlined, ngoLocation),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),

            // --- ACTION BUTTONS ---
            if (!isAcceptedByMe)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _acceptDelivery(donationId, myId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Accept Delivery", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(otherUserId: donorId, otherUserName: donorName),
                      ),
                    );
                  },
                  icon: Icon(Icons.chat_bubble_outline_rounded, color: themeColor, size: 20),
                  label: Text("Open Chat with Donor", style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: themeColor.withValues(alpha: 0.5), width: 1.5),
                    backgroundColor: themeColor.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text, 
            style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.2),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: themeColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.local_shipping_outlined, size: 60, color: themeColor),
          ),
          const SizedBox(height: 24),
          const Text("No deliveries available", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          Text("Check back later for new pickup requests.", style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
        ],
      ),
    );
  }
}