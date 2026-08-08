import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Ajoutez cette dépendance dans pubspec.yaml

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
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

// ============ MODELES DE DONNEES ============

class Transaction {
  final String title;
  final double amount;
  final String type; // 'income' ou 'expense'
  final String date;
  final String? id;

  Transaction({
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    this.id,
  });

  Map<String, dynamic> toJson() => {
    'id': id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    'title': title,
    'amount': amount,
    'type': type,
    'date': date,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'] as String?,
    title: json['title'] as String,
    amount: (json['amount'] as num).toDouble(),
    type: json['type'] as String,
    date: json['date'] as String,
  );

  bool get isIncome => type == 'income';
}

class WardrobeItem {
  final String name;
  final String category;
  final double price;
  final String date;
  final String? id;

  WardrobeItem({
    required this.name,
    required this.category,
    required this.price,
    required this.date,
    this.id,
  });

  Map<String, dynamic> toJson() => {
    'id': id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    'name': name,
    'category': category,
    'price': price,
    'date': date,
  };

  factory WardrobeItem.fromJson(Map<String, dynamic> json) => WardrobeItem(
    id: json['id'] as String?,
    name: json['name'] as String,
    category: json['category'] as String,
    price: (json['price'] as num).toDouble(),
    date: json['date'] as String,
  );
}

// ============ SERVICE DE STOCKAGE ============

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _transactionsKey = 'transactions';
  static const String _wardrobeKey = 'wardrobe';
  static const String _balanceKey = 'balance';

  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  Future<Map<String, dynamic>> loadAllData() async {
    try {
      final prefs = await _getPrefs();
      
      final List<Transaction> transactions = [];
      final String? txData = prefs.getString(_transactionsKey);
      if (txData != null && txData.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(txData);
        transactions.addAll(decoded.map((e) => Transaction.fromJson(e as Map<String, dynamic>)));
      }

      final List<WardrobeItem> wardrobe = [];
      final String? wardrobeData = prefs.getString(_wardrobeKey);
      if (wardrobeData != null && wardrobeData.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(wardrobeData);
        wardrobe.addAll(decoded.map((e) => WardrobeItem.fromJson(e as Map<String, dynamic>)));
      }

      // Récupérer le solde sauvegardé ou le recalculer
      double balance = prefs.getDouble(_balanceKey) ?? 0.0;
      if (balance == 0.0 && transactions.isNotEmpty) {
        balance = _calculateBalance(transactions);
      }

      return {
        'transactions': transactions,
        'wardrobe': wardrobe,
        'balance': balance,
      };
    } catch (e) {
      print('Erreur de chargement: $e');
      return {
        'transactions': <Transaction>[],
        'wardrobe': <WardrobeItem>[],
        'balance': 0.0,
      };
    }
  }

  Future<void> saveAllData({
    required List<Transaction> transactions,
    required List<WardrobeItem> wardrobe,
    required double balance,
  }) async {
    try {
      final prefs = await _getPrefs();
      
      await prefs.setString(_transactionsKey, jsonEncode(transactions.map((e) => e.toJson()).toList()));
      await prefs.setString(_wardrobeKey, jsonEncode(wardrobe.map((e) => e.toJson()).toList()));
      await prefs.setDouble(_balanceKey, balance);
    } catch (e) {
      print('Erreur de sauvegarde: $e');
      rethrow;
    }
  }

  double _calculateBalance(List<Transaction> transactions) {
    return transactions.fold(0.0, (sum, item) {
      return item.isIncome ? sum + item.amount : sum - item.amount;
    });
  }
}

// ============ SCREEN PRINCIPAL ============

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  double _balance = 0.0;
  List<Transaction> _transactions = [];
  List<WardrobeItem> _wardrobe = [];
  bool _isLoading = true;

  final StorageService _storage = StorageService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _storage.loadAllData();
      setState(() {
        _transactions = data['transactions'] as List<Transaction>;
        _wardrobe = data['wardrobe'] as List<WardrobeItem>;
        _balance = data['balance'] as double;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Erreur de chargement des données', isError: true);
    }
  }

  Future<void> _saveData() async {
    try {
      await _storage.saveAllData(
        transactions: _transactions,
        wardrobe: _wardrobe,
        balance: _balance,
      );
    } catch (e) {
      _showSnackBar('Erreur de sauvegarde', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String? _validateAmount(String value) {
    final clean = value.replaceAll(',', '.');
    if (clean.isEmpty) return 'Le montant est requis';
    if (double.tryParse(clean) == null) return 'Entrez un nombre valide';
    final amount = double.parse(clean);
    if (amount <= 0) return 'Le montant doit être positif';
    return null;
  }

  // ============ GESTION DES TRANSACTIONS ============

  void _addTransaction(String title, double amount, String type) {
    setState(() {
      final transaction = Transaction(
        title: title,
        amount: amount,
        type: type,
        date: _formatDate(DateTime.now()),
      );
      _transactions.insert(0, transaction);
      _balance = type == 'income' ? _balance + amount : _balance - amount;
    });
    _saveData();
    _showSnackBar('Transaction ajoutée avec succès');
  }

  void _deleteTransaction(int index) {
    final transaction = _transactions[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la transaction'),
        content: Text('Voulez-vous supprimer "${transaction.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _transactions.removeAt(index);
                _balance = transaction.isIncome 
                    ? _balance - transaction.amount 
                    : _balance + transaction.amount;
              });
              _saveData();
              Navigator.pop(context);
              _showSnackBar('Transaction supprimée');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  // ============ GESTION DE LA GARDE-ROBE ============

  void _addWardrobeItem(String name, String category, double price) {
    setState(() {
      final item = WardrobeItem(
        name: name,
        category: category,
        price: price,
        date: _formatDate(DateTime.now()),
      );
      _wardrobe.insert(0, item);
      
      if (price > 0) {
        final transaction = Transaction(
          title: 'Achat Vêtement: $name',
          amount: price,
          type: 'expense',
          date: _formatDate(DateTime.now()),
        );
        _transactions.insert(0, transaction);
        _balance -= price;
      }
    });
    _saveData();
    _showSnackBar('Vêtement ajouté à la garde-robe');
  }

  void _deleteWardrobeItem(int index) {
    final item = _wardrobe[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer un vêtement'),
        content: Text('Voulez-vous supprimer "${item.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _wardrobe.removeAt(index);
              });
              _saveData();
              Navigator.pop(context);
              _showSnackBar('Vêtement supprimé');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  // ============ DIALOGUES ============

  void _showAddTransactionDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String type = 'expense';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nouvelle opération'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Titre / Description',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer un titre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Montant (DZD)',
                    border: OutlineInputBorder(),
                    helperText: 'Utilisez le point ou la virgule',
                  ),
                  validator: (value) => _validateAmount(value ?? ''),
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  final cleanAmount = amountController.text.replaceAll(',', '.');
                  final amt = double.parse(cleanAmount);
                  _addTransaction(titleController.text.trim(), amt, type);
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
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ajouter à la garde-robe'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de l\'article',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer un nom';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Prix d\'achat (DZD, optionnel)',
                    border: OutlineInputBorder(),
                    helperText: '0 = non renseigné',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    return _validateAmount(value);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(
                    labelText: 'Catégorie',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Haut', 'Bas', 'Chaussures', 'Accessoires', 'Autre']
                      .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => category = val);
                  },
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
                if (formKey.currentState?.validate() ?? false) {
                  final cleanPrice = priceController.text.replaceAll(',', '.');
                  final price = double.tryParse(cleanPrice) ?? 0.0;
                  _addWardrobeItem(nameController.text.trim(), category, price);
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

  // ============ BUILD UI ============

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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

  // ============ ONGLET PORTEFEUILLE ============

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
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showAddTransactionDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_transactions.isNotEmpty)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _clearAllTransactions,
                            icon: const Icon(Icons.delete_sweep),
                            label: const Text('Tout effacer'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Historique des transactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_transactions.length} transaction${_transactions.length > 1 ? 's' : ''}',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _transactions.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Aucune transaction enregistrée.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          'Appuyez sur "Ajouter" pour commencer',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final item = _transactions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: item.isIncome ? Colors.green.shade100 : Colors.red.shade100,
                          child: Icon(
                            item.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                            color: item.isIncome ? Colors.green.shade800 : Colors.red.shade800,
                          ),
                        ),
                        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(item.date),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${item.isIncome ? '+' : '-'} ${item.amount.toStringAsFixed(2)} DZD',
                              style: TextStyle(
                                color: item.isIncome ? Colors.green.shade700 : Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                              onPressed: () => _deleteTransaction(index),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  void _clearAllTransactions() {
    if (_transactions.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer toutes les transactions'),
        content: const Text('Cette action est irréversible. Voulez-vous continuer ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _transactions.clear();
                _balance = 0.0;
              });
              _saveData();
              Navigator.pop(context);
              _showSnackBar('Toutes les transactions ont été effacées');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Effacer tout'),
          ),
        ],
      ),
    );
  }

  // ============ ONGLET GARDE-ROBE ============

  Widget _buildWardrobeTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showAddWardrobeDialog,
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Ajouter un vêtement'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (_wardrobe.isNotEmpty) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _clearAllWardrobe,
                  icon: const Icon(Icons.delete_sweep),
                  label: const Text('Effacer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ma garde-robe',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_wardrobe.length} article${_wardrobe.length > 1 ? 's' : ''}',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _wardrobe.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.checkroom, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Votre garde-robe est vide.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          'Ajoutez vos premiers vêtements !',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _wardrobe.length,
                    itemBuilder: (context, index) {
                      final item = _wardrobe[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.deepPurple.shade50,
                                    child: Icon(
                                      _getCategoryIcon(item.category),
                                      size: 30,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    item.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      item.category,
                                      style: const TextStyle(fontSize: 11, color: Colors.deepPurple),
                                    ),
                                  ),
                                  if (item.price > 0) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.price.toStringAsFixed(2)} DZD',
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
                            Positioned(
                              top: 4,
                              right: 4,
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                                onPressed: () => _deleteWardrobeItem(index),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Haut': return Icons.style;
      case 'Bas': return Icons.emoji_people;
      case 'Chaussures': return Icons.shopping_bag;
      case 'Accessoires': return Icons.watch;
      default: return Icons.checkroom;
    }
  }

  void _clearAllWardrobe() {
    if (_wardrobe.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer la garde-robe'),
        content: const Text('Cette action est irréversible. Voulez-vous continuer ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _wardrobe.clear();
              });
              _saveData();
              Navigator.pop(context);
              _showSnackBar('Garde-robe vidée');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Effacer tout'),
          ),
        ],
      ),
    );
  }

  // ============ ONGLET PARAMÈTRES ============

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profil Utilisateur'),
            subtitle: const Text('Compte local'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                _showSnackBar('Fonctionnalité à venir');
              },
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('Sauvegarde des données'),
            subtitle: Text('${_transactions.length} transactions, ${_wardrobe.length} vêtements'),
            trailing: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
              tooltip: 'Recharger les données',
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Effacer toutes les données'),
            subtitle: const Text('Supprimer définitivement'),
            trailing: const Icon(Icons.warning, color: Colors.orange),
            onTap: _showResetConfirmDialog,
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('À propos de RAM Wallet'),
            subtitle: Text('Version 2.0.0'),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            '${_transactions.length} transactions • ${_wardrobe.length} articles',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      ],
    );
  }

  void _showResetConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Effacer toutes les données'),
        content: const Text(
          'Cette action supprimera définitivement toutes vos transactions et votre garde-robe. '
          'Cette opération est irréversible. Êtes-vous sûr ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _transactions.clear();
                _wardrobe.clear();
                _balance = 0.0;
              });
              _saveData();
              Navigator.pop(context);
              _showSnackBar('Toutes les données ont été effacées');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Effacer tout définitivement'),
          ),
        ],
      ),
    );
  }
}
