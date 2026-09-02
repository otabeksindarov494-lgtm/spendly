import 'model_utils.dart';

/// `chats/{chatId}/messages/{messageId}`.
///
/// `participants` maydoni xabar hujjatida ham takrorlanadi — shunda
/// xavfsizlik qoidalarida `get()` chaqirish shart bo'lmaydi (har bir
/// xabarni o'qishda qo'shimcha hujjat o'qish xarajati tushardi).
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    this.createdAt,
    this.replyToId,
    this.replyToText,
    this.replyToSenderId,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime? createdAt;

  /// Javob berilayotgan xabar (bo'lsa).
  final String? replyToId;
  final String? replyToText;
  final String? replyToSenderId;

  bool get isReply => replyToId != null;

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    return ChatMessage(
      id: id,
      senderId: asString(map['senderId']) ?? '',
      text: asString(map['text']) ?? '',
      createdAt: asDateTime(map['createdAt']),
      replyToId: asString(map['replyToId']),
      replyToText: asString(map['replyToText']),
      replyToSenderId: asString(map['replyToSenderId']),
    );
  }
}

/// Suhbat haqidagi qisqa ma'lumot — chat ro'yxatidagi oxirgi xabar uchun.
class ChatSummary {
  const ChatSummary({
    required this.chatId,
    this.lastMessage,
    this.lastMessageAt,
    this.lastSenderId,
  });

  final String chatId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastSenderId;

  factory ChatSummary.fromMap(String chatId, Map<String, dynamic> map) {
    return ChatSummary(
      chatId: chatId,
      lastMessage: asString(map['lastMessage']),
      lastMessageAt: asDateTime(map['lastMessageAt']),
      lastSenderId: asString(map['lastSenderId']),
    );
  }
}
