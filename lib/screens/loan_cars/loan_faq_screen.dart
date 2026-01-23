// lib/screens/loan_cars/loan_faq_screen.dart
import 'package:flutter/material.dart';

class LoanFaqScreen extends StatelessWidget {
  const LoanFaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Requirements & FAQ'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Eligibility Requirements',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _RequirementItem('Age: 21–65 years at loan maturity'),
          _RequirementItem('Valid Ugandan National ID'),
          _RequirementItem(
            'Proof of income (salary slip, bank statement, or business records)',
          ),
          _RequirementItem(
            'Minimum monthly income: UGX 1,000,000 (employed) / UGX 1,500,000 (self-employed)',
          ),
          _RequirementItem('Good credit history (no active defaults)'),
          _RequirementItem(
            'Vehicle must be valued at least 120% of loan amount',
          ),
          const SizedBox(height: 32),

          const Text(
            'Frequently Asked Questions',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _FaqItem(
            question: 'What interest rates do you offer?',
            answer:
                'Rates range from 15%–22% per annum (reducing balance), depending on loan amount, term, and your credit profile.',
          ),
          _FaqItem(
            question: 'How long does approval take?',
            answer:
                'Most complete applications are reviewed within 48 hours. Disbursement can take 3–7 working days after approval.',
          ),
          _FaqItem(
            question: 'Can I repay early?',
            answer:
                'Yes. Early repayment is allowed with no or minimal penalty (usually 1–2% of outstanding balance).',
          ),
          _FaqItem(
            question: 'What documents do I need?',
            answer:
                'National ID (front & back), recent passport photo, proof of income (last 3–6 months), and car valuation report (if applicable).',
          ),
          _FaqItem(
            question: 'Is there a processing fee?',
            answer:
                'Yes, a one-time fee of 1–2% of the loan amount (capped at UGX 1,000,000) is charged upon disbursement.',
          ),
          _FaqItem(
            question: 'Can I use the loan to refinance an existing car loan?',
            answer:
                'Yes, refinance and top-up options are available for existing vehicle loans with good repayment history.',
          ),
        ],
      ),
    );
  }
}

class _RequirementItem extends StatelessWidget {
  final String text;

  const _RequirementItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(answer, style: const TextStyle(fontSize: 15, height: 1.4)),
        ],
      ),
    );
  }
}
