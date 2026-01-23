// lib/screens/rental_cars/rental_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class RentalBooking {
  String id;
  final String userId;
  final String carMake;
  final String carModel;
  final String carImage;
  final int dailyRate;
  final DateTime pickupDate;
  final DateTime dropoffDate;
  final String pickupLocation;
  final String dropoffLocation;
  final bool withDriver;
  final int totalAmount;
  final String status; // pending, confirmed, ongoing, completed, cancelled
  final Timestamp createdAt;

  RentalBooking({
    required this.id,
    required this.userId,
    required this.carMake,
    required this.carModel,
    required this.carImage,
    required this.dailyRate,
    required this.pickupDate,
    required this.dropoffDate,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.withDriver,
    required this.totalAmount,
    this.status = 'pending',
    required this.createdAt,
  });

  int get totalDays => dropoffDate.difference(pickupDate).inDays + 1;

  factory RentalBooking.fromMap(Map<String, dynamic> map) {
    return RentalBooking(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      carMake: map['carMake'] ?? '',
      carModel: map['carModel'] ?? '',
      carImage: map['carImage'] ?? '',
      dailyRate: map['dailyRate'] ?? 0,
      pickupDate: (map['pickupDate'] as Timestamp).toDate(),
      dropoffDate: (map['dropoffDate'] as Timestamp).toDate(),
      pickupLocation: map['pickupLocation'] ?? '',
      dropoffLocation: map['dropoffLocation'] ?? '',
      withDriver: map['withDriver'] ?? false,
      totalAmount: map['totalAmount'] ?? 0,
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'carMake': carMake,
      'carModel': carModel,
      'carImage': carImage,
      'dailyRate': dailyRate,
      'pickupDate': Timestamp.fromDate(pickupDate),
      'dropoffDate': Timestamp.fromDate(dropoffDate),
      'pickupLocation': pickupLocation,
      'dropoffLocation': dropoffLocation,
      'withDriver': withDriver,
      'totalAmount': totalAmount,
      'status': status,
      'createdAt': createdAt,
    };
  }
}
