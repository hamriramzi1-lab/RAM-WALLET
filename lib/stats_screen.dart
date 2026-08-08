import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/transaction.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final StorageService _storage = StorageService();
  List<Transaction> _transactions = [];
  String _selectedYear = DateTime.now().year.toString();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final transactions = await _storage.loadTransactions();
    setState(() {
      _transactions = transactions;
    });
  }

  Map<String, double> _getCategorySpending() {
    final Map<String, double> categories = {};
    for (var tx in _transactions) {
      if (tx.type == 'expense') {
        categories[tx.category] = (categories[tx.category] ?? 0) + tx.amount;
      }
    }
    return categories;
  }

  double _getYearlyTotal() {
    double total = 0;
    for (var tx in _transactions) {
      if (tx.date.year.toString() == _selectedYear) {
        total += tx.amount;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final categories = _getCategorySpending();
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '📊 Bilan Annuel',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      DropdownButton<String>(
                        value: _selectedYear,
                        items: ['2026', '2027', '2028'].map((year) {
                          return DropdownMenuItem(value: year, child: Text(year));
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedYear = value);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total: ${_getYearlyTotal().toStringAsFixed(2)} DZD',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '📈 Répartition des dépenses',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (categories.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text('Aucune donnée de dépense'),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.entries.map((entry) {
                final index = categories.keys.toList().indexOf(entry.key);
                return Chip(
                  backgroundColor: colors[index % colors.length].withOpacity(0.2),
                  label: Text('${entry.key}: ${entry.value.toStringAsFixed(2)} DZD'),
                  avatar: CircleAvatar(
                    backgroundColor: colors[index % colors.length],
                    child: Text('${(entry.value / categories.values.reduce((a, b) => a + b) * 100).toInt()}%'),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📝 Dernières transactions',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_transactions.isEmpty)
                    const Text('Aucune transaction')
                  else
                    Column(
                      children: _transactions.take(5).map((tx) {
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            tx.type == 'income' ? Icons.arrow_upward : Icons.arrow_downward,
                            color: tx.type == 'income' ? Colors.green : Colors.red,
                            size: 16,
                          ),
                          title: Text(tx.title, style: const TextStyle(fontSize: 14)),
                          trailing: Text(
                            '${tx.type == 'income' ? '+' : '-'} ${tx.amount.toStringAsFixed(2)} DZD',
                            style: TextStyle(
                              color: tx.type == 'income' ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
