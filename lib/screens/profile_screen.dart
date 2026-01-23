// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:success_motors/Admin/admin_panel_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:success_motors/auth/login_screen.dart';
import 'package:success_motors/screens/garage_cars/garage_hub_screen.dart';
import 'package:success_motors/screens/loan_cars/loan_car_hub_screen.dart';
import 'package:success_motors/screens/rentals_cars/rentals_car_hub_screen.dart';
import 'dart:io';
import 'package:success_motors/screens/profile/personal_info_screen.dart';
import 'package:success_motors/screens/profile/delivery_address_screen.dart';
import 'package:success_motors/screens/profile/payment_methods_screen.dart';
import 'package:success_motors/screens/profile/order_history_screen.dart';
import 'package:success_motors/screens/profile/help_support_screen.dart';
import 'package:success_motors/screens/profile/invite_friend_screen.dart';
import 'package:success_motors/screens/profile/inbox_screen.dart';
import 'package:success_motors/screens/profile/change_password_screen.dart';
import 'package:success_motors/screens/profile/privacy_policy_screen.dart';
import 'package:success_motors/screens/profile/help_feedback_screen.dart';
import 'package:success_motors/screens/profile/live_chat_screen.dart';
//import 'package:success_motors/screens/admin/admin_panel_screen.dart'; // ← ADMIN PANEL IMPORT ADDED

import 'home_screen.dart';
import 'wishlist_screen.dart';
import 'category_screen.dart';
import 'cart_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  String _photoUrl = '';
  bool _isUploading = false;
  int _adminTapCount = 0;

  // Track which sections are expanded
  final Map<String, bool> _expandedSections = {
    'Account': true,
    'Support': false,
    'More': false,
    'More Services': false, // new section
  };

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Profile',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
        ),
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUser!.uid)
              .snapshots(),
          builder: (context, snapshot) {
            String displayName = 'User';
            String displayEmail = _currentUser!.email ?? 'No email';
            String photoUrl = '';
            bool isAdmin = false;

            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data()!;
              displayName = data['name']?.toString().trim() ?? 'User';
              displayEmail = data['email']?.toString().trim() ?? displayEmail;
              photoUrl = data['photoUrl']?.toString() ?? '';
              isAdmin = data['isAdmin'] == true;
            }

            return _buildProfileBody(
              name: displayName,
              email: displayEmail,
              photoUrl: photoUrl,
              isAdmin: isAdmin,
            );
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF2E7D32),
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          currentIndex: 4,
          onTap: (i) => _navigateTo(context, i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              label: 'Wishlist',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.category_outlined),
              label: 'Categories',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              label: 'Cart',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileBody({
    required String name,
    required String email,
    required String photoUrl,
    required bool isAdmin,
  }) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Profile Header
        Center(
          child: GestureDetector(
            onTap: () {
              if (isAdmin) {
                _adminTapCount++;
                if (_adminTapCount >= 7) {
                  _adminTapCount = 0;
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AdminPanelScreen()),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Welcome back, Boss!'),
                      backgroundColor: Color(0xFF2E7D32),
                    ),
                  );
                }
              }
            },
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 70,
                  backgroundColor: const Color(0xFF2E7D32),
                  backgroundImage: photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl.isEmpty
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 60,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                if (_isUploading)
                  const Positioned.fill(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 4,
                    ),
                  )
                else
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickAndUploadImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2E7D32),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                if (isAdmin)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          email,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
        const SizedBox(height: 30),

        // === ACCOUNT SECTION ===
        _sectionTitle('Account', 'Account'),
        if (_expandedSections['Account']!)
          Column(
            children: [
              _buildTile(
                Icons.person_outline,
                'Personal Info',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PersonalInfoScreen()),
                ),
              ),
              _buildTile(
                Icons.location_on_outlined,
                'Delivery Address',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DeliveryAddressScreen(),
                  ),
                ),
              ),
              _buildTile(
                Icons.payment,
                'Payment Methods',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PaymentMethodsScreen(),
                  ),
                ),
              ),
              _buildTile(
                Icons.history,
                'Order History',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                ),
              ),
              _buildTile(
                Icons.lock_outline,
                'Change Password',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                ),
              ),
            ],
          ),

        // === SUPPORT SECTION ===
        _sectionTitle('Support', 'Support'),
        if (_expandedSections['Support']!)
          Column(
            children: [
              _buildTile(
                Icons.mail_outline,
                'Inbox',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InboxScreen()),
                ),
              ),
              _buildTile(
                Icons.chat_bubble_outline,
                'Live Chat',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LiveChatScreen()),
                ),
              ),
              _buildTile(
                Icons.feedback_outlined,
                'Help & Feedback',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpFeedbackScreen()),
                ),
              ),
            ],
          ),

        // === MORE SECTION ===
        _sectionTitle('More', 'More'),
        if (_expandedSections['More']!)
          Column(
            children: [
              _buildTile(
                Icons.group_add,
                'Invite Friends',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => InviteFriendScreen()),
                ),
              ),
              _buildTile(
                Icons.policy,
                'Privacy Policy',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyScreen(),
                  ),
                ),
              ),
            ],
          ),

        // === NEW: MORE SERVICES SECTION ===
        _sectionTitle('More Services', 'More Services'),
        if (_expandedSections['More Services']!)
          Column(
            children: [
              _buildTile(Icons.build_circle_outlined, 'Online Garage', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GarageHubScreen()),
                );
              }),
              _buildTile(Icons.directions_car_outlined, 'Rental Cars', () {
                // TODO: Replace with your actual Rental Cars screen/navigation
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RentalsCarHubScreen(),
                  ),
                );
              }),
              _buildTile(Icons.money_outlined, 'Loan Cars', () {
                // TODO: Replace with your actual Loan Cars screen/navigation
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoanCarHubScreen()),
                );
              }),
            ],
          ),

        const SizedBox(height: 30),

        // Logout (always visible)
        _buildTile(
          Icons.logout,
          'Logout',
          () => _logout(context),
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, String sectionKey) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedSections[sectionKey] =
              !(_expandedSections[sectionKey] ?? false);
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 12, bottom: 8, top: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
            Icon(
              _expandedSections[sectionKey] == true
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: const Color(0xFF2E7D32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (color ?? const Color(0xFF2E7D32)).withOpacity(0.1),
          child: Icon(icon, color: color ?? const Color(0xFF2E7D32), size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: color ?? Colors.black87,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: onTap,
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (pickedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child(_currentUser!.uid);

      await ref.putFile(File(pickedFile.path));
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .set({'photoUrl': url}, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload photo: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _navigateTo(BuildContext context, int index) {
    if (index == 4) return;
    final List<Widget> routes = [
      const HomeScreen(),
      const WishlistScreen(),
      const CategoryScreen(),
      const CartScreen(),
      const ProfileScreen(),
    ];
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => routes[index]),
    );
  }
}
