import 'dart:io';

import 'package:share_plus/share_plus.dart';

/// Thin wrapper over `share_plus` so features depend on this instead of
/// the package directly — same "core wraps the plugin" convention
/// TokenStorage/ConnectivityController use elsewhere in this app.
class ShareService {
  const ShareService();

  Future<void> shareFile(File file, {String? text, String? subject}) {
    return Share.shareXFiles([XFile(file.path)], text: text, subject: subject);
  }

  Future<void> shareText(String text, {String? subject}) {
    return Share.share(text, subject: subject);
  }
}
