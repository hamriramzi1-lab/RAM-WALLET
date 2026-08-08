import 'package:flutter/material.dart';

void main() {
  runApp(const RamWalletApp());
}

class RamWalletApp extends StatelessWidget {
  const RamWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RAM Wallet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
        useMaterial3: true,
      ),
      home: const WalletHomePage(),
    );
  }
}

class WalletHomePage extends StatefulWidget {
  const WalletHomePage({super.key});

  @override
  State<WalletHomePage> createState() => _WalletHomePageState();
}

class _WalletHomePageState extends State<WalletHomePage> {
  int _selectedIndex = 0;
  double _balance = 0.0;
  final List<Map<String, dynamic>> _transactions = [];

  void _showAddTransactionDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Titre (ex: Vêtement, Achat)'),
            ),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Montant (DZD)'),
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
              final title = titleController.text;
              final amount = double.tryParse(amountController.text) ?? 0.0;

              if (title.isNotEmpty && amount > 0) {
                setState(() {
                  _balance += amount;
                  _transactions.insert(0, {
                    'title': title,
                    'amount': amount,
                    'date': DateTime.now().toString().split(' ')[0],
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RAM Wallet'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardTab(),
          const Center(child: Text('Statistiques & Analyse', style: TextStyle(fontSize: 18, color: Colors.grey))),
          const Center(child: Text('Paramètres de l\'application', style: TextStyle(fontSize: 18, color: Colors.grey))),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Portefeuille'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Statistiques'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Paramètres'),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Solde Total', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(
                    '${_balance.toStringAsFixed(2)} DZD',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _showAddTransactionDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.send),
                        label: const Text('Envoyer'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Dernières Transactions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          _transactions.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('Aucune dépense enregistrée cette année.')),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final item = _transactions[index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.monetization_on)),
                      title: Text(item['title']),
                      subtitle: Text(item['date']),
                      trailing: Text('+ ${item['amount']} DZD', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
