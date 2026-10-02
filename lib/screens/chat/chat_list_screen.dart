import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/chat_message_model.dart';
import '../../models/public_profile_model.dart';
import '../../providers/chat_provider.dart';
import '../../providers/core_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/time_utils.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/shimmer_box.dart';
import '../../widgets/common/user_avatar.dart';
import 'chat_screen.dart';

/// Chat tabi: ro'yxatdan o'tgan foydalanuvchilar ro'yxati.
///
/// Yozishmasi borlar yuqorida (oxirgi xabar vaqti bo'yicha), qolganlari
/// alifbo tartibida.
class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<PublicProfile>> usersAsync = ref.watch(
      chatUsersProvider,
    );
    final List<ChatListEntry> entries = ref.watch(chatListProvider);
    final String? currentUserId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: SafeArea(
        top: false,
        child: usersAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: ShimmerList(itemCount: 6, itemHeight: 64),
          ),
          error: (Object e, StackTrace _) =>
              ErrorView(message: 'Foydalanuvchilar yuklanmadi: $e'),
          data: (List<PublicProfile> users) {
            if (entries.isEmpty) {
              return const EmptyState(
                icon: IconsaxPlusLinear.profile_2user,
                title: 'Hozircha boshqa foydalanuvchi yo\'q',
                message:
                    'Kimdir ro\'yxatdan o\'tib profilini to\'ldirgach, shu '
                    'yerda paydo bo\'ladi.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: entries.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(height: 2),
              itemBuilder: (BuildContext context, int index) => _UserTile(
                entry: entries[index],
                currentUserId: currentUserId,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.entry, required this.currentUserId});

  final ChatListEntry entry;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;
    final PublicProfile profile = entry.profile;
    final ChatSummary? summary = entry.summary;
    final bool isMine = summary?.lastSenderId == currentUserId;

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => ChatScreen(peer: profile),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: <Widget>[
            UserAvatar(
              initials: profile.initials,
              base64: profile.avatarBase64,
              size: 48,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    profile.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.mainDarkBlue,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    summary?.lastMessage == null
                        ? 'Suhbatni boshlang'
                        : '${isMine ? 'Siz: ' : ''}${summary!.lastMessage}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: summary?.lastMessage == null
                          ? theme.favoriteGray
                          : theme.textGray,
                    ),
                  ),
                ],
              ),
            ),
            if (summary?.lastMessageAt != null) ...<Widget>[
              const SizedBox(width: 10),
              Text(
                _timeLabel(summary!.lastMessageAt!),
                style: TextStyle(fontSize: 11, color: theme.textGray),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Bugungi xabar uchun soat, aks holda sana.
  static String _timeLabel(DateTime at) {
    return TimeUtils.isSameDay(at, DateTime.now())
        ? Formatters.time(at)
        : Formatters.shortDayLabel(at);
  }
}
