import '../../domain/entities/entities.dart';

class UserProfileDTO {
  final String id;
  final String? fullName;
  final String? username;
  final String? gender;
  final int? age;
  final double? height;
  final String? activityLevel;
  final String? goal;
  final String? avatarUrl;

  UserProfileDTO({
    required this.id,
    this.fullName,
    this.username,
    this.gender,
    this.age,
    this.height,
    this.activityLevel,
    this.goal,
    this.avatarUrl,
  });

  factory UserProfileDTO.fromJson(Map<String, dynamic> json) {
    return UserProfileDTO(
      id: json['id'],
      fullName: json['full_name'],
      username: json['username'],
      gender: json['gender'],
      age: json['age'],
      height: json['height']?.toDouble(),
      activityLevel: json['activity_level'],
      goal: json['goal'],
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'username': username,
      'gender': gender,
      'age': age,
      'height': height,
      'activity_level': activityLevel,
      'goal': goal,
      'avatar_url': avatarUrl,
    };
  }

  UserProfile toEntity() {
    return UserProfile(
      id: id,
      email: null, // Profile DTO doesn't have email
      fullName: fullName,
      username: username,
      gender: gender,
      age: age,
      height: height,
      activityLevel: activityLevel,
      goal: goal,
      avatarUrl: avatarUrl,
    );
  }
}

class BodyMetricsDTO {
  final String? id;
  final String userId;
  final double weight;
  final double height;
  final double bmi;
  final double bodyFat;
  final double dailyCalorieExp;
  final String? createdAt;

  BodyMetricsDTO({
    this.id,
    required this.userId,
    required this.weight,
    required this.height,
    required this.bmi,
    required this.bodyFat,
    required this.dailyCalorieExp,
    this.createdAt,
  });

  factory BodyMetricsDTO.fromJson(Map<String, dynamic> json) {
    return BodyMetricsDTO(
      id: json['id'],
      userId: json['user_id'],
      weight: json['weight'].toDouble(),
      height: json['height'].toDouble(),
      bmi: json['bmi'].toDouble(),
      bodyFat: json['body_fat'].toDouble(),
      dailyCalorieExp: json['daily_calorie_exp'].toDouble(),
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'weight': weight,
      'height': height,
      'bmi': bmi,
      'body_fat': bodyFat,
      'daily_calorie_exp': dailyCalorieExp,
    };
  }

  BodyMetrics toEntity() {
    return BodyMetrics(
      id: id ?? '',
      userId: userId,
      weight: weight,
      height: height,
      bmi: bmi,
      bodyFat: bodyFat,
      dailyCalorieExp: dailyCalorieExp,
      createdAt:
          createdAt != null ? DateTime.parse(createdAt!) : DateTime.now(),
    );
  }
}
