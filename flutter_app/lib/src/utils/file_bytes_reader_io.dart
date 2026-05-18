import 'dart:io';

Future<List<int>?> readFileBytes(String path) async {
  final file = File(path);
  if (!await file.exists()) return null;
  return file.readAsBytes();
}
