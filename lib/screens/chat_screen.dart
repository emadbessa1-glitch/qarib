import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/chat_repository.dart';
import '../models/chat.dart';
import '../data/reports_repository.dart';
import '../services/auth_service.dart';
import '../widgets/report_dialog.dart';

/// شاشة المحادثة.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.chatId, required this.title});

  final String chatId;
  final String title;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final Stream<List<ChatMessage>> _messages;
  late final Stream<Chat?> _chat;
  final _text = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _messages = context.read<ChatRepository>().watchMessages(widget.chatId);
    _chat = context.read<ChatRepository>().watchChat(widget.chatId);
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.isEmpty || _sending) return;
    final myId = context.read<AuthService>().userId;
    if (myId == null) return;
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<ChatRepository>().send(widget.chatId, myId, text);
      _text.clear();
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('الرسالة ماتبعتتش، حاول تاني')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _toggleBlock(Chat chat, String myId) async {
    final repo = context.read<ChatRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final blocking = !chat.isBlocked;
    if (blocking) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('حظر المحادثة؟'),
          content: const Text(
              'محدش فيكم هيقدر يبعت رسايل في المحادثة دي لحد ما تفك الحظر.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('حظر'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    try {
      await repo.setBlocked(widget.chatId, blocking ? myId : null);
      messenger.showSnackBar(SnackBar(
        content: Text(blocking ? 'اتحظرت المحادثة' : 'اتفك الحظر'),
      ));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('العملية فشلت، حاول تاني')),
      );
    }
  }

  String _time(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.hour < 12 ? 'ص' : 'م'}';
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.watch<AuthService>().userId;
    final theme = Theme.of(context);

    return StreamBuilder<Chat?>(
      stream: _chat,
      builder: (context, chatSnap) {
        final chat = chatSnap.data;
        final otherId = chat == null || myId == null
            ? ''
            : (myId == chat.ownerId ? chat.userId : chat.ownerId);
        final blocked = chat?.isBlocked ?? false;
        final blockedByMe = chat?.blockedBy == myId;

        return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (chat != null && myId != null)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'block') _toggleBlock(chat, myId);
                if (v == 'report') {
                  showReportDialog(
                    context,
                    target: ReportTarget.chat,
                    placeId: chat.placeId,
                    chatId: chat.id,
                    reportedUserId: otherId,
                    excerpt: chat.lastMessage,
                  );
                }
              },
              itemBuilder: (_) => [
                if (!blocked || blockedByMe)
                  PopupMenuItem(
                    value: 'block',
                    child: Text(blockedByMe ? 'فك الحظر' : 'حظر'),
                  ),
                const PopupMenuItem(
                  value: 'report',
                  child: Text('إبلاغ عن المحادثة'),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _messages,
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(child: Text('حصلت مشكلة في التحميل'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snap.data!;
                if (messages.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('ابدأ المحادثة واكتب سؤالك',
                          textAlign: TextAlign.center),
                    ),
                  );
                }
                // reverse عشان آخر رسالة تبقى تحت على طول.
                return ListView.builder(
                  controller: _scroll,
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[messages.length - 1 - i];
                    final mine = m.senderId == myId;
                    return GestureDetector(
                      onLongPress: mine
                          ? null
                          : () => showReportDialog(
                                context,
                                target: ReportTarget.message,
                                placeId: chat?.placeId ?? '',
                                chatId: widget.chatId,
                                itemId: m.id,
                                reportedUserId: m.senderId,
                                excerpt: m.text,
                              ),
                      child: Align(
                      alignment: mine
                          ? AlignmentDirectional.centerEnd
                          : AlignmentDirectional.centerStart,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: mine
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.text),
                            const SizedBox(height: 2),
                            Text(_time(m.createdAt),
                                style: theme.textTheme.labelSmall),
                          ],
                        ),
                      ),
                    ),
                    );
                  },
                );
              },
            ),
          ),
          if (blocked)
            SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: theme.colorScheme.errorContainer,
                child: Text(
                  blockedByMe
                      ? 'إنت حظرت المحادثة دي. تقدر تفك الحظر من القايمة فوق.'
                      : 'المحادثة دي اتحظرت، ومش هتقدر تبعت رسايل.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            )
          else
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _text,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 1000,
                      textInputAction: TextInputAction.send,
                      decoration: const InputDecoration(
                        hintText: 'اكتب رسالة...',
                        counterText: '',
                        isDense: true,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'إرسال',
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }
}

/// قائمة محادثاتي.
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  Stream<List<Chat>>? _chats;
  String? _forUser;

  @override
  Widget build(BuildContext context) {
    final myId = context.watch<AuthService>().userId;
    if (myId != null && myId != _forUser) {
      _forUser = myId;
      _chats = context.read<ChatRepository>().watchMyChats(myId);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('المحادثات')),
      body: myId == null || _chats == null
          ? const Center(child: Text('سجّل الأول عشان تشوف محادثاتك'))
          : StreamBuilder<List<Chat>>(
              stream: _chats,
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(child: Text('حصلت مشكلة في التحميل'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final chats = snap.data!;
                if (chats.isEmpty) {
                  return const Center(child: Text('مفيش محادثات لسه'));
                }
                return ListView.separated(
                  itemCount: chats.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final c = chats[i];
                    final title = c.titleFor(myId);
                    final waiting = c.awaitingReplyFrom(myId);
                    return ListTile(
                      leading: CircleAvatar(
                        child: Icon(myId == c.ownerId
                            ? Icons.person
                            : Icons.storefront),
                      ),
                      title: Text(title,
                          style: waiting
                              ? const TextStyle(fontWeight: FontWeight.bold)
                              : null),
                      subtitle: Text(
                        [
                          if (myId == c.ownerId) c.placeName,
                          c.lastMessage.isEmpty ? 'لسه مفيش رسايل' : c.lastMessage,
                        ].join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: waiting
                          ? Icon(Icons.circle,
                              size: 12,
                              color: Theme.of(context).colorScheme.primary)
                          : null,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              ChatScreen(chatId: c.id, title: title),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
