class ExpenseItem {
  String category;
  double amount;
  bool isPaid;

  ExpenseItem({
    required this.category,
    required this.amount,
    this.isPaid = false,
  });
}