import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_message_model.dart';
import '../models/public_profile_model.dart';

/// Foydalanuvchilar ro'yxati va 1:1 suhbatlar.
class ChatService {
  const ChatService(this._db);

  final FirebaseFirestore _db;

  /// Ikki uid'dan barqaror suhbat identifikatori.
  ///
  /// Saralab birlashtiriladi — shunda A→B va B→A bir xil suhbatga tushadi.
  static String chatIdFor(String a, String b) {
    final List<String> ids = <String>[a, b]..sort();
    return '${ids[0]}__${ids[1]}';
  }

  static List<String> participantsFor(String a, String b) =>
      <String>[a, b]..sort();

  CollectionReference<Map<String, dynamic>> get _publicProfiles =>
      _db.collection('publicProfiles');

  CollectionReference<Map<String, dynamic>> get _chats =>
      _db.collection('chats');

  /// Ro'yxatdan o'tgan barcha foydalanuvchilar (o'zidan tashqari).
  Stream<List<PublicProfile>> watchUsers(String currentUserId) {
    return _publicProfiles.orderBy('fullName').snapshots().map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .where(
                (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                    doc.id != currentUserId,
              )
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                    PublicProfile.fromMap(doc.id, doc.data()),
              )
              .toList(),
        );
  }

  /// Joriy foydalanuvchi ishtirok etadigan suhbatlar — chatId bo'yicha.
  ///
  /// `orderBy` ataylab qo'llanilmagan: `array-contains` bilan birga u
  /// composite index talab qilardi. Suhbatlar soni kam, saralash mijozda.
  Stream<Map<String, ChatSummary>> watchMyChats(String currentUserId) {
    return _chats
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      return <String, ChatSummary>{
        for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
            in snapshot.docs)
          doc.id: ChatSummary.fromMap(doc.id, doc.data()),
      };
    });
  }

  /// Suhbat xabarlari — eng yangisi birinchi.
  ///
  /// Ro'yxat `reverse: true` bilan chiziladi, shuning uchun kamayish
  /// tartibida so'raladi: yangi xabar avtomatik pastda paydo bo'ladi.
  Stream<List<ChatMessage>> watchMessages(String chatId, {int limit = 200}) {
    return _chats
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                    ChatMessage.fromMap(doc.id, doc.data()),
              )
              .toList(),
        );
  }

  /// Xabar yuboradi va suhbat kartochkasini yangilaydi.
  ///
  /// Ikkalasi bitta `WriteBatch` da — biri yozilib, ikkinchisi yozilmay
  /// qolishi mumkin emas.
  Future<void> sendMessage({
    required String currentUserId,
    required String otherUserId,
    required String text,
    ChatMessage? replyTo,
  }) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final String chatId = chatIdFor(currentUserId, otherUserId);
    final List<String> participants =
        participantsFor(currentUserId, otherUserId);
    // Mijoz vaqti: serverTimestamp mahalliy snapshot'da null bo'lib turadi va
    // yangi xabar ro'yxatda noto'g'ri joyda ko'rinib ketardi.
    final DateTime now = DateTime.now();

    final DocumentReference<Map<String, dynamic>> chatRef = _chats.doc(chatId);
    final DocumentReference<Map<String, dynamic>> messageRef =
        chatRef.collection('messages').doc();

    final WriteBatch batch = _db.batch();

    batch.set(
      chatRef,
      <String, dynamic>{
        'participants': participants,
        'lastMessage': trimmed,
        'lastMessageAt': now,
        'lastSenderId': currentUserId,
      },
      SetOptions(merge: true),
    );

    batch.set(messageRef, <String, dynamic>{
      'participants': participants,
      'senderId': currentUserId,
      'text': trimmed,
      'createdAt': now,
      'replyToId': replyTo?.id,
      'replyToText': replyTo?.text,
      'replyToSenderId': replyTo?.senderId,
    });

    await batch.commit();
  }

  /// Xabarni o'chirish (faqat muallifi).
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) {
    return _chats.doc(chatId).collection('messages').doc(messageId).delete();
  }
}
