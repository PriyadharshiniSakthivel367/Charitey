//ngo_listing_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class NgoListingModel {
  final String listingId;
  final String ngoId;
  final String ngoName;
  final String ngoLocation;
  final String type;

  final String? imageUrl;

  final String? foodType;
  final int? quantity;
  final int? fulfilledQuantity; // <-- NEW: Tracks balance progression
  final String? unit;

  final String? category;
  final String? productName;

  final String availability;
  final DateTime liveUntil;
  final DateTime createdAt;
  final String status;
  
  // --- Volunteer Availability Field ---
  final bool? isVolunteerAvailable; 
  final String? ngoProfileImage; // ADD THIS
  final String? description;

  NgoListingModel({
    required this.listingId,
    required this.ngoId,
    required this.ngoName,
    required this.ngoLocation,
    required this.type,
    this.imageUrl,
    this.foodType,
    this.quantity,
    this.fulfilledQuantity, // <-- Added to constructor
    this.unit,
    this.category,
    this.productName,
    required this.availability,
    required this.liveUntil,
    required this.createdAt,
    required this.status,
    this.isVolunteerAvailable, 
    this.ngoProfileImage, // ADD THIS
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'listingId': listingId,
      'ngoId': ngoId,
      'ngoName': ngoName,
      'ngoLocation': ngoLocation,
      'type': type,
      'imageUrl': imageUrl,
      'foodType': foodType,
      'quantity': quantity,
      'fulfilledQuantity': fulfilledQuantity ?? 0, // <-- Added to Map for Firebase
      'unit': unit,
      'category': category,
      'productName': productName,
      'availability': availability,
      'liveUntil': Timestamp.fromDate(liveUntil),
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'isVolunteerAvailable': isVolunteerAvailable, 
      'ngoProfileImage': ngoProfileImage, // ADD THIS
      'description': description, // <-- NEW
    };
  }

  factory NgoListingModel.fromMap(Map<String, dynamic> map, String documentId) {
    return NgoListingModel(
      listingId: documentId,
      ngoId: map['ngoId'] ?? '',
      ngoName: map['ngoName'] ?? '',
      ngoLocation: map['ngoLocation'] ?? '',
      type: map['type'] ?? 'food',

      imageUrl: map['imageUrl'],

      foodType: map['foodType'],
      quantity: map['quantity'],
      fulfilledQuantity: map['fulfilledQuantity'] ?? 0, // <-- Read from Firebase, defaults to 0
      unit: map['unit'],
      category: map['category'],
      productName: map['productName'],

      availability: map['availability'] ?? '',

      liveUntil: (map['liveUntil'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),

      status: map['status'] ?? 'open',
      isVolunteerAvailable: map['isVolunteerAvailable'] as bool?, 
      ngoProfileImage: map['ngoProfileImage'] as String?, // ADD THIS
      description: map['description'] as String?, // <-- NEW
    );
  }
}