import 'package:med_syn/data/remote/datasources/task_log_completion_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('decideExactReminderCompletion', () {
    test('inserts when no exact-slot row exists', () {
      final decision = decideExactReminderCompletion(const []);

      expect(decision.action, ExactReminderCompletionAction.insertNew);
      expect(decision.taskLogId, isNull);
    });

    test('updates the existing exact-slot row when not done yet', () {
      final decision = decideExactReminderCompletion([
        const ExactReminderTaskLogMatch(id: 'pending-row', status: 'pending'),
      ]);

      expect(decision.action, ExactReminderCompletionAction.updateExisting);
      expect(decision.taskLogId, 'pending-row');
    });

    test('does not update when the exact slot is already done', () {
      final decision = decideExactReminderCompletion([
        const ExactReminderTaskLogMatch(id: 'done-row', status: 'done'),
        const ExactReminderTaskLogMatch(id: 'pending-row', status: 'pending'),
      ]);

      expect(decision.action, ExactReminderCompletionAction.noOp);
      expect(decision.taskLogId, isNull);
    });
  });
}
