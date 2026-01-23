// lib/screens/loan_cars/loan_application_screen.dart
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:success_motors/constants/constants.dart';
import 'loan_review_screen.dart';
import 'loan_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class LoanApplicationScreen extends StatefulWidget {
  const LoanApplicationScreen({super.key});

  @override
  State<LoanApplicationScreen> createState() => _LoanApplicationScreenState();
}

class _LoanApplicationScreenState extends State<LoanApplicationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _firstNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _carMakeController = TextEditingController();
  final _carModelController = TextEditingController();
  final _carYearController = TextEditingController();
  final _carMarketValueController = TextEditingController();
  final _loanAmountController = TextEditingController();
  final _loanTermController = TextEditingController();
  final _monthlyIncomeController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _addressController = TextEditingController();

  String? _phoneNumber;
  String _employmentStatus = 'Employed';
  String _loanPurpose = 'Purchase';
  bool _isLoading = false;

  // File uploads
  File? _nationalIdFront;
  File? _nationalIdBack;
  File? _proofOfIncome;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        _firstNameController.text = data['firstName'] ?? '';
        _surnameController.text = data['surname'] ?? '';
        _emailController.text = user.email ?? '';
        _phoneNumber = data['phoneNumber'] ?? '';
      }
    }
  }

  Future<void> _pickImage(String type) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null && mounted) {
      setState(() {
        if (type == 'national_front') _nationalIdFront = File(picked.path);
        if (type == 'national_back') _nationalIdBack = File(picked.path);
        if (type == 'income_proof') _proofOfIncome = File(picked.path);
      });
    }
  }

  Future<String?> _uploadFile(File file, String fileName, String uid) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(
        'loan_docs/$uid/$fileName',
      );
      print('Uploading to: ${ref.fullPath}');

      final task = ref.putFile(file);

      // Optional: Listen for progress/errors
      task.snapshotEvents
          .listen((TaskSnapshot snapshot) {
            print(
              '$fileName - ${snapshot.state}: ${snapshot.bytesTransferred}/${snapshot.totalBytes} bytes',
            );
          })
          .onError((e) {
            print('$fileName snapshot error: $e');
          });

      await task;
      final url = await ref.getDownloadURL();
      print('$fileName uploaded successfully: $url');
      return url;
    } catch (e) {
      print('Upload failed for $fileName: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload $fileName: $e')),
        );
      }
      return null; // Continue with other uploads even if one fails
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Refresh auth state (helps with token expiry issues)
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('User not logged in. Please sign in again.');
      }

      String? idFrontUrl;
      String? idBackUrl;
      String? incomeUrl;

      // Upload documents one by one with individual error handling
      if (_nationalIdFront != null) {
        idFrontUrl = await _uploadFile(
          _nationalIdFront!,
          'id_front.jpg',
          user.uid,
        );
      }

      if (_nationalIdBack != null) {
        idBackUrl = await _uploadFile(
          _nationalIdBack!,
          'id_back.jpg',
          user.uid,
        );
      }

      if (_proofOfIncome != null) {
        incomeUrl = await _uploadFile(
          _proofOfIncome!,
          'income_proof.jpg',
          user.uid,
        );
      }

      final application = LoanApplication(
        id: '',
        userId: user.uid,
        firstName: _firstNameController.text.trim(),
        surname: _surnameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneNumber ?? '',
        nationalId: _nationalIdController.text.trim(),
        address: _addressController.text.trim(),
        employmentStatus: _employmentStatus,
        monthlyIncome:
            double.tryParse(
              _monthlyIncomeController.text.trim().replaceAll(',', ''),
            ) ??
            0,
        carMake: _carMakeController.text.trim(),
        carModel: _carModelController.text.trim(),
        carYear: int.tryParse(_carYearController.text.trim()) ?? 0,
        carMarketValue:
            double.tryParse(
              _carMarketValueController.text.trim().replaceAll(',', ''),
            ) ??
            0,
        loanAmountRequested:
            double.tryParse(
              _loanAmountController.text.trim().replaceAll(',', ''),
            ) ??
            0,
        loanTermMonths: int.tryParse(_loanTermController.text.trim()) ?? 0,
        interestRateAnnual:
            0.18, // 18% typical in Uganda – can be dynamic later
        loanPurpose: _loanPurpose,
        createdAt: Timestamp.now(),
        nationalIdFrontUrl: idFrontUrl,
        nationalIdBackUrl: idBackUrl,
        proofOfIncomeUrl: incomeUrl,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LoanReviewScreen(application: application),
        ),
      );
    } catch (e) {
      print('Submit application error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Apply for Car Loan'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Personal Information
              const Text(
                'Personal Information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _surnameController,
                decoration: const InputDecoration(
                  labelText: 'Surname',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              IntlPhoneField(
                initialValue: _phoneNumber,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                initialCountryCode: 'UG',
                onChanged: (phone) => _phoneNumber = phone.completeNumber,
                validator: (v) =>
                    v == null || v.number.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _employmentStatus,
                decoration: const InputDecoration(
                  labelText: 'Employment Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Employed', child: Text('Employed')),
                  DropdownMenuItem(
                    value: 'Self-Employed',
                    child: Text('Self-Employed'),
                  ),
                  DropdownMenuItem(
                    value: 'Business Owner',
                    child: Text('Business Owner'),
                  ),
                  DropdownMenuItem(
                    value: 'Unemployed',
                    child: Text('Unemployed'),
                  ),
                ],
                onChanged: (v) => setState(() => _employmentStatus = v!),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _monthlyIncomeController,
                decoration: const InputDecoration(
                  labelText: 'Monthly Income (UGX)',
                  border: OutlineInputBorder(),
                  prefixText: 'UGX ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nationalIdController,
                decoration: const InputDecoration(
                  labelText: 'National ID Number',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Residential Address',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),

              // Document Uploads
              const Text(
                'Required Documents',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              _buildUploadTile(
                'National ID (Front)',
                _nationalIdFront,
                () => _pickImage('national_front'),
              ),
              _buildUploadTile(
                'National ID (Back)',
                _nationalIdBack,
                () => _pickImage('national_back'),
              ),
              _buildUploadTile(
                'Proof of Income (Salary Slip / Bank Statement)',
                _proofOfIncome,
                () => _pickImage('income_proof'),
              ),
              const SizedBox(height: 32),

              // Car & Loan Details
              const Text(
                'Car & Loan Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _carMakeController,
                decoration: const InputDecoration(
                  labelText: 'Car Make',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _carModelController,
                decoration: const InputDecoration(
                  labelText: 'Car Model',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _carYearController,
                decoration: const InputDecoration(
                  labelText: 'Car Year',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _carMarketValueController,
                decoration: const InputDecoration(
                  labelText: 'Estimated Car Value (UGX)',
                  border: OutlineInputBorder(),
                  prefixText: 'UGX ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _loanPurpose,
                decoration: const InputDecoration(
                  labelText: 'Loan Purpose',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Purchase', child: Text('Purchase')),
                  DropdownMenuItem(
                    value: 'Refinance',
                    child: Text('Refinance'),
                  ),
                  DropdownMenuItem(value: 'Top-up', child: Text('Top-up')),
                ],
                onChanged: (v) => setState(() => _loanPurpose = v!),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _loanAmountController,
                decoration: const InputDecoration(
                  labelText: 'Loan Amount Requested (UGX)',
                  border: OutlineInputBorder(),
                  prefixText: 'UGX ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _loanTermController,
                decoration: const InputDecoration(
                  labelText: 'Loan Term (Months)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: AppStyles.orangeButtonStyle,
                  onPressed: _isLoading ? null : _submitApplication,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Review & Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadTile(String label, File? file, VoidCallback onTap) {
    return ListTile(
      leading: Icon(
        Icons.upload_file,
        color: file != null ? Colors.green : Colors.grey,
      ),
      title: Text(label),
      subtitle: file != null
          ? const Text('Uploaded', style: TextStyle(color: Colors.green))
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _carMakeController.dispose();
    _carModelController.dispose();
    _carYearController.dispose();
    _carMarketValueController.dispose();
    _loanAmountController.dispose();
    _loanTermController.dispose();
    _monthlyIncomeController.dispose();
    _nationalIdController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
