import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../auth/providers/auth_provider.dart';

const _surface = kSurface;
const _surfaceHigh = kSurfaceHigh;
const _surfaceHighest = kSurfaceActive;
const _outlineVariant = Color(0x1FFFFFFF);
const _primary = kBrandBlue;
const _onSurface = kTextPrimary;
const _onSurfaceMuted = kTextMuted;
const _tertiary = kSecondary;

class IncidentChatPanel extends StatefulWidget {
  final String incidentId;
  final GuestProfile? profile;
  final bool expanded;

  const IncidentChatPanel({
    super.key,
    required this.incidentId,
    required this.profile,
    this.expanded = false,
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
    final panelHeight = widget.expanded ? 420.0 : 220.0;

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _surfaceHigh.withValues(alpha: 0.6),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: Border.all(color: Colors.transparent),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.security,
                  color: _tertiary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'HOTEL SECURITY DISPATCH',
                    style: TextStyle(
                      color: _onSurface,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _tertiary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: panelHeight,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: _primary,
                      strokeWidth: 2.0,
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? const [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Security can message you here.',
                      style: TextStyle(
                        color: _onSurfaceMuted,
                        fontSize: 13,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final isGuest = data['senderRole'] == 'GUEST';
                    final label = data['senderLabel']?.toString() ??
                        (isGuest ? 'You' : 'Dispatch');
                    final text = data['text']?.toString() ?? '';
                    final createdAtMs =
                        (data['createdAtMs'] as num?)?.toInt() ?? 0;

                    return Align(
                      alignment: isGuest
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 290),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isGuest
                                ? _primary.withValues(alpha: 0.12)
                                : _surfaceHighest,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              topRight: const Radius.circular(12),
                              bottomLeft: Radius.circular(isGuest ? 12 : 4),
                              bottomRight: Radius.circular(isGuest ? 4 : 12),
                            ),
                            border: Border.all(
                              color: isGuest
                                  ? _primary.withValues(alpha: 0.32)
                                  : _outlineVariant,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$label • ${_timeLabel(createdAtMs)}',
                                style: TextStyle(
                                  color: isGuest ? _primary : _onSurfaceMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                text,
                                style: const TextStyle(
                                  color: _onSurface,
                                  fontSize: 13,
                                  height: 1.4,
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: _outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageCtrl,
                    minLines: 1,
                    maxLines: 2,
                    enabled: !_sending,
                    style: const TextStyle(color: _onSurface, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(
                        color: _onSurfaceMuted,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: _surfaceHighest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _primary),
                      ),
                    ),
                    onSubmitted: (_) => _sendReply(),
                  ),
                ),
                const SizedBox(width: 8),
                _sending
                    ? const SizedBox(
                        width: 38,
                        height: 38,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _primary,
                        ),
                      )
                    : SizedBox(
                        width: 38,
                        height: 38,
                        child: ElevatedButton(
                          onPressed: _sendReply,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: const Icon(Icons.send, size: 18),
                        ),
                      ),
              ],
            ),
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
    final hour24 = dateTime.hour;
    final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $period';
  }
}
