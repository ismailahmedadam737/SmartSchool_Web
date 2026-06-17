class IncomeModel {
  final String receiptNo;
  final String studentName;
  final double amountPaid;
  final double remainingDebt;
  final String paymentMethod;

  IncomeModel({
    required this.receiptNo,
    required this.studentName,
    required this.amountPaid,
    required this.remainingDebt,
    required this.paymentMethod,
  });

  Map<String, dynamic> toJson() => {
    'receipt_no': receiptNo,
    'student_name': studentName,
    'amount_paid': amountPaid,
    'remaining_debt': remainingDebt,
    'payment_method': paymentMethod,
  };
}