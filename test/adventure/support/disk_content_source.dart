import 'dart:io';

import 'package:kidzo/features/Adventure/data/adventure_content_loader.dart';

/// Reads adventure content straight off disk.
///
/// The content test is the highest-value test in this feature and it must not
/// need a widget binding, an asset bundle or a running app — otherwise it stops
/// being the thing an author runs before committing.
class DiskAdventureContentSource implements AdventureContentSource {
  const DiskAdventureContentSource({this.rootPath = 'assets/adventures'});

  final String rootPath;

  @override
  Future<String> readString(String relativePath) {
    final File file = File('$rootPath/$relativePath');
    if (!file.existsSync()) {
      throw FileSystemException('content file not found', file.path);
    }
    return file.readAsString();
  }
}
