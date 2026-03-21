import '../../domain/models/medicine.dart';
import '../../domain/repositories/medicine_repository.dart';
import '../remote/datasources/medicine_remote_datasource.dart';

class MedicineRepositoryImpl implements MedicineRepository {
  MedicineRepositoryImpl(this._remote);

  final MedicineRemoteDataSource _remote;

  @override
  Future<List<Medicine>> getMedicines({
    String? carePersonId,
    bool includeInactive = false,
  }) {
    return _remote.getMedicines(
      carePersonId: carePersonId,
      includeInactive: includeInactive,
    );
  }

  @override
  Future<void> createMedicine({
    required String name,
    String? dosage,
    required int stockCurrent,
    String stockUnit = 'tablet',
    String medicineType = 'tablet',
    String? carePersonId,
    String? photoUrl,
  }) {
    return _remote.createMedicine(
      name: name,
      dosage: dosage,
      stockCurrent: stockCurrent,
      stockUnit: stockUnit,
      medicineType: medicineType,
      carePersonId: carePersonId,
      photoUrl: photoUrl,
    );
  }

  @override
  Future<void> deactivateMedicine(String medicineId) {
    return _remote.deactivateMedicine(medicineId);
  }

  @override
  Future<void> activateMedicine(String medicineId) {
    return _remote.activateMedicine(medicineId);
  }

  @override
  Future<void> deleteMedicine(String medicineId) {
    return _remote.deleteMedicine(medicineId);
  }
}
