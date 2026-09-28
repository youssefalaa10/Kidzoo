import 'dart:io';

import 'package:flutter/foundation.dart' show SynchronousFuture;
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

/// The same content, read once and handed back without touching the disk again.
///
/// A widget test runs on a fake clock, and real file I/O started inside it does
/// not complete between pumps — a screen that loads its content from disk sits
/// on its spinner forever and every finder comes back empty. Reading the files
/// up front and answering synchronously takes the I/O out of the test without
/// taking the real content out of it.
class PreloadedAdventureContentSource implements AdventureContentSource {
  PreloadedAdventureContentSource._(this._files);

  final Map<String, String> _files;

  /// Reads every file [AdventureContentLoader] will ask for, ahead of time.
  static Future<PreloadedAdventureContentSource> load({
    String rootPath = 'assets/adventures',
  }) async {
    final Map<String, String> files = <String, String>{};
    final Directory root = Directory(rootPath);
    for (final FileSystemEntity entity in root.listSync(recursive: true)) {
      if (entity is! File) {
        continue;
      }
      // Windows hands back backslashes; the loader asks with forward slashes.
      final String relative = entity.path
          .replaceAll(Platform.pathSeparator, '/')
          .substring(rootPath.length + 1);
      files[relative] = await entity.readAsString();
    }
    return PreloadedAdventureContentSource._(files);
  }

  @override
  Future<String> readString(String relativePath) {
    final String? contents = _files[relativePath];
    if (contents == null) {
      throw FileSystemException('content file not preloaded', relativePath);
    }
    return SynchronousFuture<String>(contents);
  }
}
