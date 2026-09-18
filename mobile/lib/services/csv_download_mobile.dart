import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Saving the inventory sheet on Android and iOS.
///
/// Conditional-import pair with csv_download_web.dart — the same pattern this
/// project already uses for Razorpay and the notification service. This file is
/// what every non-web platform compiles against.
///
/// Phones have no "Downloads" to drop a file into the way a browser does, so
/// this opens the system share sheet instead. From there the owner can open the
/// sheet in Excel or Google Sheets on the phone, save it to Drive, or send it to
/// themselves on WhatsApp or email and finish editing on a laptop.
///
/// That last route is the realistic one — editing 400 rows on a phone is
/// painful — but the owner may not be at the laptop when they want the file.
bool get canDownloadFiles => true;

Future<void> downloadCsvBytes(List<int> bytes, String filename) async {
  // XFile.fromData needs no file path. share_plus writes the bytes to a temp
  // directory itself before handing them to the platform share sheet, using
  // fileNameOverrides for the name — which is why path_provider isn't needed.
  //
  // The bytes are passed through untouched, so the UTF-8 byte-order mark the
  // server writes survives. Excel on the phone needs it as much as on a laptop,
  // or Hindi and Punjabi product names open as mojibake.
  final file = XFile.fromData(
    Uint8List.fromList(bytes),
    name: filename,
    mimeType: 'text/csv',
  );

  await SharePlus.instance.share(
    ShareParams(
      files: [file],
      fileNameOverrides: [filename],
      subject: filename,
    ),
  );
}
