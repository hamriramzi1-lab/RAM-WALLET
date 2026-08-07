import 'package:flutter/material.dart';

void main() {
  runApp(const RamWalletApp());
}

class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final bool isIncome;
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

  void _deleteTransaction(String id) {
    setState(() {
      _transactions.removeWhere((tx) => tx.id == id);
    });
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Pourboire':
        return Icons.volunteer_activism;
      case 'Repas':
        return Icons.restaurant;
      case 'Transport':
        return Icons.directions_bus;
      case 'Café/Tabac':
        return Icons.local_cafe;
      case 'Achat Perso':
        return Icons.shopping_bag;
      default:
        return Icons.attach_money;
    }
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- GRAND TABLEAU DE BORD (SOLDE NET) ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00695C), Color(0xFF00897B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text('SOLDE NET (RESTE À VIVRE)', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    '${netBalance.toStringAsFixed(0)} DA',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildHeaderInfo('Salaires', '${totalSalary.toStringAsFixed(0)} DA'),
                      _buildHeaderInfo('Pourboires', '+${totalTips.toStringAsFixed(0)} DA'),
                      _buildHeaderInfo('Dépenses', '-${totalExpenses.toStringAsFixed(0)} DA'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- BOUTONS D'ACTION RAPIDE ---
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.vertical: 14,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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
                      padding: const EdgeInsets.vertical: 14,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _showAddTransactionDialog(isIncome: false),
                    icon: const Icon(Icons.remove),
                    label: const Text('- Dépense'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- HISTORIQUE RÉCENT ET SUPPRESSION ---
            const Text(
              'Aperçu des Opérations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black80),
            ),
            const SizedBox(height: 10),

            _transactions.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text('Aucune opération enregistrée pour le moment.', style: TextStyle(color: Colors.grey.shade600)),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _transactions.length,
                    itemBuilder: (ctx, index) {
                      final tx = _transactions[index];
                      return Dismissible(
                        key: Key(tx.id),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          _deleteTransaction(tx.id);
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: tx.isIncome ? Colors.green.shade50 : Colors.red.shade50,
                              child: Icon(_getCategoryIcon(tx.category), color: tx.isIncome ? Colors.green : Colors.red),
                            ),
                            title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${tx.category} • ${tx.date.day}/${tx.date.month} ${tx.date.hour}:${tx.date.minute.toString().padLeft(2, '0')}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${tx.isIncome ? '+' : '-'}${tx.amount.toStringAsFixed(0)} DA',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: tx.isIncome ? Colors.green.shade700 : Colors.red.shade700,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                                  onPressed: () => _confirmDeleteDialog(tx.id),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  void _confirmDeleteDialog(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'opération'),
        content: const Text('Voulez-vous vraiment effacer cette ligne ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              _deleteTransaction(id);
              Navigator.pop(context);
            },
            child: const Text('Supprimer'),
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
