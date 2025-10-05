import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';

class SecurityScopedResource {
  static const MethodChannel _channel =
      MethodChannel('security_scoped_resource');

  static final instance = SecurityScopedResource();

  /// Grant access to a directory or file.
  /// Call [stopAccessingSecurityScopedResource] when you're done
  Future<bool> startAccessingSecurityScopedResource(
      FileSystemEntity entity) async {
    assert(entity is File || entity is Directory,
        "Entity should be a File or a Directory");
    return await _channel.invokeMethod('startAccessingSecurityScopedResource', {
      'path': entity.absolute.path,
      'isDirectory': entity is Directory,
    });
  }

  /// Frees association with the security scoped resource.
  Future<bool> stopAccessingSecurityScopedResource(
      FileSystemEntity entity) async {
    assert(entity is File || entity is Directory,
        "Entity should be a File or a Directory");
    return await _channel.invokeMethod('stopAccessingSecurityScopedResource', {
      'path': entity.absolute.path,
      'isDirectory': entity is Directory,
    });
  }

  /// Create a security-scoped bookmark from a file/directory path.
  Future<Uint8List?> createBookmark(FileSystemEntity entity) async {
    assert(entity is File || entity is Directory,
        "Entity should be a File or a Directory");
    final data = await _channel.invokeMethod('createBookmark', {
      'path': entity.absolute.path,
      'isDirectory': entity is Directory,
    });
    if (data == null) return null;
    return data as Uint8List;
  }

  /// Restore a previously saved bookmark.
  /// Returns a map containing:
  ///   path: String -> resolved file/dir path
  ///   stale: bool -> whether bookmark is stale and should be recreated
  ///   started: bool -> whether startAccessing succeeded
  Future<Map<String, dynamic>?> restoreBookmark(
      Uint8List bookmarkData) async {
    final result = await _channel.invokeMethod('restoreBookmark', {
      'bookmarkData': bookmarkData,
    });
    if (result == null) return null;
    return Map<String, dynamic>.from(result as Map);
  }
}
