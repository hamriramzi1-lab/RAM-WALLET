import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/transaction.dart';

class AllTransactionsScreen extends StatelessWidget {
  final List<Transaction> transactions;

  const AllTransactionsScreen({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toutes les transactions'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: transactions.isEmpty
          ? const Center(
              child: Text(
                'Aucune transaction',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: tx.type == 'income'
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      child: Icon(
                        tx.type == 'income'
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color: tx.type == 'income'
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                      ),
                    ),
                    title: Text(tx.title),
                    subtitle: Text(
                      '${DateFormat('dd/MM/yyyy').format(tx.date)} • ${tx.category}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Text(
                      '${tx.type == 'income' ? '+' : '-'} ${tx.amount.toStringAsFixed(2)} DZD',
                      style: TextStyle(
                        color: tx.type == 'income'
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
