import 'package:flutter/material.dart';
import 'package:iftiinshe/models/expense_model.dart';
import 'package:iftiinshe/Service/expense_service.dart'; // Hubi path-kaaga

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key, required List<ExpenseItem> expenseList});
  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  final List<String> _expenseTitles = ['Kirada', 'Biyaha', 'Laydhka', 'Xashiishka', 'Nadaafada', 'Mushahar', 'Agabka xafiiska'];
  String? _selectedTitle;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  List<dynamic> _registeredExpenses = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    final data = await ExpenseService.getAllExpenses();
    setState(() {
      _registeredExpenses = data;
      _isLoading = false;
    });
  }

  void _deleteExpense(int id) async {
    bool success = await ExpenseService.deleteExpense(id);
    if (success) {
      setState(() {
        _registeredExpenses.removeWhere((item) => item['id'] == id);
      });
      _showSnackBar("Kharashka si guul leh ayaa loo tirtiray!", Colors.green);
    } else {
      _showSnackBar("Tirtiriddii way guuldarraysatay!", Colors.red);
    }
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Ma hubtaa?"),
        content: const Text("Xogtan si rasmi ah ayaa loo tirtirayaa."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Maya", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
              _deleteExpense(id);
            },
            child: const Text("Haa, Tirtir", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _saveExpense() async {
    if (_selectedTitle != null && _amountController.text.isNotEmpty) {
      setState(() => _isLoading = true);
      
      final Map<String, dynamic> kharashData = {
        'category': _selectedTitle,
        'amount': double.parse(_amountController.text),
        'is_paid': true,
      };

      bool success = await ExpenseService.addExpense(kharashData);
      
      if (success) {
        _showSnackBar("Kharashka si guul leh ayaa loo keydiyay!", Colors.green);
        _amountController.clear();
        _noteController.clear();
        _selectedTitle = null;
        _loadExpenses();
      } else {
        _showSnackBar("Khalad ayaa dhacay!", Colors.red);
      }
      setState(() => _isLoading = false);
    } else {
      _showSnackBar("Fadlan buuxi meelaha banaan!", Colors.orange);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _buildRegistrationForm()),
            const SizedBox(width: 30),
            Expanded(flex: 3, child: _buildExpensesList()),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(children: [Icon(Icons.add_circle_outline, color: Colors.green), SizedBox(width: 10), Text("Diiwaangeli Kharashka", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
          const Divider(height: 40),
          _buildLabel("Nooca Kharashka"),
          _buildDropdown(),
          const SizedBox(height: 20),
          _buildLabel("Cadadka Lacagta (\$)"),
          _buildInputField(_amountController, "Enter Amount", Icons.monetization_on, TextInputType.number),
          const SizedBox(height: 20),
          _buildLabel("Faahfaahin (Notes)"),
          _buildInputField(_noteController, "Add details...", Icons.note_add, TextInputType.text),
          const SizedBox(height: 40),
          InkWell(
            onTap: _isLoading ? null : _saveExpense,
            child: Container(
              height: 55,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.green, Colors.greenAccent]),
                borderRadius: BorderRadius.circular(15),
              ),
              alignment: Alignment.center,
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Keydi & Bixi (Paid)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesList() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("Liiska Kharashyada", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (_registeredExpenses.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.pinkAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text("${_registeredExpenses.length} Items", style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold, fontSize: 12)))
          ]),
          const Divider(height: 40),
          Expanded(child: _isLoading ? const Center(child: CircularProgressIndicator()) : _registeredExpenses.isEmpty ? _buildEmptyState() : ListView.builder(itemCount: _registeredExpenses.length, itemBuilder: (context, index) => _buildExpenseItem(_registeredExpenses[index], index))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() { return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.receipt_long_outlined, size: 70, color: Colors.grey[200]), const SizedBox(height: 15), Text("Ma jiraan xog la diwaangaliyay", style: TextStyle(color: Colors.grey[400], fontSize: 15))])); }

  Widget _buildExpenseItem(Map<String, dynamic> item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15), padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade100)),
      child: Row(children: [
        CircleAvatar(backgroundColor: Colors.green.withOpacity(0.1), child: const Icon(Icons.check_circle, color: Colors.green, size: 20)),
        const SizedBox(width: 15),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item['category'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), Text(item['note'] ?? 'No notes', style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text("-\$${item['amount']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 16)),
          const SizedBox(height: 5),
          Row(
            children: [
              IconButton(
                onPressed: () => _confirmDelete(item['id']),
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 10),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Text("PAID", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10))),
            ],
          ),
        ]),
      ]),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)));

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: const Color(0xFFF5F6FA), borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: _selectedTitle, hint: const Text("Dooro nooca kharashka", style: TextStyle(fontSize: 14)), isExpanded: true, icon: const Icon(Icons.keyboard_arrow_down, color: Colors.pinkAccent), items: _expenseTitles.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => _selectedTitle = v))),
    );
  }

  Widget _buildInputField(TextEditingController ctrl, String hint, IconData icon, TextInputType type) {
    return TextField(controller: ctrl, keyboardType: type, style: const TextStyle(fontSize: 14), decoration: InputDecoration(prefixIcon: Icon(icon, color: Colors.green, size: 20), hintText: hint, hintStyle: const TextStyle(color: Colors.grey, fontSize: 13), filled: true, fillColor: const Color(0xFFF5F6FA), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 15)));
  }
}