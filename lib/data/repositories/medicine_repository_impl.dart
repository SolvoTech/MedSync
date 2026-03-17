import '../../domain/models/medicine.dart';
import '../../domain/repositories/medicine_repository.dart';
import '../remote/datasources/medicine_remote_datasource.dart';

class MedicineRepositoryImpl implements MedicineRepository {
  MedicineRepositoryImpl(this._remote);

  final MedicineRemoteDataSource _remote;

  @override
  Future<List<Medicine>> getMedicines({String? carePersonId}) {
    return _remote.getMedicines(carePersonId: carePersonId);
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
    String? prescriptionUrl,
  }) {
    return _remote.createMedicine(
      name: name,
      dosage: dosage,
      stockCurrent: stockCurrent,
      stockUnit: stockUnit,
      medicineType: medicineType,
      carePersonId: carePersonId,
      photoUrl: photoUrl,
      prescriptionUrl: prescriptionUrl,
    );
  }

  @override
  Future<void> deactivateMedicine(String medicineId) {
    return _remote.deactivateMedicine(medicineId);
  }

  @override
  Future<void> deleteMedicine(String medicineId) {
    return _remote.deleteMedicine(medicineId);
  }
}
