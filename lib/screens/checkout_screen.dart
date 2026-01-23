// lib/screens/checkout_screen.dart

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:success_motors/screens/models/product_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'home_screen.dart';

class CartItem {
  final Product product;
  final int quantity;
  CartItem({required this.product, this.quantity = 1});
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _altPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  String? defaultPaymentMethod;
  String selectedPaymentMethod = 'cash_on_delivery';
  bool isPlacingOrder = false;
  late ConfettiController _confettiController;

  List<CartItem> cartItems = [];
  int totalItemsPrice = 0;
  final int deliveryFee = 5000;
  int get grandTotal => totalItemsPrice + deliveryFee;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 4),
    );
    _loadCart();
    _loadUserProfileAndPaymentPreference();
  }

  Future<void> _loadUserProfileAndPaymentPreference() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['name'] ?? user.displayName ?? 'Customer';
          _phoneController.text = data['phoneNumber'] ?? '';
          _altPhoneController.text = data['alternativePhone'] ?? '';
          _addressController.text = data['deliveryAddress'] ?? '';

          defaultPaymentMethod = data['defaultPaymentMethod'] as String?;

          if (defaultPaymentMethod != null) {
            selectedPaymentMethod = defaultPaymentMethod!;
          } else {
            selectedPaymentMethod = 'cash_on_delivery';
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? list = prefs.getStringList('cart_items_list');

    if (list != null && list.isNotEmpty) {
      final items = <CartItem>[];
      for (var jsonStr in list) {
        final map = jsonDecode(jsonStr);
        items.add(CartItem(product: Product.fromJson(map)));
      }
      setState(() {
        cartItems = items;
        totalItemsPrice = items.fold(
          0,
          (sum, i) => sum + (i.product.price * i.quantity),
        );
      });
    }
  }

  String _generateOrderNumber() {
    final random = Random();
    return 'FB${DateTime.now().millisecondsSinceEpoch}${random.nextInt(99)}';
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isPlacingOrder = true);

    try {
      final orderNumber = _generateOrderNumber();
      final user = FirebaseAuth.instance.currentUser;

      String paymentDisplayName;
      if (selectedPaymentMethod == 'cash_on_delivery') {
        paymentDisplayName = 'Cash on Delivery';
      } else if (selectedPaymentMethod == 'mobile_money') {
        paymentDisplayName = 'Mobile Money';
      } else {
        paymentDisplayName = 'Card Payment';
      }

      await FirebaseFirestore.instance.collection('orders').add({
        'order_number': orderNumber,
        'user_id': user?.uid,
        'customer': {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'alternative_phone': _altPhoneController.text.trim().isEmpty
              ? null
              : _altPhoneController.text.trim(),
          'address': _addressController.text.trim(),
        },
        'items': cartItems
            .map(
              (item) => {
                'id': item.product.id,
                'name': item.product.name,
                'price': item.product.price,
                'quantity': item.quantity,
                'image': item.product.image,
              },
            )
            .toList(),
        'subtotal': totalItemsPrice,
        'delivery_fee': deliveryFee,
        'total_amount': grandTotal,
        'payment_method': paymentDisplayName,
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cart_items_list');
      await prefs.setInt('cart_count', 0);

      _confettiController.play();

      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(30),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 20),
              const Text(
                'Order Placed Successfully!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Order #: $orderNumber',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Total: UGX $grandTotal',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (_) => false,
                ),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Back to Home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF2E7D32),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Checkout',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
          ),
          body: cartItems.isEmpty
              ? const Center(
                  child: Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Delivery Details'),
                        _card(
                          Column(
                            children: [
                              _textField(
                                _nameController,
                                'Full Name',
                                Icons.person,
                              ),
                              const SizedBox(height: 16),
                              _textField(
                                _phoneController,
                                'Phone Number (WhatsApp)',
                                Icons.phone,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 16),
                              _textField(
                                _altPhoneController,
                                'Alternative Phone (Optional)',
                                Icons.phone_android,
                              ),
                              const SizedBox(height: 16),
                              _textField(
                                _addressController,
                                'Delivery Address',
                                Icons.location_on,
                                maxLines: 3,
                              ),
                              const SizedBox(height: 16),
                              _textField(
                                _notesController,
                                'Order Notes (Optional)',
                                Icons.note_add,
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _sectionTitle('Payment Method'),
                        _card(
                          Column(
                            children: [
                              _paymentTile(
                                value: 'cash_on_delivery',
                                icon: Icons.money,
                                title: 'Cash on Delivery',
                                subtitle: 'Pay when you receive',
                              ),
                              _paymentTile(
                                value: 'mobile_money',
                                icon: Icons.phone_iphone,
                                title: 'Mobile Money',
                                subtitle: 'MTN • Airtel Money',
                              ),
                              _paymentTile(
                                value: 'visa_card',
                                icon: Icons.credit_card,
                                title: 'Credit/Debit Card',
                                subtitle: 'Secure online payment',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _sectionTitle('Order Summary'),
                        _card(
                          Column(
                            children: [
                              ...cartItems.map(
                                (item) => _cartSummaryItem(item),
                              ),
                              const Divider(height: 40),
                              _summaryRow('Subtotal', totalItemsPrice),
                              _summaryRow('Delivery Fee', deliveryFee),
                              const Divider(height: 40),
                              _summaryRow(
                                'Total to Pay',
                                grandTotal,
                                isTotal: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),

          bottomSheet: SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: ElevatedButton(
                onPressed: isPlacingOrder ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 12,
                  shadowColor: Colors.black45,
                ),
                child: isPlacingOrder
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Place Order',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),

        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.orange,
              Colors.red,
              Colors.blue,
              Colors.purple,
            ],
          ),
        ),
      ],
    );
  }

  Widget _cartSummaryItem(CartItem item) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: item.product.image.startsWith('http')
              ? Image.network(
                  item.product.image,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[200],
                      child: const Icon(Icons.error, color: Colors.red),
                    );
                  },
                )
              : Image.asset(
                  item.product.image,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.product.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                'x${item.quantity}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Text(
          'UGX ${item.product.price * item.quantity}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2E7D32),
      ),
    ),
  );

  Widget _card(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4)),
      ],
    ),
    child: child,
  );

  Widget _textField(
    TextEditingController c,
    String hint,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
      ),
      validator: (v) {
        if (maxLines == 1 && (v == null || v.trim().isEmpty)) return 'Required';
        return null;
      },
    );
  }

  Widget _paymentTile({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final bool isSelected = selectedPaymentMethod == value;
    final bool isDefault = defaultPaymentMethod == value;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF2E7D32).withOpacity(0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: selectedPaymentMethod,
        activeColor: const Color(0xFF2E7D32),
        onChanged: (val) => setState(() => selectedPaymentMethod = val!),
        secondary: Stack(
          children: [
            Icon(icon, color: const Color(0xFF2E7D32), size: 32),
            if (isDefault)
              const Positioned(
                right: -4,
                top: -4,
                child: Icon(
                  Icons.check_circle,
                  color: Color(0xFF2E7D32),
                  size: 20,
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            if (isDefault)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Default',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(subtitle),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }

  Widget _summaryRow(String label, int amount, {bool isTotal = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 22 : 18,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            Text(
              'UGX $amount',
              style: TextStyle(
                fontSize: isTotal ? 28 : 20,
                fontWeight: FontWeight.bold,
                color: isTotal ? const Color(0xFF2E7D32) : null,
              ),
            ),
          ],
        ),
      );

  @override
  void dispose() {
    _confettiController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
