import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../../domain/logic/body_metrics_calculator.dart';
import 'evaluation_page.dart';
import 'login_page.dart';
import '../widgets/water_tracker_card.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final historyAsync = ref.watch(metricsHistoryProvider);

    return Scaffold(
      // AppBar handled by MainScaffold
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Inicia sesión para continuar'));
          }

          return historyAsync.when(
            data: (history) {
              if (history.isEmpty) {
                // ... (Keep empty state logic same as before but without navigation pushReplacement if not needed)
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.analytics_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text('Aún no tienes registros.'),
                      const SizedBox(height: 16),
                      // Button functionality is handled by FAB in MainScaffold mostly,
                      // but keeping a button here for empty state is good UX.
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EvaluationPage(),
                            ),
                          );
                        },
                        child: const Text('Comenzar Primera Evaluación'),
                      ),
                    ],
                  ),
                );
              }

              final latest = history.first;
              final classification = BodyMetricsCalculator.classifyBMI(
                latest.bmi,
              );

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(metricsHistoryProvider);
                  ref.invalidate(userProfileProvider);
                  ref.invalidate(todayWaterLogsProvider);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumen de Hoy',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.4,
                        children: [
                          _buildCompactMetricCard(
                            context,
                            'IMC',
                            latest.bmi.toStringAsFixed(1),
                            classification,
                            _getBmiColor(latest.bmi),
                            Icons.monitor_weight_outlined,
                          ),
                          _buildCompactMetricCard(
                            context,
                            '% Grasa',
                            '${latest.bodyFat.toStringAsFixed(1)}%',
                            'Estimado',
                            Colors.blue,
                            Icons.accessibility_new_rounded,
                          ),
                          _buildCompactMetricCard(
                            context,
                            'Calorías',
                            latest.dailyCalorieExp.toStringAsFixed(0),
                            'Kcal/día',
                            Colors.orange,
                            Icons.local_fire_department_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const WaterTrackerCard(), // Slim water card
                      const SizedBox(height: 80), // Bottom padding for FAB
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error de usuario: $e')),
      ),
      // FAB is handled by MainScaffold
    );
  }

  Widget _buildCompactMetricCard(
    BuildContext context,
    String title,
    String value,
    String subtitle,
    Color color,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Gradient Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.1), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Left Accent Line
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: Container(color: color),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 16,
                top: 16,
                bottom: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      Icon(icon, size: 18, color: color.withOpacity(0.7)),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: color.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }
}
