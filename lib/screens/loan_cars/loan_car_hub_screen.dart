// lib/screens/loan_cars/loan_car_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:success_motors/constants/constants.dart';
import 'loan_application_screen.dart';
import 'my_loans_screen.dart';
import 'loan_calculator_screen.dart';
import 'loan_faq_screen.dart';

class LoanCarHubScreen extends StatelessWidget {
  const LoanCarHubScreen({super.key});

  void _showSuccessPayBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const Text(
                'Success Pay Plan – How It Works at Success Motors',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'At Success Motors (Nakawa, Kampala), we make it easy to own your dream car today — even if you can\'t pay the full amount upfront. Our Success Pay Plan is our flexible in-house payment option (not a bank loan), so you can drive away quickly with minimal hassle.\n\n'
                'We offer three main ways to pay for any car in our stock (mostly quality used Japanese imports like Toyota, Honda, Nissan, Subaru, and more):',
                style: TextStyle(fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 16),
              _buildListItem(
                '1. Full Cash Payment',
                'Pay the entire price at once → no balance, no waiting. Drive home the same day!',
              ),
              _buildListItem(
                '2. Success Pay Instalment Plan (the popular "pay later" option)',
                '• Pay at least 60% of the car\'s price as your initial down payment/deposit.\n'
                    '• Once paid, complete simple paperwork and drive the car away immediately (same day!).\n'
                    '• Pay the remaining balance (usually 40% or less) in easy instalments over an agreed period.\n'
                    '   - Timeframe: Flexible — often 3 months for smaller balances, but can be longer.\n'
                    '   - Payments: Monthly (or as agreed).\n'
                    '• Example: For a car priced at UGX 65,000,000 → Pay UGX 55,000,000 upfront → drive away → pay the remaining UGX 10,000,000 over 3 months while enjoying the car.',
              ),
              _buildListItem(
                '3. Success Account Opening Promo (start small and build up)',
                '• Open a savings account with us starting from just UGX 500,000 (or more).\n'
                    '• Keep depositing money regularly.\n'
                    '• Once your deposits reach 60% of your chosen car\'s price, switch to the Success Pay instalment plan → take the car and pay the balance over time.',
              ),
              const SizedBox(height: 20),
              const Text(
                'Why Choose Success Pay?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Quick approval — no long bank processes or strict credit checks.\n'
                '• Take the car home the same day after your down payment.\n'
                '• Flexible terms tailored to you.\n'
                '• Buy with confidence from a trusted dealer.',
                style: TextStyle(fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 24),
              const Text(
                'Important Notes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Terms depend on the car, your situation, and current promotions — always get everything in writing.\n'
                '• If payments are missed, the car may be repossessed.\n'
                '• For the latest details, contact us directly:',
                style: TextStyle(fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 12),
              const Text(
                '📞 +256 707 787 650 | +256 701 283 293 | +256 779 345 369\n'
                '📍 Nakawa, off Jinja Road (opposite Steel & Tube / Pepsi-Cola)\n'
                '🌐 successmotorsltd.com',
                style: TextStyle(fontSize: 15, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Got it!', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(content, style: const TextStyle(fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }

  void _showInfoBottomSheet(
    BuildContext context,
    String title,
    String message,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(fontSize: 15, height: 1.5)),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Color(0xFF2E7D32)),
                ),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Car Loan Hub'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Banner
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF2E7D32), const Color(0xFF1B5E20)],
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.directions_car_filled_rounded,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Drive Your Dream Car Today',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Flexible car loans with competitive rates.\nQuick approval • No hidden fees',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow_rounded, size: 28),
                      label: const Text(
                        'Apply for Car Loan Now',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoanApplicationScreen(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Feature Cards Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Why Choose Success Motors Financing?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  _FeatureCard(
                    icon: Icons.money_outlined,
                    title: 'Success Pay',
                    subtitle: 'Pay at least 60% upfront and drive away today',
                    onTap: () => _showSuccessPayBottomSheet(context),
                  ),
                  _FeatureCard(
                    icon: Icons.speed,
                    title: 'Fast Approval',
                    subtitle: 'Most applications reviewed within 48 hours',
                    onTap: () => _showInfoBottomSheet(
                      context,
                      'Fast Approval',
                      'We aim to review and respond to most loan applications within 48 hours. Once approved, funds can be disbursed quickly — often within the same week!',
                    ),
                  ),
                  _FeatureCard(
                    icon: Icons.percent,
                    title: 'Competitive Rates',
                    subtitle: 'Starting from 15–22% p.a. depending on profile',
                    onTap: () => _showInfoBottomSheet(
                      context,
                      'Competitive Rates',
                      'Our interest rates start from 15% per annum and go up to 22%, depending on your credit profile, loan amount, and repayment term. Better profiles get better rates!',
                    ),
                  ),
                  _FeatureCard(
                    icon: Icons.security,
                    title: 'Flexible Terms',
                    subtitle: '12 to 60 months repayment plans',
                    onTap: () => _showInfoBottomSheet(
                      context,
                      'Flexible Terms',
                      'Choose a repayment period that suits your budget — from 12 months up to 60 months (5 years). Longer terms mean lower monthly payments.',
                    ),
                  ),
                  _FeatureCard(
                    icon: Icons.handshake,
                    title: 'No Hidden Fees',
                    subtitle:
                        'Transparent process from application to disbursement',
                    onTap: () => _showInfoBottomSheet(
                      context,
                      'No Hidden Fees',
                      'We believe in full transparency. All fees (if any) are clearly stated upfront. There are no surprise charges during application, approval, or disbursement.',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Improved Secondary CTAs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _StyledOutlinedButton(
                    icon: Icons.list_alt,
                    label: 'View My Loan Applications',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyLoansScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StyledOutlinedButton(
                    icon: Icons.calculate,
                    label: 'Loan Calculator',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoanCalculatorScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StyledOutlinedButton(
                    icon: Icons.help_outline,
                    label: 'Loan Requirements & FAQ',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoanFaqScreen()),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF2E7D32).withOpacity(0.12),
            radius: 30,
            child: Icon(icon, color: const Color(0xFF2E7D32), size: 32),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          trailing: onTap != null
              ? const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: Color(0xFF2E7D32),
                )
              : null,
        ),
      ),
    );
  }
}

class _StyledOutlinedButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _StyledOutlinedButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(30),
      child: OutlinedButton.icon(
        icon: Icon(icon, size: 26),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF2E7D32),
          side: const BorderSide(color: Color(0xFF2E7D32), width: 2),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          backgroundColor: Colors.white,
        ),
        onPressed: onPressed,
      ),
    );
  }
}
