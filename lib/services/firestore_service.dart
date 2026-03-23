import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ngo_listing_model.dart';
import '../models/donation_model.dart';
import '../models/volunteer_request_model.dart';
import '../models/notification_model.dart'; // Added this import

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- NGO Listings ---

  // Create NGO Listing
  Future<void> createNgoListing(NgoListingModel listing) async {
    try {
      await _firestore
          .collection('ngo_listings')
          .doc(listing.listingId)
          .set(listing.toMap());
    } catch (e) {
      print('Error creating listing: $e');
      rethrow;
    }
  }

  // Get NGO Listings Stream (for Donor side)
  Stream<List<NgoListingModel>> getOpenListingsStream() {
    return _firestore
        .collection('ngo_listings')
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NgoListingModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Get NGO Listings Stream (for specific NGO)
  Stream<List<NgoListingModel>> getNgoListingsStream(String ngoId) {
    return _firestore
        .collection('ngo_listings')
        .where('ngoId', isEqualTo: ngoId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NgoListingModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Update NGO Listing status
  Future<void> updateListingStatus(String listingId, String newStatus) async {
    try {
      await _firestore.collection('ngo_listings').doc(listingId).update({
        'status': newStatus,
      });
    } catch (e) {
      print('Error updating listing status: $e');
      rethrow;
    }
  }

  // --- Donations ---

  // Process Donation (Transactional: Create donation, update listing, create volunteer request if needed)
  Future<void> processDonation(DonationModel donation) async {
    try {
      // 1. Transaction to ensure consistency
      await _firestore.runTransaction((transaction) async {
        // Document References
        DocumentReference listingRef =
            _firestore.collection('ngo_listings').doc(donation.listingId);
        DocumentReference donationRef =
            _firestore.collection('donations').doc(donation.donationId);

        // a. Read listing to verify its still open
        DocumentSnapshot listingSnapshot = await transaction.get(listingRef);
        if (!listingSnapshot.exists) {
          throw Exception("Listing does not exist!");
        }

        String currentStatus = listingSnapshot.get('status');
        if (currentStatus != 'open') {
          throw Exception("Listing has already been claimed.");
        }

        // b. Write: Update listing status
        transaction.update(listingRef, {'status': 'claimed'});

        // c. Write: Create donation record
        transaction.set(donationRef, donation.toMap());
        
        // d. Write: Auto-create a volunteer request for this donation
        DocumentReference volunteerRequestRef = _firestore.collection('volunteer_requests').doc();
         VolunteerRequestModel vRequest = VolunteerRequestModel(
            requestId: volunteerRequestRef.id,
            ngoId: donation.ngoId,
            donorId: donation.donorId,
            listingId: donation.listingId,
            status: 'pending',
            createdAt: DateTime.now(),
         );
         transaction.set(volunteerRequestRef, vRequest.toMap());

      });
    } catch (e) {
      print('Error processing donation: $e');
      rethrow;
    }
  }

  // Get user donations
  Stream<List<DonationModel>> getUserDonationsStream(String donorId) {
    return _firestore
        .collection('donations')
        .where('donorId', isEqualTo: donorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DonationModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // ==========================================
  // --- IN-APP NOTIFICATION LOGIC (NEW) ---
  // ==========================================
  
  // 1. Send a notification to the database
  Future<void> sendNotification(NotificationModel notification) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());
    } catch (e) {
      print("Error sending notification: $e");
    }
  }

 // 2. Listen for new notifications for a specific user (NGO)
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('receiverId', isEqualTo: userId)
        // 🔥 REMOVED .orderBy to fix the Firestore Index error!
        .snapshots()
        .map((snapshot) {
          // Convert the raw data into our Notification models
          var docs = snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
              .toList();
              
          // 🔥 Sort them manually in the app (newest first)
          docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          return docs;
        });
  }

  // 3. Mark a notification as read when clicked
  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({'isRead': true});
  }
} // Make sure this closing bracket matches the end of your FirestoreService class!