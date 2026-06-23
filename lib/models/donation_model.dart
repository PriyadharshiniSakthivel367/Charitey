import 'package:cloud_firestore/cloud_firestore.dart';

class DonationModel {
  final String donationId;
  final String listingId;
  final String ngoId;
  final String donorId;
  final String donorName;
  final String donorPhone;
  final String donorLocation;
  final String status; // pending / claimed / completed
  final DateTime createdAt;
  final int donatedQuantity;

  DonationModel({
    required this.donationId,
    required this.listingId,
    required this.ngoId,
    required this.donorId,
    required this.donorName,
    required this.donorPhone,
    required this.donorLocation,
    required this.status,
    required this.createdAt,
    required this.donatedQuantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'donationId': donationId,
      'listingId': listingId,
      'ngoId': ngoId,
      'donorId': donorId,
      'donorName': donorName,
      'donorPhone': donorPhone,
      'donorLocation': donorLocation,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'donatedQuantity': donatedQuantity,
    };
  }

  factory DonationModel.fromMap(Map<String, dynamic> map, String documentId) {
    return DonationModel(
      donationId: documentId,
      listingId: map['listingId'] ?? '',
      ngoId: map['ngoId'] ?? '',
      donorId: map['donorId'] ?? '',
      donorName: map['donorName'] ?? '',
      donorPhone: map['donorPhone'] ?? '',
      donorLocation: map['donorLocation'] ?? '',
      status: map['status'] ?? 'pending',
      donatedQuantity: map['donatedQuantity'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
