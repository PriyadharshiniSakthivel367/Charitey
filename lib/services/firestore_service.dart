import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ngo_listing_model.dart';
import '../models/donation_model.dart';
import '../models/volunteer_request_model.dart';
import '../models/notification_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==========================================
  // --- NGO LISTINGS LOGIC ---
  // ==========================================

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

  // Get Open NGO Listings Stream
  Stream<List<NgoListingModel>> getOpenListingsStream() {
    return _firestore
        .collection('ngo_listings')
        .where('status', isEqualTo: 'open') // Optimized to only stream available listings
        .snapshots()
        .map((snapshot) {
          print("Documents Found: ${snapshot.docs.length}");
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
          print("NGO LISTINGS COUNT: ${snapshot.docs.length}");
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

  // ==========================================
  // --- DONATIONS LOGIC ---
  // ==========================================

  // Process Donation (Transactional: Create donation, update listing, create volunteer request, and notify NGO)
  Future<void> processDonation({
    required DonationModel donation,
    required NotificationModel notification,
  }) async {
    try {
      // Atomic Transaction block ensures data integrity across all 4 operations
      await _firestore.runTransaction((transaction) async {
        // Document References
        DocumentReference listingRef = _firestore.collection('ngo_listings').doc(donation.listingId);
        DocumentReference donationRef = _firestore.collection('donations').doc(donation.donationId);
        DocumentReference notificationRef = _firestore.collection('notifications').doc(notification.id);

        // a. Read listing to verify it's still open
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

        // e. Write: Create notification record inside the same atomic window
        transaction.set(notificationRef, notification.toMap());
      });
    } catch (e) {
      print('Error processing transactional donation: $e');
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
  // --- IN-APP NOTIFICATION LOGIC ---
  // ==========================================

  // Send a standalone notification to the database (fallback/external usage)
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

  // Listen for new notifications for a specific user (NGO)
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          // Convert raw map data to models
          var docs = snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
              .toList();

          // Sort manually in client-side runtime to avoid Firestore index generation errors
          docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return docs;
        });
  }

  // Mark a notification as read when clicked
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      print("Error marking notification as read: $e");
    }
  }
}