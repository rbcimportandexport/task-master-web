import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../services/file_picker_service.dart';
import '../theme/app_theme.dart';
import '../widgets/task_add_sheet.dart';
import '../widgets/sheet_view/in_app_sheet_viewer.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;
  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Project _project;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _launchUrlLink(String urlStr) async {
    try {
      String formattedUrl = urlStr.trim();
      if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
        formattedUrl = 'https://$formattedUrl';
      }
      final uri = Uri.parse(formattedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch URL';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening link: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _openAttachment(ProjectAttachment att) async {
    try {
      if (att.base64Data != null && att.base64Data!.isNotEmpty) {
        final bytes = base64Decode(att.base64Data!);
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/${att.name}');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(file.path)], text: 'Attachment: ${att.name}');
      } else if (att.path.isNotEmpty) {
        final file = File(att.path);
        if (await file.exists()) {
          await Share.shareXFiles([XFile(file.path)], text: 'Attachment: ${att.name}');
        } else {
          throw 'File path not accessible on this device';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot open file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addNewLink() async {
    final urlController = TextEditingController();
    final titleController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.link_rounded, color: Color(0xFF4F46E5)),
            SizedBox(width: 10),
            Text('Add Google Sheet / Link', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: 'URL *',
                hintText: 'https://docs.google.com/spreadsheets/...',
                prefixIcon: const Icon(Icons.language_rounded, color: Color(0xFF4F46E5)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Label (optional)',
                hintText: 'e.g. Sales Sheet Q4',
                prefixIcon: const Icon(Icons.label_outline_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Link'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final url = urlController.text.trim();
              if (url.isEmpty) return;
              final type = ProjectLink.detectType(url);
              final label = titleController.text.trim().isEmpty ? _defaultLinkLabel(type) : titleController.text.trim();
              final newLink = ProjectLink(title: label, url: url, type: type);
              final updatedLinks = List<ProjectLink>.from(_project.links)..add(newLink);
              final updatedProject = _project.copyWith(links: updatedLinks);

              final taskProvider = context.read<TaskProvider>();
              await taskProvider.updateProject(updatedProject);
              if (mounted) {
                setState(() => _project = updatedProject);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link added successfully!'), backgroundColor: Color(0xFF10B981)),
                );
              }
            },
          ),
        ],
      ),
    );
    urlController.dispose();
    titleController.dispose();
  }

  Future<void> _uploadNewFiles() async {
    try {
      final newAtts = await FilePickerService.pickAnyFiles();

      if (newAtts.isNotEmpty) {
        final updatedAtts = List<ProjectAttachment>.from(_project.attachments)..addAll(newAtts);
        final updatedProject = _project.copyWith(attachments: updatedAtts);
        final taskProvider = context.read<TaskProvider>();
        await taskProvider.updateProject(updatedProject);
        if (mounted) {
          setState(() => _project = updatedProject);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${newAtts.length} file${newAtts.length > 1 ? "s" : ""} attached successfully!'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Create a new document/file or attach existing directly inside the project
  Future<void> _createNewDocFile() async {
    final fileNameController = TextEditingController();
    final contentController = TextEditingController();
    String fileType = 'docx'; // default to Word document

    final fileTypesList = [
      {'ext': 'docx', 'label': 'Word Doc (.docx)', 'icon': Icons.description_rounded, 'color': const Color(0xFF2563EB)},
      {'ext': 'pdf', 'label': 'PDF Document (.pdf)', 'icon': Icons.picture_as_pdf_rounded, 'color': const Color(0xFFDC2626)},
      {'ext': 'pptx', 'label': 'PowerPoint PPT (.pptx)', 'icon': Icons.slideshow_rounded, 'color': const Color(0xFFEA580C)},
      {'ext': 'xlsx', 'label': 'Excel Sheet (.xlsx)', 'icon': Icons.table_view_rounded, 'color': const Color(0xFF16A34A)},
      {'ext': 'txt', 'label': 'Text File (.txt)', 'icon': Icons.article_rounded, 'color': const Color(0xFF64748B)},
      {'ext': 'notes', 'label': 'Quick Notes (.notes)', 'icon': Icons.sticky_note_2_rounded, 'color': const Color(0xFFD97706)},
      {'ext': 'md', 'label': 'Markdown (.md)', 'icon': Icons.text_snippet_rounded, 'color': const Color(0xFF7C3AED)},
      {'ext': 'csv', 'label': 'CSV Table (.csv)', 'icon': Icons.grid_on_rounded, 'color': const Color(0xFF059669)},
      {'ext': 'json', 'label': 'JSON / Code (.json)', 'icon': Icons.code_rounded, 'color': const Color(0xFF0284C7)},
      {'ext': 'html', 'label': 'HTML Page (.html)', 'icon': Icons.html_rounded, 'color': const Color(0xFFE11D48)},
    ];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Row(
            children: [
              Icon(Icons.create_new_folder_rounded, color: Color(0xFF4F46E5), size: 24),
              SizedBox(width: 10),
              Text('Create or Attach File', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Direct Attach from Storage Banner
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF4F46E5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.upload_file_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Have a file on device?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF312E81))),
                              Text('Attach Word, PDF, PPT, Excel, etc.', style: TextStyle(fontSize: 11, color: Color(0xFF4338CA))),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _uploadNewFiles();
                          },
                          icon: const Icon(Icons.attach_file_rounded, size: 16),
                          label: const Text('Attach File'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 14),

                  const Text('Or Create / Compose New:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                  const SizedBox(height: 8),

                  TextField(
                    controller: fileNameController,
                    autofocus: true,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      labelText: 'File / Document Title *',
                      hintText: 'e.g. Project Proposal, Sales PPT, Annual Report',
                      prefixIcon: const Icon(Icons.edit_note_rounded, color: Color(0xFF4F46E5)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Format / Type:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: fileTypesList.map((item) {
                      final isSelected = fileType == item['ext'];
                      final itemColor = item['color'] as Color;
                      return ChoiceChip(
                        avatar: Icon(item['icon'] as IconData, size: 16, color: isSelected ? Colors.white : itemColor),
                        label: Text(item['label'] as String),
                        selected: isSelected,
                        selectedColor: itemColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF0F172A),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        backgroundColor: (itemColor).withValues(alpha: 0.08),
                        side: BorderSide(color: isSelected ? itemColor : const Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        onSelected: (selected) {
                          if (selected) setDialogState(() => fileType = item['ext'] as String);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    maxLines: 7,
                    decoration: InputDecoration(
                      labelText: 'Document Content & Body *',
                      hintText: 'Write your text, points, data, headings, or outline here...',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_rounded, size: 18),
              label: const Text('Create & Save File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                var name = fileNameController.text.trim();
                if (name.isEmpty) name = 'untitled_document';
                if (!name.contains('.')) {
                  name = '$name.$fileType';
                }
                final content = contentController.text;
                final bytes = utf8.encode(content);
                final base64Str = base64Encode(bytes);

                final newAtt = ProjectAttachment(
                  name: name,
                  path: '',
                  extension: fileType,
                  sizeBytes: bytes.length,
                  base64Data: base64Str,
                );

                final updatedAtts = List<ProjectAttachment>.from(_project.attachments)..add(newAtt);
                final updatedProject = _project.copyWith(attachments: updatedAtts);
                await context.read<TaskProvider>().updateProject(updatedProject);

                if (mounted) {
                  setState(() => _project = updatedProject);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$name created successfully!'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
    fileNameController.dispose();
    contentController.dispose();
  }

  String _defaultLinkLabel(String type) {
    switch (type) {
      case 'sheet': return 'Google Sheet';
      case 'doc': return 'Google Doc';
      case 'slides': return 'Google Slides';
      case 'form': return 'Google Form';
      case 'drive': return 'Google Drive';
      case 'youtube': return 'YouTube Video';
      default: return 'Web Link';
    }
  }

  IconData _linkIcon(String type) {
    switch (type) {
      case 'sheet': return Icons.table_chart_rounded;
      case 'doc': return Icons.description_rounded;
      case 'slides': return Icons.slideshow_rounded;
      case 'form': return Icons.assignment_rounded;
      case 'drive': return Icons.folder_rounded;
      case 'youtube': return Icons.play_circle_rounded;
      default: return Icons.language_rounded;
    }
  }

  Color _linkColor(String type) {
    switch (type) {
      case 'sheet': return const Color(0xFF0F9D58);
      case 'doc': return const Color(0xFF4285F4);
      case 'slides': return const Color(0xFFF4B400);
      case 'form': return const Color(0xFF9C27B0);
      case 'drive': return const Color(0xFF0288D1);
      case 'youtube': return const Color(0xFFFF0000);
      default: return const Color(0xFF4F46E5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(_project.colorValue);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_project.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A))),
            Text(_project.category, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: color,
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: color,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          tabs: [
            Tab(
              icon: const Icon(Icons.table_chart_rounded, size: 20),
              text: 'Sheets & Links (${_project.links.length})',
            ),
            Tab(
              icon: const Icon(Icons.folder_open_rounded, size: 20),
              text: 'Files (${_project.attachments.length})',
            ),
            const Tab(
              icon: Icon(Icons.task_alt_rounded, size: 20),
              text: 'Tasks',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLinksTab(),
          _buildFilesTab(),
          _buildTasksTab(),
        ],
      ),
    );
  }

  // ── 1. Sheets & Links Tab ───────────────────────────────────────────────
  Widget _buildLinksTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Google Sheets & Web Links',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
            ),
            ElevatedButton.icon(
              onPressed: _addNewLink,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Sheet/Link'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F9D58),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (_project.links.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.only(top: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.table_chart_rounded, size: 48, color: Color(0xFF0F9D58)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Google Sheets or Links Yet',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Click "Add Sheet/Link" above to attach Google Spreadsheets, Docs, Drive folders, or YouTube videos to this project.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          )
        else
          ..._project.links.map((link) {
            final linkColor = _linkColor(link.type);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: linkColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_linkIcon(link.type), color: linkColor, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              link.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              link.url,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 20),
                        tooltip: 'Delete Link',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () async {
                          final updated = List<ProjectLink>.from(_project.links)..remove(link);
                          final newProj = _project.copyWith(links: updated);
                          await context.read<TaskProvider>().updateProject(newProj);
                          setState(() => _project = newProj);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          InAppSheetViewerScreen.open(
                            context,
                            title: link.title,
                            url: link.url,
                            project: _project,
                          );
                        },
                        icon: const Icon(Icons.edit_document, size: 15),
                        label: const Text('Open & Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F9D58),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _launchUrlLink(link.url),
                        icon: const Icon(Icons.open_in_new_rounded, size: 14),
                        label: const Text('New Tab'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF059669)),
                            SizedBox(width: 4),
                            Text('Auto-Saved', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ── 2. Files & Docs Tab ────────────────────────────────────────────────
  Widget _buildFilesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            const Text(
              'Project Files & Documents',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: _createNewDocFile,
                  icon: const Icon(Icons.note_add_rounded, size: 18),
                  label: const Text('Create File'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4F46E5),
                    side: const BorderSide(color: Color(0xFF4F46E5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _uploadNewFiles,
                  icon: const Icon(Icons.attach_file_rounded, size: 18),
                  label: const Text('Attach File (PC / Phone)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (_project.attachments.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEF2FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.file_present_rounded, size: 48, color: Color(0xFF4F46E5)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Files Attached Yet',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Attach existing Word, PDF, Excel, PPT, or Image files from your device, or create new files directly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _uploadNewFiles,
                      icon: const Icon(Icons.attach_file_rounded, size: 18),
                      label: const Text('Attach File from Device'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _createNewDocFile,
                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                      label: const Text('Create New File'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4F46E5),
                        side: const BorderSide(color: Color(0xFF4F46E5)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          ..._project.attachments.map((att) {
            final isPdf = att.extension.toLowerCase().contains('pdf');
            final isImg = ['png', 'jpg', 'jpeg', 'webp', 'gif'].contains(att.extension.toLowerCase());
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ListTile(
                onTap: () {
                  final ext = att.extension.toLowerCase();
                  if (ext == 'csv' || ext == 'xlsx' || ext == 'sheet') {
                    InAppSheetViewerScreen.open(
                      context,
                      title: att.name,
                      url: 'https://docs.google.com/spreadsheets/create',
                      project: _project,
                    );
                    return;
                  }

                  if (att.base64Data != null && att.base64Data!.isNotEmpty) {
                    try {
                      final content = utf8.decode(base64Decode(att.base64Data!));
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          title: Row(
                            children: [
                              const Icon(Icons.article_rounded, color: Color(0xFF4F46E5)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(att.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                            ],
                          ),
                          content: Container(
                            width: double.maxFinite,
                            constraints: const BoxConstraints(maxHeight: 350),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: SingleChildScrollView(
                              child: SelectableText(
                                content,
                                style: const TextStyle(fontSize: 13, height: 1.5, fontFamily: 'monospace'),
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                          ],
                        ),
                      );
                    } catch (_) {
                      _openAttachment(att);
                    }
                  } else {
                    _openAttachment(att);
                  }
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: () {
                  final ext = att.extension.toLowerCase();
                  IconData fileIcon = Icons.insert_drive_file_rounded;
                  Color fileColor = const Color(0xFF4F46E5);
                  Color fileBg = const Color(0xFFEEF2FF);

                  if (ext.contains('pdf')) {
                    fileIcon = Icons.picture_as_pdf_rounded;
                    fileColor = const Color(0xFFDC2626);
                    fileBg = const Color(0xFFFEE2E2);
                  } else if (ext.contains('doc') || ext.contains('docx')) {
                    fileIcon = Icons.description_rounded;
                    fileColor = const Color(0xFF2563EB);
                    fileBg = const Color(0xFFEFF6FF);
                  } else if (ext.contains('ppt') || ext.contains('pptx')) {
                    fileIcon = Icons.slideshow_rounded;
                    fileColor = const Color(0xFFEA580C);
                    fileBg = const Color(0xFFFFF7ED);
                  } else if (ext.contains('xls') || ext.contains('xlsx') || ext.contains('csv')) {
                    fileIcon = Icons.table_view_rounded;
                    fileColor = const Color(0xFF16A34A);
                    fileBg = const Color(0xFFF0FDF4);
                  } else if (['png', 'jpg', 'jpeg', 'webp', 'gif'].contains(ext)) {
                    fileIcon = Icons.image_rounded;
                    fileColor = const Color(0xFF9333EA);
                    fileBg = const Color(0xFFFAF5FF);
                  } else if (ext.contains('notes')) {
                    fileIcon = Icons.sticky_note_2_rounded;
                    fileColor = const Color(0xFFD97706);
                    fileBg = const Color(0xFFFFFBEB);
                  } else if (ext.contains('md')) {
                    fileIcon = Icons.text_snippet_rounded;
                    fileColor = const Color(0xFF7C3AED);
                    fileBg = const Color(0xFFF5F3FF);
                  } else if (ext.contains('json') || ext.contains('js') || ext.contains('dart')) {
                    fileIcon = Icons.code_rounded;
                    fileColor = const Color(0xFF0284C7);
                    fileBg = const Color(0xFFF0F9FF);
                  }

                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: fileBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      fileIcon,
                      color: fileColor,
                      size: 24,
                    ),
                  );
                }(),
                title: Text(
                  att.name,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                ),
                subtitle: Text(
                  '${(att.sizeBytes / 1024).toStringAsFixed(1)} KB • ${att.extension.toUpperCase()}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.download_rounded, color: Color(0xFF4F46E5)),
                      onPressed: () => _openAttachment(att),
                      tooltip: 'Download / Share',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey),
                      onPressed: () async {
                        final updated = List<ProjectAttachment>.from(_project.attachments)..remove(att);
                        final newProj = _project.copyWith(attachments: updated);
                        await context.read<TaskProvider>().updateProject(newProj);
                        setState(() => _project = newProj);
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // ── 3. Tasks Tab ───────────────────────────────────────────────────────
  Widget _buildTasksTab() {
    final taskProvider = Provider.of<TaskProvider>(context);
    final projectTasks = taskProvider.tasks.where((t) => t.category.toLowerCase() == _project.category.toLowerCase()).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tasks in ${_project.category} (${projectTasks.length})',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const TaskAddSheet(),
                );
              },
              icon: const Icon(Icons.add_task_rounded, size: 18),
              label: const Text('Add Task'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (projectTasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.only(top: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 48, color: Color(0xFF10B981)),
                SizedBox(height: 16),
                Text('No Active Tasks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text('Create tasks and assign team members under this project category.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              ],
            ),
          )
        else
          ...projectTasks.map((t) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: Checkbox(
                value: t.isCompleted,
                onChanged: (val) => taskProvider.toggleTaskCompletion(t.id),
              ),
              title: Text(
                t.title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  decoration: t.isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: t.notes.isNotEmpty
                  ? Text(t.notes, maxLines: 1, overflow: TextOverflow.ellipsis)
                  : null,
            ),
          )),
      ],
    );
  }
}
