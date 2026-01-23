// lib/screens/profile/delivery_address_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class DeliveryAddressScreen extends StatefulWidget {
  const DeliveryAddressScreen({super.key});

  @override
  State<DeliveryAddressScreen> createState() => _DeliveryAddressScreenState();
}

class _DeliveryAddressScreenState extends State<DeliveryAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _altPhoneController = TextEditingController();

  String? _selectedArea;
  bool _isLoading = false;

  // Updated: Areas across Uganda (organized by region)
  final Map<String, List<String>> areas = {
    "KAMPALA CITY": [
      "Central Division",
      "Kawempe Division",
      "Makindye Division",
      "Nakawa Division",
      "Rubaga Division",
      "Kololo",
      "Nakaseke",
      "Muyenga",
      "Buziga",
      "Munyonho",
      "Ntinda",
      "Kiwatule",
      "Naalya",
      "Kira",
      "Namugongo",
      "Kisaasi",
      "Kyanja",
      "Kulambiro",
      "Bukoto",
      "Kamwokya",
      "Naguru",
      "Lugogo",
      "Bugolobi",
      "Mbuya",
      "Luzira",
      "Kitintale",
      "Kabalagala",
      "Nsambya",
      "Katwe",
      "Kibuli",
      "Wandegeya",
      "Makerere",
      "Mulago",
      "Nateete",
      "Rubaga",
      "Mengo",
      "Lungujja",
      "Busega",
      "Nansana",
      "Kawempe",
      "Bwaise",
    ],
    "WAKISO DISTRICT": [
      "Entebbe",
      "Kajjansi",
      "Kasangati",
      "Gayaza",
      "Matugga",
      "Nansana",
      "Namayumba",
      "Kakiri",
      "Wakiso Town",
      "Bulenga",
      "Nsangi",
      "Kyengera",
      "Katende",
      "Kitemu",
      "Masuliita",
    ],
    "CENTRAL REGION": [
      "Mukono",
      "Seeta",
      "Njeru",
      "Jinja",
      "Iganga",
      "Mbale",
      "Tororo",
      "Soroti",
      "Lira",
      "Gulu",
      "Masaka",
      "Mbarara",
      "Kabale",
      "Fort Portal",
      "Hoima",
      "Kasese",
    ],
    "EASTERN REGION": [
      "Jinja",
      "Iganga",
      "Busia",
      "Tororo",
      "Mbale",
      "Soroti",
      "Kapchorwa",
      "Kumi",
      "Pallisa",
      "Budaka",
      "Butaleja",
      "Sironko",
    ],
    "NORTHERN REGION": [
      "Gulu",
      "Lira",
      "Arua",
      "Nebbi",
      "Kitgum",
      "Pader",
      "Apac",
      "Oyamu",
      "Adjumani",
      "Moyo",
      "Yumbe",
      "Koboko",
    ],
    "WESTERN REGION": [
      "Mbarara",
      "Bushenyi",
      "Ntungamo",
      "Kabale",
      "Kisoro",
      "Rukungiri",
      "Ibanda",
      "Kiruhura",
      "Fort Portal",
      "Kasese",
      "Bundibugyo",
      "Hoima",
      "Masindi",
      "Kagadi",
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
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
          _addressController.text = data['deliveryAddress'] ?? '';
          _phoneController.text = data['phoneNumber'] ?? '';
          _altPhoneController.text = data['alternativePhone'] ?? '';
          _selectedArea = data['selectedArea'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error loading data: $e")));
      }
    }
  }

  Future<void> _saveAllDetails() async {
    if (!_formKey.currentState!.validate() || _selectedArea == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all required fields and select an area"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser!;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'deliveryAddress': _addressController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'alternativePhone': _altPhoneController.text.trim().isEmpty
            ? null
            : _altPhoneController.text.trim(),
        'selectedArea': _selectedArea,
        'addressUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Delivery details saved successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error saving: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    super.dispose();
  }

  void _showAreaSelectionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "Select Your Area in Uganda",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: areas.length,
                  itemBuilder: (context, index) {
                    final region = areas.keys.elementAt(index);
                    final locations = areas[region]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                          child: Text(
                            region,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                        ...locations.map(
                          (area) => RadioListTile<String>(
                            title: Text(area),
                            value: area,
                            groupValue: _selectedArea,
                            activeColor: const Color(0xFF2E7D32),
                            dense: true,
                            onChanged: (val) {
                              setState(() => _selectedArea = val);
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2E7D32)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Delivery Address',
          style: TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Delivery Address
            const Text(
              "Delivery Address",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addressController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "e.g. Plot 12, Tank Hill Road, Muyenga",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF2E7D32),
                    width: 2,
                  ),
                ),
              ),
              validator: (v) =>
                  v!.trim().isEmpty ? "Enter delivery address" : null,
            ),
            const SizedBox(height: 24),

            // Main Phone
            const Text(
              "Phone Number (WhatsApp preferred)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                prefixText: "+256 ",
                hintText: "77 123 4567",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF2E7D32),
                    width: 2,
                  ),
                ),
              ),
              validator: (v) => (v == null || v.length < 9)
                  ? "Enter valid phone number"
                  : null,
            ),
            const SizedBox(height: 16),

            // Alternative Phone
            const Text(
              "Alternative Phone (Optional)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _altPhoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                prefixText: "+256 ",
                hintText: "70 987 6543 (e.g. family member)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF2E7D32),
                    width: 2,
                  ),
                ),
              ),
              validator: (v) => v!.isNotEmpty && v.length < 9
                  ? "Invalid phone or leave empty"
                  : null,
            ),
            const SizedBox(height: 24),

            // Area Selection (replaces Market)
            const Text(
              "Your Area / Location",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: ListTile(
                leading: const Icon(
                  Icons.location_on,
                  color: Color(0xFF2E7D32),
                ),
                title: Text(_selectedArea ?? "No area selected"),
                subtitle: _selectedArea == null
                    ? const Text("Required for delivery")
                    : null,
                trailing: _selectedArea != null
                    ? TextButton(
                        onPressed: _showAreaSelectionDialog,
                        child: const Text("Change"),
                      )
                    : null,
                onTap: _showAreaSelectionDialog,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _showAreaSelectionDialog,
              icon: const Icon(Icons.add_location),
              label: const Text("Select Your Area"),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2E7D32),
                side: const BorderSide(color: Color(0xFF2E7D32)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),

            const SizedBox(height: 40),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveAllDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Save Delivery Details",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
