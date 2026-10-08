class ProjectAttachment {
  final String name;
  final String path;
  final String extension;
  final int sizeBytes;
  final String? base64Data;

  ProjectAttachment({
    required this.name,
    required this.path,
    required this.extension,
    required this.sizeBytes,
    this.base64Data,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'path': path,
        'extension': extension,
        'sizeBytes': sizeBytes,
        'base64Data': base64Data,
      };

  factory ProjectAttachment.fromJson(Map<String, dynamic> json) =>
      ProjectAttachment(
        name: json['name'] as String? ?? 'file',
        path: json['path'] as String? ?? '',
        extension: json['extension'] as String? ?? '',
        sizeBytes: json['sizeBytes'] as int? ?? 0,
        base64Data: json['base64Data'] as String?,
      );
}

/// Represents an external URL link (Google Sheet, Doc, YouTube, etc.)
class ProjectLink {
  final String title;
  final String url;
  final String type; // 'sheet', 'doc', 'youtube', 'other'

  ProjectLink({
    required this.title,
    required this.url,
    this.type = 'other',
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'url': url,
        'type': type,
      };

  factory ProjectLink.fromJson(Map<String, dynamic> json) => ProjectLink(
        title: json['title'] as String? ?? 'Link',
        url: json['url'] as String? ?? '',
        type: json['type'] as String? ?? 'other',
      );

  /// Auto-detect type from URL
  static String detectType(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('docs.google.com/spreadsheets')) return 'sheet';
    if (lower.contains('docs.google.com/document')) return 'doc';
    if (lower.contains('docs.google.com/presentation')) return 'slides';
    if (lower.contains('docs.google.com/forms')) return 'form';
    if (lower.contains('youtube.com') || lower.contains('youtu.be')) return 'youtube';
    if (lower.contains('drive.google.com')) return 'drive';
    return 'other';
  }
}

class Project {
  final String id;
  final String title;
  final String description;
  final String category;
  final int colorValue; // Color ARGB
  final DateTime? deadline;
  final DateTime createdAt;
  final String createdBy;
  final List<String> assignedUsers;
  final List<ProjectAttachment> attachments;
  final List<ProjectLink> links; // Google Sheets, Docs, YouTube, etc.
  final String status; // 'Active', 'In Progress', 'Completed', 'On Hold'
  final int progress; // 0 - 100

  Project({
    required this.id,
    required this.title,
    this.description = '',
    this.category = 'General',
    this.colorValue = 0xFF4F46E5,
    this.deadline,
    DateTime? createdAt,
    this.createdBy = '',
    List<String>? assignedUsers,
    List<ProjectAttachment>? attachments,
    List<ProjectLink>? links,
    this.status = 'Active',
    this.progress = 0,
  })  : createdAt = createdAt ?? DateTime.now(),
        assignedUsers = assignedUsers ?? [],
        attachments = attachments ?? [],
        links = links ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'colorValue': colorValue,
        'deadline': deadline?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'createdBy': createdBy,
        'assignedUsers': assignedUsers,
        'attachments': attachments.map((a) => a.toJson()).toList(),
        'links': links.map((l) => l.toJson()).toList(),
        'status': status,
        'progress': progress,
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        category: json['category'] as String? ?? 'General',
        colorValue: json['colorValue'] as int? ?? 0xFF4F46E5,
        deadline: json['deadline'] != null ? DateTime.tryParse(json['deadline']) : null,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
            : DateTime.now(),
        createdBy: json['createdBy'] as String? ?? '',
        assignedUsers: (json['assignedUsers'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        attachments: (json['attachments'] as List<dynamic>?)
                ?.map((e) => ProjectAttachment.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        links: (json['links'] as List<dynamic>?)
                ?.map((e) => ProjectLink.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        status: json['status'] as String? ?? 'Active',
        progress: json['progress'] as int? ?? 0,
      );

  Project copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    int? colorValue,
    DateTime? deadline,
    DateTime? createdAt,
    String? createdBy,
    List<String>? assignedUsers,
    List<ProjectAttachment>? attachments,
    List<ProjectLink>? links,
    String? status,
    int? progress,
  }) {
    return Project(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      colorValue: colorValue ?? this.colorValue,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      assignedUsers: assignedUsers ?? this.assignedUsers,
      attachments: attachments ?? this.attachments,
      links: links ?? this.links,
      status: status ?? this.status,
      progress: progress ?? this.progress,
    );
  }
}
