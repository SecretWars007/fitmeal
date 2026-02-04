import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

class WaterTrackerCard extends ConsumerWidget {
  const WaterTrackerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayLogsAsync = ref.watch(todayWaterLogsProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Icon and Counter Section
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.water_drop_rounded,
              color: Colors.blue,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Agua',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                todayLogsAsync.when(
                  data: (logs) {
                    final total = logs.fold(
                      0,
                      (sum, log) => sum + log.amountMl,
                    );
                    return Text(
                      '$total / 2000 ml',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    );
                  },
                  loading:
                      () => const SizedBox(
                        height: 10,
                        width: 10,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  error: (_, __) => const Text('--'),
                ),
              ],
            ),
          ),
          // Action Buttons Section (Compact Circles)
          Row(
            children: [
              _buildCompactAddButton(context, ref, 250),
              const SizedBox(width: 12),
              _buildCompactAddButton(context, ref, 500),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactAddButton(
    BuildContext context,
    WidgetRef ref,
    int amount,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          // Logic same as before
          try {
            final user = await ref.read(currentUserProvider.future);
            if (user == null) return;
            await ref.read(waterRepositoryProvider).logWater(user.id, amount);
            ref.invalidate(todayWaterLogsProvider);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('💧 +$amount ml'),
                  backgroundColor: Colors.blue,
                  behavior: SnackBarBehavior.fixed,
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          } catch (e) {
            /* Error handling */
          }
        },
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(30),
            color: Colors.blue.withOpacity(0.05),
          ),
          child: Text(
            '+$amount',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
