import '../models/medicine.dart';

abstract class MedicineRepository {
  Future<List<Medicine>> getMedicines({String? carePersonId});

  Future<void> createMedicine({
    required String name,
    String? dosage,
    required int stockCurrent,
    String stockUnit,
    String medicineType,
    String? carePersonId,
    String? photoUrl,
    String? prescriptionUrl,
  });

  Future<void> deactivateMedicine(String medicineId);

  Future<void> deleteMedicine(String medicineId);
}
