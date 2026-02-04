import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/entities.dart';
import '../providers/providers.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController =
      TextEditingController(); // Initial weight for first evaluation

  String? _selectedGender;
  String? _selectedActivityLevel;
  String? _selectedGoal;
  bool _isLoading = false;

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGender == null ||
        _selectedActivityLevel == null ||
        _selectedGoal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todas las selecciones'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await ref.read(currentUserProvider.future);
      final currentProfile = await ref.read(userProfileProvider.future);
      String? email = user?.email;
      String fullName = 'Usuario';
      String username = email?.split('@')[0] ?? 'usuario';

      if (currentProfile != null) {
        email = currentProfile.email;
        fullName = currentProfile.fullName ?? fullName;
        username = currentProfile.username ?? username;
      }

      if (user != null) {
        final userId = user.id;

        // Prepare data map for partial update
        final updates = {
          'gender': _selectedGender,
          'age': int.parse(_ageController.text),
          'height': double.parse(_heightController.text),
          'activity_level': _selectedActivityLevel,
          'goal': _selectedGoal,
        };

        debugPrint(
          'Onboarding: Attempting update for user $userId with updates: $updates',
        );

        if (currentProfile != null) {
          // SAFE UPDATE: Only update the onboarding fields
          await ref
              .read(metricsRepositoryProvider)
              .updateProfileFields(userId, updates);
          debugPrint('Onboarding: Update successful');
        } else {
          // CREATE/UPSERT: We need a full profile object
          // Try to get info from User metadata if available
          String? email = user.email;
          String fullName = 'Usuario';
          String username = email?.split('@')[0] ?? 'usuario';

          final newProfile = UserProfile(
            id: userId,
            email: email,
            fullName: fullName,
            username: username,
            // Onboarding fields
            gender: _selectedGender,
            age: int.parse(_ageController.text),
            height: double.parse(_heightController.text),
            activityLevel: _selectedActivityLevel,
            goal: _selectedGoal,
          );
          await ref.read(metricsRepositoryProvider).saveProfile(newProfile);
        }

        // Also save initial weight metric if provided
        if (_weightController.text.isNotEmpty) {
          final weight = double.parse(_weightController.text);
          final h = double.parse(_heightController.text) / 100;
          final bmi = weight / (h * h);

          final metric = BodyMetrics(
            id: '',
            userId: userId,
            weight: weight,
            height: double.parse(_heightController.text),
            bmi: bmi,
            bodyFat: 0,
            dailyCalorieExp: 0,
            createdAt: DateTime.now(),
          );
          await ref.read(metricsRepositoryProvider).saveMetrics(metric);
        }

        // Refresh providers
        ref.invalidate(userProfileProvider);
        ref.invalidate(metricsHistoryProvider);

        // Navigation handled by AuthGate
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.celebration, size: 60, color: Colors.green),
                const SizedBox(height: 20),
                Text(
                  '¡Te damos la bienvenida!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Para crear tu plan personalizado, necesitamos conocerte un poco mejor.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 40),

                // Gender Selection
                Text(
                  '¿Cuál es tu sexo biológico?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildGenderCard('Hombre', 'male', Icons.male),
                    const SizedBox(width: 16),
                    _buildGenderCard('Mujer', 'female', Icons.female),
                  ],
                ),
                const SizedBox(height: 30),

                // Basic Info
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Edad',
                          suffixText: 'años',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Altura',
                          suffixText: 'cm',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Peso Actual (Opcional)',
                    hintText: 'Para tu primera evaluación',
                    suffixText: 'kg',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 30),

                // Activity Level
                DropdownButtonFormField<String>(
                  value: _selectedActivityLevel,
                  decoration: const InputDecoration(
                    labelText: 'Nivel de Actividad',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'sedentary',
                      child: Text('Sedentario (Poco o nada)'),
                    ),
                    DropdownMenuItem(
                      value: 'light',
                      child: Text('Ligero (1-3 días/sem)'),
                    ),
                    DropdownMenuItem(
                      value: 'moderate',
                      child: Text('Moderado (3-5 días/sem)'),
                    ),
                    DropdownMenuItem(
                      value: 'active',
                      child: Text('Activo (6-7 días/sem)'),
                    ),
                    DropdownMenuItem(
                      value: 'very_active',
                      child: Text('Muy Activo (Físico diario)'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedActivityLevel = v),
                  validator: (v) => v == null ? 'Requerido' : null,
                ),
                const SizedBox(height: 20),

                // Goal
                DropdownButtonFormField<String>(
                  value: _selectedGoal,
                  decoration: const InputDecoration(
                    labelText: '¿Cuál es tu objetivo?',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'lose_fat',
                      child: Text('Perder Grasa'),
                    ),
                    DropdownMenuItem(
                      value: 'maintain',
                      child: Text('Mantener Peso'),
                    ),
                    DropdownMenuItem(
                      value: 'improve_habits',
                      child: Text('Mejorar Hábitos'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedGoal = v),
                  validator: (v) => v == null ? 'Requerido' : null,
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              'Comenzar mi Viaje',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderCard(String label, String value, IconData icon) {
    final isSelected = _selectedGender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green.withOpacity(0.1) : Colors.grey[50],
            border: Border.all(
              color: isSelected ? Colors.green : Colors.grey[300]!,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 40,
                color: isSelected ? Colors.green : Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.green : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
