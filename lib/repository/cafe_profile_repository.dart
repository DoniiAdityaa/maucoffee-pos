import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:maucoffee/model/cafe_profile_model.dart';

class CafeProfileRepository {
  final _client = Supabase.instance.client;

  // Mendapatkan profil kafe (selalu ID 'default')
  Future<CafeProfileModel?> getProfile() async {
    try {
      final response = await _client
          .from('cafe_profiles')
          .select()
          .eq('id', 'default')
          .maybeSingle();

      if (response == null) return null;
      return CafeProfileModel.fromJson(response);
    } catch (e) {
      throw Exception('Gagal memuat profil kafe dari cloud: $e');
    }
  }

  // Menyimpan/mengupdate profil kafe (Upsert)
  Future<void> saveProfile(CafeProfileModel profile) async {
    try {
      final data = profile.toJson();
      data['id'] = 'default'; // Pastikan ID selalu 'default'
      await _client.from('cafe_profiles').upsert(data);
    } catch (e) {
      throw Exception('Gagal menyimpan profil kafe ke cloud: $e');
    }
  }
}
