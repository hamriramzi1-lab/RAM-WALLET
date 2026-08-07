import 'package:flutter/material.dart';

void main() {
  runApp(const RamWalletApp());
}

class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final bool isIncome; // true = Pourboire, false = Dépense
  final String category;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.isIncome,
    required this.category,
  });
}

class RamWalletApp extends StatelessWidget {
  const RamWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RAM WALLET',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: const FinanceHomeScreen(),
    );
  }
}

class FinanceHomeScreen extends StatefulWidget {
  const FinanceHomeScreen({super.key});

  @override
  State<FinanceHomeScreen> createState() => _FinanceHomeScreenState();
}

class _FinanceHomeScreenState extends State<FinanceHomeScreen> {
  double salary4th = 0.0;
  double salary14th = 0.0;

  final List<Transaction> _transactions = [];

  double get totalSalary => salary4th + salary14th;

  double get totalTips {
    return _transactions
        .where((tx) => tx.isIncome)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalExpenses {
    return _transactions
        .where((tx) => !tx.isIncome)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get netBalance => (totalSalary + totalTips) - totalExpenses;

  void _addTransaction(String title, double amount, bool isIncome, String category) {
    setState(() {
      _transactions.insert(
        0,
        Transaction(
          id: DateTime.now().toString(),
          title: title.isEmpty ? (isIncome ? 'Pourboire' : 'Dépense') : title,
          amount: amount,
          date: DateTime.now(),
          isIncome: isIncome,
          category: category,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RAM WALLET', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSalarySettingsDialog,
            tooltip: 'Configurer les salaires',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- CARTE DES SALAIRES ---
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSalaryItem('Salaire du 4', salary4th),
                        Container(height: 35, width: 1, color: Colors.grey.shade300),
                        _buildSalaryItem('Salaire du 14', salary14th),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Salaires :', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          '${totalSalary.toStringAsFixed(0)} DA',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- BOUTONS D'ACTION RAPIDE ---
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.vertical: 14),
                    onPressed: () => _showAddTransactionDialog(isIncome: true),
                    icon: const Icon(Icons.add),
                    label: const Text('+ Pourboire'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.vertical: 14),
                    onPressed: () => _showAddTransactionDialog(isIncome: false),
                    icon: const Icon(Icons.remove),
                    label: const Text('- Dépense'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- APERÇU RAPIDE ---
            Row(
              children: [
                Expanded(child: _buildSummaryCard('Pourboires', totalTips, Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _buildSummaryCard('Dépenses', totalExpenses, Colors.red)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalaryItem(String title, double amount) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text('${amount.toStringAsFixed(0)} DA', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            '${amount.toStringAsFixed(0)} DA',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _showSalarySettingsDialog() {
    final s4Controller = TextEditingController(text: salary4th > 0 ? salary4th.toStringAsFixed(0) : '');
    final s14Controller = TextEditingController(text: salary14th > 0 ? salary14th.toStringAsFixed(0) : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réglage des Salaires'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: s4Controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Salaire du 4 du mois (DA)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: s14Controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Salaire du 14 du mois (DA)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                salary4th = double.tryParse(s4Controller.text) ?? 0.0;
                salary14th = double.tryParse(s14Controller.text) ?? 0.0;
              });
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionDialog({required bool isIncome}) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String selectedCategory = isIncome ? 'Pourboire' : 'Repas';

    final categories = isIncome
        ? ['Pourboire', 'Autre']
        : ['Repas', 'Transport', 'Café/Tabac', 'Achat Perso', 'Autre'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isIncome ? 'Ajouter un Pourboire' : 'Ajouter une Dépense'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Montant (DA)', prefixIcon: Icon(Icons.attach_money)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Note (ex: Chambre 102)', prefixIcon: Icon(Icons.note)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (val) => setDialogState(() => selectedCategory = val!),
                decoration: const InputDecoration(labelText: 'Catégorie'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isIncome ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final amount = double.tryParse(amountController.text) ?? 0.0;
                if (amount > 0) {
                  _addTransaction(noteController.text.trim(), amount, isIncome, selectedCategory);
                }
                Navigator.pop(context);
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }
}
