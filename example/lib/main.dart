import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:security_scoped_resource/security_scoped_resource.dart';

// 简单模拟的存储（你要是真持久化，可以换成 Hive/SharedPreferences 等）
final Map<String, Uint8List> fakeStorage = {};

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? lastPickedPath;
  String log = "";

  void appendLog(String msg) {
    setState(() {
      log += "$msg\n";
    });
    debugPrint(msg);
  }

  /// 选择目录 -> startAccess -> createBookmark
  Future<void> pickAndBookmark() async {
    final path = await FilePicker.platform.getDirectoryPath();

    if (path == null) {
      appendLog("❌ No directory picked");
      return;
    }

    final dir = Directory(path);
    lastPickedPath = dir.path;

    // 1. 当场 startAccess
    final ok = await SecurityScopedResource.instance.startAccessingSecurityScopedResource(dir);
    appendLog("startAccessing: $ok");

    // 2. 列目录试试
    try {
      final entries = dir.listSync();
      appendLog("Listed ${entries.length} entries");
    } catch (e) {
      appendLog("List failed: $e");
    }

    // 3. 创建 bookmark 并保存
    final bookmark = await SecurityScopedResource.instance.createBookmark(dir);
    if (bookmark != null) {
      fakeStorage['myDir'] = bookmark;
      appendLog("Bookmark stored for ${dir.path}, length=${bookmark.length}");
    }
  }

  /// 从存储里恢复 bookmark
  Future<void> restoreFromBookmark() async {
    final data = fakeStorage['myDir'];
    if (data == null) {
      appendLog("❌ No bookmark stored");
      return;
    }

    final restored = await SecurityScopedResource.instance.restoreBookmark(data);
    if (restored == null) {
      appendLog("❌ Restore failed");
      return;
    }

    appendLog("Restore result: $restored");
    // restored = { "path": "...", "stale": false, "started": true }
    if (restored["started"] == true) {
      final dir = Directory(restored["path"] as String);
      try {
        final entries = dir.listSync();
        appendLog("Restored dir listed ${entries.length} entries");
      } catch (e) {
        appendLog("Restored dir list failed: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Security Scoped Resource Example')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: pickAndBookmark,
                child: const Text("Pick & Bookmark"),
              ),
              TextButton(
                onPressed: restoreFromBookmark,
                child: const Text("Restore Bookmark"),
              ),
              const SizedBox(height: 20),
              Expanded(child: SingleChildScrollView(child: Text(log))),
            ],
          ),
        ),
      ),
    );
  }
}
