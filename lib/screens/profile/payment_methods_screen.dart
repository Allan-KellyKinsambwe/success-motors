// lib/screens/profile/payment_methods_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  String?
  defaultPaymentMethod; // 'mobile_money', 'visa_card', 'cash_on_delivery'
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentPreferences();
  }

  Future<void> _loadPaymentPreferences() async {
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
        setState(() {
          defaultPaymentMethod = data['defaultPaymentMethod'] as String?;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading payment methods: $e')),
        );
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _setDefaultPaymentMethod(String method) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'defaultPaymentMethod': method,
      }, SetOptions(merge: true));

      setState(() {
        defaultPaymentMethod = method;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Default payment method updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    }
  }

  Widget _paymentCard({
    required String methodName,
    required String detail,
    required String
    methodKey, // 'mobile_money', 'visa_card', 'cash_on_delivery'
    required IconData icon,
  }) {
    final bool isDefault = defaultPaymentMethod == methodKey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF2E7D32),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        title: Text(
          methodName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(detail),
        trailing: isDefault
            ? const Text(
                'Default',
                style: TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              )
            : OutlinedButton(
                onPressed: () => _setDefaultPaymentMethod(methodKey),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32),
                  side: const BorderSide(color: Color(0xFF2E7D32)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Set Default'),
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
          'Payment Methods',
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
                // Mobile Money
                _paymentCard(
                  methodName: 'Mobile Money',
                  detail: 'MTN MoMo • Ends with xxxx',
                  methodKey: 'mobile_money',
                  icon: Icons.phone_android,
                ),
                const SizedBox(height: 8),

                // Visa Card
                _paymentCard(
                  methodName: 'Visa Card',
                  detail: '•••• •••• •••• 1234',
                  methodKey: 'visa_card',
                  icon: Icons.credit_card,
                ),
                const SizedBox(height: 8),

                // Cash on Delivery (Added as requested)
                _paymentCard(
                  methodName: 'Cash on Delivery',
                  detail: 'Pay with cash when your order arrives',
                  methodKey: 'cash_on_delivery',
                  icon: Icons.payments_outlined,
                ),
                const SizedBox(height: 40),

                // Add Payment Method Button (kept for future expansion)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Future: Navigate to add card/mobile money screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon!')),
                      );
                    },
                    icon: const Icon(Icons.add_card),
                    label: const Text(
                      'Add Payment Method',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
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
