import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/dashboard_theme.dart';
import '../providers/incident_provider.dart';

class CommandChatPanel extends ConsumerStatefulWidget {
  final String incidentId;

  const CommandChatPanel({super.key, required this.incidentId});

  @override
  ConsumerState<CommandChatPanel> createState() => _CommandChatPanelState();
}

class _CommandChatPanelState extends ConsumerState<CommandChatPanel> {
  final _messageCtrl = TextEditingController();
  bool _sending = false;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _messagesStream;

  bool get _hasIncident =>
      widget.incidentId.isNotEmpty && widget.incidentId != '-';

  @override
  void initState() {
    super.initState();
    _syncMessagesStream();
  }

  @override
  void didUpdateWidget(covariant CommandChatPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.incidentId != widget.incidentId) {
      _syncMessagesStream();
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (!_hasIncident || text.isEmpty) {
      return;
    }

    setState(() => _sending = true);
    try {
      final profile = ref.read(staffProfileProvider);
      await FirebaseFirestore.instance
          .collection('incidents')
          .doc(widget.incidentId)
          .collection('chat_messages')
          .add({
        'incidentId': widget.incidentId,
        'senderId': profile.uid,
        'senderRole': 'STAFF',
        'senderLabel':
            profile.role.isEmpty ? 'Security Desk' : profile.role,
        'text': text,
        'createdAtMs': DateTime.now().millisecondsSinceEpoch,
      });
      _messageCtrl.clear();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to send message: $error'),
          backgroundColor: kDashDanger,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  void _syncMessagesStream() {
    _messagesStream = _hasIncident
        ? FirebaseFirestore.instance
            .collection('incidents')
            .doc(widget.incidentId)
            .collection('chat_messages')
            .orderBy('createdAtMs')
            .snapshots()
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: glassSurfaceDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.forum_outlined,
                color: kDashAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'COMMAND THREAD',
                style: GoogleFonts.inter(
                  color: kDashTextMut,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.6,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: kDashAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: kDashAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _hasIncident ? 'SECURE LINK' : 'NO INCIDENT',
                  style: GoogleFonts.inter(
                    color: _hasIncident ? kDashAccent : kDashTextMut,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: !_hasIncident
                ? const _EmptyThread(
                    title: 'Select an incident',
                    subtitle:
                        'Messages sent here appear on the guest SOS screen.',
                  )
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _messagesStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final docs = snapshot.data?.docs ?? const [];
                      if (docs.isEmpty) {
                        return const _EmptyThread(
                          title: 'Open the channel',
                          subtitle:
                              'Send a calm instruction or ask what the guest can see.',
                        );
                      }

                      return ListView.separated(
                        itemCount: docs.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final data = docs[index].data();
                          final isStaff = data['senderRole'] == 'STAFF';
                          final label =
                              data['senderLabel']?.toString() ??
                                  (isStaff ? 'Security Desk' : 'Guest');
                          final text = data['text']?.toString() ?? '';
                          final createdAtMs =
                              (data['createdAtMs'] as num?)?.toInt() ?? 0;

                          return Align(
                            alignment: isStaff
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxWidth: 280),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isStaff
                                      ? kDashAccent.withValues(alpha: 0.12)
                                      : const Color(0x0DFFFFFF),
                                  borderRadius:
                                      BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isStaff
                                        ? kDashAccent
                                            .withValues(alpha: 0.3)
                                        : kDashBorder,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          label.toUpperCase(),
                                          style: GoogleFonts.inter(
                                            color: isStaff
                                                ? kDashAccent
                                                : kDashTextSub,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          _timeLabel(createdAtMs),
                                          style: GoogleFonts.inter(
                                            color: kDashTextMut,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      text,
                                      style: GoogleFonts.inter(
                                        color: kDashText,
                                        fontSize: 13,
                                        height: 1.45,
                                      ),
                                    ),
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageCtrl,
                  enabled: _hasIncident && !_sending,
                  minLines: 1,
                  maxLines: 3,
                  style: GoogleFonts.inter(color: kDashText),
                  decoration: InputDecoration(
                    hintText:
                        'Send a calm instruction or ask for details...',
                    hintStyle: GoogleFonts.inter(
                      color: kDashTextSub.withValues(alpha: 0.5),
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 10),
              _sending
                  ? const SizedBox(
                      width: 42,
                      height: 42,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: kDashAccent.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton.filled(
                        onPressed: _hasIncident ? _sendMessage : null,
                        style: IconButton.styleFrom(
                          backgroundColor:
                              kDashAccent.withValues(alpha: 0.8),
                          foregroundColor: kDashBg,
                          minimumSize: const Size(44, 44),
                        ),
                        icon: const Icon(Icons.north_east_rounded),
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  String _timeLabel(int createdAtMs) {
    if (createdAtMs <= 0) {
      return '--:--';
    }
    final dateTime = DateTime.fromMillisecondsSinceEpoch(createdAtMs);
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _EmptyThread extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyThread({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0x0DFFFFFF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: kDashBorder),
                    ),
                    child: const Icon(
                      Icons.forum_outlined,
                      color: kDashTextSub,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: GoogleFonts.fustat(
                      color: kDashText,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: kDashTextSub,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
