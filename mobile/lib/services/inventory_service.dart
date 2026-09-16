import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Talks to the bulk-inventory endpoints.
///
/// Deliberately uses `http` directly rather than going through ApiService: two
/// of these three calls are not JSON. The export returns a CSV body and the
/// uploads are multipart, neither of which ApiService's json-encode /
/// json-decode path can carry. Auth is passed explicitly by the caller.
class InventoryService {
  static String get _base => AppConfig.apiBaseUrl;

  /// Download the catalogue as CSV bytes.
  ///
  /// Returns raw bytes, not a String, so the UTF-8 byte-order mark the server
  /// writes survives untouched all the way to the file. Decoding to a Dart
  /// String and re-encoding would strip it, and Excel needs it to read Hindi
  /// and Punjabi correctly.
  static Future<Uint8List> downloadSheet({required String token}) async {
    final response = await http.get(
      Uri.parse('$_base/admin/inventory/export'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw Exception(_messageFrom(response, 'Could not download the sheet.'));
    }
    return response.bodyBytes;
  }

  /// Ask the server what the sheet WOULD change. Writes nothing.
  static Future<InventorySheetResult> preview({
    required String token,
    required Uint8List bytes,
    required String filename,
  }) =>
      _upload(token: token, bytes: bytes, filename: filename, path: 'preview');

  /// Apply the sheet for real.
  static Future<InventorySheetResult> apply({
    required String token,
    required Uint8List bytes,
    required String filename,
  }) =>
      _upload(token: token, bytes: bytes, filename: filename, path: 'apply');

  static Future<InventorySheetResult> _upload({
    required String token,
    required Uint8List bytes,
    required String filename,
    required String path,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_base/admin/inventory/$path'),
    )
      ..headers['Authorization'] = 'Bearer $token'
      // Field name must be 'file' — that is what uploadCsvSingle expects.
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

    final streamed = await request.send().timeout(const Duration(minutes: 2));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception(_messageFrom(response, 'The server rejected the sheet.'));
    }
    return InventorySheetResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Surface the server's own wording where there is any — it explains exactly
  /// what is wrong with the file, which a generic message cannot.
  static String _messageFrom(http.Response response, String fallback) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] is String) return body['message'] as String;
    } catch (_) {
      // Not JSON — fall through.
    }
    return '$fallback (${response.statusCode})';
  }
}

/// What the server says a sheet would do, or did.
class InventorySheetResult {
  final bool applied;
  final String? message;
  final int totalRows;
  final int unchangedRows;
  final int changedRows;
  final int stockChanges;
  final int priceChanges;
  final int availabilityChanges;
  final int errorCount;
  final List<SheetProblem> problems;
  final bool problemsTruncated;
  final List<SheetPreviewRow> preview;
  final bool previewTruncated;

  const InventorySheetResult({
    required this.applied,
    required this.message,
    required this.totalRows,
    required this.unchangedRows,
    required this.changedRows,
    required this.stockChanges,
    required this.priceChanges,
    required this.availabilityChanges,
    required this.errorCount,
    required this.problems,
    required this.problemsTruncated,
    required this.preview,
    required this.previewTruncated,
  });

  /// True when there is nothing to confirm — no changes, or every row failed.
  bool get hasNothingToApply => changedRows == 0;

  factory InventorySheetResult.fromJson(Map<String, dynamic> json) {
    final changes = (json['changes'] as Map<String, dynamic>?) ?? const {};
    int count(String key) => (changes[key] as num?)?.toInt() ?? 0;
    int at(String key) => (json[key] as num?)?.toInt() ?? 0;

    return InventorySheetResult(
      applied: json['applied'] as bool? ?? false,
      message: json['message'] as String?,
      totalRows: at('totalRows'),
      unchangedRows: at('unchangedRows'),
      changedRows: at('changedRows'),
      stockChanges: count('stock'),
      priceChanges: count('price'),
      availabilityChanges: count('available'),
      errorCount: at('errorCount'),
      problems: ((json['problems'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SheetProblem.fromJson)
          .toList(),
      problemsTruncated: json['problemsTruncated'] as bool? ?? false,
      preview: ((json['preview'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SheetPreviewRow.fromJson)
          .toList(),
      previewTruncated: json['previewTruncated'] as bool? ?? false,
    );
  }
}

class SheetProblem {
  final int lineNumber;
  final String label;
  final String message;

  /// Errors skip that row; warnings are applied anyway but worth reading —
  /// typically "this changed since you downloaded".
  final bool isError;

  const SheetProblem({
    required this.lineNumber,
    required this.label,
    required this.message,
    required this.isError,
  });

  factory SheetProblem.fromJson(Map<String, dynamic> json) => SheetProblem(
        lineNumber: (json['lineNumber'] as num?)?.toInt() ?? 0,
        label: json['label'] as String? ?? '',
        message: json['message'] as String? ?? '',
        isError: (json['severity'] as String?) != 'warning',
      );
}

class SheetPreviewRow {
  final int lineNumber;
  final String label;
  final List<SheetFieldChange> changes;

  const SheetPreviewRow({
    required this.lineNumber,
    required this.label,
    required this.changes,
  });

  factory SheetPreviewRow.fromJson(Map<String, dynamic> json) => SheetPreviewRow(
        lineNumber: (json['lineNumber'] as num?)?.toInt() ?? 0,
        label: json['label'] as String? ?? '',
        changes: ((json['changes'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(SheetFieldChange.fromJson)
            .toList(),
      );
}

class SheetFieldChange {
  final String field;
  final String from;
  final String to;

  const SheetFieldChange({
    required this.field,
    required this.from,
    required this.to,
  });

  factory SheetFieldChange.fromJson(Map<String, dynamic> json) => SheetFieldChange(
        field: json['field'] as String? ?? '',
        from: json['from'] as String? ?? '',
        to: json['to'] as String? ?? '',
      );
}
