class TransactionModel {
  final String type;
  final double amount;
  final String note;
  final String? category;
  final DateTime date;

  TransactionModel({
    required this.type,
    required this.amount,
    required this.note,
    this.category,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'amount': amount,
      'note': note,
      'category': category,
      'date': date.toIso8601String(),
    };
  }

  static TransactionModel fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      type: map['type'],
      amount: map['amount'],
      note: map['note'],
      category: map['category'],
      date: DateTime.parse(map['date']),
    );
  }
}
