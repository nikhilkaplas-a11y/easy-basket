// ignore_for_file: avoid_web_libraries_in_flutter
//
// dart:html is the only way to hand bytes to the browser as a file download,
// and this file is ONLY ever compiled for web — see csv_download_stub.dart for
// the conditional-import pair. The lint exists to stop dart:html leaking into
// shared code, which the stub prevents.
import 'dart:html' as html;

bool get canDownloadFiles => true;

/// Trigger a browser download of [bytes] as [filename].
///
/// Why bytes rather than just opening the export URL in a new tab: that endpoint
/// requires an admin bearer token, and a plain link cannot carry an
/// Authorization header. So the app fetches the CSV itself, then hands the
/// result to the browser here.
void downloadCsvBytes(List<int> bytes, String filename) {
  // 'text/csv;charset=utf-8' matters. The bytes already begin with a UTF-8
  // byte-order mark (the server writes one) and Excel needs both that and a
  // charset it recognises, or Hindi and Punjabi product names open as mojibake.
  final blob = html.Blob(<Object>[bytes], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);

  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();

  // The blob stays in memory for the life of the page otherwise, and this
  // screen can be used repeatedly in one session.
  html.Url.revokeObjectUrl(url);
}
