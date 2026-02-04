class UserProfile {
  final String id;
  final String? fullName;
  final String? username;
  final String? gender;
  final int? age;
  final double? height;
  final String? activityLevel;
  final String? goal;
  final String? avatarUrl;

  final String? email;

  UserProfile({
    required this.id,
    this.email,
    this.fullName,
    this.username,
    this.gender,
    this.age,
    this.height,
    this.activityLevel,
    this.goal,
    this.avatarUrl,
  });
}

class BodyMetrics {
  final String id;
  final String userId;
  final double weight;
  final double height;
  final double bmi;
  final double bodyFat;
  final double dailyCalorieExp;
  final DateTime createdAt;

  BodyMetrics({
    required this.id,
    required this.userId,
    required this.weight,
    required this.height,
    required this.bmi,
    required this.bodyFat,
    required this.dailyCalorieExp,
    required this.createdAt,
  });
}

class HealthyRecommendation {
  final String id;
  final String type; // 'diet' or 'habit'
  final String title;
  final String content;
  final double minBmi;
  final double maxBmi;

  HealthyRecommendation({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.minBmi,
    required this.maxBmi,
  });
}

class UserReminder {
  final String id;
  final String userId;
  final String type; // 'breakfast' or 'activity'
  final int hour;
  final int minute;
  final bool isEnabled;
  final List<int> daysOfWeek;

  UserReminder({
    required this.id,
    required this.userId,
    required this.type,
    required this.hour,
    required this.minute,
    required this.isEnabled,
    required this.daysOfWeek,
  });
}
