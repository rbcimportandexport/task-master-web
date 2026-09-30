import 'dart:io';
import 'dart:convert';

void main() {
  final jsonFile = File(r"C:\Users\DELL\Downloads\todo-list-app-ef186-firebase-adminsdk-fbsvc-1277350fb6.json");
  final jsonStr = jsonFile.readAsStringSync();
  
  // We need to embed this EXACT string into a Dart file as a String literal.
  // The easiest way is to JSON encode it AGAIN, which will wrap it in quotes and escape everything!
  final dartStringLiteral = jsonEncode(jsonStr); 

  final dartFile = File(r"d:\TO DO LIST\lib\services\fcm_service.dart");
  var content = dartFile.readAsStringSync();
  
  final regex = RegExp(r"static const String _serviceAccountJson = .*?;", multiLine: true, dotAll: true);
  content = content.replaceAll(regex, "static const String _serviceAccountJson = $dartStringLiteral;");
  
  dartFile.writeAsStringSync(content);
  print("Fixed JSON escaping using Dart's own jsonEncode!");
}
