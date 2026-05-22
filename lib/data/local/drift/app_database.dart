import 'package:drift/drift.dart';

// ─── Drift Tables ──────────────────────────────────

/// Local medicines cache.
class LocalMedicines extends Table {
  TextColumn get id => text()();
  TextColumn get ownerId => text()();
  TextColumn get name => text()();
  TextColumn get dosage => text().nullable()();
  TextColumn get medicineType => text().withDefault(const Constant('tablet'))();
  IntColumn get stockCurrent => integer().withDefault(const Constant(0))();
  TextColumn get stockUnit => text().withDefault(const Constant('tablet'))();
  TextColumn get photoUrl => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local medicine schedules cache.
class LocalSchedules extends Table {
  TextColumn get id => text()();
  TextColumn get medicineId => text()();
  TextColumn get ownerId => text()();
  TextColumn get frequencyType => text()();
  IntColumn get frequencyValue => integer().withDefault(const Constant(1))();
  TextColumn get startDate => text()();
  TextColumn get endDate => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local task logs cache.
class LocalTaskLogs extends Table {
  TextColumn get id => text()();
  TextColumn get ownerId => text()();
  TextColumn get taskType => text()();
  TextColumn get referenceId => text()();
  DateTimeColumn get scheduledAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get notes => text().nullable()();
  TextColumn get mood => text().nullable()();
  TextColumn get symptomNotes => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Pending sync queue for offline mutations.
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get syncTable => text()(); // 'medicines', 'task_logs', etc.
  TextColumn get operation => text()(); // 'insert', 'update', 'delete'
  TextColumn get recordId => text()();
  TextColumn get payload => text()(); // JSON string
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

// ─── Database ──────────────────────────────────────

// NOTE: To generate the database, run:
//   dart run build_runner build
// The generated file will be: app_database.g.dart
//
// @DriftDatabase(tables: [LocalMedicines, LocalSchedules, LocalTaskLogs, SyncQueue])
// class AppDatabase extends _$AppDatabase {
//   AppDatabase() : super(_openConnection());
//
//   @override
//   int get schemaVersion => 1;
//
//   static QueryExecutor _openConnection() {
//     return NativeDatabase.createInBackground(
//       File(join(await getApplicationDocumentsDirectory()).path, 'medsync.db'),
//     );
//   }
// }
//
// Uncomment and run build_runner when ready to use Drift locally.
