import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/entities.dart';
import '../providers/providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      // AppBar handled by MainScaffold
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.green,
                  child:
                      profileAsync.value?.avatarUrl == null
                          ? const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white,
                          )
                          : ClipOval(
                            child: Image.network(
                              profileAsync.value!.avatarUrl!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint('Error loading avatar: $error');
                                return const Icon(
                                  Icons.error,
                                  size: 50,
                                  color: Colors.red,
                                );
                              },
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) return child;
                                return const CircularProgressIndicator(
                                  color: Colors.white,
                                );
                              },
                            ),
                          ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap:
                        () => _pickAndUploadImage(
                          context,
                          ref,
                          profileAsync.value,
                        ),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            profileAsync.when(
              data:
                  (profile) => Text(
                    profile?.fullName ?? 'Usuario',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Error al cargar perfil'),
            ),
            const SizedBox(height: 8),
            userAsync.when(
              data:
                  (user) => Text(
                    user?.email ?? '',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 48),
            _buildProfileItem(
              Icons.height,
              'Altura',
              '${profileAsync.value?.height ?? '-'} cm',
            ),
            _buildProfileItem(
              Icons.cake,
              'Edad',
              '${profileAsync.value?.age ?? '-'} años',
            ),
            _buildProfileItem(
              Icons.wc,
              'Sexo',
              _translateGender(profileAsync.value?.gender),
            ),
            const SizedBox(height: 48),
            // Logout button was moved to Dashboard AppBar as requested
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.green),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _translateGender(String? gender) {
    if (gender == 'male') return 'Hombre';
    if (gender == 'female') return 'Mujer';
    return gender ?? '-';
  }

  Future<void> _pickAndUploadImage(
    BuildContext context,
    WidgetRef ref,
    UserProfile? currentProfile,
  ) async {
    if (currentProfile == null) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    try {
      final bytes = await image.readAsBytes();
      // On web, image.path is a blob URL, so use image.name for extension
      final fileExt = image.name.split('.').last;

      final repo = ref.read(metricsRepositoryProvider);
      final url = await repo.uploadProfilePicture(
        currentProfile.id,
        bytes,
        fileExt,
      );
      debugPrint('Uploaded Avatar URL: $url');

      // Append timestamp to bust cache
      final urlWithTimestamp =
          '$url?t=${DateTime.now().millisecondsSinceEpoch}';

      final updatedProfile = UserProfile(
        id: currentProfile.id,
        email: currentProfile.email,
        fullName: currentProfile.fullName,
        username: currentProfile.username,
        gender: currentProfile.gender,
        age: currentProfile.age,
        height: currentProfile.height,
        activityLevel: currentProfile.activityLevel,
        goal: currentProfile.goal,
        avatarUrl:
            urlWithTimestamp, // Save with timestamp to force refresh on other clients too?
        // Actually, saving query params in DB is okay, but usually we just want the base URL.
        // But for immediate feedback, let's use the one we got.
      );

      await repo.saveProfile(updatedProfile);
      ref.invalidate(userProfileProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Foto actualizada')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al subir: $e. Verifica que el bucket "avatars" sea publico y tenga politicas.',
            ),
          ),
        );
      }
    }
  }
}
