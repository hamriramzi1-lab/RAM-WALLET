import 'all_transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../models/debt.dart';
import '../services/storage_service.dart';
import 'stats_screen.dart';
import 'debts_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  final Uuid _uuid = const Uuid();

  List<Transaction> _transactions = [];
  List<Debt> _debts = [];
  double _balance = 0.0;
  int _currentIndex = 0;

  double _salary1 = 0.0;
  double _salary2 = 0.0;
  DateTime? _salary1Date;
  DateTime? _salary2Date;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final transactions = await _storage.loadTransactions();
    final debts = await _storage.loadDebts();
    final salaryData = await _storage.loadSalaryData();

    setState(() {
      _transactions = transactions;
      _debts = debts;
      _balance = _storage.calculateBalance(transactions);
      
      if (salaryData != null) {
        _salary1 = salaryData['salary1'] ?? 0.0;
        _salary2 = salaryData['salary2'] ?? 0.0;
        _salary1Date = salaryData['salary1Date'] != null 
            ? DateTime.parse(salaryData['salary1Date']) 
            : null;
        _salary2Date = salaryData['salary2Date'] != null 
            ? DateTime.parse(salaryData['salary2Date']) 
            : null;
      }
    });
  }

  Future<void> _saveAllData() async {
    await _storage.saveTransactions(_transactions);
    await _storage.saveDebts(_debts);
    await _storage.saveSalaryData({
      'salary1': _salary1,
      'salary2': _salary2,
      'salary1Date': _salary1Date?.toIso8601String(),
      'salary2Date': _salary2Date?.toIso8601String(),
    });
  }

  void _addTransaction(String title, double amount, String type, String category, DateTime date) {
    final transaction = Transaction(
      id: _uuid.v4(),
      title: title,
      amount: amount,
      type: type,
      category: category,
      date: date,
    );

    setState(() {
      _transactions.insert(0, transaction);
      _balance = type == 'income' ? _balance + amount : _balance - amount;
    });
    _saveAllData();
    _showSnackBar('${type == 'income' ? 'Revenu' : 'Dépense'} ajouté(e)');
  }

  void _deleteTransaction(int index) {
    final tx = _transactions[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text('Supprimer "${tx.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _transactions.removeAt(index);
                _balance = tx.type == 'income' 
                    ? _balance - tx.amount 
                    : _balance + tx.amount;
              });
              _saveAllData();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String type = 'expense';
    String category = 'Autre';
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nouvelle opération'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Montant (DZD)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(
                    labelText: 'Catégorie',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Nourriture', 'Transport', 'Loisirs', 'Salaire', 'Dette', 'Autre']
                      .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => category = val);
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('Dépense'),
                      selected: type == 'expense',
                      selectedColor: Colors.red.shade100,
                      onSelected: (val) => setDialogState(() => type = 'expense'),
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('Revenu'),
                      selected: type == 'income',
                      selectedColor: Colors.green.shade100,
                      onSelected: (val) => setDialogState(() => type = 'income'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final amt = double.tryParse(amountController.text) ?? 0.0;
                if (titleController.text.isNotEmpty && amt > 0) {
                  _addTransaction(titleController.text, amt, type, category, selectedDate);
                  Navigator.pop(context);
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSalaryDialog() {
    final salary1Controller = TextEditingController(text: _salary1.toString());
    final salary2Controller = TextEditingController(text: _salary2.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('💰 Gestion des salaires'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Salaire 1 (4 du mois)'),
              TextField(
                controller: salary1Controller,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Montant (DZD)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Salaire 2 (14 du mois)'),
              TextField(
                controller: salary2Controller,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Montant (DZD)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _salary1 = double.tryParse(salary1Controller.text) ?? 0.0;
                _salary2 = double.tryParse(salary2Controller.text) ?? 0.0;
                _salary1Date = DateTime(DateTime.now().year, DateTime.now().month, 4);
                _salary2Date = DateTime(DateTime.now().year, DateTime.now().month, 14);
              });
              _saveAllData();
              Navigator.pop(context);
              _showSnackBar('Salaires enregistrés !');
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  String _getNextSalaryDate() {
    final now = DateTime.now();
    final day = now.day;
    
    if (_salary1Date != null && day < 4) {
      return '4/${now.month}/${now.year}';
    } else if (_salary2Date != null && day < 14) {
      return '14/${now.month}/${now.year}';
    } else if (_salary1Date != null) {
      final nextMonth = now.month + 1 > 12 ? 1 : now.month + 1;
      final nextYear = now.month + 1 > 12 ? now.year + 1 : now.year;
      return '4/$nextMonth/$nextYear';
    }
    return 'Non configuré';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomePage(),
      const StatsScreen(),
      const DebtsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 
            ? 'RAM Wallet' 
            : (_currentIndex == 1 ? 'Statistiques' : 'Dettes')),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.attach_money),
              onPressed: _showSalaryDialog,
              tooltip: 'Gérer les salaires',
            ),
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.add_card),
              onPressed: _showAddTransactionDialog,
              tooltip: 'Ajouter une transaction',
            ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Dettes',
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text('Solde Net', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(
                    '${_balance.toStringAsFixed(2)} DZD',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _balance >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showAddTransactionDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Dépense'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade100,
                            foregroundColor: Colors.red.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showAddTransactionDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Revenu'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade100,
                            foregroundColor: Colors.green.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Salaires
          if (_salary1 > 0 || _salary2 > 0) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💰 Salaires du mois',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (_salary1 > 0)
                      Text('• 4 du mois: ${_salary1.toStringAsFixed(2)} DZD'),
                    if (_salary2 > 0)
                      Text('• 14 du mois: ${_salary2.toStringAsFixed(2)} DZD'),
                    const SizedBox(height: 4),
                    Text(
                      '📅 Prochain salaire: ${_getNextSalaryDate()}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dernières opérations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_transactions.length} transaction${_transactions.length > 1 ? 's' : ''}',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (_transactions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text('Aucune transaction', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            AnimationLimiter(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _transactions.length > 10 ? 10 : _transactions.length,
                itemBuilder: (context, index) {
                  final tx = _transactions[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 300),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: Card(
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
                            onTap: () => _deleteTransaction(index),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          
          // ✅ BOUTON MODIFIÉ ICI
          if (_transactions.length > 10)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AllTransactionsScreen(
                        transactions: _transactions,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '📂 Voir toutes les transactions (${_transactions.length})',
                      style: TextStyle(
                        color: Colors.deepPurple.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
