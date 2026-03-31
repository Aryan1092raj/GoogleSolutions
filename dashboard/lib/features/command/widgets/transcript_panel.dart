import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/dashboard_theme.dart';

class TranscriptPanel extends StatefulWidget {
  final String incidentId;

  const TranscriptPanel({super.key, required this.incidentId});

  @override
  State<TranscriptPanel> createState() => _TranscriptPanelState();
}

class _TranscriptPanelState extends State<TranscriptPanel> {
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _incidentStream;

  @override
  void initState() {
    super.initState();
    _syncIncidentStream();
  }

  @override
  void didUpdateWidget(covariant TranscriptPanel oldWidget) {
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
            'No incident selected',
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
          final data = snapshot.data!.data() ?? {};
          final original = data['originalTranscript']?.toString() ?? '';
          final translated = data['translatedTranscript']?.toString() ?? '';
          final lang = data['detectedLanguage']?.toString() ?? 'en';
          final aiStatus = data['aiStatus']?.toString() ?? 'PENDING';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.translate,
                    color: kDashAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'TRANSCRIPT',
                    style: GoogleFonts.inter(
                      color: kDashTextMut,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (original.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0x0DFFFFFF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kDashBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: kDashAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              lang.toUpperCase(),
                              style: GoogleFonts.inter(
                                color: kDashAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Original',
                            style: GoogleFonts.inter(
                              color: kDashTextMut,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        original,
                        style: GoogleFonts.inter(
                          color: kDashText,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kDashAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: kDashAccent.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.arrow_forward,
                            color: kDashAccent,
                            size: 12,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'English Translation',
                            style: GoogleFonts.inter(
                              color: kDashAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        translated,
                        style: GoogleFonts.inter(
                          color: kDashText,
                          fontSize: 13,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      _emptyStateFor(aiStatus),
                      style: GoogleFonts.inter(
                        color: kDashTextSub,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _emptyStateFor(String aiStatus) {
    switch (aiStatus.toUpperCase()) {
      case 'UNAVAILABLE':
        return 'Transcript unavailable because AI analysis is offline.';
      case 'DEGRADED':
        return 'Transcript pending while fallback AI mode runs.';
      case 'AVAILABLE':
        return 'No transcript captured yet.';
      case 'PENDING':
      default:
        return 'Awaiting transcript...';
    }
  }
}
