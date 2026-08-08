import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/debt.dart';
import '../services/storage_service.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  final StorageService _storage = StorageService();
  final Uuid _uuid = const Uuid();
  List<Debt> _debts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final debts = await _storage.loadDebts();
    setState(() {
      _debts = debts;
    });
  }

  Future<void> _saveData() async {
    await _storage.saveDebts(_debts);
  }

  void _addDebt(String name, double amount, String type) {
    final debt = Debt(
      id: _uuid.v4(),
      name: name,
      amount: amount,
      type: type,
    );

    setState(() {
      _debts.insert(0, debt);
    });
    _saveData();
    _showSnackBar('Dette ajoutée');
  }

  void _settleDebt(String debtId, double amount) {
    final debtIndex = _debts.indexWhere((d) => d.id == debtId);
    if (debtIndex == -1) return;

    final debt = _debts[debtIndex];
    final newRemaining = (debt.remainingAmount - amount).clamp(0.0, double.infinity);

    setState(() {
      _debts[debtIndex] = Debt(
        id: debt.id,
        name: debt.name,
        amount: debt.amount,
        type: debt.type,
        remainingAmount: newRemaining,
        date: debt.date,
        isSettled: newRemaining <= 0,
      );
    });
    _saveData();
    _showSnackBar('Dette réglée: $amount DZD');
  }

  void _showAddDebtDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    String type = 'owed_to_me';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nouvelle dette'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom / Description',
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('On me doit'),
                    selected: type == 'owed_to_me',
                    selectedColor: Colors.green.shade100,
                    onSelected: (val) => setDialogState(() => type = 'owed_to_me'),
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text('Je dois'),
                    selected: type == 'i_owe',
                    selectedColor: Colors.red.shade100,
                    onSelected: (val) => setDialogState(() => type = 'i_owe'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final amt = double.tryParse(amountController.text) ?? 0.0;
                if (nameController.text.isNotEmpty && amt > 0) {
                  _addDebt(nameController.text, amt, type);
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

  void _showSettleDialog(Debt debt) {
    final amountController = TextEditingController();
    bool fullPayment = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Régler la dette'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Dette: ${debt.name}'),
              Text('Montant total: ${debt.amount.toStringAsFixed(2)} DZD'),
              Text('Reste: ${debt.remainingAmount.toStringAsFixed(2)} DZD'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: fullPayment,
                    onChanged: (val) {
                      setDialogState(() {
                        fullPayment = val ?? true;
                        if (fullPayment) {
                          amountController.text = debt.remainingAmount.toStringAsFixed(2);
                        } else {
                          amountController.clear();
                        }
                      });
                    },
                  ),
                  const Text('Règlement total'),
                ],
              ),
              if (!fullPayment)
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Montant à régler',
                    border: OutlineInputBorder(),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                double amount = 0.0;
                if (fullPayment) {
                  amount = debt.remainingAmount;
                } else {
                  amount = double.tryParse(amountController.text) ?? 0.0;
                }
                if (amount > 0 && amount <= debt.remainingAmount) {
                  _settleDebt(debt.id, amount);
                  Navigator.pop(context);
                }
              },
              child: const Text('Régler'),
            ),
          ],
        ),
      ),
    );
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showAddDebtDialog,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une dette'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_debts.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Aucune dette', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _debts.length,
                itemBuilder: (context, index) {
                  final debt = _debts[index];
                  final isOwedToMe = debt.type == 'owed_to_me';
                  final color = isOwedToMe ? Colors.green : Colors.red;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.shade100,
                        child: Icon(
                          isOwedToMe ? Icons.arrow_downward : Icons.arrow_upward,
                          color: color.shade800,
                        ),
                      ),
                      title: Text(debt.name),
                      subtitle: Text(
                        isOwedToMe ? 'On me doit' : 'Je dois',
                        style: TextStyle(color: color.shade700),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${debt.amount.toStringAsFixed(2)} DZD',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (!debt.isSettled)
                            Text(
                              'Reste: ${debt.remainingAmount.toStringAsFixed(2)} DZD',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          if (debt.isSettled)
                            const Text(
                              '✅ Réglé',
                              style: TextStyle(fontSize: 12, color: Colors.green),
                            ),
                        ],
                      ),
                      onTap: () {
                        if (!debt.isSettled) {
                          _showSettleDialog(debt);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
