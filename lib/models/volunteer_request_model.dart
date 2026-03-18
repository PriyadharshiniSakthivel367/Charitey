import 'package:cloud_firestore/cloud_firestore.dart';

class VolunteerRequestModel {
  final String requestId;
  final String ngoId;
  final String donorId;
  final String listingId;
  final String status;
  final String? assignedVolunteer;
  final DateTime createdAt;

  VolunteerRequestModel({
    required this.requestId,
    required this.ngoId,
    required this.donorId,
    required this.listingId,
    required this.status,
    this.assignedVolunteer,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'ngoId': ngoId,
      'donorId': donorId,
      'listingId': listingId,
      'status': status,
      'assignedVolunteer': assignedVolunteer,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory VolunteerRequestModel.fromMap(
      Map<String, dynamic> map, String documentId) {
    return VolunteerRequestModel(
      requestId: documentId,
      ngoId: map['ngoId'] ?? '',
      donorId: map['donorId'] ?? '',
      listingId: map['listingId'] ?? '',
      status: map['status'] ?? 'pending',
      assignedVolunteer: map['assignedVolunteer'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
