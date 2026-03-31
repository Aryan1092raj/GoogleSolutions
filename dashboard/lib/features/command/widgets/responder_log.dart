import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/dashboard_theme.dart';

class ResponderLog extends StatefulWidget {
  final String incidentId;

  const ResponderLog({super.key, required this.incidentId});

  @override
  State<ResponderLog> createState() => _ResponderLogState();
}

class _ResponderLogState extends State<ResponderLog> {
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _incidentStream;

  @override
  void initState() {
    super.initState();
    _syncIncidentStream();
  }

  @override
  void didUpdateWidget(covariant ResponderLog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.incidentId != widget.incidentId) {
      _syncIncidentStream();
    }
  }

  void _syncIncidentStream() {
    _incidentStream = widget.incidentId.isEmpty || widget.incidentId == '-'
        ? null
        : FirebaseFirestore.instance
            .collection('incidents')
            .doc(widget.incidentId)
            .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.incidentId.isEmpty || widget.incidentId == '-') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: glassSurfaceDecoration,
        child: Center(
          child: Text(
            'Select an incident to view responder log',
            style: GoogleFonts.inter(
              color: kDashTextSub,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: glassSurfaceDecoration,
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _incidentStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          final data = snapshot.data!.data() ?? <String, dynamic>{};
          final rawHistory = data['actionHistory'] as List<dynamic>? ?? <dynamic>[];
          final rawLog = data['responderLog'] as List<dynamic>? ?? <dynamic>[];
          final entries = (rawHistory.isNotEmpty ? rawHistory : rawLog)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList()
              .reversed
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.history,
                    color: kDashAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'RESPONDER LOG',
                    style: GoogleFonts.inter(
                      color: kDashTextMut,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (entries.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'No responder log entries yet',
                      style: GoogleFonts.inter(
                        color: kDashTextSub,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final title =
                          entry['title']?.toString() ?? _fallbackTitle(entry);
                      final detail = entry['detail']?.toString() ??
                          entry['action']?.toString() ?? '';
                      final staffName =
                          entry['actorLabel']?.toString() ??
                              entry['staffName']?.toString() ??
                              'System';
                      final timestamp = entry['timestamp']?.toString() ?? '';
                      final type = entry['type']?.toString() ?? 'ACTION';

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0x0DFFFFFF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kDashBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.history,
                                  color: kDashAccent,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: GoogleFonts.inter(
                                      color: kDashText,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (detail.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  detail,
                                  style: GoogleFonts.inter(
                                    color: kDashTextSub,
                                    fontSize: 12,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            Text(
                              '$staffName • $type${timestamp.isNotEmpty ? ' • $timestamp' : ''}',
                              style: GoogleFonts.inter(
                                color: kDashTextMut,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _fallbackTitle(Map<String, dynamic> entry) {
    final type = entry['type']?.toString() ?? 'ACTION';
    switch (type) {
      case 'NOTE':
        return 'Responder note';
      case 'SYSTEM':
        return 'System event';
      case 'ACTION':
      default:
        return 'Responder action';
    }
  }
}
