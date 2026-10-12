import 'package:share_plus/share_plus.dart';

typedef ShareFile = Future<void> Function(String path);

/// Único lugar que toca share_plus.
Future<void> shareFileWithSystem(String path) async {
  await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
}
