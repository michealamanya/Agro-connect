import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/produce_model.dart';
import 'api_service.dart';

class ProduceService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Upload images through the backend API (stores in MongoDB or Firebase Storage)
  Future<List<String>> _uploadImages(List<File> images, String produceId) async {
    List<String> urls = [];
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final token = await user.getIdToken();

    for (var image in images) {
      final uri = Uri.parse('${ApiService.baseUrl}/produce/$produceId/upload');
      final ext = image.path.split('.').last.toLowerCase();
      final mimeType = {
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
        'gif': 'image/gif',
        'webp': 'image/webp',
      }[ext] ?? 'image/jpeg';
      final parts = mimeType.split('/');

      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath(
          'image',
          image.path,
          contentType: MediaType(parts[0], parts[1]),
        ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = ApiService.parseJson(response.body);
        final imageUrl = data['imageUrl'] as String;
        // Convert relative URLs to full URLs
        urls.add(ApiService.getFullImageUrl(imageUrl));
      } else {
        throw Exception('Image upload failed: ${response.body}');
      }
    }
    return urls;
  }

  // Add new produce
  Future<String?> addProduce({
    required String farmerId,
    required String farmerName,
    required String name,
    required String description,
    required String category,
    required double price,
    required String unit,
    required double quantity,
    required ProduceStatus status,
    required List<File> images,
    String? location,
    DateTime? expectedReadyDate,
  }) async {
    try {
      final docRef = _firestore.collection('produce').doc();
      final imageUrls = await _uploadImages(images, docRef.id);

      final produce = ProduceModel(
        id: docRef.id,
        farmerId: farmerId,
        farmerName: farmerName,
        name: name,
        description: description,
        category: category,
        price: price,
        unit: unit,
        quantity: quantity,
        status: status,
        imageUrls: imageUrls,
        location: location,
        expectedReadyDate: expectedReadyDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await docRef.set(produce.toMap());
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Get all produce stream
  Stream<List<ProduceModel>> getAllProduceStream() {
    return _firestore
        .collection('produce')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProduceModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get produce by status
  Stream<List<ProduceModel>> getProduceByStatus(ProduceStatus status) {
    final statusStr = status == ProduceStatus.ready ? 'ready' : 'unready';
    return _firestore
        .collection('produce')
        .where('status', isEqualTo: statusStr)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProduceModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get farmer's produce
  Stream<List<ProduceModel>> getFarmerProduce(String farmerId) {
    return _firestore
        .collection('produce')
        .where('farmerId', isEqualTo: farmerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProduceModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get produce by category
  Stream<List<ProduceModel>> getProduceByCategory(String category) {
    return _firestore
        .collection('produce')
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProduceModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Update produce
  Future<String?> updateProduce(String produceId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await _firestore.collection('produce').doc(produceId).update(data);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Delete produce
  Future<String?> deleteProduce(String produceId) async {
    try {
      // Images are cleaned up by the backend automatically
      await _firestore.collection('produce').doc(produceId).delete();
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Search produce
  Stream<List<ProduceModel>> searchProduce(String query) {
    final lowerQuery = query.toLowerCase();
    return _firestore
        .collection('produce')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProduceModel.fromMap(doc.data(), doc.id))
            .where((produce) =>
                produce.name.toLowerCase().contains(lowerQuery) ||
                produce.description.toLowerCase().contains(lowerQuery) ||
                produce.category.toLowerCase().contains(lowerQuery))
            .toList());
  }

  // Get produce categories
  static List<String> get categories => [
        'Vegetables',
        'Fruits',
        'Grains',
        'Legumes',
        'Tubers',
        'Herbs',
        'Dairy',
        'Poultry',
        'Livestock',
        'Other',
      ];
}
