// lib/screens/market_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart'; // Your main screen with bottom navigation

class MarketSelectionScreen extends StatefulWidget {
  const MarketSelectionScreen({super.key});

  @override
  State<MarketSelectionScreen> createState() => _MarketSelectionScreenState();
}

class _MarketSelectionScreenState extends State<MarketSelectionScreen> {
  String? selectedMarket;

  final Map<String, List<String>> markets = {
    "KAMPALA – Major Markets": [
      "Owino Market (St. Balikuddembe)",
      "Nakasero Market",
      "Kikuubo Business Zone",
      "Nakawa Market",
      "Wandegeya Market",
      "Kalerwe Market",
      "Kiswa Market",
      "Nateete Market",
      "Kamwokya Market",
      "Katwe Market",
      "Kiseka Market",
      "Kasubi Market",
      "Bukoto Market",
      "Busega Market",
      "Kanyanya Market",
    ],
    "KAMPALA – Local Markets": [
      "Kansanga Market",
      "Kibuye Market",
      "Namuwongo Market",
      "Kyengera Market",
      "Kireka Market",
      "Banda Market",
      "Luzira Market",
      "Mutungo Market",
      "Komamboga Market",
      "Mulago Market",
      "Mpererwe Market",
      "Kabusu Market",
      "Makerere Market",
      "Kawaala Market",
      "Kasokoso Market",
    ],
    "WAKISO – Major Markets": [
      "Nansana Market",
      "Kasangati Market",
      "Wakiso Market",
      "Bulaga Market",
      "Bulenga Market",
      "Gayaza Market",
      "Entebbe Central Market",
      "Kitooro Market (Entebbe)",
      "Kajjansi Market",
      "Matugga Market",
    ],
    "WAKISO – Local Markets": [
      "Nsangi Market",
      "Kakiri Market",
      "Namayumba Market",
      "Naluvule Market",
      "Masuuliita Market",
      "Busukuma Market",
      "Ssentema Market",
      "Kiteezi Market",
    ],
    "Popular Supermarkets": [
      "Carrefour",
      "Quality Supermarket",
      "Capital Shoppers",
      "Mega Standard Supermarket",
      "Kenjoy Supermarket",
      "Samona Supermarket",
      "Checkers Supermarket",
      "Tuskeys",
      "Super Supermarket (Muyenga)",
      "Freedom City Supermarket",
      "Lugogo Mall Supermarket",
      "Acacia Mall Supermarket",
      "Village Mall Supermarket",
      "Oasis Mall Supermarket",
      "Victoria Supermarket",
    ],
  };

  Future<void> _saveAndEnterApp() async {
    if (selectedMarket == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select your nearest market or supermarket"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser!;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'selectedMarket': selectedMarket,
        'marketSelectedAt': FieldValue.serverTimestamp(),
        'onboardingCompleted': true,
      }, SetOptions(merge: true));

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error saving: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2E7D32)),
          onPressed: () => FirebaseAuth.instance.signOut(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
              child: Column(
                children: const [
                  Text(
                    "Where do you shop?",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Select your nearest market or supermarket so we can show you real-time prices and fresh produce near you.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: markets.length,
                itemBuilder: (context, index) {
                  final category = markets.keys.elementAt(index);
                  final items = markets[category]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 24, 12, 10),
                        child: Text(
                          category,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                      ...items.map(
                        (market) => RadioListTile<String>(
                          title: Text(market),
                          value: market,
                          groupValue: selectedMarket,
                          activeColor: const Color(0xFF2E7D32),
                          dense: true,
                          onChanged: (val) =>
                              setState(() => selectedMarket = val),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveAndEnterApp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    "Continue to FreshBasket",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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
