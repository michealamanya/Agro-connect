import 'package:cloud_firestore/cloud_firestore.dart';

enum ProduceStatus { ready, unready }

class ProduceModel {
  final String id;
  final String farmerId;
  final String farmerName;
  final String name;
  final String description;
  final String category;
  final double price;
  final String unit; // e.g., kg, bunch, crate
  final double quantity;
  final ProduceStatus status;
  final List<String> imageUrls;
  final String? location;
  final DateTime? expectedReadyDate; // for unready produce
  final DateTime createdAt;
  final DateTime updatedAt;

  ProduceModel({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.unit,
    required this.quantity,
    required this.status,
    required this.imageUrls,
    this.location,
    this.expectedReadyDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProduceModel.fromMap(Map<String, dynamic> map, String docId) {
    return ProduceModel(
      id: docId,
      farmerId: map['farmerId'] ?? '',
      farmerName: map['farmerName'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      unit: map['unit'] ?? 'kg',
      quantity: (map['quantity'] ?? 0).toDouble(),
      status: map['status'] == 'ready' ? ProduceStatus.ready : ProduceStatus.unready,
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      location: map['location'],
      expectedReadyDate: (map['expectedReadyDate'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'farmerId': farmerId,
      'farmerName': farmerName,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'unit': unit,
      'quantity': quantity,
      'status': status == ProduceStatus.ready ? 'ready' : 'unready',
      'imageUrls': imageUrls,
      'location': location,
      'expectedReadyDate': expectedReadyDate != null
          ? Timestamp.fromDate(expectedReadyDate!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool get isReady => status == ProduceStatus.ready;
}
