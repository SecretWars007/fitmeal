import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

class AppDrawer extends ConsumerWidget {
  final Function(int) onIndexSelected;

  const AppDrawer({super.key, required this.onIndexSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Colors.green),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child:
                  profileAsync.value?.avatarUrl == null
                      ? const Icon(Icons.person, size: 40, color: Colors.green)
                      : ClipOval(
                        child: Image.network(
                          profileAsync.value!.avatarUrl!,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.green,
                            );
                          },
                        ),
                      ),
            ),
            accountName: Text(
              profileAsync.value?.fullName ?? 'Usuario',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(userAsync.value?.email ?? ''),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Inicio'),
            onTap: () {
              onIndexSelected(0);
              Navigator.pop(context); // Close drawer
            },
          ),
          ListTile(
            leading: const Icon(Icons.show_chart),
            title: const Text('Mi Progreso'),
            onTap: () {
              onIndexSelected(1);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Mi Perfil'),
            onTap: () {
              onIndexSelected(2);
              Navigator.pop(context);
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              await ref.read(authRepositoryProvider).signOut();
              // Navigation handled by AuthGate
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
