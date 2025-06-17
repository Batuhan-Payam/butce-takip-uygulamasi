import 'package:intl/intl.dart';

final NumberFormat currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

String formatDate(DateTime date) {
  return DateFormat('dd/MM/yyyy HH:mm').format(date);
}
