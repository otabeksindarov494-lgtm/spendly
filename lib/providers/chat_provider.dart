import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_message_model.dart';
import '../models/public_profile_model.dart';
import '../services/chat_service.dart';
import 'core_providers.dart';

final Provider<ChatService> chatServiceProvider = Provider<ChatService>(
  (Ref ref) => ChatService(ref.watch(firestoreProvider)),
);

/// Ro'yxatdan o'tgan barcha foydalanuvchilar (o'zidan tashqari).
final StreamProvider<List<PublicProfile>> chatUsersProvider =
    StreamProvider<List<PublicProfile>>((Ref ref) {
  final String? userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream<List<PublicProfile>>.value(<PublicProfile>[]);
  }
  return ref.watch(chatServiceProvider).watchUsers(userId);
});

/// Suhbatlar bo'yicha oxirgi xabar ma'lumoti (chatId -> xulosa).
final StreamProvider<Map<String, ChatSummary>> myChatsProvider =
    StreamProvider<Map<String, ChatSummary>>((Ref ref) {
  final String? userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream<Map<String, ChatSummary>>.value(<String, ChatSummary>{});
  }
  return ref.watch(chatServiceProvider).watchMyChats(userId);
});

/// Foydalanuvchilar oxirgi yozishmaga qarab saralangan ro'yxat.
///
/// Yozishmasi borlar yuqorida (eng yangisi birinchi), qolganlari
/// ism bo'yicha alifbo tartibida.
class ChatListEntry {
  const ChatListEntry({required this.profile, this.summary});

  final PublicProfile profile;
  final ChatSummary? summary;
}

final Provider<List<ChatListEntry>> chatListProvider =
    Provider<List<ChatListEntry>>((Ref ref) {
  final String? userId = ref.watch(currentUserIdProvider);
  final List<PublicProfile> users =
      ref.watch(chatUsersProvider).value ?? <PublicProfile>[];
  final Map<String, ChatSummary> chats =
      ref.watch(myChatsProvider).value ?? <String, ChatSummary>{};
  if (userId == null) return <ChatListEntry>[];

  final List<ChatListEntry> entries = users
      .map(
        (PublicProfile profile) => ChatListEntry(
          profile: profile,
          summary: chats[ChatService.chatIdFor(userId, profile.userId)],
        ),
      )
      .toList();

  entries.sort((ChatListEntry a, ChatListEntry b) {
    final DateTime? aAt = a.summary?.lastMessageAt;
    final DateTime? bAt = b.summary?.lastMessageAt;
    if (aAt != null && bAt != null) return bAt.compareTo(aAt);
    if (aAt != null) return -1;
    if (bAt != null) return 1;
    return a.profile.fullName
        .toLowerCase()
        .compareTo(b.profile.fullName.toLowerCase());
  });

  return entries;
});

/// Bitta suhbat xabarlari.
// Tip ataylab yozilmagan: `StreamProvider.family` qaytaradigan tip
// flutter_riverpod'dan eksport qilinmagan, shuning uchun inferensiya.
final chatMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((Ref ref, String chatId) {
  return ref.watch(chatServiceProvider).watchMessages(chatId);
});
