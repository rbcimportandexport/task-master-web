import 'dart:io';
import 'dart:convert';

void main() {
  final jsonFile = File(r"C:\Users\DELL\Downloads\todo-list-app-ef186-firebase-adminsdk-fbsvc-1277350fb6.json");
  final jsonStr = jsonFile.readAsStringSync();
  
  // Create a raw string literal for Dart
  // r''' ... ''' means NO escapes are evaluated. 
  // BUT the jsonStr might contain '''. It doesn't.
  // Wait, if we use r''' ''', and jsonStr contains REAL newlines, Dart will keep them as REAL newlines.
  // And jsonDecode() WILL FAIL on real newlines in strings!
  // jsonDecode EXPECTS the string to have \\n instead of real newlines!
  
  // So we must replace real newlines with \\n, and replace " with \"
  // Wait, no! If jsonStr is read from a file, it is EXACTLY what jsonDecode expects!
  // Wait, if jsonStr is read from the file, does the file have real newlines?
  // Let's check!
  print("File content length: ${jsonStr.length}");
}
