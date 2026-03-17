import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/models/care_person.dart';

class CarePersonRemoteDataSource {
  SupabaseClient get _client => Supabase.instance.client;
  String get _userId => _client.auth.currentUser!.id;

  Future<List<CarePerson>> getCarePersons() async {
    final rows = await _client
        .from('care_persons')
        .select()
        .eq('owner_id', _userId)
        .order('created_at');

    return (rows as List<dynamic>)
        .map((row) => CarePerson.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<CarePerson> getCarePerson(String id) async {
    final row = await _client
        .from('care_persons')
        .select()
        .eq('id', id)
        .eq('owner_id', _userId)
        .single();

    return CarePerson.fromMap(row);
  }

  Future<void> createCarePerson({
    required String displayName,
    String? relationship,
    DateTime? birthDate,
    String? notes,
    String? avatarColor,
  }) async {
    await _client.from('care_persons').insert({
      'owner_id': _userId,
      'display_name': displayName,
      'relationship': relationship,
      'birth_date': birthDate?.toIso8601String().split('T').first,
      'notes': notes,
      'avatar_color': avatarColor,
    });
  }

  Future<void> updateCarePerson({
    required String id,
    required String displayName,
    String? relationship,
    DateTime? birthDate,
    String? notes,
    String? avatarColor,
  }) async {
    await _client
        .from('care_persons')
        .update({
          'display_name': displayName,
          'relationship': relationship,
          'birth_date': birthDate?.toIso8601String().split('T').first,
          'notes': notes,
          'avatar_color': avatarColor,
        })
        .eq('id', id)
        .eq('owner_id', _userId);
  }

  Future<void> deleteCarePerson(String id) async {
    await _client
        .from('care_persons')
        .delete()
        .eq('id', id)
        .eq('owner_id', _userId);
  }
}
