# success_motors

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.



index.js bBEFORE ADDING AFRICAN TALKING
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

exports.onGarageBookingStatusChange = onDocumentUpdated(
  "garage_bookings/{bookingId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    const bookingId = event.params.bookingId;

    // Only proceed if status changed
    if (before.status === after.status) {
      console.log(`Status unchanged for booking ${bookingId}`);
      return null;
    }

    const newStatus = after.status;
    const userId = after.userId;

    if (!userId) {
      console.error("No userId in booking document");
      return null;
    }

    // Prepare nice notification message
    let title = "Garage Booking Update";
    let body = "";

    switch (newStatus.toLowerCase()) {
      case "confirmed":
        body = `Your booking for ${after.carMake} ${after.carModel} has been CONFIRMED!`;
        break;
      case "in-progress":
        body = `Your service is now IN PROGRESS.`;
        break;
      case "completed":
        body = `Your garage service is COMPLETE! Thank you.`;
        break;
      case "cancelled":
        body = `Your booking has been CANCELLED.`;
        break;
      default:
        body = `Status updated to: ${newStatus.toUpperCase()}`;
    }

    // Create notification in Firestore
    await admin.firestore().collection("notifications").add({
      userId: userId,
      title: title,
      body: body,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      read: false,
      type: "garage_booking",
      bookingId: bookingId,
      status: newStatus,
    });

    console.log(`Notification created for user ${userId}`);

    // Optional: Send push notification (needs FCM token stored)
    // Uncomment and adjust if you already save fcmToken in users collection
    /*
    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    const fcmToken = userDoc.data()?.fcmToken;

    if (fcmToken) {
      await admin.messaging().send({
        token: fcmToken,
        notification: { title, body },
        data: { bookingId, type: "garage_booking" },
      });
    }
    */

    return null;
  }
);

