import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../providers/task_provider.dart';
import '../services/file_picker_service.dart';
import '../theme/app_theme.dart';

class CreateProjectSheet extends StatefulWidget {
  const CreateProjectSheet({super.key});

  @override
  State<CreateProjectSheet> createState() => _CreateProjectSheetState();
}

class _CreateProjectSheetState extends State<CreateProjectSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  
  String _selectedCategory = 'Work';
  DateTime? _selectedDeadline;
  int _selectedColor = 0xFF4F46E5;
  bool _isLoading = false;
  bool _isDragOver = false; // drag-over highlight state

  final List<ProjectAttachment> _attachments = [];
  final List<ProjectLink> _links = []; // Google Sheet / URL links
  final List<String> _assignedUsers = [];
  List<Map<String, dynamic>> _availableUsers = [];

  final List<String> _categories = ['Work', 'Personal', 'Office', 'IT Support', 'Marketing', 'Management'];
  final List<int> _palette = [
    0xFF4F46E5, // Indigo
    0xFF0D9488, // Teal
    0xFF2563EB, // Blue
    0xFFE11D48, // Rose
    0xFFD97706, // Amber
    0xFF7C3AED, // Violet
    0xFF059669, // Emerald
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final taskProvider = context.read<TaskProvider>();
    final users = await taskProvider.getEmployees();
    if (mounted) {
      setState(() {
        _availableUsers = users;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  /// Show dialog to add a Google Sheet / external URL link
  Future<void> _addLink() async {
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
            Text('Add Link', style: TextStyle(fontWeight: FontWeight.w800)),
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
            label: const Text('Add'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final url = urlController.text.trim();
              if (url.isEmpty) return;
              final type = ProjectLink.detectType(url);
              final label = titleController.text.trim().isEmpty
                  ? _defaultLinkLabel(type)
                  : titleController.text.trim();
              setState(() {
                _links.add(ProjectLink(title: label, url: url, type: type));
              });
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
    urlController.dispose();
    titleController.dispose();
  }

  String _defaultLinkLabel(String type) {
    switch (type) {
      case 'sheet': return 'Google Sheet';
      case 'doc': return 'Google Doc';
      case 'slides': return 'Google Slides';
      case 'form': return 'Google Form';
      case 'drive': return 'Google Drive';
      case 'youtube': return 'YouTube Video';
      default: return 'External Link';
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
      default: return Icons.link_rounded;
    }
  }

  Color _linkColor(String type) {
    switch (type) {
      case 'sheet': return const Color(0xFF0F9D58); // Google Sheets green
      case 'doc': return const Color(0xFF4285F4);   // Google Docs blue
      case 'slides': return const Color(0xFFF4B400); // Google Slides yellow
      case 'form': return const Color(0xFF9C27B0);  // Google Forms purple
      case 'drive': return const Color(0xFF0288D1); // Drive blue
      case 'youtube': return const Color(0xFFFF0000); // YouTube red
      default: return const Color(0xFF64748B);
    }
  }

  Future<void> _pickFiles() async {
    try {
      final newAtts = await FilePickerService.pickAnyFiles();

      if (newAtts.isNotEmpty) {
        setState(() {
          _attachments.addAll(newAtts);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File selection error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submit(TaskProvider taskProvider) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await taskProvider.createProject(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: _selectedCategory,
        colorValue: _selectedColor,
        deadline: _selectedDeadline,
        assignedUsers: _assignedUsers,
        attachments: _attachments,
        links: _links,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project created successfully with all attachments!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating project: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Color(_selectedColor).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.folder_special_rounded, color: Color(_selectedColor), size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Create New Project',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Title input
              TextFormField(
                controller: _titleController,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Project Title *',
                  hintText: 'e.g. Website Redesign Q4',
                  prefixIcon: const Icon(Icons.title_rounded, color: AppTheme.primaryBlue),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Project title enter karein' : null,
              ),
              const SizedBox(height: 14),

              const SizedBox(height: 16),

              // File & PDF Attachments Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.attach_file_rounded, size: 18, color: Color(0xFF0F172A)),
                      SizedBox(width: 6),
                      Text(
                        'Project Attachments (PDF / Docs)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: _pickFiles,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add File / PDF'),
                    style: TextButton.styleFrom(foregroundColor: AppTheme.primaryBlue),
                  ),
                ],
              ),

              if (_attachments.isEmpty)
                DragTarget<List<XFile>>(
                  onWillAcceptWithDetails: (details) {
                    setState(() => _isDragOver = true);
                    return true;
                  },
                  onLeave: (_) => setState(() => _isDragOver = false),
                  onAcceptWithDetails: (details) async {
                    setState(() => _isDragOver = false);
                    for (final file in details.data) {
                      final bytes = await file.readAsBytes();
                      String? base64Str;
                      if (bytes.lengthInBytes <= 500 * 1024) {
                        base64Str = base64Encode(bytes);
                      }
                      final ext = file.name.contains('.') ? file.name.split('.').last : 'dat';
                      setState(() {
                        _attachments.add(ProjectAttachment(
                          name: file.name,
                          path: file.path,
                          extension: ext,
                          sizeBytes: bytes.lengthInBytes,
                          base64Data: base64Str,
                        ));
                      });
                    }
                  },
                  builder: (context, candidateData, rejectedData) {
                    final isHighlighted = _isDragOver || candidateData.isNotEmpty;
                    return GestureDetector(
                      onTap: _pickFiles,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isHighlighted
                                ? const Color(0xFFEFF6FF)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isHighlighted
                                  ? AppTheme.primaryBlue
                                  : const Color(0xFFCBD5E1),
                              width: isHighlighted ? 2 : 1.5,
                              style: BorderStyle.solid,
                            ),
                            boxShadow: isHighlighted
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isHighlighted
                                    ? Icons.cloud_done_rounded
                                    : Icons.cloud_upload_outlined,
                                color: isHighlighted
                                    ? AppTheme.primaryBlue
                                    : const Color(0xFF94A3B8),
                                size: 36,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                isHighlighted
                                    ? 'Drop files here!'
                                    : 'Click to browse or drag & drop files here',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isHighlighted
                                      ? AppTheme.primaryBlue
                                      : const Color(0xFF64748B),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'PDF, Images, Docs — max 500KB each',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade400,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _attachments.map((att) {
                    final isPdf = att.extension.toLowerCase().contains('pdf');
                    return Chip(
                      avatar: Icon(
                        isPdf ? Icons.picture_as_pdf_rounded : Icons.insert_drive_file_rounded,
                        size: 18,
                        color: isPdf ? Colors.red : AppTheme.primaryBlue,
                      ),
                      label: Text(
                        att.name,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      deleteIcon: const Icon(Icons.cancel_rounded, size: 16),
                      onDeleted: () {
                        setState(() => _attachments.remove(att));
                      },
                      backgroundColor: const Color(0xFFF1F5F9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    );
                  }).toList(),
                ),



              const SizedBox(height: 16),

              // ── Links Section (Google Sheet, Doc, YouTube, etc.) ──────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.link_rounded, size: 18, color: Color(0xFF0F172A)),
                      SizedBox(width: 6),
                      Text(
                        'Links (Sheet / Doc / YouTube)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: _addLink,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Link'),
                    style: TextButton.styleFrom(foregroundColor: Color(0xFF0F9D58)),
                  ),
                ],
              ),
              if (_links.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.table_chart_rounded, color: Color(0xFF0F9D58), size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Google Sheet, Doc, YouTube ya koi bhi link add karein',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _links.map((link) {
                    final color = _linkColor(link.type);
                    return Chip(
                      avatar: Icon(_linkIcon(link.type), size: 16, color: color),
                      label: Text(
                        link.title,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      deleteIcon: Icon(Icons.cancel_rounded, size: 16, color: color.withValues(alpha: 0.7)),
                      onDeleted: () => setState(() => _links.remove(link)),
                      backgroundColor: color.withValues(alpha: 0.10),
                      side: BorderSide(color: color.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 24),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _submit(taskProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(_selectedColor),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_circle_rounded),
                  label: Text(
                    _isLoading ? 'Creating Project...' : 'Create Project',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
