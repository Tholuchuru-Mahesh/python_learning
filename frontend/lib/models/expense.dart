class Expense {
  final String id;
  final String title;
  final String category; // RENT, UTILITY, PACKAGING, MAINTENANCE, GENERAL (PRD §5.7)
  final double amount;
  final DateTime expenseDate;
  final String? notes;
  final String createdByName;

  Expense({
    required this.id,
    required this.title,
    this.category = 'GENERAL',
    required this.amount,
    required this.expenseDate,
    this.notes,
    this.createdByName = 'Owner',
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String? ?? 'GENERAL',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      expenseDate: DateTime.tryParse(json['expenseDate'] as String? ?? '') ?? DateTime.now(),
      notes: json['notes'] as String?,
      createdByName: json['createdByName'] as String? ?? 'Owner',
    );
  }
}

