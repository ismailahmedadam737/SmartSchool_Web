import 'package:flutter/material.dart';
import 'package:iftiinshe/Service/payment_api_service.dart';

class IncomePage extends StatefulWidget {
  const IncomePage({super.key});

  @override
  State<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  double totalIncome = 0.0;
  double totalExpenses = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFinancialData();
  }

  Future<void> _fetchFinancialData() async {
    try {
      final income = await PaymentApiService.getTotalIncome();
      final expenses = await PaymentApiService.getTotalExpenses();
      setState(() {
        totalIncome = income;
        totalExpenses = expenses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error fetching data: $e");
    }
  }

  double get netProfit => totalIncome - totalExpenses;

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color cardColor = isDark ? Colors.grey[900]! : Colors.white;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 850),
            child: Column(
              children: [
                _buildAnimatedProfitCard(),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(child: _buildSummaryCard("Income & ", "\$${totalIncome.toStringAsFixed(2)}", Icons.arrow_upward_rounded, Colors.green, cardColor)),
                    const SizedBox(width: 15),
                    Expanded(child: _buildSummaryCard("Expenses", "\$${totalExpenses.toStringAsFixed(2)}", Icons.arrow_downward_rounded, Colors.red, cardColor)),
                    const SizedBox(width: 15),
                    Expanded(child: _buildSummaryCard("Net Profit", "\$${netProfit.toStringAsFixed(2)}", Icons.account_balance_wallet_rounded, Colors.blue, cardColor)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedProfitCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(colors: [Color(0xFF00F260), Color(0xFF0575E6)]),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          const Icon(Icons.show_chart_rounded, color: Colors.white, size: 30),
          const SizedBox(height: 10),
          const Text("NET PROFIT", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
          Text("\$${netProfit.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String amount, IconData icon, Color color, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 5),
          Text(amount, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}