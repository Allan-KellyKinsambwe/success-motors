const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

// ────────────────────────────────────────────────
// GARAGE BOOKINGS (your existing function – kept almost unchanged)
// ────────────────────────────────────────────────

exports.onGarageBookingStatusChange = onDocumentUpdated(
  "garage_bookings/{bookingId}",
  async (event) => {
    const before = event.data.before?.data();
    const after = event.data.after.data();
    const bookingId = event.params.bookingId;

    if (!before || before.status === after.status) {
      console.log(`Garage status unchanged or new doc: ${bookingId}`);
      return null;
    }

    const newStatus = after.status;
    const userId = after.userId;

    if (!userId) {
      console.error(`No userId in garage booking ${bookingId}`);
      return null;
    }

    let title = "Garage Booking Update";
    let body = "";

    switch (newStatus.toLowerCase()) {
      case "confirmed":
        body = `Your garage booking for ${after.carMake || ''} ${after.carModel || ''} has been CONFIRMED!`;
        break;
      case "in-progress":
        body = `Your garage service is now IN PROGRESS.`;
        break;
      case "completed":
        body = `Your garage service is COMPLETE! Thank you.`;
        break;
      case "cancelled":
        body = `Your garage booking has been CANCELLED.`;
        break;
      default:
        body = `Garage booking status updated to: ${newStatus.toUpperCase()}`;
    }

    await admin.firestore().collection("notifications").add({
      userId: userId,
      title: title,
      body: body,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      read: false,
      type: "garage_booking",
      bookingId: bookingId,
      status: newStatus,
      // Optional extra context (helps frontend display richer info)
      carMake: after.carMake || null,
      carModel: after.carModel || null,
    });

    console.log(`Garage notification created for user ${userId}`);

    return null;
  }
);

// ────────────────────────────────────────────────
// RENTAL BOOKINGS (new – matches the style exactly)
// ────────────────────────────────────────────────

exports.onRentalBookingStatusChange = onDocumentUpdated(
  "rental_bookings/{bookingId}",
  async (event) => {
    const before = event.data.before?.data();
    const after = event.data.after.data();
    const bookingId = event.params.bookingId;

    if (!before || before.status === after.status) {
      console.log(`Rental status unchanged or new doc: ${bookingId}`);
      return null;
    }

    const newStatus = after.status;
    const userId = after.userId;

    if (!userId) {
      console.error(`No userId in rental booking ${bookingId}`);
      return null;
    }

    let title = "Rental Booking Update";
    let body = "";

    switch (newStatus.toLowerCase()) {
      case "pending":
        body = `Your rental booking is now PENDING (ID: ${bookingId})`;
        break;
      case "confirmed":
        body = `Your rental for ${after.carMake || ''} ${after.carModel || ''} has been CONFIRMED!`;
        break;
      case "ongoing":
        body = `Your rental is now ONGOING. Enjoy your trip!`;
        break;
      case "completed":
        body = `Your rental has been marked as COMPLETED. Thank you!`;
        break;
      case "cancelled":
        body = `Your rental booking has been CANCELLED.`;
        break;
      default:
        body = `Rental booking status updated to: ${newStatus.toUpperCase()}`;
    }

    await admin.firestore().collection("notifications").add({
      userId: userId,
      title: title,
      body: body,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      read: false,
      type: "rental_booking",
      bookingId: bookingId,
      status: newStatus,
      // Consistent optional fields with garage
      carMake: after.carMake || null,
      carModel: after.carModel || null,
    });

    console.log(`Rental notification created for user ${userId}`);

    return null;
  }
);