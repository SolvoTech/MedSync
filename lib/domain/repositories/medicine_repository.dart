import '../models/medicine.dart';

abstract class MedicineRepository {
  Future<List<Medicine>> getMedicines({
    String? carePersonId,
    bool includeInactive,
  });

  Future<void> createMedicine({
    required String name,
    String? dosage,
    required int stockCurrent,
    String stockUnit,
    String medicineType,
    String? carePersonId,
    String? photoUrl,
  });

  Future<void> deactivateMedicine(String medicineId);

  Future<void> activateMedicine(String medicineId);

  Future<void> deleteMedicine(String medicineId);
}
