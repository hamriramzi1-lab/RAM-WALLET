import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const RamWalletApp());
}

class RamWalletApp extends StatelessWidget {
  const RamWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RAM Wallet & Wardrobe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  double _balance = 0.0;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _wardrobe = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? txData = prefs.getString('transactions');
    final String? wardrobeData = prefs.getString('wardrobe');

    setState(() {
      if (txData != null) {
        _transactions = List<Map<String, dynamic>>.from(jsonDecode(txData));
        _balance = _transactions.fold(0.0, (sum, item) {
          final amt = (item['amount'] as num).toDouble();
          return item['type'] == 'income' ? sum + amt : sum - amt;
        });
      }
      if (wardrobeData != null) {
        _wardrobe = List<Map<String, dynamic>>.from(jsonDecode(wardrobeData));
      }
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('transactions', jsonEncode(_transactions));
    await prefs.setString('wardrobe', jsonEncode(_wardrobe));
  }

  void _addTransaction(String title, double amount, String type) {
    setState(() {
      _transactions.insert(0, {
        'title': title,
        'amount': amount,
        'type': type,
        'date': DateTime.now().toString().split(' ')[0],
      });
      if (type == 'income') {
        _balance += amount;
      } else {
        _balance -= amount;
      }
    });
    _saveData();
  }

  void _addWardrobeItem(String name, String category, double price) {
    setState(() {
      _wardrobe.insert(0, {
        'name': name,
        'category': category,
        'price': price,
        'date': DateTime.now().toString().split(' ')[0],
      });
      if (price > 0) {
        _transactions.insert(0, {
          'title': 'Achat Vêtement: $name',
          'amount': price,
          'type': 'expense',
          'date': DateTime.now().toString().split(' ')[0],
        });
        _balance -= price;
      }
    });
    _saveData();
  }

  void _showAddTransactionDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String type = 'expense';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nouvelle opération'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre / Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Montant (DZD)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final amt = double.tryParse(amountController.text) ?? 0.0;
                if (titleController.text.isNotEmpty && amt > 0) {
                  _addTransaction(titleController.text, amt, type);
                  Navigator.pop(context);
                }
              },
              child: const Text('Valider'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddWardrobeDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    String category = 'Haut';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ajouter à la garde-robe'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'article (ex: Veste en cuir)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Prix d\'achat (DZD, optionnel)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(),
                ),
                items: ['Haut', 'Bas', 'Chaussures', 'Accessoires']
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => category = val);
                },
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
                final price = double.tryParse(priceController.text) ?? 0.0;
                if (nameController.text.isNotEmpty) {
                  _addWardrobeItem(nameController.text, category, price);
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

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildWalletTab(),
      _buildWardrobeTab(),
      _buildSettingsTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0
              ? 'RAM Wallet'
              : (_currentIndex == 1 ? 'Garde-robe' : 'Paramètres'),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Portefeuille',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checkroom),
            label: 'Garde-robe',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }

  Widget _buildWalletTab() {
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
                  const Text('Solde Disponible', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(
                    '${_balance.toStringAsFixed(2)} DZD',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _balance >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showAddTransactionDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter une transaction'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Historique des transactions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _transactions.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'Aucune transaction enregistrée.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final item = _transactions[index];
                    final isIncome = item['type'] == 'income';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isIncome ? Colors.green.shade100 : Colors.red.shade100,
                          child: Icon(
                            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isIncome ? Colors.green.shade800 : Colors.red.shade800,
                          ),
                        ),
                        title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(item['date']),
                        trailing: Text(
                          '${isIncome ? '+' : '-'} ${item['amount']} DZD',
                          style: TextStyle(
                            color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildWardrobeTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showAddWardrobeDialog,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Ajouter un vêtement'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _wardrobe.isEmpty
                ? const Center(
                    child: Text(
                      'Votre garde-robe est vide.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: _wardrobe.length,
                    itemBuilder: (context, index) {
                      final item = _wardrobe[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.deepPurple.shade50,
                                child: const Icon(Icons.checkroom, size: 30, color: Colors.deepPurple),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                item['name'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['category'],
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              if (item['price'] > 0) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${item['price']} DZD',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: const [
        Card(
          child: ListTile(
            leading: Icon(Icons.person),
            title: Text('Profil Utilisateur'),
            subtitle: Text('Compte local'),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.storage),
            title: Text('Sauvegarde des données'),
            subtitle: Text('Données stockées en local sur l\'appareil'),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('À propos de RAM Wallet'),
            subtitle: Text('Version 1.0.0'),
          ),
        ),
      ],
    );
  }
}
