import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/interfaces.dart';
import '../models/models.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

  SupabaseAuthRepository(this._client);

  @override
  Future<UserProfile?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return UserProfile(id: user.id, email: user.email);
  }

  @override
  Future<void> signIn(String identifier, String password) async {
    // Attempt to login with email or username
    String email = identifier;

    // Check if identifier is an email (basic check)
    if (!identifier.contains('@')) {
      // It's likely a username, fetch the email from profiles table
      final response =
          await _client
              .from('profiles')
              .select('auth_id:id, users!inner(email)')
              .eq('username', identifier)
              .maybeSingle();

      if (response != null && response['users'] != null) {
        email = response['users']['email'];
      } else {
        throw Exception('Usuario no encontrado');
      }
    }

    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signUp(String email, String password) async {
    await _client.auth.signUp(email: email, password: password);
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}

class SupabaseMetricsRepository implements MetricsRepository {
  final SupabaseClient _client;

  SupabaseMetricsRepository(this._client);

  @override
  Future<void> saveMetrics(BodyMetrics metrics) async {
    final dto = BodyMetricsDTO(
      userId: metrics.userId,
      weight: metrics.weight,
      height: metrics.height,
      bmi: metrics.bmi,
      bodyFat: metrics.bodyFat,
      dailyCalorieExp: metrics.dailyCalorieExp,
    );
    await _client.from('body_metrics').upsert(dto.toJson());
  }

  @override
  Future<List<BodyMetrics>> getMetricsHistory(String userId) async {
    final response = await _client
        .from('body_metrics')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => BodyMetricsDTO.fromJson(json).toEntity())
        .toList();
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    final dto = UserProfileDTO(
      id: profile.id,
      fullName: profile.fullName,
      username: profile.username,
      gender: profile.gender,
      age: profile.age,
      height: profile.height,
      activityLevel: profile.activityLevel,
      goal: profile.goal,
      avatarUrl: profile.avatarUrl,
    );
    await _client.from('profiles').upsert(dto.toJson());
  }

  @override
  Future<void> updateProfileFields(
    String userId,
    Map<String, dynamic> fields,
  ) async {
    // Only allow updating existing records, but since we use ID, update is fine.
    // 'id' must be part of the matching strategy for update(), but usually we eq('id', ...)
    // Upsert needs Primary Key. Update needs eq.
    await _client.from('profiles').update(fields).eq('id', userId);
  }

  @override
  Future<String> uploadProfilePicture(
    String userId,
    List<int> imageBytes,
    String fileExt,
  ) async {
    final path = '$userId/avatar.$fileExt';
    await _client.storage
        .from('avatars')
        .uploadBinary(
          path,
          Uint8List.fromList(imageBytes),
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage.from('avatars').getPublicUrl(path);
  }

  @override
  Future<UserProfile?> getProfile(String userId) async {
    final response =
        await _client.from('profiles').select().eq('id', userId).maybeSingle();
    if (response == null) return null;
    return UserProfileDTO.fromJson(response).toEntity();
  }
}
