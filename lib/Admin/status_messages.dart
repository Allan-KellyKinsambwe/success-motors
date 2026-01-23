// lib/Admin/status_messages.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class OrderStatusService {
  static Future<void> sendOrderStatusMessage({
    required String orderId,
    required String userId,
    required String newStatus,
    required String productName,
    required riderName,
  }) async {
    try {
      String title;
      String body;

      switch (newStatus.toLowerCase()) {
        case 'confirmed':
          title = 'Order Confirmed!';
          body = 'Your order #$orderId for $productName has been confirmed.';
          break;
        case 'preparing':
          title = 'Preparing Your Order';
          body = 'We are preparing your order #$orderId.';
          break;
        case 'out_for_delivery':
          title = 'On Its Way!';
          body = 'Your order #$orderId is out for delivery!';
          break;
        case 'delivered':
          title = 'Delivered!';
          body = 'Your order #$orderId has been delivered. Enjoy!';
          break;
        default:
          title = 'Order Update';
          body = 'Your order #$orderId status: $newStatus';
      }

      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'orderId': orderId,
        'title': title,
        'body': body,
        'type': 'order_status',
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to send notification: $e');
    }
  }
}
