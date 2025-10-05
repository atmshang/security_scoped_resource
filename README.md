# security_scoped_resource

[![Pub](https://img.shields.io/pub/v/security_scoped_resource?color=green)](https://pub.dev/packages/security_scoped_resource)

A Flutter plugin that allows iOS apps to access security‑scoped resources (files and directories picked via `UIDocumentPicker`).  
Now with **persisted bookmark support**, so your app can keep accessing files across app restarts.

---

## Features

- ✅ Access picked files & directories with `startAccessingSecurityScopedResource` / `stopAccessingSecurityScopedResource`  
- ✅ Create `security-scoped bookmarks` for long‑term access  
- ✅ Restore bookmarks after restart to regain access without asking user to pick again  

---

## Usage

### Temporary access (current session only)

```dart
final dir = Directory(pathFromFilePicker);

// Start accessing
await SecurityScopedResource.instance.startAccessingSecurityScopedResource(dir);

// Do file I/O
final files = dir.listSync();

// Stop accessing when done
await SecurityScopedResource.instance.stopAccessingSecurityScopedResource(dir);
```

---

### Persisted access with bookmarks

```dart
// 1. Create bookmark right after user picks a file/dir
final bookmark = await SecurityScopedResource.instance.createBookmark(dir);

// Save [bookmark] (a Uint8List) using Hive / SharedPreferences / DB
await box.put('myDirBookmark', bookmark);
```

Later (even after app restart):

```dart
// 2. Restore bookmark from storage
final Uint8List? data = box.get('myDirBookmark');
if (data != null) {
  final restored = await SecurityScopedResource.instance.restoreBookmark(data);

  print(restored);
  // => { "path": "...", "stale": false, "started": true }

  if (restored["started"] == true) {
    final dir = Directory(restored["path"] as String);
    final entries = dir.listSync();
    print("Restored dir has ${entries.length} entries");
  }
}
```

---

## API

```dart
Future<bool> startAccessingSecurityScopedResource(FileSystemEntity entity);
Future<bool> stopAccessingSecurityScopedResource(FileSystemEntity entity);

Future<Uint8List?> createBookmark(FileSystemEntity entity);
Future<Map<String, dynamic>?> restoreBookmark(Uint8List bookmarkData);
```

---

## Notes

- You still need to let the user pick the file/directory once via a file picker.  
- Only **bookmarkData (Uint8List)** can be used for persistence — plain paths (`String`) will not keep permissions after app restart.  
- Always call `stopAccessingSecurityScopedResource` when you no longer need to access the resource.  

---
