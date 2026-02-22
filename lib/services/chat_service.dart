import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';

class ChatService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get or create a chat room between two users
  Future<String> getOrCreateChatRoom({
    required String currentUserId,
    required String currentUserName,
    required String otherUserId,
    required String otherUserName,
    String? produceId,
    String? produceName,
  }) async {
    // Check if chat room exists between these two users
    final query = await _firestore
        .collection('chatRooms')
        .where('participantIds', arrayContains: currentUserId)
        .get();

    for (var doc in query.docs) {
      final participants = List<String>.from(doc.data()['participantIds'] ?? []);
      if (participants.contains(otherUserId)) {
        return doc.id;
      }
    }

    // Create new chat room
    final chatRoom = ChatRoom(
      id: '',
      participantIds: [currentUserId, otherUserId],
      participantNames: {
        currentUserId: currentUserName,
        otherUserId: otherUserName,
      },
      produceId: produceId,
      produceName: produceName,
    );

    final docRef = await _firestore.collection('chatRooms').add(chatRoom.toMap());
    return docRef.id;
  }

  // Send a message
  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    final message = ChatMessage(
      id: '',
      senderId: senderId,
      text: text,
      timestamp: DateTime.now(),
    );

    await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(message.toMap());

    // Update last message in chat room
    await _firestore.collection('chatRooms').doc(chatRoomId).update({
      'lastMessage': text,
      'lastMessageTime': Timestamp.fromDate(DateTime.now()),
    });

    // Create in-app notification for the other participant
    try {
      final roomDoc = await _firestore.collection('chatRooms').doc(chatRoomId).get();
      if (roomDoc.exists) {
        final participants = List<String>.from(roomDoc.data()?['participantIds'] ?? []);
        final recipientId = participants.firstWhere(
          (id) => id != senderId,
          orElse: () => '',
        );
        if (recipientId.isNotEmpty) {
          final preview = text.length > 50 ? '${text.substring(0, 50)}...' : text;
          await _firestore.collection('notifications').add({
            'userId': recipientId,
            'title': 'New message from $senderName',
            'body': preview,
            'chatRoomId': chatRoomId,
            'isRead': false,
            'createdAt': Timestamp.fromDate(DateTime.now()),
          });
        }
      }
    } catch (e) {
      // Don't fail the send if notification creation fails
      debugPrint('Failed to create chat notification: $e');
    }
  }

  // Get messages stream (latest 100 for fast initial load)
  Stream<List<ChatMessage>> getMessages(String chatRoomId) {
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .limitToLast(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get user's chat rooms
  Stream<List<ChatRoom>> getUserChatRooms(String userId) {
    return _firestore
        .collection('chatRooms')
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatRoom.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatRoomId, String currentUserId) async {
    final unread = await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: currentUserId)
        .get();

    final batch = _firestore.batch();
    for (var doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
