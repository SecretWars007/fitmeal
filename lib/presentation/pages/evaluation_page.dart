import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../../domain/logic/body_metrics_calculator.dart';



class EvaluationPage extends ConsumerStatefulWidget {
  const EvaluationPage({super.key});

  @override
  ConsumerState<EvaluationPage> createState() => _EvaluationPageState();
}

class _EvaluationPageState extends ConsumerState<EvaluationPage> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();

  String _gender = 'male';
  String _activityLevel = 'moderate';
  bool _isLoading = false;
  bool _showResults = false;

  // Results
  double _bmi = 0;
  double _bodyFat = 0;
  double _calories = 0;
  String _classification = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final profile = await ref.read(userProfileProvider.future);
    if (profile != null) {
      setState(() {
        _heightController.text = profile.height?.toString() ?? '';
        _ageController.text = profile.age?.toString() ?? '';
        _gender = profile.gender ?? 'male';
        _activityLevel = profile.activityLevel ?? 'moderate';
      });
    }
  }

  Future<void> _calculateAndSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final weight = double.parse(_weightController.text);
      final height = double.parse(_heightController.text);
      final age = int.parse(_ageController.text);

      final user = await ref.read(currentUserProvider.future);
      if (user == null) throw Exception('Usuario no autenticado');

      // 1. Calculate
      _bmi = BodyMetricsCalculator.calculateBMI(weight, height);
      _bodyFat = BodyMetricsCalculator.estimateBodyFat(_bmi, age, _gender);
      _calories = BodyMetricsCalculator.calculateTDEE(
        weight,
        height,
        age,
        _gender,
        _activityLevel,
      );
      _classification = BodyMetricsCalculator.classifyBMI(_bmi);

      // 2. Save to history
      await ref
          .read(calculateAndSaveMetricsProvider)
          .execute(
            userId: user.id,
            weight: weight,
            height: height,
            age: age,
            gender: _gender,
            activityLevel: _activityLevel,
          );

      // 3. Update profile if height/age changed
      // 3. Update profile safely (Partial Update)
      // This prevents overwriting other fields like 'goal' with null if we don't have them.
      await ref.read(metricsRepositoryProvider).updateProfileFields(user.id, {
        'height': height,
        'age': age,
        'gender': _gender,
        'activity_level': _activityLevel, // Ensure key matches DB column name
      });

      // Invalidate to refresh dashboard
      ref.invalidate(metricsHistoryProvider);
      ref.invalidate(userProfileProvider);

      if (!mounted) return;
      setState(() {
        _showResults = true;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Datos guardados correctamente!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evaluación Corporal')),
      body: _showResults ? _buildResultsView() : _buildInputForm(),
    );
  }

  Widget _buildInputForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresa tus datos actuales',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Calcularemos tu IMC, grasa corporal y gasto calórico.'),
            const SizedBox(height: 32),

            _buildTextField(
              _weightController,
              'Peso Actual (kg)',
              Icons.monitor_weight,
            ),
            const SizedBox(height: 16),
            _buildTextField(_heightController, 'Altura (cm)', Icons.height),
            const SizedBox(height: 16),
            _buildTextField(_ageController, 'Edad', Icons.calendar_today),
            const SizedBox(height: 24),

            const Text('Sexo', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Hombre'),
                    value: 'male',
                    groupValue: _gender,
                    onChanged: (val) => setState(() => _gender = val!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Mujer'),
                    value: 'female',
                    groupValue: _gender,
                    onChanged: (val) => setState(() => _gender = val!),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Text(
              'Nivel de Actividad',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            DropdownButtonFormField<String>(
              value: _activityLevel,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items:
                  {
                        'sedentary': 'Sedentario (Poco ejercicio)',
                        'light': 'Ligero (1-3 días/semana)',
                        'moderate': 'Moderado (3-5 días/semana)',
                        'active': 'Activo (6-7 días/semana)',
                        'very_active': 'Muy Activo (Atleta)',
                      }.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
              onChanged: (val) => setState(() => _activityLevel = val!),
            ),

            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _calculateAndSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'Calcular Resultados',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
    );
  }

  Widget _buildResultsView() {
    final color = _getBmiColor(_bmi);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  'Tu clasificación es:',
                  style: TextStyle(color: color, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  _classification,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const Divider(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildResultItem('IMC', _bmi.toStringAsFixed(1), color),
                    _buildResultItem(
                      '% Grasa',
                      '${_bodyFat.toStringAsFixed(1)}%',
                      Colors.blue,
                    ),
                    _buildResultItem(
                      'Kcal/día',
                      _calories.toStringAsFixed(0),
                      Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildRecommendations(),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ir al Panel Principal'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recomendaciones para ti',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildRecCard(Icons.restaurant, 'Dieta Sugerida', _getDietText()),
        const SizedBox(height: 12),
        _buildRecCard(
          Icons.directions_walk,
          'Hábitos Saludables',
          _getHabitsText(),
        ),
      ],
    );
  }

  Widget _buildRecCard(IconData icon, String title, String content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.green),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(content, style: TextStyle(color: Colors.grey[700])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDietText() {
    if (_bmi < 18.5) {
      return 'Aumenta tu ingesta de proteínas y carbohidratos complejos. Consume frutos secos y grasas saludables.';
    }
    if (_bmi < 25) {
      return 'Mantén una dieta equilibrada rica en fibra, frutas y verduras. Prioriza proteínas magras.';
    }
    return 'Reduce el consumo de azúcares refinados y harinas. Controla las porciones y aumenta el consumo de agua.';
  }

  String _getHabitsText() {
    if (_bmi < 25) {
      return 'Realiza actividad física regular y asegúrate de dormir entre 7-8 horas diarias para mantener tu metabolismo.';
    }
    return 'Empieza con caminatas diarias de 30 minutos. Evita el sedentarismo y reduce el consumo de sal.';
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }
}
