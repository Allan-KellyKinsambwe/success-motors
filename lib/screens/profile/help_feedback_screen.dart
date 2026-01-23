// lib/screens/profile/help_feedback_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'live_chat_screen.dart';

class HelpFeedbackScreen extends StatefulWidget {
  const HelpFeedbackScreen({super.key});

  @override
  State<HelpFeedbackScreen> createState() => _HelpFeedbackScreenState();
}

class _HelpFeedbackScreenState extends State<HelpFeedbackScreen> {
  final _feedbackController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  final List<Map<String, String>> faqs = [
    {
      "question": "How do I place an order?",
      "answer":
          "Browse products, add to cart, proceed to checkout, and confirm your delivery.",
    },
    {
      "question": "What is the minimum order amount?",
      "answer":
          "Minimum order is 10,000 UGX. Delivery is free for orders above 50,000 UGX.",
    },
    {
      "question": "How do I track my order?",
      "answer": "Go to Order History in profile to track real-time status.",
    },
    {
      "question": "Is my payment safe?",
      "answer":
          "Yes! We use secure encryption and are compliant with Uganda's data protection laws.",
    },
    {
      "question": "How do credits work?",
      "answer": "Earn credits on referrals and use them on future orders.",
    },
  ];

  Future<void> _sendEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@freshbasket.com',
      queryParameters: {
        'subject': 'Help Request - FreshBasket App',
        'body':
            'Hi Support,\n\nI need help with:\n\n[Describe your issue]\n\nUser ID: ${FirebaseAuth.instance.currentUser?.uid}\nThank you!',
      },
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      _showSnackBar("Could not open email app");
    }
  }

  Future<void> _makeCall() async {
    final Uri telUri = Uri(scheme: 'tel', path: '+256750467976');
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    } else {
      _showSnackBar("Could not make call");
    }
  }

  Future<void> _openWhatsApp() async {
    final String whatsappUrl =
        "https://wa.me/256750467976?text=Hello%20Support!%20I%20need%20help%20with%20FreshBasket%20app.";
    final Uri uri = Uri.parse(whatsappUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar("WhatsApp not installed");
    }
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('feedback').add({
        'userId': user?.uid ?? 'anonymous',
        'email': user?.email ?? 'N/A',
        'message': _feedbackController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'new',
      });

      _feedbackController.clear();
      _showSnackBar(
        "Thank you! Feedback submitted successfully.",
        success: true,
      );
    } catch (e) {
      _showSnackBar("Failed to send feedback: $e");
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? const Color(0xFF2E7D32) : Colors.red,
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
          'Help & Feedback',
          style: TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FAQs',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 12),
            ...faqs.map(
              (faq) =>
                  FAQTile(question: faq["question"]!, answer: faq["answer"]!),
            ),
            const SizedBox(height: 20),
            const Text(
              'Contact Support',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 12),
            _buildSupportCard(
              icon: Icons.email,
              title: 'Email Support',
              subtitle: 'support@freshbasket.com',
              color: const Color(0xFF2E7D32),
              onTap: _sendEmail,
            ),
            _buildSupportCard(
              icon: Icons.phone,
              title: 'Call Support',
              subtitle: '+256 750 467 976',
              color: const Color(0xFF2E7D32),
              onTap: _makeCall,
            ),
            _buildSupportCard(
              icon: Icons.chat,
              title: 'Live Chat',
              subtitle: 'Chat with us now',
              color: const Color(0xFF2E7D32),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LiveChatScreen()),
              ),
            ),
            _buildSupportCard(
              icon: Icons.chat_bubble,
              title: 'WhatsApp',
              subtitle: 'Message on WhatsApp',
              color: const Color(0xFF2E7D32),
              onTap: _openWhatsApp,
            ),
            const SizedBox(height: 30),
            const Text(
              'Send Feedback',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _feedbackController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: "Share your feedback or report an issue...",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (v) =>
                        v!.trim().isEmpty ? "Please write something" : null,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitFeedback,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Submit Feedback",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}

class FAQTile extends StatefulWidget {
  final String question;
  final String answer;
  const FAQTile({required this.question, required this.answer, super.key});

  @override
  State<FAQTile> createState() => _FAQTileState();
}

class _FAQTileState extends State<FAQTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: const Icon(
          Icons.help_outline,
          color: Color(0xFF2E7D32),
          size: 28,
        ),
        title: Text(
          widget.question,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        onExpansionChanged: (v) => setState(() => _expanded = v),
        children: [
          Text(
            widget.answer,
            style: const TextStyle(color: Colors.black87, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
