import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/supabase_repositories.dart';
import '../../data/repositories/water_repository.dart';
import '../../domain/repositories/interfaces.dart';
import '../../domain/usecases/metrics_usecases.dart';
import '../../domain/entities/entities.dart';
import '../../domain/entities/water_log.dart';

// Supabase Client Provider
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

// Repositories
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(Supabase.instance.client);
});

// Water Repository Provider
final waterRepositoryProvider = Provider<WaterRepository>((ref) {
  return WaterRepository(Supabase.instance.client);
});

// Logic Provider: Get Today's Water Logs
// Logic Provider: Get Today's Water Logs
final todayWaterLogsProvider = FutureProvider.autoDispose<List<WaterLog>>((
  ref,
) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];
  return ref.read(waterRepositoryProvider).getTodayLogs(user.id);
});

final metricsRepositoryProvider = Provider<MetricsRepository>((ref) {
  return SupabaseMetricsRepository(Supabase.instance.client);
});

// Use Cases
final calculateAndSaveMetricsProvider = Provider<CalculateAndSaveMetrics>((
  ref,
) {
  return CalculateAndSaveMetrics(ref.watch(metricsRepositoryProvider));
});

// State Providers
// State Providers
final currentUserProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(authRepositoryProvider).getCurrentUser();
});

final userProfileProvider = FutureProvider.autoDispose((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return null;
  return ref.watch(metricsRepositoryProvider).getProfile(user.id);
});

final metricsHistoryProvider = FutureProvider.autoDispose<List<BodyMetrics>>((
  ref,
) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];
  return ref.watch(metricsRepositoryProvider).getMetricsHistory(user.id);
});
