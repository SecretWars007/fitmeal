import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/water_log.dart';

class WaterRepository {
  final SupabaseClient _client;

  WaterRepository(this._client);

  Future<void> logWater(String userId, int amountMl) async {
    final now = DateTime.now();
    // Format date as YYYY-MM-DD string to ensure compatibility with Supabase date type
    final dateString =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    await _client.from('water_logs').insert({
      'user_id': userId,
      'amount_ml': amountMl,
      'drink_date': dateString,
    });
  }

  Future<List<WaterLog>> getTodayLogs(String userId) async {
    final now = DateTime.now();
    final dateString =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final response = await _client
        .from('water_logs')
        .select()
        .eq('user_id', userId)
        .eq('drink_date', dateString) // Simply filter by the date column
        .order('created_at', ascending: true);

    return (response as List)
        .map(
          (json) => WaterLog(
            id: json['id'],
            userId: json['user_id'],
            amountMl: json['amount_ml'],
            drinkDate: DateTime.parse(json['drink_date']),
            createdAt: DateTime.parse(json['created_at']),
          ),
        )
        .toList();
  }

  Future<void> deleteLog(String logId) async {
    await _client.from('water_logs').delete().eq('id', logId);
  }
}
