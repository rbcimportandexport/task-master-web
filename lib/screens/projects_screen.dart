import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/project.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/create_project_sheet.dart';
import 'project_detail_screen.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  void _openCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateProjectSheet(),
    );
  }

  Future<void> _openAttachment(BuildContext context, ProjectAttachment att) async {
    try {
      if (att.base64Data != null && att.base64Data!.isNotEmpty) {
        final bytes = base64Decode(att.base64Data!);
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/${att.name}');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(file.path)], text: 'Project Attachment: ${att.name}');
      } else if (att.path.isNotEmpty) {
        final file = File(att.path);
        if (await file.exists()) {
          await Share.shareXFiles([XFile(file.path)], text: 'Project Attachment: ${att.name}');
        } else {
          throw 'File path not accessible on this device';
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot open file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Projects', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryBlue, size: 28),
            onPressed: () => _openCreateSheet(context),
            tooltip: 'Create New Project',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Project>>(
        stream: taskProvider.getProjectsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final projects = snapshot.data ?? [];
          if (projects.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.folder_copy_rounded, size: 64, color: Color(0xFF4F46E5)),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No Projects Created Yet',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create organized project workspaces, assign team members, and attach PDF/specs documents.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _openCreateSheet(context),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Create First Project'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return _buildProjectCard(context, project, taskProvider);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateSheet(context),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Project', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, Project project, TaskProvider taskProvider) {
    final color = Color(project.colorValue);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProjectDetailScreen(project: project),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Top Row: Category & Menu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    project.category,
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz_rounded, color: Colors.grey),
                  onSelected: (val) {
                    if (val == 'delete') {
                      taskProvider.deleteProject(project.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Project deleted')),
                      );
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Delete Project', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Title
            Text(
              project.title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A)),
            ),
            if (project.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                project.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
            const SizedBox(height: 14),

            // Links / Sheets Preview on Card
            if (project.links.isNotEmpty) ...[
              const Text(
                'Sheets & Links:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: project.links.map((lnk) {
                  final isSheet = lnk.type == 'sheet';
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSheet ? const Color(0xFFE8F5E9) : const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSheet ? const Color(0xFFA5D6A7) : const Color(0xFFC7D2FE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSheet ? Icons.table_chart_rounded : Icons.link_rounded,
                          size: 15,
                          color: isSheet ? const Color(0xFF0F9D58) : const Color(0xFF4F46E5),
                        ),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 150),
                          child: Text(
                            lnk.title,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSheet ? const Color(0xFF0F9D58) : const Color(0xFF4F46E5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Open Workspace Hint
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app_rounded, size: 16, color: Color(0xFF4F46E5)),
                  SizedBox(width: 6),
                  Text(
                    'Click to open workspace (Sheets, Files & Tasks)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5)),
                  ),
                ],
              ),
            ),


            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 10),

            // Footer: Deadline & Created info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      project.createdBy.isNotEmpty ? project.createdBy : 'Admin',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                if (project.deadline != null)
                  Row(
                    children: [
                      const Icon(Icons.event_rounded, size: 16, color: Color(0xFFEF4444)),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd MMM yyyy').format(project.deadline!),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  ),
);
  }
}
