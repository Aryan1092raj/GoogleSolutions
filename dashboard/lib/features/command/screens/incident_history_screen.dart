import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/dashboard_theme.dart';
import '../providers/incident_provider.dart';

class IncidentHistoryScreen extends ConsumerStatefulWidget {
  const IncidentHistoryScreen({super.key});

  @override
  ConsumerState<IncidentHistoryScreen> createState() =>
      _IncidentHistoryScreenState();
}

class _IncidentHistoryScreenState extends ConsumerState<IncidentHistoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _statusFilter = 'ALL';
  String _severityFilter = 'ALL';
  int _currentPage = 0;
  static const int _rowsPerPage = 12;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(incidentHistoryProvider);

    return Scaffold(
      backgroundColor: kDashBg,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kDashBg,
                    Color(0xFF071325),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                _HistorySidebar(
                  onLiveBoardTap: () => context.go('/dashboard'),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                    child: historyAsync.when(
                      data: (records) {
                        final filtered = _filteredRecords(records);
                        IncidentHistoryRecord? latestResolved;
                        for (final record in records) {
                          if (record.status == 'RESOLVED' ||
                              record.status == 'FALSE_ALARM') {
                            latestResolved = record;
                            break;
                          }
                        }
                        final stats = _statsFor(records);
                        final page = _paginated(filtered);
                        final highlightRecord = latestResolved;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTopHeader(filtered),
                            const SizedBox(height: 14),
                            if (highlightRecord != null) ...[
                              _ResolvedHighlightCard(
                                record: highlightRecord,
                                onOpen: () => context.go(
                                    '/incident/${highlightRecord.incidentId}'),
                              ),
                              const SizedBox(height: 14),
                            ],
                            _buildFilterRow(filtered),
                            const SizedBox(height: 14),
                            Expanded(
                              child: Container(
                                decoration: glassSurfaceDecoration,
                                child: Column(
                                  children: [
                                    _TableHeader(),
                                    const Divider(
                                        height: 1, color: kDashBorder),
                                    Expanded(
                                      child: page.items.isEmpty
                                          ? _EmptyState(
                                              hasActiveFilters: _hasFilters(),
                                            )
                                          : ListView.separated(
                                              itemCount: page.items.length,
                                              separatorBuilder: (_, __) =>
                                                  const Divider(
                                                height: 1,
                                                color: kDashBorder,
                                              ),
                                              itemBuilder: (context, index) {
                                                final row = page.items[index];
                                                return _HistoryRow(
                                                  record: row,
                                                  onTap: () => context.go(
                                                      '/incident/${row.incidentId}'),
                                                );
                                              },
                                            ),
                                    ),
                                    const Divider(
                                        height: 1, color: kDashBorder),
                                    _PaginationBar(
                                      pageStart: page.start,
                                      pageEnd: page.end,
                                      totalRows: filtered.length,
                                      currentPage: _currentPage,
                                      totalPages: page.totalPages,
                                      onPrevious: _currentPage == 0
                                          ? null
                                          : () {
                                              setState(() {
                                                _currentPage -= 1;
                                              });
                                            },
                                      onNext:
                                          _currentPage >= page.totalPages - 1
                                              ? null
                                              : () {
                                                  setState(() {
                                                    _currentPage += 1;
                                                  });
                                                },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _StatsRow(stats: stats),
                          ],
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (error, _) => Center(
                        child: Text(
                          'Failed to load incident history: $error',
                          style: GoogleFonts.inter(
                            color: kDashDanger,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader(List<IncidentHistoryRecord> filtered) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Incident History',
                style: GoogleFonts.fustat(
                  color: kDashText,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Archive of past incidents and system outcomes.',
                style: GoogleFonts.inter(
                  color: kDashTextSub,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 280,
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() => _currentPage = 0),
            style: GoogleFonts.inter(color: kDashText),
            decoration: InputDecoration(
              hintText: 'Search incidents...',
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _currentPage = 0);
                      },
                    ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: filtered.isEmpty ? null : () => _copyCsv(filtered),
          icon: const Icon(Icons.download, size: 16),
          label: const Text('Export CSV'),
        ),
      ],
    );
  }

  Widget _buildFilterRow(List<IncidentHistoryRecord> filtered) {
    return Row(
      children: [
        _FilterDropdown(
          label: 'Status',
          value: _statusFilter,
          options: const [
            'ALL',
            'RESOLVED',
            'FALSE_ALARM',
            'ACKNOWLEDGED',
            'ACTIVE',
          ],
          onChanged: (value) {
            setState(() {
              _statusFilter = value;
              _currentPage = 0;
            });
          },
        ),
        const SizedBox(width: 10),
        _FilterDropdown(
          label: 'Severity',
          value: _severityFilter,
          options: const ['ALL', 'CRITICAL', 'HIGH', 'MEDIUM', 'LOW'],
          onChanged: (value) {
            setState(() {
              _severityFilter = value;
              _currentPage = 0;
            });
          },
        ),
        const SizedBox(width: 12),
        if (_hasFilters())
          TextButton.icon(
            onPressed: () {
              _searchCtrl.clear();
              setState(() {
                _statusFilter = 'ALL';
                _severityFilter = 'ALL';
                _currentPage = 0;
              });
            },
            icon: const Icon(Icons.filter_alt_off, size: 16),
            label: const Text('Clear Filters'),
          ),
        const Spacer(),
        Text(
          '${filtered.length} records',
          style: GoogleFonts.inter(
            color: kDashTextSub,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  List<IncidentHistoryRecord> _filteredRecords(
      List<IncidentHistoryRecord> all) {
    final query = _searchCtrl.text.trim().toLowerCase();

    return all.where((record) {
      final statusMatch =
          _statusFilter == 'ALL' || record.status == _statusFilter;
      final severityMatch =
          _severityFilter == 'ALL' || record.severity == _severityFilter;

      if (!statusMatch || !severityMatch) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final haystack = [
        record.incidentId,
        record.guestName,
        record.roomNumber,
        record.wing,
        record.primaryHazard,
        record.aiSummary,
      ].join(' ').toLowerCase();

      return haystack.contains(query);
    }).toList();
  }

  _HistoryPage _paginated(List<IncidentHistoryRecord> rows) {
    if (rows.isEmpty) {
      return const _HistoryPage(
        items: <IncidentHistoryRecord>[],
        start: 0,
        end: 0,
        totalPages: 1,
      );
    }

    final totalPages = (rows.length / _rowsPerPage).ceil();
    final safePage = math.min(_currentPage, totalPages - 1);
    if (safePage != _currentPage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _currentPage = safePage);
        }
      });
    }

    final start = safePage * _rowsPerPage;
    final end = math.min(start + _rowsPerPage, rows.length);

    return _HistoryPage(
      items: rows.sublist(start, end),
      start: start + 1,
      end: end,
      totalPages: totalPages,
    );
  }

  bool _hasFilters() {
    return _statusFilter != 'ALL' ||
        _severityFilter != 'ALL' ||
        _searchCtrl.text.trim().isNotEmpty;
  }

  _HistoryStats _statsFor(List<IncidentHistoryRecord> rows) {
    if (rows.isEmpty) {
      return const _HistoryStats(
        averageResponseMs: 0,
        resolutionRate: 0,
        falseAlarmRate: 0,
      );
    }

    final resolvedOrClosed = rows
        .where((row) => row.status == 'RESOLVED' || row.status == 'FALSE_ALARM')
        .toList();
    final falseAlarms = rows.where((row) => row.status == 'FALSE_ALARM').length;

    int responseTotal = 0;
    int responseCount = 0;
    for (final row in resolvedOrClosed) {
      if (row.resolvedAtMs != null && row.createdAtMs > 0) {
        final delta = row.resolvedAtMs! - row.createdAtMs;
        if (delta > 0) {
          responseTotal += delta;
          responseCount += 1;
        }
      }
    }

    final averageResponseMs =
        responseCount == 0 ? 0 : (responseTotal / responseCount).round();
    final resolutionRate = (resolvedOrClosed.length / rows.length) * 100;
    final falseAlarmRate = (falseAlarms / rows.length) * 100;

    return _HistoryStats(
      averageResponseMs: averageResponseMs,
      resolutionRate: resolutionRate,
      falseAlarmRate: falseAlarmRate,
    );
  }

  Future<void> _copyCsv(List<IncidentHistoryRecord> rows) async {
    final buffer = StringBuffer();
    buffer.writeln(
      'incident_id,created_at,status,severity,room,floor,wing,guest_name,primary_hazard,ai_summary',
    );

    for (final row in rows) {
      buffer.writeln([
        _csv(row.incidentId),
        _csv(_dateTimeLabel(row.createdAtMs)),
        _csv(row.status),
        _csv(row.severity),
        _csv(row.roomNumber),
        _csv(row.floor.toString()),
        _csv(row.wing),
        _csv(row.guestName),
        _csv(row.primaryHazard),
        _csv(row.aiSummary),
      ].join(','));
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('CSV copied to clipboard (${rows.length} rows)'),
        backgroundColor: kDashSurface,
      ),
    );
  }

  String _csv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  String _dateLabel(int ms) {
    if (ms <= 0) {
      return '--';
    }
    final date = DateTime.fromMillisecondsSinceEpoch(ms);
    final month = _monthName(date.month);
    return '$month ${date.day}, ${date.year}';
  }

  String _timeLabel(int ms) {
    if (ms <= 0) {
      return '--:--';
    }
    final date = DateTime.fromMillisecondsSinceEpoch(ms);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final hour12 = ((date.hour + 11) % 12) + 1;
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour12:$minute $period';
  }

  String _dateTimeLabel(int ms) {
    if (ms <= 0) {
      return '';
    }
    return '${_dateLabel(ms)} ${_timeLabel(ms)}';
  }

  String _monthName(int month) {
    const names = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month < 1 || month > 12) {
      return '---';
    }
    return names[month - 1];
  }
}

class _HistorySidebar extends StatelessWidget {
  final VoidCallback onLiveBoardTap;

  const _HistorySidebar({required this.onLiveBoardTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      margin: const EdgeInsets.fromLTRB(12, 12, 0, 12),
      decoration: glassSurfaceDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Obsidian Security',
                  style: GoogleFonts.fustat(
                    color: kDashText,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: kDashGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'All Systems Nominal',
                      style: GoogleFonts.inter(
                        color: kDashTextSub,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: kDashBorder),
          const SizedBox(height: 8),
          _RailItem(
            label: 'Live Board',
            icon: Icons.sensors,
            selected: false,
            onTap: onLiveBoardTap,
          ),
          _RailItem(
            label: 'History',
            icon: Icons.history,
            selected: true,
            onTap: () {},
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x0DFFFFFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kDashBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined,
                      color: kDashAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'System Secure',
                      style: GoogleFonts.inter(
                        color: kDashText,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RailItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0x1AFFFFFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? kDashAccent.withValues(alpha: 0.45)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: selected ? kDashAccent : kDashTextSub),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                color: selected ? kDashAccent : kDashTextSub,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kDashBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: kDashSurface,
          style: GoogleFonts.inter(color: kDashText, fontSize: 12),
          iconEnabledColor: kDashTextSub,
          onChanged: (next) {
            if (next != null) {
              onChanged(next);
            }
          },
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Row(
                    children: [
                      Text(
                        '$label: ',
                        style: GoogleFonts.inter(
                          color: kDashTextSub,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(option),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          _headerCell('Incident ID', 1.4),
          _headerCell('Date & Time', 1.8),
          _headerCell('Location / Room', 1.6),
          _headerCell('Status', 1.3),
          _headerCell('Severity', 1.2),
          _headerCell('Details', 2.7),
        ],
      ),
    );
  }

  Widget _headerCell(String text, double flex) {
    return Expanded(
      flex: (flex * 100).round(),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: kDashTextMut,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ResolvedHighlightCard extends StatelessWidget {
  final IncidentHistoryRecord record;
  final VoidCallback onOpen;

  const _ResolvedHighlightCard({required this.record, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: glassSurfaceDecoration,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kDashGreen.withValues(alpha: 0.14),
              border: Border.all(color: kDashGreen.withValues(alpha: 0.35)),
            ),
            child: const Icon(Icons.task_alt, color: kDashGreen, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Latest resolved incident',
                  style: GoogleFonts.inter(
                    color: kDashTextMut,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${record.incidentId} • Room ${record.roomNumber} • ${record.guestName}',
                  style: GoogleFonts.inter(
                    color: kDashText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  record.aiSummary.isEmpty
                      ? 'Help has been notified and responders were on-site.'
                      : record.aiSummary,
                  style: GoogleFonts.inter(
                    color: kDashTextSub,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TextButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Open'),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final IncidentHistoryRecord record;
  final VoidCallback onTap;

  const _HistoryRow({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            Expanded(
              flex: 140,
              child: Text(
                record.incidentId,
                style: GoogleFonts.robotoMono(
                  color: kDashAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              flex: 180,
              child: _DateCell(ms: record.updatedAtMs),
            ),
            Expanded(
              flex: 160,
              child: Text(
                '${record.roomNumber} · Floor ${record.floor} ${record.wing.isEmpty ? '' : '· ${record.wing}'}',
                style: GoogleFonts.inter(
                  color: kDashText,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 130,
              child: _StatusChip(status: record.status),
            ),
            Expanded(
              flex: 120,
              child: _SeverityChip(severity: record.severity),
            ),
            Expanded(
              flex: 270,
              child: Text(
                record.aiSummary.isEmpty
                    ? 'No AI summary recorded for this incident.'
                    : record.aiSummary,
                style: GoogleFonts.inter(
                  color: kDashTextSub,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateCell extends StatelessWidget {
  final int ms;

  const _DateCell({required this.ms});

  @override
  Widget build(BuildContext context) {
    if (ms <= 0) {
      return Text(
        '--',
        style: GoogleFonts.inter(color: kDashTextSub, fontSize: 12),
      );
    }

    final date = DateTime.fromMillisecondsSinceEpoch(ms);
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final month = months[date.month - 1];
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final hour = ((date.hour + 11) % 12) + 1;
    final minute = date.minute.toString().padLeft(2, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$month ${date.day}, ${date.year}',
          style: GoogleFonts.inter(
            color: kDashText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$hour:$minute $period',
          style: GoogleFonts.inter(
            color: kDashTextSub,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          status,
          style: GoogleFonts.inter(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  final String severity;

  const _SeverityChip({required this.severity});

  @override
  Widget build(BuildContext context) {
    final color = severityColor(severity);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          severity,
          style: GoogleFonts.inter(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final int pageStart;
  final int pageEnd;
  final int totalRows;
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _PaginationBar({
    required this.pageStart,
    required this.pageEnd,
    required this.totalRows,
    required this.currentPage,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Text(
            totalRows == 0
                ? 'Showing 0 entries'
                : 'Showing $pageStart-$pageEnd of $totalRows entries',
            style: GoogleFonts.inter(
              color: kDashTextSub,
              fontSize: 11,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
            color: kDashTextSub,
            iconSize: 18,
            tooltip: 'Previous page',
          ),
          Text(
            '${currentPage + 1} / $totalPages',
            style: GoogleFonts.inter(
              color: kDashText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
            color: kDashTextSub,
            iconSize: 18,
            tooltip: 'Next page',
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final _HistoryStats stats;

  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Avg. Response Time',
            icon: Icons.timer,
            value: _durationLabel(stats.averageResponseMs),
            accent: kDashAccent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Resolution Rate',
            icon: Icons.check_circle,
            value: '${stats.resolutionRate.toStringAsFixed(1)}%',
            accent: kDashGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'False Alarm Ratio',
            icon: Icons.report_off,
            value: '${stats.falseAlarmRate.toStringAsFixed(1)}%',
            accent: kDashWarning,
          ),
        ),
      ],
    );
  }

  String _durationLabel(int ms) {
    if (ms <= 0) {
      return '--';
    }
    final totalSeconds = (ms / 1000).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final Color accent;

  const _StatCard({
    required this.label,
    required this.icon,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: glassSurfaceDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: kDashTextSub,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(icon, color: accent, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.fustat(
              color: kDashText,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasActiveFilters;

  const _EmptyState({required this.hasActiveFilters});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, color: kDashTextSub, size: 30),
          const SizedBox(height: 10),
          Text(
            hasActiveFilters
                ? 'No incidents match the current filters.'
                : 'No history incidents found yet.',
            style: GoogleFonts.inter(
              color: kDashTextSub,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryPage {
  final List<IncidentHistoryRecord> items;
  final int start;
  final int end;
  final int totalPages;

  const _HistoryPage({
    required this.items,
    required this.start,
    required this.end,
    required this.totalPages,
  });
}

class _HistoryStats {
  final int averageResponseMs;
  final double resolutionRate;
  final double falseAlarmRate;

  const _HistoryStats({
    required this.averageResponseMs,
    required this.resolutionRate,
    required this.falseAlarmRate,
  });
}
