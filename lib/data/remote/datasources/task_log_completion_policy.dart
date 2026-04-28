enum ExactReminderCompletionAction { updateExisting, insertNew, noOp }

class ExactReminderTaskLogMatch {
  const ExactReminderTaskLogMatch({required this.id, required this.status});

  final String id;
  final String status;

  factory ExactReminderTaskLogMatch.fromMap(Map<String, dynamic> map) {
    return ExactReminderTaskLogMatch(
      id: map['id'] as String,
      status: (map['status'] as String?) ?? 'pending',
    );
  }
}

class ExactReminderCompletionDecision {
  const ExactReminderCompletionDecision._({
    required this.action,
    this.taskLogId,
  });

  const ExactReminderCompletionDecision.insertNew()
    : this._(action: ExactReminderCompletionAction.insertNew);

  const ExactReminderCompletionDecision.noOp()
    : this._(action: ExactReminderCompletionAction.noOp);

  const ExactReminderCompletionDecision.updateExisting(String taskLogId)
    : this._(
        action: ExactReminderCompletionAction.updateExisting,
        taskLogId: taskLogId,
      );

  final ExactReminderCompletionAction action;
  final String? taskLogId;
}

ExactReminderCompletionDecision decideExactReminderCompletion(
  List<ExactReminderTaskLogMatch> matches,
) {
  String? firstNonDoneTaskLogId;

  for (final match in matches) {
    if (match.status == 'done') {
      return const ExactReminderCompletionDecision.noOp();
    }

    firstNonDoneTaskLogId ??= match.id;
  }

  if (firstNonDoneTaskLogId != null) {
    return ExactReminderCompletionDecision.updateExisting(
      firstNonDoneTaskLogId,
    );
  }

  return const ExactReminderCompletionDecision.insertNew();
}
