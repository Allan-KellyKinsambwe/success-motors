// lib/screens/profile/personal_info_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  String firstName = '';
  String surname = '';
  String fullName = 'No name set';
  String currentEmail = '';
  String currentPhone = 'Not set';
  String currentPhotoUrl = '';

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;

        final String? fn = data['firstName']?.toString().trim();
        final String? sn = data['surname']?.toString().trim();

        setState(() {
          firstName = fn ?? '';
          surname = sn ?? '';

          // Build full name only if both parts exist
          if (firstName.isNotEmpty && surname.isNotEmpty) {
            fullName = '$firstName $surname';
          } else if (firstName.isNotEmpty) {
            fullName = firstName;
          } else if (surname.isNotEmpty) {
            fullName = surname;
          } else {
            fullName = 'No name set';
          }

          currentEmail =
              data['email']?.toString().trim() ?? user.email ?? 'No email';

          final phone = data['phoneNumber']?.toString().trim();
          currentPhone = (phone == null || phone.isEmpty) ? 'Not set' : phone;

          currentPhotoUrl = data['photoUrl']?.toString().trim() ?? '';

          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error loading profile: $e")));
        setState(() => isLoading = false);
      }
    }
  }

  void _showEditDialog() {
    final firstNameCtrl = TextEditingController(text: firstName);
    final surnameCtrl = TextEditingController(text: surname);
    final phoneCtrl = TextEditingController(
      text: currentPhone == 'Not set' ? '' : currentPhone,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Edit Personal Info',
          style: TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: surnameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Surname',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Email field - readonly
              TextField(
                controller: TextEditingController(text: currentEmail),
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Email (cannot be changed)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Phone Number (WhatsApp preferred)',
                  prefixText: '+256 ',
                  hintText: '77 123 4567',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: isSaving
                ? null
                : () async {
                    final newFirstName = firstNameCtrl.text.trim();
                    final newSurname = surnameCtrl.text.trim();
                    final newPhoneRaw = phoneCtrl.text.trim();

                    if (newFirstName.isEmpty || newSurname.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('First name and surname are required'),
                        ),
                      );
                      return;
                    }

                    if (newPhoneRaw.isNotEmpty && newPhoneRaw.length < 9) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Phone number must be 9 digits'),
                        ),
                      );
                      return;
                    }

                    setState(() => isSaving = true);

                    try {
                      final userId = FirebaseAuth.instance.currentUser!.uid;

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .set({
                            'firstName': newFirstName,
                            'surname': newSurname,
                            if (newPhoneRaw.isNotEmpty)
                              'phoneNumber': newPhoneRaw,
                            if (newPhoneRaw.isEmpty) 'phoneNumber': null,
                          }, SetOptions(merge: true));

                      if (mounted) {
                        Navigator.pop(context);
                        setState(() {
                          firstName = newFirstName;
                          surname = newSurname;
                          fullName = '$newFirstName $newSurname';
                          currentPhone = newPhoneRaw.isEmpty
                              ? 'Not set'
                              : newPhoneRaw;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile updated successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error updating profile: $e')),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => isSaving = false);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
            child: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2E7D32)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Personal Info',
          style: TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: const Color(0xFF2E7D32),
                        backgroundImage: currentPhotoUrl.isNotEmpty
                            ? NetworkImage(currentPhotoUrl)
                            : null,
                        child: currentPhotoUrl.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
                _buildInfoCard('Full Name', fullName),
                const SizedBox(height: 16),
                _buildInfoCard('Email', currentEmail),
                const SizedBox(height: 16),
                _buildInfoCard(
                  'Phone Number',
                  currentPhone == 'Not set' ? 'Not set' : '+256 $currentPhone',
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _showEditDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }
}
