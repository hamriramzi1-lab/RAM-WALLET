class Debt {
  final String id;
  final String name;
  final double amount;
  final String type;
  final double remainingAmount;
  final DateTime date;
  final bool isSettled;

  Debt({
    required this.id,
    required this.name,
    required this.amount,
    required this.type,
    double? remainingAmount,
    DateTime? date,
    this.isSettled = false,
  }) : 
    this.remainingAmount = remainingAmount ?? amount,
    this.date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'amount': amount,
    'type': type,
    'remainingAmount': remainingAmount,
    'date': date.toIso8601String(),
    'isSettled': isSettled,
  };

  factory Debt.fromJson(Map<String, dynamic> json) => Debt(
    id: json['id'],
    name: json['name'],
    amount: json['amount'].toDouble(),
    type: json['type'],
    remainingAmount: json['remainingAmount']?.toDouble(),
    date: DateTime.parse(json['date']),
    isSettled: json['isSettled'] ?? false,
  );

  bool get isFullySettled => remainingAmount <= 0 || isSettled;
}
