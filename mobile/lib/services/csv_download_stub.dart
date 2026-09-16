/// Saving a downloaded file, on platforms that are not the web.
///
/// Conditional-import pair with csv_download_web.dart — the same pattern this
/// project already uses for Razorpay and the notification service. The web
/// version is the real one; this is what Android and iOS compile against, and
/// it deliberately does nothing.
///
/// That is a decision, not an omission. The inventory sheet is edited in Excel
/// on a laptop, so the meaningful flow is the browser one. Writing the file to
/// a phone's storage and opening a share sheet would be real work in service of
/// a workflow nobody has asked for, and a button that half-works is worse than
/// one that says plainly where it does work.
bool get canDownloadFiles => false;

/// Never called on mobile — the caller checks [canDownloadFiles] first.
void downloadCsvBytes(List<int> bytes, String filename) {
  throw UnsupportedError(
    'Downloading the inventory sheet is only supported in the web admin panel.',
  );
}
