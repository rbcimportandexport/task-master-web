import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/project.dart';
import 'sheet_view_stub.dart' if (dart.library.html) 'sheet_view_web.dart' as platform_sheet;

class InAppSheetViewerScreen extends StatefulWidget {
  final String title;
  final String url;
  final Project? project;

  const InAppSheetViewerScreen({
    super.key,
    required this.title,
    required this.url,
    this.project,
  });

  static Future<void> open(BuildContext context, {
    required String title,
    required String url,
    Project? project,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InAppSheetViewerScreen(
          title: title,
          url: url,
          project: project,
        ),
      ),
    );
  }

  @override
  State<InAppSheetViewerScreen> createState() => _InAppSheetViewerScreenState();
}

class _InAppSheetViewerScreenState extends State<InAppSheetViewerScreen> {
  int _reloadKey = 0;
  bool _directGoogleEmbed = false;

  void _reload() {
    setState(() {
      _reloadKey++;
    });
  }

  Future<void> _openExternal() async {
    final effectiveUrl = widget.url.trim().isNotEmpty
        ? widget.url.trim()
        : 'https://docs.google.com/spreadsheets/create';
    final uri = Uri.parse(effectiveUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final effectiveUrl = widget.url.trim().isNotEmpty
        ? widget.url.trim()
        : 'https://docs.google.com/spreadsheets/create';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.table_chart_rounded, color: Color(0xFF10B981), size: 18),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.title.isNotEmpty ? widget.title : 'Google Sheet',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569), size: 20),
            tooltip: 'Reload Sheet',
            onPressed: _reload,
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded, color: Color(0xFF475569), size: 20),
            tooltip: 'Open in Google Sheets',
            onPressed: _openExternal,
          ),
          PopupMenuButton<bool>(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF475569), size: 20),
            tooltip: 'View mode',
            initialValue: _directGoogleEmbed,
            onSelected: (val) => setState(() => _directGoogleEmbed = val),
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: false,
                child: Row(
                  children: [
                    Icon(Icons.grid_on_rounded, size: 18, color: Color(0xFF10B981)),
                    SizedBox(width: 8),
                    Text('Full Spreadsheet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: true,
                child: Row(
                  children: [
                    Icon(Icons.web_rounded, size: 18, color: Color(0xFF4F46E5)),
                    SizedBox(width: 8),
                    Text('Raw Web Embed', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SizedBox.expand(
        child: KeyedSubtree(
          key: ValueKey('sheet-$_reloadKey-$_directGoogleEmbed-$effectiveUrl'),
          child: platform_sheet.buildPlatformSheetView(
            url: effectiveUrl,
            viewId: 'sheet_$_reloadKey',
            title: widget.title,
            directGoogleEmbed: _directGoogleEmbed,
          ),
        ),
      ),
    );
  }
}


