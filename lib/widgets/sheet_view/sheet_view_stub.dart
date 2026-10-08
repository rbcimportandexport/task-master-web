import 'package:flutter/material.dart';

Widget buildPlatformSheetView({
  required String url,
  required String viewId,
  String title = 'Untitled spreadsheet',
  bool directGoogleEmbed = false,
}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.table_chart_rounded, size: 48, color: Color(0xFF10B981)),
        const SizedBox(height: 12),
        const Text(
          'Sheet In-App Viewer',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          url,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
