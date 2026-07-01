const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendDonationNotification = functions.firestore
  .document("donations/{donationId}")
  .onCreate(async (snap, context) => {
    const donation = snap.data();
    
    // Safety check: ensure we have an ngoId to send to
    if (!donation.ngoId) return null;

    try {
      // 1. Get NGO's profile from the 'users' collection
      const ngoDoc = await admin.firestore()
        .collection("users")
        .doc(donation.ngoId)
        .get();

      const fcmToken = ngoDoc.data()?.fcmToken;
      
      // If the NGO hasn't logged in on a phone yet, they won't have a token
      if (!fcmToken) {
        console.log("No FCM token found for NGO:", donation.ngoId);
        return null;
      }

      // 2. Format the donated item details
      const itemName = donation.productName || donation.foodType || 'items';
      const quantity = `${donation.quantity || ''} ${donation.unit || ''}`.trim();

      // 3. Construct the push notification (HIGH PRIORITY FORMAT)
      const message = {
        token: fcmToken,
        notification: {
          title: "New Donation Request! 🎉",
          body: `A donor has offered ${quantity} of ${itemName}. Open the app to view details.`,
        },
        // 👇 Tells Android to pop it up at the top of the screen
        android: {
          priority: "high",
          notification: {
            sound: "default",
            channelId: "high_importance_channel" 
          }
        },
        // 👇 Tells iOS (iPhones) to play a sound and show banner
        apns: {
          payload: {
            aps: {
              sound: "default",
              contentAvailable: true,
            }
          }
        },
        data: {
          donationId: context.params.donationId,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
      };

      // 4. Send it!
      await admin.messaging().send(message);
      console.log("Donation notification sent successfully to", donation.ngoId);
      
    } catch (error) {
      console.error("Error sending notification:", error);
    }
  });