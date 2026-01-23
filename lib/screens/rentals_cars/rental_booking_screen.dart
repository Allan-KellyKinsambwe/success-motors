// lib/screens/rental_cars/rental_booking_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:success_motors/constants/constants.dart';
import 'rental_review_screen.dart';
import 'rental_model.dart';

class RentalBookingScreen extends StatefulWidget {
  final Map<String, dynamic> car; // From hub or car list

  const RentalBookingScreen({super.key, required this.car});

  @override
  State<RentalBookingScreen> createState() => _RentalBookingScreenState();
}

class _RentalBookingScreenState extends State<RentalBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _pickupDate;
  DateTime? _dropoffDate;
  final _pickupLocationController = TextEditingController(text: 'Kampala');
  final _dropoffLocationController = TextEditingController(text: 'Kampala');
  bool _withDriver = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _pickupLocationController.dispose();
    _dropoffLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Safely extract car data with defaults
    final dailyRate =
        (widget.car['rentalPricePerDay'] as num?)?.toInt() ?? 300000;
    final make = widget.car['make'] as String? ?? 'Select';
    final model = widget.car['model'] as String? ?? 'Car';
    final carImage =
        widget.car['image'] as String? ?? 'assets/images/default_car.png';
    final carName = '$make $model'.trim();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Book Rental Car'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2E7D32),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Car Summary Card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 80,
                          height: 60,
                          child: carImage.startsWith('http')
                              ? Image.network(
                                  carImage,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _errorPlaceholder(),
                                )
                              : Image.asset(
                                  carImage,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _errorPlaceholder(),
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              carName.isEmpty ? 'Select a Car' : carName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'UGX $dailyRate per day',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Rental Period Section
              const Text(
                'Rental Period',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Pickup Date
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _pickupDate == null
                      ? 'Select Pickup Date'
                      : DateFormat('EEEE, dd MMM yyyy').format(_pickupDate!),
                  style: TextStyle(
                    color: _pickupDate == null
                        ? Colors.grey[700]
                        : Colors.black87,
                  ),
                ),
                trailing: const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF2E7D32),
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => _pickupDate = date);
                    // Auto-adjust dropoff if needed
                    if (_dropoffDate != null && _dropoffDate!.isBefore(date)) {
                      setState(
                        () => _dropoffDate = date.add(const Duration(days: 1)),
                      );
                    }
                  }
                },
              ),
              const Divider(),

              // Dropoff Date
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _dropoffDate == null
                      ? 'Select Dropoff Date'
                      : DateFormat('EEEE, dd MMM yyyy').format(_dropoffDate!),
                  style: TextStyle(
                    color: _dropoffDate == null
                        ? Colors.grey[700]
                        : Colors.black87,
                  ),
                ),
                trailing: const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF2E7D32),
                ),
                onTap: () async {
                  if (_pickupDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select pickup date first'),
                      ),
                    );
                    return;
                  }
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _pickupDate!.add(const Duration(days: 1)),
                    firstDate: _pickupDate!.add(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) setState(() => _dropoffDate = date);
                },
              ),
              const Divider(),
              const SizedBox(height: 24),

              // Locations
              TextFormField(
                controller: _pickupLocationController,
                decoration: InputDecoration(
                  labelText: 'Pickup Location',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _dropoffLocationController,
                decoration: InputDecoration(
                  labelText: 'Dropoff Location',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              // With Driver Switch
              SwitchListTile(
                title: const Text('Rent with Driver'),
                subtitle: const Text('Additional UGX 150,000 per day'),
                secondary: const Icon(Icons.person, color: Color(0xFF2E7D32)),
                value: _withDriver,
                activeColor: const Color(0xFF2E7D32),
                onChanged: (val) => setState(() => _withDriver = val),
              ),
              const SizedBox(height: 32),

              // Total Estimate (only show when dates selected)
              if (_pickupDate != null && _dropoffDate != null) ...[
                Card(
                  color: AppColors.orange.withOpacity(0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          'Estimated Total',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: const Color(0xFF2E7D32)),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'UGX ${dailyRate * totalDays + (_withDriver ? 150000 * totalDays : 0)}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.orange,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$totalDays day${totalDays > 1 ? 's' : ''}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: AppStyles.orangeButtonStyle.copyWith(
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  onPressed:
                      (_pickupDate == null ||
                          _dropoffDate == null ||
                          _isLoading)
                      ? null
                      : () {
                          if (_formKey.currentState?.validate() ?? false) {
                            setState(() => _isLoading = true);

                            final totalDays =
                                _dropoffDate!.difference(_pickupDate!).inDays +
                                1;
                            final total =
                                dailyRate * totalDays +
                                (_withDriver ? 150000 * totalDays : 0);

                            final booking = RentalBooking(
                              id: '',
                              userId: FirebaseAuth.instance.currentUser!.uid,
                              carMake: make,
                              carModel: model,
                              carImage: carImage,
                              dailyRate: dailyRate,
                              pickupDate: _pickupDate!,
                              dropoffDate: _dropoffDate!,
                              pickupLocation: _pickupLocationController.text
                                  .trim(),
                              dropoffLocation: _dropoffLocationController.text
                                  .trim(),
                              withDriver: _withDriver,
                              totalAmount: total,
                              createdAt: Timestamp.now(),
                            );

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    RentalReviewScreen(booking: booking),
                              ),
                            ).then((_) => setState(() => _isLoading = false));
                          }
                        },
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          'Review Booking',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int get totalDays {
    if (_pickupDate == null || _dropoffDate == null) return 0;
    return _dropoffDate!.difference(_pickupDate!).inDays + 1;
  }

  Widget _errorPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
    );
  }
}
