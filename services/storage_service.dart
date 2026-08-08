// lib/services/storage_service.dart
// Ce fichier gère la sauvegarde et le chargement des données

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../models/debt.dart';

class StorageService {
  // Instance unique (patron Singleton)
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // Clés pour le stockage
  static const String TRANSACTIONS_KEY = 'transactions';
  static const String DEBTS_KEY = 'debts';
  static const String SALARY_KEY = 'salary_data';

  // ==========================================
  // SAUVEGARDER LES DONNÉES
  // ==========================================

  Future<void> saveTransactions(List<Transaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = transactions.map((t) => t.toJson()).toList();
    await prefs.setString(TRANSACTIONS_KEY, jsonEncode(jsonData));
  }

  Future<void> saveDebts(List<Debt> debts) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = debts.map((d) => d.toJson()).toList();
    await prefs.setString(DEBTS_KEY, jsonEncode(jsonData));
  }

  Future<void> saveSalaryData(Map<String, dynamic> salaryData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SALARY_KEY, jsonEncode(salaryData));
  }

  // ==========================================
  // CHARGER LES DONNÉES
  // ==========================================

  Future<List<Transaction>> loadTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(TRANSACTIONS_KEY);
      if (data == null || data.isEmpty) return [];
      
      final List<dynamic> jsonData = jsonDecode(data);
      return jsonData.map((item) => Transaction.fromJson(item)).toList();
    } catch (e) {
      print('Erreur chargement transactions: $e');
      return [];
    }
  }

  Future<List<Debt>> loadDebts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(DEBTS_KEY);
      if (data == null || data.isEmpty) return [];
      
      final List<dynamic> jsonData = jsonDecode(data);
      return jsonData.map((item) => Debt.fromJson(item)).toList();
    } catch (e) {
      print('Erreur chargement dettes: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> loadSalaryData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(SALARY_KEY);
      if (data == null || data.isEmpty) return null;
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (e) {
      print('Erreur chargement salaires: $e');
      return null;
    }
  }

  // ==========================================
  // CALCULS
  // ==========================================

  // Calculer le solde total
  double calculateBalance(List<Transaction> transactions) {
    double balance = 0.0;
    for (var tx in transactions) {
      if (tx.type == 'income') {
        balance += tx.amount;
      } else {
        balance -= tx.amount;
      }
    }
    return balance;
  }

  // Calculer le total des dettes
  double calculateTotalDebts(List<Debt> debts) {
    double total = 0.0;
    for (var debt in debts) {
      if (!debt.isSettled) {
        total += debt.remainingAmount;
      }
    }
    return total;
  }
}
