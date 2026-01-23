// lib/Admin/rental_bookings_admin_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:success_motors/screens/rentals_cars/rental_model.dart';
import 'package:success_motors/screens/product_detail_screen.dart';
import 'package:success_motors/screens/models/product_model.dart';

class RentalBookingsAdminScreen extends StatefulWidget {
  const RentalBookingsAdminScreen({super.key});

  @override
  State<RentalBookingsAdminScreen> createState() =>
      _RentalBookingsAdminScreenState();
}

class _RentalBookingsAdminScreenState extends State<RentalBookingsAdminScreen> {
  // Track which bookings are expanded
  final Map<String, bool> _expandedStates = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text('Rental Bookings (Admin)'),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rental_bookings')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Error loading bookings:\n${snapshot.error}',
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_car_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No rental bookings found',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            );
          }

          final bookings = snapshot.data!.docs.map((doc) {
            return RentalBooking.fromMap(doc.data() as Map<String, dynamic>);
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return _buildBookingCard(booking);
            },
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(RentalBooking booking) {
    final days = booking.totalDays;
    final isActive = DateTime.now().isBefore(booking.dropoffDate);
    final statusColor = _getStatusColor(booking.status);
    final isOngoing = booking.status == 'ongoing';

    // Per-booking expand state
    final bookingId = booking.id;
    _expandedStates.putIfAbsent(bookingId, () => false);
    final isExpanded = _expandedStates[bookingId]!;

    // Minimal Product object for ProductDetailScreen
    final productForDetail = Product(
      id: booking.id, // or replace with real product ID if you have it
      name: '${booking.carMake} ${booking.carModel}',
      price: (booking.dailyRate.toDouble() * days).toInt(),
      image: booking.carImage,
      images: [booking.carImage],
      description: 'Rental booking reference',
      category: 'Rental Car',
      rating: 4.5,
      year: '2023',
      mileage: 'N/A',
      transmission: 'N/A',
      fuelType: 'N/A',
      color: 'N/A',
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ────────────────────────────────────────────────
            // Header row — tappable for product detail or expand
            // ────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Car image → Product Detail
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProductDetailScreen(product: productForDetail),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: booking.carImage.startsWith('http')
                        ? Image.network(
                            booking.carImage,
                            width: 80,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(),
                          )
                        : Image.asset(
                            booking.carImage.isNotEmpty
                                ? booking.carImage
                                : 'assets/images/default_car.png',
                            width: 80,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(),
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Car name & basic info → also opens Product Detail
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ProductDetailScreen(product: productForDetail),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${booking.carMake} ${booking.carModel}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                            decoration: TextDecoration.underline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'UGX ${booking.totalAmount.toStringAsFixed(0)} • $days day${days != 1 ? "s" : ""}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Status: ${booking.status.toUpperCase()}',
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'User: ${booking.userId.substring(0, 8)}...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Expand/collapse arrow (only this part toggles details)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _expandedStates[bookingId] = !_expandedStates[bookingId]!;
                    });
                  },
                  child: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            // ────────────────────────────────────────────────
            // Expanded content (only shown when expanded)
            // ────────────────────────────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Customer full details
                          _buildUserInfoRow(booking.userId),

                          const Divider(height: 20),

                          // Dates & Locations
                          _infoRow(
                            Icons.calendar_today,
                            'Pickup',
                            DateFormat(
                              'dd MMM yyyy',
                            ).format(booking.pickupDate),
                          ),
                          _infoRow(
                            Icons.calendar_today_outlined,
                            'Dropoff',
                            DateFormat(
                              'dd MMM yyyy',
                            ).format(booking.dropoffDate),
                          ),
                          _infoRow(
                            Icons.location_on_outlined,
                            'Pickup Loc',
                            booking.pickupLocation,
                          ),
                          _infoRow(
                            Icons.location_on,
                            'Dropoff Loc',
                            booking.dropoffLocation,
                          ),

                          const Divider(height: 20),

                          // Action buttons
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (booking.status == 'pending')
                                _actionButton(
                                  label: 'Confirm',
                                  icon: Icons.check_circle_outline,
                                  color: Colors.green,
                                  onPressed: () =>
                                      _updateStatus(booking.id, 'confirmed'),
                                ),

                              if (booking.status == 'pending' ||
                                  booking.status == 'confirmed')
                                _actionButton(
                                  label: 'Cancel',
                                  icon: Icons.cancel_outlined,
                                  color: Colors.red,
                                  onPressed: () =>
                                      _updateStatus(booking.id, 'cancelled'),
                                ),

                              if (booking.status == 'confirmed' && isActive)
                                _actionButton(
                                  label: 'Mark Ongoing',
                                  icon: Icons.play_circle_outline,
                                  color: Colors.blue,
                                  onPressed: () =>
                                      _updateStatus(booking.id, 'ongoing'),
                                ),

                              if (booking.status == 'ongoing' && !isActive)
                                _actionButton(
                                  label: 'Complete',
                                  icon: Icons.done_all,
                                  color: Colors.teal,
                                  onPressed: () =>
                                      _updateStatus(booking.id, 'completed'),
                                ),

                              if (isOngoing)
                                _actionButton(
                                  label: 'Track Live',
                                  icon: Icons.location_searching_rounded,
                                  color: Colors.deepOrange,
                                  onPressed: () =>
                                      _showComingSoonDialog(context),
                                ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────
  // Load customer name, email, phone from users collection
  // ────────────────────────────────────────────────
  Widget _buildUserInfoRow(String userId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text(
            'Error loading user info',
            style: TextStyle(color: Colors.red, fontSize: 13),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text(
            'User not found',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final firstName = data['firstName'] ?? '';
        final surname = data['surname'] ?? '';
        final email = data['email'] ?? '—';
        final phone = data['phoneNumber'] ?? '—';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Name: $firstName $surname',
              style: const TextStyle(fontSize: 13),
            ),
            Text('Email: $email', style: const TextStyle(fontSize: 13)),
            Text('Phone: $phone', style: const TextStyle(fontSize: 13)),
          ],
        );
      },
    );
  }

  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Coming Soon'),
        content: const Text(
          'Live vehicle tracking feature is under development.\n\nIt will be available in the next update.\nThank you for your patience!',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: $value',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      onPressed: onPressed,
    );
  }

  Future<void> _updateStatus(String bookingId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('rental_bookings')
          .doc(bookingId)
          .update({
            'status': newStatus,
            if (newStatus == 'cancelled') 'cancelledAt': Timestamp.now(),
            if (newStatus == 'completed') 'completedAt': Timestamp.now(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking updated to $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'ongoing':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _placeholder() {
    return Container(
      width: 80,
      height: 60,
      color: Colors.grey[300],
      child: const Icon(Icons.directions_car, color: Colors.grey, size: 32),
    );
  }
}
