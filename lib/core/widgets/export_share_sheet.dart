import 'package:flutter/material.dart';

import '../../features/meetings/domain/entities/meeting.dart';
import '../../features/meetings/domain/entities/meeting_summary.dart';
import '../export/share_service.dart';
import '../export/summary_export_service.dart';
import '../theme/spacing.dart';

/// Bottom sheet offering "export as ..." / "share as text" actions for a
/// generated meeting summary — SRD FR-5.4 and PHASES.md Phase 12's
/// export + share checklist items.
Future<void> showExportShareSheet(
  BuildContext context, {
  required Meeting meeting,
  required MeetingSummary summary,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => _ExportShareSheet(meeting: meeting, summary: summary),
  );
}

class _ExportShareSheet extends StatefulWidget {
  const _ExportShareSheet({required this.meeting, required this.summary});

  final Meeting meeting;
  final MeetingSummary summary;

  @override
  State<_ExportShareSheet> createState() => _ExportShareSheetState();
}

class _ExportShareSheetState extends State<_ExportShareSheet> {
  static const _exportService = SummaryExportService();
  static const _shareService = ShareService();

  SummaryExportFormat? _working;

  Future<void> _export(SummaryExportFormat format) async {
    setState(() => _working = format);
    try {
      final file = await _exportService.export(widget.meeting, widget.summary, format);
      if (!mounted) return;
      await _shareService.shareFile(file, subject: widget.meeting.title);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not export: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _working = null);
    }
  }

  Future<void> _shareAsText() async {
    final buffer = StringBuffer()
      ..writeln(widget.meeting.title)
      ..writeln()
      ..writeln(widget.summary.executiveSummary);
    await _shareService.shareText(buffer.toString(), subject: widget.meeting.title);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Export & share', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Spacing.sm),
            _Tile(
              icon: Icons.description_outlined,
              label: 'Export as Markdown',
              loading: _working == SummaryExportFormat.markdown,
              onTap: () => _export(SummaryExportFormat.markdown),
            ),
            _Tile(
              icon: Icons.picture_as_pdf_outlined,
              label: 'Export as PDF',
              loading: _working == SummaryExportFormat.pdf,
              onTap: () => _export(SummaryExportFormat.pdf),
            ),
            _Tile(
              icon: Icons.article_outlined,
              label: 'Export as Word (.rtf)',
              loading: _working == SummaryExportFormat.word,
              onTap: () => _export(SummaryExportFormat.word),
            ),
            const Divider(),
            _Tile(
              icon: Icons.ios_share,
              label: 'Share as text',
              loading: false,
              onTap: _shareAsText,
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.loading, required this.onTap});

  final IconData icon;
  final String label;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: loading
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(icon),
      title: Text(label),
      onTap: loading ? null : onTap,
    );
  }
}
