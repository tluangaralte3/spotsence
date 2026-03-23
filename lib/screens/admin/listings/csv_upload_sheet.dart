// lib/screens/admin/listings/csv_upload_sheet.dart
//
// Bottom sheet that lets an admin pick a CSV file and bulk-upload listings
// to a specific Firestore collection.
//
// Features:
//  • Shows column schema for the active tab so the admin knows the format
//  • "Download Template" button generates a CSV header row (share/save)
//  • Progress bar during upload
//  • Summary card: uploaded / skipped / errors

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import '../../../controllers/admin_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/csv_upload_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public entry-point
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showCsvUploadSheet(BuildContext context, ListingTab tab) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CsvUploadSheet(tab: tab),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CsvUploadSheet extends StatefulWidget {
  final ListingTab tab;
  const _CsvUploadSheet({required this.tab});

  @override
  State<_CsvUploadSheet> createState() => _CsvUploadSheetState();
}

class _CsvUploadSheetState extends State<_CsvUploadSheet> {
  // State machine
  _SheetState _state = _SheetState.idle;
  double _progress = 0;
  CsvUploadResult? _result;
  String? _pickedFileName;
  List<int>? _pickedBytes;
  String? _errorMessage;
  bool _schemaExpanded = false;

  List<({String header, String hint, bool required})> get _columns =>
      getCsvColumnHints(widget.tab);

  // ── Pick CSV file ─────────────────────────────────────────────────────────
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      setState(() {
        _pickedFileName = file.name;
        _pickedBytes =
            file.bytes?.toList() ??
            (file.path != null
                ? File(file.path!).readAsBytesSync().toList()
                : null);
        _state = _pickedBytes != null ? _SheetState.ready : _SheetState.idle;
        _result = null;
        _errorMessage = null;
      });
    } on PlatformException catch (e) {
      setState(() => _errorMessage = 'Could not pick file: ${e.message}');
    } catch (e) {
      setState(() => _errorMessage = 'Could not pick file: $e');
    }
  }

  // ── Upload ────────────────────────────────────────────────────────────────
  Future<void> _upload() async {
    if (_pickedBytes == null) return;
    setState(() {
      _state = _SheetState.uploading;
      _progress = 0;
      _result = null;
      _errorMessage = null;
    });

    try {
      final service = CsvUploadService();
      final result = await service.upload(
        csvBytes: _pickedBytes!,
        collection: widget.tab.collection,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      setState(() {
        _result = result;
        _state = _SheetState.done;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Upload failed: $e';
        _state = _SheetState.ready;
      });
    }
  }

  // ── Download template ─────────────────────────────────────────────────────
  Future<void> _downloadTemplate() async {
    try {
      final csv = buildCsvTemplate(widget.tab.collection);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.tab.collection}_template.csv');
      await file.writeAsString(csv);
      await share_plus.SharePlus.instance.share(
        share_plus.ShareParams(
          files: [XFile(file.path, mimeType: 'text/csv')],
          subject: '${widget.tab.label} CSV Template',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not generate template: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final maxH = MediaQuery.of(context).size.height * 0.92;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: BoxDecoration(
        color: col.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: col.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.upload_file_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bulk Upload — ${widget.tab.label}',
                        style: TextStyle(
                          color: col.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Upload a CSV file to add multiple listings at once.',
                        style: TextStyle(
                          color: col.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: col.textSecondary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Divider(color: col.border, height: 16),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Schema accordion ────────────────────────────────────
                  _SchemaAccordion(
                    columns: _columns,
                    expanded: _schemaExpanded,
                    onToggle: () =>
                        setState(() => _schemaExpanded = !_schemaExpanded),
                    col: col,
                    tabLabel: widget.tab.label,
                    onDownloadTemplate: _downloadTemplate,
                  ),

                  const SizedBox(height: 16),

                  // ── File picker ─────────────────────────────────────────
                  _FilePicker(
                    fileName: _pickedFileName,
                    onPick: _pickFile,
                    col: col,
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 10),
                    _ErrorBanner(message: _errorMessage!, col: col),
                  ],

                  const SizedBox(height: 16),

                  // ── Progress ────────────────────────────────────────────
                  if (_state == _SheetState.uploading)
                    _ProgressCard(progress: _progress, col: col),

                  // ── Result summary ──────────────────────────────────────
                  if (_state == _SheetState.done && _result != null)
                    _ResultCard(result: _result!, col: col),

                  const SizedBox(height: 8),

                  // ── Action buttons ──────────────────────────────────────
                  if (_state != _SheetState.uploading) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed:
                            (_state == _SheetState.ready ||
                                _state == _SheetState.done)
                            ? _upload
                            : null,
                        icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                        label: Text(
                          _state == _SheetState.done
                              ? 'Upload Again'
                              : 'Upload to Firestore',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: col.border.withValues(
                            alpha: 0.5,
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: _pickFile,
                        icon: Icon(
                          Icons.folder_open_outlined,
                          size: 16,
                          color: col.textSecondary,
                        ),
                        label: Text(
                          _pickedFileName == null
                              ? 'Choose CSV File'
                              : 'Choose Different File',
                          style: TextStyle(color: col.textSecondary),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: col.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// State enum
// ─────────────────────────────────────────────────────────────────────────────

enum _SheetState { idle, ready, uploading, done }

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SchemaAccordion extends StatelessWidget {
  final List<({String header, String hint, bool required})> columns;
  final bool expanded;
  final VoidCallback onToggle;
  final AppColorScheme col;
  final String tabLabel;
  final VoidCallback onDownloadTemplate;

  const _SchemaAccordion({
    required this.columns,
    required this.expanded,
    required this.onToggle,
    required this.col,
    required this.tabLabel,
    required this.onDownloadTemplate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.border),
      ),
      child: Column(
        children: [
          // Header row
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.table_chart_outlined,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'CSV Column Format (${columns.length} columns)',
                      style: TextStyle(
                        color: col.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  // Download template button
                  GestureDetector(
                    onTap: onDownloadTemplate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.download_outlined,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Template',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: col.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          // Column list
          if (expanded) ...[
            Divider(height: 1, color: col.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Column(
                children: [
                  // Table header
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Column Header',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: col.textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Format / Example',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: col.textMuted,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Text(
                          'Required',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: col.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...columns.map(
                    (c) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              c.header,
                              style: TextStyle(
                                fontSize: 12,
                                color: col.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              c.hint,
                              style: TextStyle(
                                fontSize: 12,
                                color: col.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 60,
                            child: Center(
                              child: c.required
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Yes',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.error,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      '—',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: col.textMuted,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Hint about lists
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: col.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 13,
                          color: col.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'For list columns (e.g. images, cuisineTypes) separate multiple values with a pipe character: value1|value2|value3',
                            style: TextStyle(
                              fontSize: 11,
                              color: col.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FilePicker extends StatelessWidget {
  final String? fileName;
  final VoidCallback onPick;
  final AppColorScheme col;

  const _FilePicker({
    required this.fileName,
    required this.onPick,
    required this.col,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: col.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: fileName != null ? AppColors.primary : col.border,
            width: fileName != null ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    (fileName != null ? AppColors.primary : col.surfaceElevated)
                        .withValues(alpha: fileName != null ? 0.12 : 1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                fileName != null
                    ? Icons.description_outlined
                    : Icons.upload_file_outlined,
                color: fileName != null ? AppColors.primary : col.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName ?? 'Tap to choose a CSV file',
                    style: TextStyle(
                      color: fileName != null
                          ? col.textPrimary
                          : col.textSecondary,
                      fontWeight: fileName != null
                          ? FontWeight.w600
                          : FontWeight.w400,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (fileName == null)
                    Text(
                      'Only .csv files are accepted',
                      style: TextStyle(fontSize: 11, color: col.textMuted),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: col.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  final double progress;
  final AppColorScheme col;
  const _ProgressCard({required this.progress, required this.col});

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).toStringAsFixed(0);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Uploading…  $pct%',
                style: TextStyle(
                  color: col.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: col.border,
              color: AppColors.primary,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final CsvUploadResult result;
  final AppColorScheme col;
  const _ResultCard({required this.result, required this.col});

  @override
  Widget build(BuildContext context) {
    final partial = result.uploaded > 0 && result.hasErrors;
    final failed = result.uploaded == 0;

    final Color accentColor = failed
        ? AppColors.error
        : partial
        ? AppColors.warning
        : AppColors.success;

    final IconData icon = failed
        ? Icons.error_outline
        : partial
        ? Icons.warning_amber_outlined
        : Icons.check_circle_outline;

    final String headline = failed
        ? 'Upload failed'
        : partial
        ? 'Uploaded with warnings'
        : 'Upload complete!';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 22),
              const SizedBox(width: 8),
              Text(
                headline,
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stats row
          Row(
            children: [
              _StatPill(
                label: 'Total rows',
                value: '${result.total}',
                color: col.textSecondary,
                col: col,
              ),
              const SizedBox(width: 8),
              _StatPill(
                label: 'Uploaded',
                value: '${result.uploaded}',
                color: AppColors.success,
                col: col,
              ),
              const SizedBox(width: 8),
              if (result.skipped > 0)
                _StatPill(
                  label: 'Skipped',
                  value: '${result.skipped}',
                  color: AppColors.warning,
                  col: col,
                ),
            ],
          ),
          // Error list
          if (result.hasErrors) ...[
            const SizedBox(height: 12),
            Text(
              'Row errors (${result.errors.length}):',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              constraints: const BoxConstraints(maxHeight: 120),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: result.errors
                      .take(20)
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '• $e',
                            style: TextStyle(
                              fontSize: 11,
                              color: col.textSecondary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            if (result.errors.length > 20)
              Text(
                '… and ${result.errors.length - 20} more errors.',
                style: TextStyle(fontSize: 11, color: col.textMuted),
              ),
          ],
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final AppColorScheme col;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
    required this.col,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 10, color: col.textSecondary)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final AppColorScheme col;
  const _ErrorBanner({required this.message, required this.col});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
