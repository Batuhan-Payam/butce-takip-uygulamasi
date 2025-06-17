import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsPage extends StatefulWidget {
  final double income;
  final double expenses;
  final List<Map<String, dynamic>> transactions;
  final NumberFormat currencyFormat;

  const StatisticsPage({
    Key? key,
    required this.income,
    required this.expenses,
    required this.transactions,
    required this.currencyFormat,
  }) : super(key: key);

  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  String selectedRange = 'Bu Ay';
  int _activeTabIndex = 0;

  List<Map<String, dynamic>> get filteredTransactions {
    final now = DateTime.now();
    return widget.transactions.where((t) {
      final rawDate = t['date'];
      DateTime? date;

      if (rawDate is DateTime) {
        date = rawDate;
      } else if (rawDate is String) {
        try {
          date = DateTime.parse(rawDate);
        } catch (e) {
          return false;
        }
      } else {
        return false;
      }

      if (selectedRange == 'Bu Ay') {
        return date.month == now.month && date.year == now.year;
      } else if (selectedRange == 'Geçen Ay') {
        final lastMonth = DateTime(now.year, now.month - 1);
        return date.month == lastMonth.month && date.year == lastMonth.year;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    Map<String, double> categoryTotals = {};
    double filteredIncome = 0;
    double filteredExpenses = 0;

    for (var t in filteredTransactions) {
      if (t['type'] == 'income') {
        filteredIncome += t['amount'];
      } else if (t['type'] == 'expense') {
        filteredExpenses += t['amount'];
        String category = t['category'] ?? 'Diğer';
        categoryTotals[category] = (categoryTotals[category] ?? 0) + t['amount'];
      }
    }

    final total = filteredIncome + filteredExpenses;
    final incomePercent = total == 0 ? 0.0 : filteredIncome / total;
    final expensePercent = total == 0 ? 0.0 : filteredExpenses / total;

    final Map<String, Color> categoryColors = {
      'Gıda': Colors.orangeAccent,
      'Ulaşım': Colors.blueAccent,
      'Eğlence': Colors.purpleAccent,
      'Sağlık': Colors.tealAccent,
      'Diğer': Colors.deepOrange,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text("Finansal Analiz",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.primaryColor,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildTabButton(0, "Giderler"),
                _buildTabButton(1, "Gelir/Gider"),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Zaman Aralığı:",
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white70 : Colors.grey[700],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.dividerColor,
                    ),
                  ),
                  child: DropdownButton<String>(
                    value: selectedRange,
                    underline: const SizedBox(),
                    items: ['Bu Ay', 'Geçen Ay', 'Tüm Zamanlar']
                        .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e),
                    ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedRange = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: IndexedStack(
              index: _activeTabIndex,
              children: [
                _buildExpenseCategoriesTab(theme, categoryTotals, categoryColors, filteredExpenses),
                _buildIncomeExpenseTab(theme, incomePercent, expensePercent, filteredIncome, filteredExpenses),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String text) {
    final isSelected = _activeTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseCategoriesTab(ThemeData theme, Map<String, double> categoryTotals,
      Map<String, Color> categoryColors, double totalExpenses) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: categoryTotals.entries.map((e) {
                  final color = categoryColors[e.key] ?? Colors.grey;
                  return PieChartSectionData(
                    value: e.value,
                    title: '${(e.value / (totalExpenses == 0 ? 1 : totalExpenses) * 100).toStringAsFixed(1)}%',
                    color: color,
                    radius: 25,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ...categoryTotals.entries.map((e) {
            final color = categoryColors[e.key] ?? Colors.grey;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      e.key,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  Text(
                    widget.currencyFormat.format(e.value),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseTab(ThemeData theme, double incomePercent,
      double expensePercent, double income, double expenses) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 80,
                sections: [
                  PieChartSectionData(
                    value: incomePercent,
                    color: Colors.greenAccent,
                    title: '${(incomePercent * 100).toStringAsFixed(1)}%',
                    radius: 25,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: expensePercent,
                    color: Colors.redAccent,
                    title: '${(expensePercent * 100).toStringAsFixed(1)}%',
                    radius: 25,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildAmountCard(
            context,
            title: "Toplam Gelir",
            amount: income,
            color: Colors.greenAccent,
            icon: Icons.arrow_downward,
          ),
          const SizedBox(height: 16),
          _buildAmountCard(
            context,
            title: "Toplam Gider",
            amount: expenses,
            color: Colors.redAccent,
            icon: Icons.arrow_upward,
          ),
          const SizedBox(height: 16),
          _buildAmountCard(
            context,
            title: "Bakiye",
            amount: income - expenses,
            color: income >= expenses ? Colors.blueAccent : Colors.orangeAccent,
            icon: Icons.account_balance_wallet,
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard(
      BuildContext context, {
        required String title,
        required double amount,
        required Color color,
        required IconData icon,
      }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    widget.currencyFormat.format(amount),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
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
}
