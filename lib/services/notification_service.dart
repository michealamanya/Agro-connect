import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationService extends ChangeNotifier {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    final token = await _messaging.getToken();
    debugPrint('FCM Token: $token');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message: ${message.notification?.title}');
      notifyListeners();
    });

    // Handle background messages when app is opened
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Message opened app: ${message.notification?.title}');
    });
  }

  // Save FCM token for user
  Future<void> saveTokenForUser(String userId) async {
    final token = await _messaging.getToken();
    if (token != null) {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
      });
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _firestore.collection('users').doc(userId).update({
        'fcmToken': newToken,
      });
    });
  }

  // Subscribe to new produce notifications
  Future<void> subscribeToNewProduce() async {
    await _messaging.subscribeToTopic('new_produce');
  }

  // Unsubscribe from new produce notifications
  Future<void> unsubscribeFromNewProduce() async {
    await _messaging.unsubscribeFromTopic('new_produce');
  }

  // Create a notification document in Firestore (for in-app notifications)
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    String? produceId,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'produceId': produceId,
      'isRead': false,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Get user notifications stream
  Stream<QuerySnapshot> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }
}
