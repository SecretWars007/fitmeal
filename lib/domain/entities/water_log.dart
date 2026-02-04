class WaterLog {
  final String id;
  final String userId;
  final int amountMl;
  final DateTime drinkDate;
  final DateTime createdAt;

  WaterLog({
    required this.id,
    required this.userId,
    required this.amountMl,
    required this.drinkDate,
    required this.createdAt,
  });
}
