import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/dashboard_theme.dart';
import '../../../../core/constants.dart';

class ActionControls extends ConsumerStatefulWidget {
  final String incidentId;

  const ActionControls({super.key, required this.incidentId});

  @override
  ConsumerState<ActionControls> createState() => _ActionControlsState();
}

class _ActionControlsState extends ConsumerState<ActionControls> {
  final _noteCtrl = TextEditingController();
  bool _sending = false;
  int? _selectedEtaMinutes;

  // ETA options for dropdown
  final List<int> _etaOptions = [1, 2, 3, 5, 10, 15, 20, 30];

  bool get _hasIncident =>
      widget.incidentId.isNotEmpty && widget.incidentId != '-';

  Future<void> _patchStatus(String status, {int? etaMinutes}) async {
    if (!_hasIncident) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Staff user is not signed in');
      }

      final idToken = await user.getIdToken();
      final uri = Uri.parse(
        '${DashboardConstants.backendBaseUrl}/api/incidents/${widget.incidentId}/status',
      );
      final body = <String, dynamic>{'status': status};
      if (etaMinutes != null) {
        body['etaMinutes'] = etaMinutes;
      }

      final response = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        throw Exception(_extractBackendError(response.body,
            fallback: 'Status update failed'));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Status updated to $status${etaMinutes != null ? ' - ETA: $etaMinutes min' : ''}'),
          backgroundColor: kDashSurface,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: kDashDanger.withValues(alpha: 0.8),
        ));
      }
    }
  }

  Future<void> _logAction() async {
    final action = _noteCtrl.text.trim();
    if (action.isEmpty || !_hasIncident) {
      if (mounted && action.isNotEmpty && !_hasIncident) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Select an active incident first'),
        ));
      }
      return;
    }

    setState(() => _sending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Staff user is not signed in');
      }

      final idToken = await user.getIdToken();
      final uri = Uri.parse(
        '${DashboardConstants.backendBaseUrl}/api/incidents/${widget.incidentId}/log',
      );
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'action': action,
          'type': 'ACTION',
        }),
      );

      if (response.statusCode != 201) {
        throw Exception(
            _extractBackendError(response.body, fallback: 'Action log failed'));
      }

      _noteCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Action logged'),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to log: $e'),
          backgroundColor: kDashDanger.withValues(alpha: 0.8),
        ));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  String _extractBackendError(String body, {required String fallback}) {
    try {
      final parsed = jsonDecode(body) as Map<String, dynamic>;
      final error = parsed['error']?.toString();
      if (error != null && error.isNotEmpty) {
        return error;
      }
    } catch (_) {}
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: glassSurfaceDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.handshake_outlined,
                color: kDashAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'INCIDENT ACTIONS',
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
          // ETA Selection Row
          Row(
            children: [
              Text(
                'ETA (min):',
                style: GoogleFonts.inter(
                  color: kDashText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: kDashSurface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kDashBorder),
                ),
                child: DropdownButton<int>(
                  value: _selectedEtaMinutes,
                  hint: const Text('Select'),
                  dropdownColor: kDashSurface,
                  style: GoogleFonts.inter(
                    color: kDashText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  underline: const SizedBox(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  items: _etaOptions.map((eta) {
                    return DropdownMenuItem<int>(
                      value: eta,
                      child: Text('$eta min'),
                    );
                  }).toList(),
                  onChanged: _hasIncident
                      ? (value) {
                          setState(() {
                            _selectedEtaMinutes = value;
                          });
                        }
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: kDashInfo.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _hasIncident
                        ? () {
                            if (_selectedEtaMinutes == null) {
                              // Show confirmation if no ETA selected
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: kDashSurface,
                                  title: const Text(
                                    'Acknowledge without ETA?',
                                    style: TextStyle(color: kDashText),
                                  ),
                                  content: const Text(
                                    'Set an ETA so the guest knows when help will arrive.',
                                    style: TextStyle(color: kDashTextMut),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        _patchStatus('ACKNOWLEDGED');
                                      },
                                      child: const Text('Acknowledge Anyway'),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              _patchStatus('ACKNOWLEDGED',
                                  etaMinutes: _selectedEtaMinutes);
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kDashInfo.withValues(alpha: 0.8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'ACKNOWLEDGE',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: kDashGreen.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed:
                        _hasIncident ? () => _patchStatus('RESOLVED') : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kDashGreen.withValues(alpha: 0.8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_alt, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'RESOLVE',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _noteCtrl,
                  enabled: _hasIncident,
                  style: GoogleFonts.inter(color: kDashText),
                  decoration: InputDecoration(
                    hintText: _hasIncident
                        ? 'Add responder note...'
                        : 'Select an incident first',
                    hintStyle: GoogleFonts.inter(
                      color: kDashTextSub.withValues(alpha: 0.5),
                    ),
                    prefixIcon: const Icon(Icons.edit_note, size: 18),
                    prefixIconColor: kDashTextSub,
                  ),
                  onSubmitted: (_) => _logAction(),
                ),
              ),
              const SizedBox(width: 10),
              _sending
                  ? const SizedBox(
                      width: 44,
                      height: 44,
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
                        onPressed: _hasIncident ? _logAction : null,
                        style: IconButton.styleFrom(
                          backgroundColor: kDashAccent.withValues(alpha: 0.8),
                          foregroundColor: kDashBg,
                          minimumSize: const Size(44, 44),
                        ),
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}
