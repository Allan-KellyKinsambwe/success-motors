// lib/screens/loan_cars/loan_model.dart
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class LoanApplication {
  final String id;
  final String userId;
  final String firstName;
  final String surname;
  final String email;
  final String phoneNumber;
  final String nationalId;
  final String address;
  final String employmentStatus;
  final double monthlyIncome;

  final String carMake;
  final String carModel;
  final int carYear;
  final double carMarketValue; // estimated value of the car
  final double loanAmountRequested;
  final int loanTermMonths;
  final double interestRateAnnual; // e.g. 18% = 0.18
  final String loanPurpose;

  String status; // 'pending', 'approved', 'rejected', 'disbursed'
  String? adminNotes; // rejection reason or admin comments
  Timestamp? updatedAt; // when admin last acted
  final Timestamp createdAt;

  // Optional uploaded docs
  String? nationalIdFrontUrl;
  String? nationalIdBackUrl;
  String? proofOfIncomeUrl;
  String? carValuationReportUrl;

  // Optional repayment schedule
  List<Map<String, dynamic>>? repaymentSchedule;

  LoanApplication({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.surname,
    required this.email,
    required this.phoneNumber,
    required this.nationalId,
    required this.address,
    required this.employmentStatus,
    required this.monthlyIncome,
    required this.carMake,
    required this.carModel,
    required this.carYear,
    required this.carMarketValue,
    required this.loanAmountRequested,
    required this.loanTermMonths,
    required this.interestRateAnnual,
    required this.loanPurpose,
    required this.createdAt,
    this.status = 'pending',
    this.adminNotes,
    this.updatedAt,
    this.repaymentSchedule,
    this.nationalIdFrontUrl,
    this.nationalIdBackUrl,
    this.proofOfIncomeUrl,
    this.carValuationReportUrl,
  });

  factory LoanApplication.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    return LoanApplication(
      id: id,
      userId: map['userId'] ?? '',
      firstName: map['firstName'] ?? '',
      surname: map['surname'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      nationalId: map['nationalId'] ?? '',
      address: map['address'] ?? '',
      employmentStatus: map['employmentStatus'] ?? '',
      monthlyIncome: (map['monthlyIncome'] as num?)?.toDouble() ?? 0.0,
      carMake: map['carMake'] ?? '',
      carModel: map['carModel'] ?? '',
      carYear: map['carYear'] as int? ?? 0,
      carMarketValue: (map['carMarketValue'] as num?)?.toDouble() ?? 0.0,
      loanAmountRequested:
          (map['loanAmountRequested'] as num?)?.toDouble() ?? 0.0,
      loanTermMonths: map['loanTermMonths'] as int? ?? 0,
      interestRateAnnual:
          (map['interestRateAnnual'] as num?)?.toDouble() ?? 0.18,
      loanPurpose: map['loanPurpose'] ?? 'Purchase',
      status: map['status'] ?? 'pending',
      adminNotes: map['adminNotes'] as String?,
      updatedAt: map['updatedAt'] as Timestamp?,
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
      repaymentSchedule: (map['repaymentSchedule'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      nationalIdFrontUrl: map['nationalIdFrontUrl'] as String?,
      nationalIdBackUrl: map['nationalIdBackUrl'] as String?,
      proofOfIncomeUrl: map['proofOfIncomeUrl'] as String?,
      carValuationReportUrl: map['carValuationReportUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'firstName': firstName,
      'surname': surname,
      'email': email,
      'phoneNumber': phoneNumber,
      'nationalId': nationalId,
      'address': address,
      'employmentStatus': employmentStatus,
      'monthlyIncome': monthlyIncome,
      'carMake': carMake,
      'carModel': carModel,
      'carYear': carYear,
      'carMarketValue': carMarketValue,
      'loanAmountRequested': loanAmountRequested,
      'loanTermMonths': loanTermMonths,
      'interestRateAnnual': interestRateAnnual,
      'loanPurpose': loanPurpose,
      'status': status,
      'adminNotes': adminNotes,
      'updatedAt': updatedAt,
      'createdAt': createdAt,
      'repaymentSchedule': repaymentSchedule,
      'nationalIdFrontUrl': nationalIdFrontUrl,
      'nationalIdBackUrl': nationalIdBackUrl,
      'proofOfIncomeUrl': proofOfIncomeUrl,
      'carValuationReportUrl': carValuationReportUrl,
    }..removeWhere((key, value) => value == null);
  }

  String get formattedCreatedAt {
    return DateFormat('dd MMM yyyy, hh:mm a').format(createdAt.toDate());
  }

  double get monthlyEMI {
    if (loanTermMonths == 0 || interestRateAnnual == 0) return 0;
    final r = interestRateAnnual / 12;
    final n = loanTermMonths;
    return (loanAmountRequested * r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
  }

  String get formattedMonthlyEMI {
    final emi = monthlyEMI;
    return emi > 0
        ? NumberFormat.currency(
            locale: 'en_US',
            symbol: 'UGX ',
            decimalDigits: 0,
          ).format(emi)
        : 'N/A';
  }

  // ────────────────────────────────────────────────
  //   copyWith method – required for updating id after Firestore save
  // ────────────────────────────────────────────────
  LoanApplication copyWith({
    String? id,
    String? userId,
    String? firstName,
    String? surname,
    String? email,
    String? phoneNumber,
    String? nationalId,
    String? address,
    String? employmentStatus,
    double? monthlyIncome,
    String? carMake,
    String? carModel,
    int? carYear,
    double? carMarketValue,
    double? loanAmountRequested,
    int? loanTermMonths,
    double? interestRateAnnual,
    String? loanPurpose,
    String? status,
    String? adminNotes,
    Timestamp? updatedAt,
    Timestamp? createdAt,
    List<Map<String, dynamic>>? repaymentSchedule,
    String? nationalIdFrontUrl,
    String? nationalIdBackUrl,
    String? proofOfIncomeUrl,
    String? carValuationReportUrl,
  }) {
    print(
      'copyWith called - new id: ${id ?? "null (keeping old: ${this.id})"}',
    );
    return LoanApplication(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      surname: surname ?? this.surname,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      nationalId: nationalId ?? this.nationalId,
      address: address ?? this.address,
      employmentStatus: employmentStatus ?? this.employmentStatus,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      carMake: carMake ?? this.carMake,
      carModel: carModel ?? this.carModel,
      carYear: carYear ?? this.carYear,
      carMarketValue: carMarketValue ?? this.carMarketValue,
      loanAmountRequested: loanAmountRequested ?? this.loanAmountRequested,
      loanTermMonths: loanTermMonths ?? this.loanTermMonths,
      interestRateAnnual: interestRateAnnual ?? this.interestRateAnnual,
      loanPurpose: loanPurpose ?? this.loanPurpose,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      repaymentSchedule: repaymentSchedule ?? this.repaymentSchedule,
      nationalIdFrontUrl: nationalIdFrontUrl ?? this.nationalIdFrontUrl,
      nationalIdBackUrl: nationalIdBackUrl ?? this.nationalIdBackUrl,
      proofOfIncomeUrl: proofOfIncomeUrl ?? this.proofOfIncomeUrl,
      carValuationReportUrl:
          carValuationReportUrl ?? this.carValuationReportUrl,
    );
  }
}
