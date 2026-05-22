import '../../core/utils/reminder_time.dart';

class TaskLog {
  const TaskLog({
    required this.id,
    required this.taskType,
    required this.referenceId,
    required this.scheduledAt,
    required this.status,
    this.completedAt,
    this.notes,
    this.mood,
    this.symptomNotes,
    this.completionProofPhotoPath,
    this.completionProofCapturedAt,
    this.completionProofUploadedAt,
  });

  final String id;
  final String taskType;
  final String referenceId;
  final DateTime scheduledAt;
  final DateTime? completedAt;
  final String status;
  final String? notes;
  final String? mood; // 'good', 'neutral', 'bad'
  final String? symptomNotes;
  final String? completionProofPhotoPath;
  final DateTime? completionProofCapturedAt;
  final DateTime? completionProofUploadedAt;

  factory TaskLog.fromMap(Map<String, dynamic> map) {
    return TaskLog(
      id: map['id'] as String,
      taskType: map['task_type'] as String,
      referenceId: map['reference_id'] as String,
      scheduledAt: parseReminderScheduledAt(map['scheduled_at'] as String),
      completedAt: map['completed_at'] == null
          ? null
          : DateTime.tryParse(map['completed_at'] as String),
      status: (map['status'] as String?) ?? 'pending',
      notes: map['notes'] as String?,
      mood: map['mood'] as String?,
      symptomNotes: map['symptom_notes'] as String?,
      completionProofPhotoPath: map['completion_proof_photo_path'] as String?,
      completionProofCapturedAt: map['completion_proof_captured_at'] == null
          ? null
          : DateTime.tryParse(map['completion_proof_captured_at'] as String),
      completionProofUploadedAt: map['completion_proof_uploaded_at'] == null
          ? null
          : DateTime.tryParse(map['completion_proof_uploaded_at'] as String),
    );
  }

  TaskLog copyWith({
    String? status,
    DateTime? completedAt,
    String? notes,
    String? mood,
    String? symptomNotes,
    String? completionProofPhotoPath,
    DateTime? completionProofCapturedAt,
    DateTime? completionProofUploadedAt,
  }) {
    return TaskLog(
      id: id,
      taskType: taskType,
      referenceId: referenceId,
      scheduledAt: scheduledAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      mood: mood ?? this.mood,
      symptomNotes: symptomNotes ?? this.symptomNotes,
      completionProofPhotoPath:
          completionProofPhotoPath ?? this.completionProofPhotoPath,
      completionProofCapturedAt:
          completionProofCapturedAt ?? this.completionProofCapturedAt,
      completionProofUploadedAt:
          completionProofUploadedAt ?? this.completionProofUploadedAt,
    );
  }
}
