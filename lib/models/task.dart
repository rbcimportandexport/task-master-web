class Subtask {
  String id;
  String title;
  bool isCompleted;

  Subtask({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
      };

  factory Subtask.fromJson(Map<String, dynamic> json) => Subtask(
        id: json['id'] as String,
        title: json['title'] as String,
        isCompleted: json['isCompleted'] as bool? ?? false,
      );
}

class Task {
  String id;
  String title;
  String category;
  DateTime? dueDate;
  bool isCompleted;
  bool isStarred;
  int priority; // 0 = none, 1 = low, 2 = medium, 3 = high
  List<Subtask> subtasks;
  String notes;
  List<String> attachments; // List of file names/URIs
  DateTime createdAt;
  DateTime? completedAt;
  int progress; // 0, 25, 50, 75, 100
  int flagColor; // 0=none, 1=pink, 2=yellow, 3=purple, 4=blue, 5=green
  String? assignedBy;
  String? estimatedTime; // e.g. "2 hours", "45 mins", "1 day"
  String? voiceNoteUrl;
  int? voiceDurationSeconds;
  bool isDeleted;
  DateTime? deletedAt;

  Task({
    required this.id,
    required this.title,
    this.category = 'No Category',
    this.dueDate,
    this.isCompleted = false,
    this.isStarred = false,
    this.priority = 0,
    List<Subtask>? subtasks,
    this.notes = '',
    List<String>? attachments,
    DateTime? createdAt,
    this.completedAt,
    this.progress = 0,
    this.flagColor = 0,
    this.assignedBy,
    this.estimatedTime,
    this.voiceNoteUrl,
    this.voiceDurationSeconds,
    this.isDeleted = false,
    this.deletedAt,
  })  : subtasks = subtasks ?? [],
        attachments = attachments ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'dueDate': dueDate?.toIso8601String(),
        'isCompleted': isCompleted,
        'isStarred': isStarred,
        'priority': priority,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
        'notes': notes,
        'attachments': attachments,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'progress': progress,
        'flagColor': flagColor,
        'assignedBy': assignedBy,
        'estimatedTime': estimatedTime,
        'voiceNoteUrl': voiceNoteUrl,
        'voiceDurationSeconds': voiceDurationSeconds,
        'isDeleted': isDeleted,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        title: json['title'] as String,
        category: json['category'] as String? ?? 'No Category',
        dueDate: json['dueDate'] != null
            ? DateTime.parse(json['dueDate'] as String)
            : null,
        isCompleted: json['isCompleted'] as bool? ?? false,
        isStarred: json['isStarred'] as bool? ?? false,
        priority: json['priority'] as int? ?? 0,
        subtasks: (json['subtasks'] as List<dynamic>?)
                ?.map((s) => Subtask.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        notes: json['notes'] as String? ?? '',
        attachments: (json['attachments'] as List<dynamic>?)
                ?.map((a) => a as String)
                .toList() ??
            [],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        progress: json['progress'] as int? ?? 0,
        flagColor: json['flagColor'] as int? ?? 0,
        assignedBy: json['assignedBy'] as String?,
        estimatedTime: json['estimatedTime'] as String?,
        voiceNoteUrl: json['voiceNoteUrl'] as String?,
        voiceDurationSeconds: json['voiceDurationSeconds'] as int?,
        isDeleted: json['isDeleted'] as bool? ?? false,
        deletedAt: json['deletedAt'] != null
            ? DateTime.parse(json['deletedAt'] as String)
            : null,
      );
}
