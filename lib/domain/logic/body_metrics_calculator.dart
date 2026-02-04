import 'dart:math';

class BodyMetricsCalculator {
  /// Calculate BMI: weight (kg) / height^2 (m)
  static double calculateBMI(double weight, double heightCm) {
    if (heightCm <= 0) return 0;
    final heightM = heightCm / 100;
    return weight / (heightM * heightM);
  }

  /// Estimar % Grasa Corporal (Fórmula de Deurenberg)
  /// Adult Body Fat % = (1.20 × BMI) + (0.23 × Age) − (10.8 × sex) − 5.4
  /// sex: Male = 1, Female = 0
  static double estimateBodyFat(double bmi, int age, String gender) {
    final sexValue = (gender.toLowerCase() == 'male') ? 1 : 0;
    return (1.20 * bmi) + (0.23 * age) - (10.8 * sexValue) - 5.4;
  }

  /// Calcula el Gasto Calórico Diario (TDEE) usando Mifflin-St Jeor
  /// BMR:
  /// Male: (10 × weight kg) + (6.25 × height cm) – (5 × age) + 5
  /// Female: (10 × weight kg) + (6.25 × height cm) – (5 × age) – 161
  static double calculateTDEE(double weight, double height, int age, String gender, String activityLevel) {
    double bmr;
    if (gender.toLowerCase() == 'male') {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }

    final multipliers = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'active': 1.725,
      'very_active': 1.9,
    };

    final multiplier = multipliers[activityLevel.toLowerCase()] ?? 1.2;
    return bmr * multiplier;
  }

  static String classifyBMI(double bmi) {
    if (bmi < 18.5) return 'Bajo peso';
    if (bmi < 25) return 'Saludable';
    if (bmi < 30) return 'Sobrepeso';
    return 'Obesidad';
  }
}
