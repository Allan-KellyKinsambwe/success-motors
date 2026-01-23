// lib/screens/garage_cars/garage_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class GarageBooking {
  String id;
  final String userId;
  final String fullName;
  final String phoneNumber;
  final String carMake;
  final String carModel;
  final String carYear;
  final String registrationNumber;
  final String serviceType;
  final String? otherService;
  final DateTime preferredDate;
  final String preferredTime;
  final String additionalNotes;
  final String status; // pending, confirmed, in-progress, completed, cancelled
  final Timestamp createdAt;

  GarageBooking({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.carMake,
    required this.carModel,
    required this.carYear,
    required this.registrationNumber,
    required this.serviceType,
    this.otherService,
    required this.preferredDate,
    required this.preferredTime,
    required this.additionalNotes,
    this.status = 'pending',
    required this.createdAt,
  });

  factory GarageBooking.fromMap(Map<String, dynamic> map) {
    return GarageBooking(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      carMake: map['carMake'] ?? '',
      carModel: map['carModel'] ?? '',
      carYear: map['carYear'] ?? '',
      registrationNumber: map['registrationNumber'] ?? '',
      serviceType: map['serviceType'] ?? '',
      otherService: map['otherService'],
      preferredDate: (map['preferredDate'] as Timestamp).toDate(),
      preferredTime: map['preferredTime'] ?? '',
      additionalNotes: map['additionalNotes'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'carMake': carMake,
      'carModel': carModel,
      'carYear': carYear,
      'registrationNumber': registrationNumber,
      'serviceType': serviceType,
      'otherService': otherService,
      'preferredDate': Timestamp.fromDate(preferredDate),
      'preferredTime': preferredTime,
      'additionalNotes': additionalNotes,
      'status': status,
      'createdAt': createdAt,
    };
  }
}
