// lib/models/debt.dart
// Ce fichier définit le modèle d'une dette

class Debt {
  final String id;              // Identifiant unique
  final String name;            // Nom de la personne ou description
  final double amount;          // Montant total de la dette
  final String type;            // 'owed_to_me' (on me doit) ou 'i_owe' (je dois)
  final double remainingAmount; // Montant restant à régler
  final DateTime date;          // Date de création
  final bool isSettled;         // Si la dette est réglée

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

  // Convertir en Map (pour sauvegarde)
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'amount': amount,
    'type': type,
    'remainingAmount': remainingAmount,
    'date': date.toIso8601String(),
    'isSettled': isSettled,
  };

  // Créer depuis une Map (pour chargement)
  factory Debt.fromJson(Map<String, dynamic> json) => Debt(
    id: json['id'],
    name: json['name'],
    amount: json['amount'].toDouble(),
    type: json['type'],
    remainingAmount: json['remainingAmount']?.toDouble(),
    date: DateTime.parse(json['date']),
    isSettled: json['isSettled'] ?? false,
  );

  // Vérifier si la dette est complètement réglée
  bool get isFullySettled => remainingAmount <= 0 || isSettled;
}
