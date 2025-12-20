import 'dart:io';

List<String> readFile(String path) {
  File file = File(path);
  return file.readAsLinesSync();
}
