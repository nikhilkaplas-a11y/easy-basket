import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/inventory_service.dart';
import '../../utils/theme.dart';

// Browser download on web; a no-op stub elsewhere. See csv_download_stub.dart
// for why mobile deliberately does not implement this.
import '../../services/csv_download_stub.dart'
    if (dart.library.html) '../../services/csv_download_web.dart';

/// Bulk stock and price editing via spreadsheet.
///
/// Three steps, in one screen so the owner never loses their place:
///
///   1. Download  — the whole catalogue as a CSV
///   2. Upload    — pick the edited file; the server reports what WOULD change
///   3. Confirm   — and only now is anything saved
///
/// Step 2 writing nothing is the entire safety model. One careless sort or
/// find-and-replace in Excel could otherwise rewrite the catalogue in a single
/// request, with no way to see it coming.
class InventorySheetScreen extends StatefulWidget {
  const InventorySheetScreen({super.key});

  @override
  State<InventorySheetScreen> createState() => _InventorySheetScreenState();
}

class _InventorySheetScreenState extends State<InventorySheetScreen> {
  bool _downloading = false;
  bool _busy = false;

  /// Held between preview and confirm so Confirm sends the SAME bytes the
  /// preview described. Re-picking the file would let a different one through.
  Uint8List? _pendingBytes;
  String? _pendingFilename;

  InventorySheetResult? _result;
  String? _error;

  String? get _token => context.read<AuthProvider>().token;

  // ---------------------------------------------------------------- download

  Future<void> _download() async {
    final token = _token;
    if (token == null) return;

    setState(() {
      _downloading = true;
      _error = null;
    });

    try {
      final bytes = await InventoryService.downloadSheet(token: token);
      final filename =
          'easybasket-inventory-${DateTime.now().toIso8601String().substring(0, 10)}.csv';
      downloadCsvBytes(bytes, filename);
      if (mounted) _toast('Sheet downloaded. Open it in Excel.');
    } catch (e) {
      if (mounted) setState(() => _error = _clean(e));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  // ------------------------------------------------------------------ upload

  Future<void> _pickAndPreview() async {
    final token = _token;
    if (token == null) return;

    // withData: true is required — on web there is no file path, only bytes.
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      withData: true,
    );
    final file = picked?.files.single;
    final bytes = file?.bytes;
    if (bytes == null) return; // cancelled

    setState(() {
      _busy = true;
      _error = null;
      _result = null;
      _pendingBytes = bytes;
      _pendingFilename = file!.name;
    });

    try {
      final result = await InventoryService.preview(
        token: token,
        bytes: bytes,
        filename: file!.name,
      );
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _clean(e);
          _pendingBytes = null;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ----------------------------------------------------------------- confirm

  Future<void> _confirm() async {
    final token = _token;
    final bytes = _pendingBytes;
    if (token == null || bytes == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final result = await InventoryService.apply(
        token: token,
        bytes: bytes,
        filename: _pendingFilename ?? 'inventory.csv',
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        // Cleared so Confirm cannot be pressed twice with the same file. The
        // second press would re-apply every stock DIFFERENCE, doubling it.
        _pendingBytes = null;
      });
      _toast(result.applied ? 'Changes saved.' : (result.message ?? 'Nothing applied.'));
    } catch (e) {
      if (mounted) setState(() => _error = _clean(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // --------------------------------------------------------------------- ui

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final canConfirm =
        result != null && !result.applied && !result.hasNothingToApply && _pendingBytes != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Update stock & prices')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StepCard(
            number: '1',
            title: 'Download the sheet',
            body: 'Every product, with its current stock and price.',
            action: canDownloadFiles
                ? FilledButton.icon(
                    onPressed: _downloading ? null : _download,
                    icon: _downloading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download),
                    label: Text(_downloading ? 'Preparing…' : 'Download sheet'),
                  )
                : const Text(
                    'Open the admin panel on a laptop to download the sheet.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
          ),
          const SizedBox(height: 12),

          _StepCard(
            number: '2',
            title: 'Edit it in Excel',
            body: 'Change the stock, price and available columns. '
                'Leave the was_ columns alone — they let us work out what you changed. '
                'Do not delete rows; a missing row changes nothing.',
          ),
          const SizedBox(height: 12),

          _StepCard(
            number: '3',
            title: 'Upload it back',
            body: 'We will show you exactly what changes before anything is saved.',
            action: OutlinedButton.icon(
              onPressed: _busy ? null : _pickAndPreview,
              icon: const Icon(Icons.upload_file),
              label: const Text('Choose file'),
            ),
          ),

          if (_busy) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],

          if (_error != null) ...[
            const SizedBox(height: 16),
            _Banner(
              colour: Colors.red,
              icon: Icons.error_outline,
              title: 'Could not read that file',
              body: _error!,
            ),
          ],

          if (result != null) ...[
            const SizedBox(height: 16),
            _ResultView(result: result),
          ],

          if (canConfirm) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _busy ? null : _confirm,
                style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                icon: const Icon(Icons.check),
                label: Text('Confirm — save ${result.changedRows} change'
                    '${result.changedRows == 1 ? '' : 's'}'),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nothing has been saved yet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  static String _clean(Object e) => e.toString().replaceAll('Exception: ', '');
}

// ---------------------------------------------------------------- components

class _StepCard extends StatelessWidget {
  final String number;
  final String title;
  final String body;
  final Widget? action;

  const _StepCard({
    required this.number,
    required this.title,
    required this.body,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppTheme.primaryGreen,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Text(body,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4)),
                if (action != null) ...[
                  const SizedBox(height: 12),
                  action!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final InventorySheetResult result;

  const _ResultView({required this.result});

  @override
  Widget build(BuildContext context) {
    final errors = result.problems.where((p) => p.isError).toList();
    final warnings = result.problems.where((p) => !p.isError).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Banner(
          colour: result.applied ? Colors.green : AppTheme.primaryGreen,
          icon: result.applied ? Icons.check_circle : Icons.fact_check_outlined,
          title: result.applied
              ? 'Saved'
              : result.hasNothingToApply
                  ? 'Nothing to change'
                  : 'Ready to save — nothing saved yet',
          body: [
            '${result.totalRows} rows read',
            '${result.unchangedRows} unchanged',
            '${result.changedRows} to change',
          ].join(' · '),
        ),

        if (result.changedRows > 0) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (result.stockChanges > 0) _Chip('${result.stockChanges} stock'),
              if (result.priceChanges > 0) _Chip('${result.priceChanges} price'),
              if (result.availabilityChanges > 0)
                _Chip('${result.availabilityChanges} availability'),
            ],
          ),
        ],

        if (errors.isNotEmpty) ...[
          const SizedBox(height: 16),
          _ProblemList(
            title: '${errors.length} row${errors.length == 1 ? '' : 's'} skipped',
            subtitle: 'These are not saved. Everything else still applies.',
            colour: Colors.red,
            problems: errors,
          ),
        ],

        if (warnings.isNotEmpty) ...[
          const SizedBox(height: 16),
          _ProblemList(
            title: '${warnings.length} warning${warnings.length == 1 ? '' : 's'}',
            subtitle: 'These ARE applied — usually something changed since you downloaded.',
            colour: Colors.orange.shade800,
            problems: warnings,
          ),
        ],

        if (result.preview.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(result.applied ? 'What changed' : 'What will change',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...result.preview.map((row) => _PreviewRow(row: row)),
          if (result.previewTruncated)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('…and more. Only the first 200 are listed.',
                  style: TextStyle(fontSize: 12, color: Colors.black54)),
            ),
        ],
      ],
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final SheetPreviewRow row;

  const _PreviewRow({required this.row});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(row.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 2),
          ...row.changes.map(
            (c) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Text(
                '${c.field}:  ${c.from}  →  ${c.to}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProblemList extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color colour;
  final List<SheetProblem> problems;

  const _ProblemList({
    required this.title,
    required this.subtitle,
    required this.colour,
    required this.problems,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colour.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: colour)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          const SizedBox(height: 10),
          ...problems.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Row ${p.lineNumber}${p.label.isEmpty ? '' : ' · ${p.label}'}\n${p.message}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade900, height: 1.35),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final Color colour;
  final IconData icon;
  final String title;
  final String body;

  const _Banner({
    required this.colour,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colour.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colour, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: colour)),
                const SizedBox(height: 3),
                Text(body, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF5F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
