// lib/screens/rental_cars/rental_booking_details_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:success_motors/sevices/location_service.dart';
import 'rental_model.dart';

class RentalBookingDetailsScreen extends StatefulWidget {
  final RentalBooking booking;

  const RentalBookingDetailsScreen({super.key, required this.booking});

  @override
  State<RentalBookingDetailsScreen> createState() =>
      _RentalBookingDetailsScreenState();
}

class _RentalBookingDetailsScreenState
    extends State<RentalBookingDetailsScreen> {
  bool _isCancelling = false;
  bool _isSharingLocation = false;
  final LocationService _locationService = LocationService();

  Future<void> _cancelBooking() async {
    setState(() => _isCancelling = true);

    try {
      await FirebaseFirestore.instance
          .collection('rental_bookings')
          .doc(widget.booking.id)
          .update({'status': 'cancelled', 'cancelledAt': Timestamp.now()});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Also stop location sharing if active
        _locationService.stopTracking();
        setState(() => _isSharingLocation = false);

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  Future<void> _toggleLocationSharing() async {
    setState(() => _isSharingLocation = !_isSharingLocation);

    if (_isSharingLocation) {
      final success = await _locationService.startTracking(widget.booking.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location sharing started – admin can now track you'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        setState(() => _isSharingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to start sharing – check location permission',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      _locationService.stopTracking();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location sharing stopped'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Make sure to stop tracking when leaving the screen
    if (_isSharingLocation) {
      _locationService.stopTracking();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final days = booking.totalDays;
    final isActive = DateTime.now().isBefore(booking.dropoffDate);
    final canCancel = booking.status == 'pending';
    final canShareLocation = booking.status == 'ongoing';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Rental Details'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2E7D32),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Car Image & Basic Info
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child:
                  booking.carImage.startsWith('http') ||
                      booking.carImage.startsWith('https')
                  ? Image.network(
                      booking.carImage,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderImage(),
                    )
                  : Image.asset(
                      booking.carImage.isNotEmpty
                          ? booking.carImage
                          : 'assets/images/default_car.png',
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderImage(),
                    ),
            ),
            const SizedBox(height: 24),

            // Status Chip
            Chip(
              label: Text(
                booking.status.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: isActive ? Colors.green[100] : Colors.grey[300],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            const SizedBox(height: 16),

            Text(
              '${booking.carMake} ${booking.carModel}',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'UGX ${booking.totalAmount} • $days day${days > 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 18, color: Color(0xFF2E7D32)),
            ),
            const SizedBox(height: 32),

            // Details
            _detailRow(
              'Pickup Date',
              DateFormat('EEEE, dd MMM yyyy').format(booking.pickupDate),
            ),
            _detailRow(
              'Dropoff Date',
              DateFormat('EEEE, dd MMM yyyy').format(booking.dropoffDate),
            ),
            _detailRow('Pickup Location', booking.pickupLocation),
            _detailRow('Dropoff Location', booking.dropoffLocation),
            _detailRow(
              'With Driver',
              booking.withDriver ? 'Yes' : 'No (Self-drive)',
            ),
            _detailRow('Daily Rate', 'UGX ${booking.dailyRate}'),
            _detailRow('Total Amount', 'UGX ${booking.totalAmount}'),
            const SizedBox(height: 32),

            // Booking Information
            const Text(
              'Booking Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _detailRow('Status', booking.status.toUpperCase()),
            _detailRow(
              'Created',
              DateFormat(
                'dd MMM yyyy • hh:mm a',
              ).format(booking.createdAt.toDate()),
            ),
            const SizedBox(height: 40),

            // Location Sharing Control – only when ongoing
            if (canShareLocation) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isSharingLocation
                      ? Colors.green[50]
                      : Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isSharingLocation ? Colors.green : Colors.orange,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _isSharingLocation
                          ? 'Location is being shared with admin'
                          : 'Share your location during the rental?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isSharingLocation
                            ? Colors.green[900]
                            : Colors.orange[900],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: Icon(
                        _isSharingLocation
                            ? Icons.location_disabled
                            : Icons.my_location,
                        color: Colors.white,
                      ),
                      label: Text(
                        _isSharingLocation
                            ? 'Stop Sharing'
                            : 'Start Sharing Location',
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSharingLocation
                            ? Colors.red[700]
                            : const Color(0xFF2E7D32),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _toggleLocationSharing,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Cancel Button – only when pending
            if (canCancel)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _isCancelling
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.cancel_outlined),
                  label: Text(
                    _isCancelling ? 'Cancelling...' : 'Cancel Booking',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[100],
                    foregroundColor: Colors.red[900],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isCancelling ? null : _cancelBooking,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.directions_car, size: 60, color: Colors.grey),
      ),
    );
  }
}
