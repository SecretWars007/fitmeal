import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../widgets/app_drawer.dart';
import 'dashboard_page.dart';
import 'history_page.dart';
import 'profile_page.dart';
import 'evaluation_page.dart';

// State provider to manage the selected tab index
final selectedTabProvider = StateProvider<int>((ref) => 0);

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedTabProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(selectedIndex)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(metricsHistoryProvider);
              ref.invalidate(userProfileProvider);
              ref.invalidate(todayWaterLogsProvider);
            },
          ),
        ],
      ),
      drawer: AppDrawer(
        onIndexSelected: (index) {
          ref.read(selectedTabProvider.notifier).state = index;
        },
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: const [DashboardPage(), HistoryPage(), ProfilePage()],
      ),
      floatingActionButton:
          selectedIndex == 0
              ? FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EvaluationPage(),
                    ),
                  );
                },
                label: const Text('Evaluar'),
                icon: const Icon(Icons.add),
              )
              : null,
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'FitMeal AI';
      case 1:
        return 'Mi Progreso';
      case 2:
        return 'Mi Perfil';
      default:
        return 'FitMeal AI';
    }
  }
}
