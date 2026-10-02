import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/chat_message_model.dart';
import '../../models/public_profile_model.dart';
import '../../providers/chat_provider.dart';
import '../../providers/core_providers.dart';
import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/time_utils.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/user_avatar.dart';

/// Ikki kishilik suhbat.
///
/// Ro'yxat `reverse: true` bilan chiziladi: eng yangi xabar pastda turadi
/// va yangi xabar kelganda ekran o'zi eng pastda qoladi — qo'lda scroll
/// boshqarish shart emas.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.peer});

  final PublicProfile peer;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  ChatMessage? _replyTo;
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final String text = _controller.text.trim();
    final String? userId = ref.read(currentUserIdProvider);
    if (text.isEmpty || userId == null || _isSending) return;

    setState(() => _isSending = true);
    final ChatMessage? replyTo = _replyTo;
    _controller.clear();

    try {
      await ref
          .read(chatServiceProvider)
          .sendMessage(
            currentUserId: userId,
            otherUserId: widget.peer.userId,
            text: text,
            replyTo: replyTo,
          );
      if (!mounted) return;
      setState(() => _replyTo = null);
      // `reverse: true` bo'lgani uchun eng past nuqta — offset 0.
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      // Yuborilmagan matn yo'qolmasin.
      _controller.text = text;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Xabar yuborilmadi: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _startReply(ChatMessage message) {
    setState(() => _replyTo = message);
    _focusNode.requestFocus();
  }

  Future<void> _showMessageActions(ChatMessage message, bool isMine) async {
    final CustomTheme theme = context.theme;
    final String? action = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(IconsaxPlusLinear.undo, color: theme.blue),
              title: const Text('Javob berish'),
              onTap: () => Navigator.of(context).pop('reply'),
            ),
            ListTile(
              leading: Icon(IconsaxPlusLinear.copy, color: theme.blue),
              title: const Text('Nusxalash'),
              onTap: () => Navigator.of(context).pop('copy'),
            ),
            if (isMine)
              ListTile(
                leading: Icon(IconsaxPlusLinear.trash, color: theme.red),
                title: Text('O\'chirish', style: TextStyle(color: theme.red)),
                onTap: () => Navigator.of(context).pop('delete'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;

    switch (action) {
      case 'reply':
        _startReply(message);
      case 'copy':
        await Clipboard.setData(ClipboardData(text: message.text));
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Matn nusxalandi')));
      case 'delete':
        final String? userId = ref.read(currentUserIdProvider);
        if (userId == null) return;
        await ref
            .read(chatServiceProvider)
            .deleteMessage(
              chatId: ChatService.chatIdFor(userId, widget.peer.userId),
              messageId: message.id,
            );
    }
  }

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;
    final String? userId = ref.watch(currentUserIdProvider);

    if (userId == null) {
      return const Scaffold(
        body: Center(child: ErrorView(message: 'Sessiya tugagan.')),
      );
    }

    final String chatId = ChatService.chatIdFor(userId, widget.peer.userId);
    final AsyncValue<List<ChatMessage>> messagesAsync = ref.watch(
      chatMessagesProvider(chatId),
    );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: <Widget>[
            UserAvatar(
              initials: widget.peer.initials,
              base64: widget.peer.avatarBase64,
              size: 36,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.peer.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.mainDarkBlue,
                ),
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: messagesAsync.when(
                loading: () =>
                    Center(child: CircularProgressIndicator(color: theme.blue)),
                error: (Object e, StackTrace _) =>
                    ErrorView(message: 'Xabarlar yuklanmadi: $e'),
                data: (List<ChatMessage> messages) {
                  if (messages.isEmpty) {
                    return EmptyState(
                      icon: IconsaxPlusLinear.message,
                      title: 'Suhbat hali boshlanmagan',
                      message:
                          '${widget.peer.fullName} bilan birinchi xabarni '
                          'siz yozing.',
                    );
                  }
                  return _buildMessageList(messages, userId);
                },
              ),
            ),
            if (_replyTo != null) _buildReplyPreview(theme, userId),
            _buildComposer(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(List<ChatMessage> messages, String userId) {
    return ListView.builder(
      controller: _scrollController,
      // Eng yangi xabar pastda: ro'yxat teskari chiziladi.
      reverse: true,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      itemCount: messages.length,
      itemBuilder: (BuildContext context, int index) {
        final ChatMessage message = messages[index];
        // Teskari ro'yxatda "keyingi element" — vaqt bo'yicha oldingisi.
        final ChatMessage? older = index + 1 < messages.length
            ? messages[index + 1]
            : null;

        final bool showDaySeparator = _needsDaySeparator(message, older);
        final bool isMine = message.senderId == userId;

        return Column(
          children: <Widget>[
            if (showDaySeparator) _buildDaySeparator(message.createdAt),
            _MessageBubble(
              message: message,
              isMine: isMine,
              peerName: widget.peer.fullName,
              onLongPress: () => _showMessageActions(message, isMine),
              onSwipeReply: () => _startReply(message),
            ),
          ],
        );
      },
    );
  }

  static bool _needsDaySeparator(ChatMessage current, ChatMessage? older) {
    final DateTime? at = current.createdAt;
    if (at == null) return false;
    if (older?.createdAt == null) return true;
    return !TimeUtils.isSameDay(at, older!.createdAt!);
  }

  Widget _buildDaySeparator(DateTime? at) {
    final CustomTheme theme = context.theme;
    if (at == null) return const SizedBox.shrink();

    final DateTime now = DateTime.now();
    final String label = TimeUtils.isSameDay(at, now)
        ? 'Bugun'
        : TimeUtils.isSameDay(at, now.subtract(const Duration(days: 1)))
        ? 'Kecha'
        : Formatters.longDate(at);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: theme.gray,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.borderGray),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 11, color: theme.textGray),
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreview(CustomTheme theme, String userId) {
    final ChatMessage reply = _replyTo!;
    final bool replyingToMe = reply.senderId == userId;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: theme.gray,
        border: Border(top: BorderSide(color: theme.borderGray)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 3,
            height: 34,
            decoration: BoxDecoration(
              color: theme.blue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  replyingToMe ? 'Siz' : widget.peer.fullName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.blue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reply.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: theme.textGray),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(IconsaxPlusLinear.close_circle, size: 16, color: theme.textGray),
            onPressed: () => setState(() => _replyTo = null),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer(CustomTheme theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: theme.background,
        border: Border(top: BorderSide(color: theme.borderGray)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                minLines: 1,
                maxLines: 5,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(fontSize: 14, color: theme.mainDarkBlue),
                decoration: InputDecoration(
                  hintText: 'Xabar yozing...',
                  counterText: '',
                  filled: true,
                  fillColor: theme.inputColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(color: theme.borderGray),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(color: theme.borderGray),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(color: theme.blue, width: 1.4),
                  ),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _SendButton(
            enabled: _controller.text.trim().isNotEmpty && !_isSending,
            isSending: _isSending,
            onTap: _send,
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.enabled,
    required this.isSending,
    required this.onTap,
  });

  final bool enabled;
  final bool isSending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;
    return Material(
      color: enabled ? theme.blue : theme.borderGray,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 46,
          height: 46,
          child: isSending
              ? Padding(
                  padding: const EdgeInsets.all(13),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      CustomTheme.onAccent,
                    ),
                  ),
                )
              : Icon(
                  IconsaxPlusBold.send_2,
                  size: 18,
                  color: enabled ? CustomTheme.onAccent : theme.textGray,
                ),
        ),
      ),
    );
  }
}

/// Bitta xabar puffagi. Chapga surish orqali ham javob berish mumkin.
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.peerName,
    required this.onLongPress,
    required this.onSwipeReply,
  });

  final ChatMessage message;
  final bool isMine;
  final String peerName;
  final VoidCallback onLongPress;
  final VoidCallback onSwipeReply;

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;
    final Color bubbleColor = isMine ? theme.blue : theme.background;
    final Color textColor = isMine ? CustomTheme.onAccent : theme.mainDarkBlue;

    return Dismissible(
      key: ValueKey<String>('swipe-${message.id}'),
      direction: DismissDirection.startToEnd,
      // O'chirmaymiz — surish faqat "javob berish" ishorasi.
      confirmDismiss: (DismissDirection _) async {
        onSwipeReply();
        return false;
      },
      background: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Icon(IconsaxPlusLinear.undo, size: 18, color: theme.textGray),
        ),
      ),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: onLongPress,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.76,
            ),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 7),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMine ? 16 : 4),
                bottomRight: Radius.circular(isMine ? 4 : 16),
              ),
              border: isMine ? null : Border.all(color: theme.borderGray),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (message.isReply) _buildQuote(theme, textColor),
                Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 3),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    message.createdAt == null
                        ? ''
                        : Formatters.time(message.createdAt!),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMine
                          ? CustomTheme.onAccentMuted
                          : theme.textGray,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuote(CustomTheme theme, Color textColor) {
    final Color quoteBg = isMine
        ? CustomTheme.onAccentOverlay
        : theme.inputColor;
    final Color accent = isMine ? CustomTheme.onAccent : theme.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(9, 6, 9, 6),
      decoration: BoxDecoration(
        color: quoteBg,
        borderRadius: BorderRadius.circular(9),
        border: Border(left: BorderSide(color: accent, width: 2.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            message.replyToSenderId == message.senderId
                ? (isMine ? 'Siz' : peerName)
                : (isMine ? peerName : 'Siz'),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            message.replyToText ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              height: 1.3,
              color: isMine ? CustomTheme.onAccentMuted : theme.textGray,
            ),
          ),
        ],
      ),
    );
  }
}
