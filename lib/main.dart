import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'isIncome': isIncome,
      'category': category,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      isIncome: map['isIncome'],
      category: map['category'],
    );
  }
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
  List<Transaction> _transactions = [];
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      salary4th = prefs.getDouble('salary4th') ?? 0.0;
      salary14th = prefs.getDouble('salary14th') ?? 0.0;

      final String? txData = prefs.getString('transactions');
      if (txData != null) {
        final List<dynamic> decoded = json.decode(txData);
        _transactions = decoded.map((item) => Transaction.fromMap(item)).toList();
      }
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('salary4th', salary4th);
    await prefs.setDouble('salary14th', salary14th);

    final List<Map<String, dynamic>> encoded = _transactions.map((tx) => tx.toMap()).toList();
    await prefs.setString('transactions', json.encode(encoded));
  }

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

  void _addTransaction(String title, double amount, bool isIncome, String category, DateTime customDate) {
    setState(() {
      _transactions.insert(
        0,
        Transaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title.isEmpty ? (isIncome ? 'Pourboire' : 'Dépense') : title,
          amount: amount,
          date: customDate,
          isIncome: isIncome,
          category: category,
        ),
      );
      _transactions.sort((a, b) => b.date.compareTo(a.date));
    });
    _saveData();
  }

  void _deleteTransaction(String id) {
    setState(() {
      _transactions.removeWhere((tx) => tx.id == id);
    });
    _saveData();
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

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Repas':
        return Colors.orange;
      case 'Transport':
        return Colors.blue;
      case 'Café/Tabac':
        return Colors.brown;
      case 'Achat Perso':
        return Colors.purple;
      default:
        return Colors.redAccent;
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
            icon: const Icon(Icons.bar_chart),
            onPressed: _showStatsAndAnnualReportModal,
            tooltip: 'Statistiques & Bilan Annuel',
          ),
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
            // Carte Solde Net
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

            // Boutons d'ajout
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

            // Liste des opérations
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
                            subtitle: Text('${tx.category} • ${tx.date.day}/${tx.date.month}/${tx.date.year} ${tx.date.hour}:${tx.date.minute.toString().padLeft(2, '0')}'),
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

  // --- Modal Statistiques & Bilan Annuel ---
  void _showStatsAndAnnualReportModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final annualTx = _transactions.where((tx) => tx.date.year == _selectedYear).toList();
            final annualTips = annualTx.where((tx) => tx.isIncome).fold(0.0, (sum, tx) => sum + tx.amount);
            final annualExpenses = annualTx.where((tx) => !tx.isIncome).fold(0.0, (sum, tx) => sum + tx.amount);
            final annualSalaryTotal = totalSalary * 12; // 12 mois de salaire
            final annualNet = (annualSalaryTotal + annualTips) - annualExpenses;

            // Calcul par catégories de dépense
            Map<String, double> categoryTotals = {};
            for (var tx in annualTx.where((tx) => !tx.isIncome)) {
              categoryTotals[tx.category] = (categoryTotals[tx.category] ?? 0.0) + tx.amount;
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Statistiques & Bilan',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                      DropdownButton<int>(
                        value: _selectedYear,
                        items: [2024, 2025, 2026, 2027].map((y) {
                          return DropdownMenuItem(value: y, child: Text('$y'));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => _selectedYear = val);
                          }
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Text('Bilan Annuel $_selectedYear', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              children: [
                                _buildReportRow('Salaires Annuels (Estimés)', '${annualSalaryTotal.toStringAsFixed(0)} DA', Colors.black),
                                const SizedBox(height: 6),
                                _buildReportRow('Total Pourboires', '+${annualTips.toStringAsFixed(0)} DA', Colors.green.shade700),
                                const SizedBox(height: 6),
                                _buildReportRow('Total Dépenses', '-${annualExpenses.toStringAsFixed(0)} DA', Colors.red.shade700),
                                const Divider(height: 16),
                                _buildReportRow('Bilan Annuel Net', '${annualNet.toStringAsFixed(0)} DA', Colors.teal.shade900, isBold: true),
                              ],
                            ),
                          ),
                          const SizedBox(height: 25),
                          const Text('Répartition des Dépenses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 15),

                          categoryTotals.isEmpty
                              ? const Center(padding: EdgeInsets.all(20), child: Text('Aucune dépense enregistrée cette année.'))
                              : SizedBox(
                                  height: 200,
                                  child: PieChart(
                                    PieChartData(
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 40,
                                      sections: categoryTotals.entries.map((entry) {
                                        return PieChartSectionData(
                                          color: _getCategoryColor(entry.key),
                                          value: entry.value,
                                          title: '${((entry.value / (annualExpenses > 0 ? annualExpenses : 1)) * 100).toStringAsFixed(0)}%',
                                          radius: 50,
                                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 15),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: categoryTotals.keys.map((cat) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(width: 12, height: 12, color: _getCategoryColor(cat)),
                                  const SizedBox(width: 6),
                                  Text('$cat (${categoryTotals[cat]!.toStringAsFixed(0)} DA)', style: const TextStyle(fontSize: 12)),
                                ],
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
          },
        );
      },
    );
  }

  Widget _buildReportRow(String title, String amount, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
        Text(amount, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color, fontSize: 14)),
      ],
    );
  }

  // --- Dialogue Ajout Transaction (avec option "Somme Oubliée" / Date Personnalisée) ---
  void _showAddTransactionDialog({required bool isIncome}) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String selectedCategory = isIncome ? 'Pourboire' : 'Repas';
    DateTime selectedDate = DateTime.now();

    final categories = isIncome
        ? ['Pourboire', 'Autre']
        : ['Repas', 'Transport', 'Café/Tabac', 'Achat Perso', 'Autre'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isIncome ? 'Ajouter un Pourboire' : 'Ajouter une Dépense'),
          content: SingleChildScrollView(
            child: Column(
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
                  decoration: const InputDecoration(labelText: 'Note (ex: Oubli hier)', prefixIcon: Icon(Icons.note)),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                  onChanged: (val) => setDialogState(() => selectedCategory = val!),
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                ),
                const SizedBox(height: 12),
                // Sélection de la date (Somme oubliée)
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20, color: Colors.teal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Date : ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      child: const Text('Modifier'),
                    ),
                  ],
                ),
              ],
            ),
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
                  _addTransaction(noteController.text.trim(), amount, isIncome, selectedCategory, selectedDate);
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
              _saveData();
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
