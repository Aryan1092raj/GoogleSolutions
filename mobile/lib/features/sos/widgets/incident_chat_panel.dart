import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme.dart';
import '../../auth/providers/auth_provider.dart';

class IncidentChatPanel extends StatefulWidget {
  final String incidentId;
  final GuestProfile? profile;

  const IncidentChatPanel({
    super.key,
    required this.incidentId,
    required this.profile,
  });

  @override
  State<IncidentChatPanel> createState() => _IncidentChatPanelState();
}

class _IncidentChatPanelState extends State<IncidentChatPanel> {
  final TextEditingController _messageCtrl = TextEditingController();
  bool _sending = false;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _messagesStream;

  @override
  void initState() {
    super.initState();
    _messagesStream = FirebaseFirestore.instance
        .collection('incidents')
        .doc(widget.incidentId)
        .collection('chat_messages')
        .orderBy('createdAtMs')
        .snapshots();
  }

  Future<void> _sendReply() async {
    final text = _messageCtrl.text.trim();
    final user = FirebaseAuth.instance.currentUser;
    if (text.isEmpty || user == null) {
      return;
    }

    setState(() => _sending = true);
    try {
      final senderLabel = widget.profile?.guestName.isNotEmpty == true
          ? widget.profile!.guestName
          : 'Guest';
      await FirebaseFirestore.instance
          .collection('incidents')
          .doc(widget.incidentId)
          .collection('chat_messages')
          .add({
        'incidentId': widget.incidentId,
        'senderId': user.uid,
        'senderRole': 'GUEST',
        'senderLabel': senderLabel,
        'text': text,
        'createdAtMs': DateTime.now().millisecondsSinceEpoch,
      });
      _messageCtrl.clear();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Message failed: $error')),
        );
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF07141F).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'RESCUE CHANNEL',
                  style: GoogleFonts.inter(
                    color: kTextMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: kSecondary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'LIVE STAFF CHAT',
                    style: GoogleFonts.inter(
                      color: kSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 170,
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _messagesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: kSecondary),
                    );
                  }

                  final docs = snapshot.data?.docs ?? const [];
                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.mark_chat_unread_outlined,
                            color: Colors.white.withValues(alpha: 0.4),
                            size: 26,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Security can message you here.',
                            style: GoogleFonts.inter(
                              color: kTextMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final isGuest = data['senderRole'] == 'GUEST';
                      final label = data['senderLabel']?.toString() ??
                          (isGuest ? 'You' : 'Security Desk');
                      final text = data['text']?.toString() ?? '';
                      final createdAtMs =
                          (data['createdAtMs'] as num?)?.toInt() ?? 0;

                      return Align(
                        alignment: isGuest
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isGuest
                                  ? kSecondary.withValues(alpha: 0.18)
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isGuest
                                    ? kSecondary.withValues(alpha: 0.24)
                                    : Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      label.toUpperCase(),
                                      style: GoogleFonts.inter(
                                        color: isGuest ? kSecondary : kTextMuted,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _timeLabel(createdAtMs),
                                      style: GoogleFonts.inter(
                                        color: kTextMuted,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  text,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageCtrl,
                    minLines: 1,
                    maxLines: 2,
                    enabled: !_sending,
                    decoration: const InputDecoration(
                      hintText: 'Reply to security team...',
                    ),
                    onSubmitted: (_) => _sendReply(),
                  ),
                ),
                const SizedBox(width: 10),
                _sending
                    ? const SizedBox(
                        width: 42,
                        height: 42,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton.filled(
                        onPressed: _sendReply,
                        style: IconButton.styleFrom(
                          backgroundColor: kSecondary,
                          foregroundColor: kBackground,
                          minimumSize: const Size(48, 48),
                        ),
                        icon: const Icon(Icons.arrow_upward_rounded),
                      ),
              ],
            ),
          ],
        ),
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
