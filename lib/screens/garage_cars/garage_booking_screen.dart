// lib/screens/garage_cars/garage_booking_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:success_motors/constants/constants.dart';
import 'garage_review_screen.dart';
import 'garage_model.dart';

class GarageBookingScreen extends StatefulWidget {
  const GarageBookingScreen({super.key});

  @override
  State<GarageBookingScreen> createState() => _GarageBookingScreenState();
}

class _GarageBookingScreenState extends State<GarageBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _carMakeController = TextEditingController();
  final _carModelController = TextEditingController();
  final _carYearController = TextEditingController();
  final _regNumberController = TextEditingController();
  final _notesController = TextEditingController();
  final _otherServiceController = TextEditingController();

  DateTime? _selectedDate;
  String _selectedTime = 'Morning (8am - 12pm)';
  String _serviceType = 'Oil Change';
  String? _phoneNumber;
  bool _isLoading = false;

  final List<String> services = [
    'Oil Change',
    'Brake Service',
    'Tire Rotation',
    'General Check-up',
    'Engine Diagnostic',
    'Battery Replacement',
    'AC Service',
    'Suspension Repair',
    'Other',
  ];

  final List<String> timeSlots = [
    'Morning (8am - 12pm)',
    'Afternoon (1pm - 5pm)',
    'Any Time',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        _fullNameController.text =
            '${data['firstName'] ?? ''} ${data['surname'] ?? ''}'.trim();
        _phoneNumber = data['phoneNumber'] ?? '';
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields and select a date'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final booking = GarageBooking(
      id: '',
      userId: FirebaseAuth.instance.currentUser!.uid,
      fullName: _fullNameController.text.trim(),
      phoneNumber: _phoneNumber ?? '',
      carMake: _carMakeController.text.trim(),
      carModel: _carModelController.text.trim(),
      carYear: _carYearController.text.trim(),
      registrationNumber: _regNumberController.text.trim(),
      serviceType: _serviceType,
      otherService: _serviceType == 'Other'
          ? _otherServiceController.text.trim()
          : null,
      preferredDate: _selectedDate!,
      preferredTime: _selectedTime,
      additionalNotes: _notesController.text.trim(),
      createdAt: Timestamp.now(),
    );

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GarageReviewScreen(booking: booking)),
    );

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Book Garage Service')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Details',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              IntlPhoneField(
                initialCountryCode: 'UG',
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                onChanged: (phone) => _phoneNumber = phone.completeNumber,
                validator: (p) =>
                    p?.completeNumber.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              const Text(
                'Vehicle Information',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _carMakeController,
                      decoration: const InputDecoration(
                        labelText: 'Make (e.g. Toyota)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _carModelController,
                      decoration: const InputDecoration(
                        labelText: 'Model',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _carYearController,
                      decoration: const InputDecoration(
                        labelText: 'Year',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _regNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Reg Number',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'Service Required',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _serviceType,
                decoration: const InputDecoration(
                  labelText: 'Select Service',
                  border: OutlineInputBorder(),
                ),
                items: services
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _serviceType = v!),
              ),
              const SizedBox(height: 16),

              if (_serviceType == 'Other')
                TextFormField(
                  controller: _otherServiceController,
                  decoration: const InputDecoration(
                    labelText: 'Describe Service',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              const SizedBox(height: 24),

              const Text(
                'Preferred Date & Time',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              ListTile(
                title: Text(
                  _selectedDate == null
                      ? 'Select Date'
                      : DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate!),
                ),
                trailing: const Icon(Icons.calendar_today),
                tileColor: Colors.grey[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.grey),
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedTime,
                decoration: const InputDecoration(
                  labelText: 'Preferred Time',
                  border: OutlineInputBorder(),
                ),
                items: timeSlots
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedTime = v!),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: AppStyles.orangeButtonStyle,
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Review Booking',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _carMakeController.dispose();
    _carModelController.dispose();
    _carYearController.dispose();
    _regNumberController.dispose();
    _notesController.dispose();
    _otherServiceController.dispose();
    super.dispose();
  }
}
