class Task {
  final String id;
  final String title;
  final String? description;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? deadline;
  final String userId;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.isCompleted,
    required this.createdAt,
    this.deadline,
    required this.userId,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(String? dateString) {
      if (dateString == null) return DateTime.now();
      
      final dateTime = DateTime.parse(dateString);
      if (dateTime.isUtc) {
        return dateTime.toLocal();
      }
      return dateTime;
    }
    
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      isCompleted: json['is_completed'] as bool,
      createdAt: parseDateTime(json['created_at'] as String),
      deadline: json['deadline'] != null ? parseDateTime(json['deadline'] as String) : null,
      userId: json['user_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'user_id': userId,
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? deadline,
    String? userId,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      deadline: deadline ?? this.deadline,
      userId: userId ?? this.userId,
    );
  }
} 