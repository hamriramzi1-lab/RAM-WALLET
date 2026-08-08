// lib/models/transaction.dart
// Ce fichier définit le modèle d'une transaction (revenu ou dépense)

class Transaction {
  final String id;          // Identifiant unique
  final String title;       // Description de la transaction
  final double amount;      // Montant
  final String type;        // 'income' (revenu) ou 'expense' (dépense)
  final String category;    // Catégorie (Nourriture, Transport, etc.)
  final DateTime date;      // Date de la transaction
  final bool isDebt;        // Si c'est lié à une dette

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.isDebt = false,
  });

  // Convertir la transaction en Map (pour sauvegarde)
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'type': type,
    'category': category,
    'date': date.toIso8601String(),
    'isDebt': isDebt,
  };

  // Créer une transaction depuis une Map (pour chargement)
  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'],
    title: json['title'],
    amount: json['amount'].toDouble(),
    type: json['type'],
    category: json['category'],
    date: DateTime.parse(json['date']),
    isDebt: json['isDebt'] ?? false,
  );
}
