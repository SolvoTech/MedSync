import 'package:flutter_test/flutter_test.dart';
import 'package:med_syn/domain/models/task_log.dart';

void main() {
  group('TaskLog', () {
    test('parses completion proof metadata from map', () {
      final log = TaskLog.fromMap({
        'id': 'task-1',
        'task_type': 'medicine',
        'reference_id': 'schedule-1',
        'scheduled_at': '2026-04-28T08:00:00.000Z',
        'completed_at': '2026-04-28T08:05:00.000Z',
        'status': 'done',
        'completion_proof_photo_path': 'user/medicine/schedule-1/proof.jpg',
        'completion_proof_captured_at': '2026-04-28T08:04:00.000Z',
        'completion_proof_uploaded_at': '2026-04-28T08:04:30.000Z',
      });

      expect(
        log.completionProofPhotoPath,
        'user/medicine/schedule-1/proof.jpg',
      );
      expect(
        log.completionProofCapturedAt,
        DateTime.parse('2026-04-28T08:04:00.000Z'),
      );
      expect(
        log.completionProofUploadedAt,
        DateTime.parse('2026-04-28T08:04:30.000Z'),
      );
    });

    test('allows missing completion proof metadata', () {
      final log = TaskLog.fromMap({
        'id': 'task-1',
        'task_type': 'medicine',
        'reference_id': 'schedule-1',
        'scheduled_at': '2026-04-28T08:00:00.000Z',
        'status': 'pending',
      });

      expect(log.completionProofPhotoPath, isNull);
      expect(log.completionProofCapturedAt, isNull);
      expect(log.completionProofUploadedAt, isNull);
    });
  });
}
