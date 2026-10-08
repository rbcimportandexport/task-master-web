import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/project.dart';

// Conditional HTML import for Web
import 'dart:html' as html;

class FilePickerService {
  /// Picks any file type (.pdf, .docx, .xlsx, .pptx, .csv, .txt, .png, etc.) across Web and Mobile
  static Future<List<ProjectAttachment>> pickAnyFiles() async {
    if (kIsWeb) {
      final completer = Completer<List<ProjectAttachment>>();
      try {
        final uploadInput = html.FileUploadInputElement();
        uploadInput.multiple = true;
        uploadInput.accept = '*/*';
        uploadInput.click();

        uploadInput.onChange.listen((e) async {
          final files = uploadInput.files;
          if (files != null && files.isNotEmpty) {
            final List<ProjectAttachment> results = [];
            for (var file in files) {
              final reader = html.FileReader();
              reader.readAsArrayBuffer(file);
              await reader.onLoadEnd.first;
              final bytes = reader.result as Uint8List?;
              String? base64Str;
              if (bytes != null && bytes.lengthInBytes <= 5 * 1024 * 1024) {
                base64Str = base64Encode(bytes);
              }
              final ext = file.name.contains('.') ? file.name.split('.').last : 'dat';
              results.add(ProjectAttachment(
                name: file.name,
                path: '',
                extension: ext,
                sizeBytes: file.size,
                base64Data: base64Str,
              ));
            }
            completer.complete(results);
          } else {
            completer.complete([]);
          }
        });
      } catch (err) {
        completer.complete([]);
      }
      return completer.future;
    } else {
      // Mobile fallback
      try {
        final picker = ImagePicker();
        final pickedFiles = await picker.pickMultipleMedia();
        if (pickedFiles.isNotEmpty) {
          final List<ProjectAttachment> results = [];
          for (var file in pickedFiles) {
            final bytes = await file.readAsBytes();
            String? base64Str;
            if (bytes.lengthInBytes <= 5 * 1024 * 1024) {
              base64Str = base64Encode(bytes);
            }
            final ext = file.name.contains('.') ? file.name.split('.').last : 'dat';
            results.add(ProjectAttachment(
              name: file.name,
              path: file.path,
              extension: ext,
              sizeBytes: bytes.lengthInBytes,
              base64Data: base64Str,
            ));
          }
          return results;
        }
      } catch (_) {}
      return [];
    }
  }
}
