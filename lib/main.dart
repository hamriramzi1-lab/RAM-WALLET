import 'package:flutter/material.dart';

void main() {
  runApp(const RamWalletApp());
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
  // Config des salaires
  double salary4th = 0.0;
  double salary14th = 0.0;

  double get totalSalary => salary4th + salary14th;

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
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet, color: Colors.teal),
                        SizedBox(width: 8),
                        Text(
                          'Configuration des Salaires',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSalaryItem('Salaire du 4', salary4th),
                        Container(height: 40, width: 1, color: Colors.grey.shade300),
                        _buildSalaryItem('Salaire du 14', salary14th),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Salaires :',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${totalSalary.toStringAsFixed(0)} DA',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Indication pour la suite
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.teal),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Étape 1 de RAM WALLET prête ! Clique sur l\'engrenage en haut à droite pour définir tes deux salaires.',
                      style: TextStyle(fontSize: 13, color: Colors.teal),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalaryItem(String title, double amount) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          '${amount.toStringAsFixed(0)} DA',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
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
              decoration: const InputDecoration(
                labelText: 'Salaire du 4 du mois (DA)',
                prefixIcon: Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: s14Controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Salaire du 14 du mois (DA)',
                prefixIcon: Icon(Icons.event_available),
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
}
