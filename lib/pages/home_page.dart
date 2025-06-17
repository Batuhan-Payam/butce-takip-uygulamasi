import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'statistics_page.dart';
import 'user_profile_page.dart';
import 'package:untitled2/goals_page.dart';
import 'package:untitled2/borsa_canli_sayfasi.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkTheme;

  HomePage({required this.onThemeToggle, required this.isDarkTheme});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  double income = 0.0;
  double expenses = 0.0;
  List<Map<String, dynamic>> transactions = [];
  int _selectedIndex = 0;
  DateTime selectedDay = DateTime.now();

  Map<String, double> categoryBudgetLimits = {
    'Gıda': 1000.0,
    'Ulaşım': 500.0,
    'Eğlence': 300.0,
    'Sağlık': 400.0,
    'Diğer': 200.0,
  };

  final NumberFormat currencyFormat =
  NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('income', income);
    prefs.setDouble('expenses', expenses);
    prefs.setString('transactions', jsonEncode(transactions));
    prefs.setString('categoryBudgetLimits', jsonEncode(categoryBudgetLimits));
  }

  void _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      income = prefs.getDouble('income') ?? 0.0;
      expenses = prefs.getDouble('expenses') ?? 0.0;
      String? data = prefs.getString('transactions');
      if (data != null) {
        transactions = List<Map<String, dynamic>>.from(jsonDecode(data));
        transactions = transactions.map((e) {
          if (e['date'] is String) {
            e['date'] = DateTime.parse(e['date']);
          }
          return e;
        }).toList();
      }
      String? limitsData = prefs.getString('categoryBudgetLimits');
      if (limitsData != null) {
        categoryBudgetLimits = Map<String, double>.from(jsonDecode(limitsData));
      }
    });
  }

  void addIncome(double amount, String note, DateTime date) {
    setState(() {
      income += amount;
      transactions.insert(0, {
        'type': 'income',
        'amount': amount,
        'note': note,
        'date': date.toIso8601String(),
      });
    });
    _saveData();
  }

  void addExpense(double amount, String note, String category, DateTime date) {
    setState(() {
      expenses += amount;
      transactions.insert(0, {
        'type': 'expense',
        'amount': amount,
        'note': note,
        'category': category,
        'date': date.toIso8601String(),
      });
    });
    _saveData();
  }

  void deleteTransaction(int index) {
    setState(() {
      final t = transactions[index];
      if (t['type'] == 'income') {
        income -= t['amount'];
      } else if (t['type'] == 'expense') {
        expenses -= t['amount'];
      }
      transactions.removeAt(index);
    });
    _saveData();
  }

  void _confirmDelete(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("İşlemi Sil"),
        content: Text("Bu işlemi silmek istediğinizden emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("İptal"),
          ),
          TextButton(
            onPressed: () {
              deleteTransaction(index);
              Navigator.pop(context);
            },
            child: Text("Sil", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _goToPreviousDay() {
    setState(() {
      selectedDay = selectedDay.subtract(Duration(days: 1));
    });
  }

  void _goToNextDay() {
    setState(() {
      selectedDay = selectedDay.add(Duration(days: 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      buildHomePage(context),
      StatisticsPage(
        income: income,
        expenses: expenses,
        transactions: transactions,
        currencyFormat: currencyFormat,
      ),
      UserProfilePage(),
      BorsaCanliSayfasi(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (int index) => setState(() => _selectedIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: primaryColor,
            unselectedItemColor: Colors.grey,
            backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
            selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: "Ana Sayfa",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.pie_chart_outline),
                activeIcon: Icon(Icons.pie_chart),
                label: "İstatistik",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: "Profil",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.show_chart_outlined),
                activeIcon: Icon(Icons.show_chart),
                label: "Borsa",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildHomePage(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Bütçe Takip', style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
        )),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.flag, color: Colors.red),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GoalsPage(
                    categoryBudgetLimits: categoryBudgetLimits,
                    onBudgetLimitsChanged: (newLimits) {
                      setState(() {
                        categoryBudgetLimits = newLimits;
                      });
                      _saveData();
                    },
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(widget.isDarkTheme ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onThemeToggle,
            color: Colors.yellow,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bütçe Özeti',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  )),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Gelir',
                      amount: income,
                      icon: Icons.arrow_downward,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Gider',
                      amount: expenses,
                      icon: Icons.arrow_upward,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Bakiye',
                      amount: income - expenses,
                      icon: Icons.account_balance_wallet,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left, color: primaryColor),
                      onPressed: _goToPreviousDay,
                    ),
                    Text(
                      DateFormat('dd MMMM yyyy').format(selectedDay),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_right, color: primaryColor),
                      onPressed: _goToNextDay,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Son İşlemler',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      )),
                  Text(
                    'Toplam: ${transactions.where((t) {
                      DateTime tDate = DateTime.parse(t['date'].toString());
                      return tDate.year == selectedDay.year &&
                          tDate.month == selectedDay.month &&
                          tDate.day == selectedDay.day;
                    }).length}',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              _buildTransactionListForSelectedDay(),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'income',
            onPressed: () => _showTransactionDialog(isIncome: true),
            child: Icon(Icons.add, size: 28),
            backgroundColor: Colors.green,
            elevation: 4,
          ),
          SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'expense',
            onPressed: () => _showTransactionDialog(isIncome: false),
            child: Icon(Icons.remove, size: 28),
            backgroundColor: Colors.red,
            elevation: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                currencyFormat.format(amount),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionListForSelectedDay() {
    final filteredTransactions = transactions.where((t) {
      DateTime tDate = DateTime.parse(t['date'].toString());
      return tDate.year == selectedDay.year &&
          tDate.month == selectedDay.month &&
          tDate.day == selectedDay.day;
    }).toList();

    if (filteredTransactions.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.receipt_long, size: 60, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text('Bu gün için işlem bulunamadı',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: filteredTransactions.length,
      separatorBuilder: (context, index) => SizedBox(height: 8),
      itemBuilder: (context, index) {
        final t = filteredTransactions[index];
        final isIncome = t['type'] == 'income';
        final icon = isIncome ? Icons.arrow_downward : Icons.arrow_upward;
        final color = isIncome ? Colors.green : Colors.red;
        final typeText = isIncome ? 'Gelir' : 'Gider';
        final category = t['category'] ?? "";

        String remainingLimitText = "";
        if (!isIncome && categoryBudgetLimits.containsKey(category)) {
          double totalCategoryExpense = transactions
              .where((tr) => tr['type'] == 'expense' && tr['category'] == category)
              .fold(0.0, (sum, item) => sum + item['amount']);
          double remainingLimit = categoryBudgetLimits[category]! - totalCategoryExpense;
          remainingLimitText = " • Kalan: ${currencyFormat.format(remainingLimit)}";
        }

        return Dismissible(
          key: Key(t['date'].toString() + index.toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 20),
            color: Colors.red,
            child: Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text("Silme Onayı"),
                  content: Text("Bu işlemi silmek istediğinizden emin misiniz?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text("İptal"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text("Sil", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                );
              },
            );
          },
          onDismissed: (direction) {
            int globalIndex = transactions.indexOf(t);
            deleteTransaction(globalIndex);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("İşlem silindi"),
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: Card(
            elevation: 1,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              title: Text(
                t['note'] ?? '',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '$typeText${category.isNotEmpty ? ' • $category' : ''}$remainingLimitText',
                style: TextStyle(fontSize: 12),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(t['amount']),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    DateFormat('HH:mm').format(DateTime.parse(t['date'].toString())),
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              onLongPress: () {
                int globalIndex = transactions.indexOf(t);
                _confirmDelete(context, globalIndex);
              },
            ),
          ),
        );
      },
    );
  }

  void _showTransactionDialog({required bool isIncome}) {
    final _amountController = TextEditingController();
    final _noteController = TextEditingController();
    String? selectedCategory;
    final categories = ['Gıda', 'Ulaşım', 'Eğlence', 'Sağlık', 'Diğer'];
    DateTime selectedDate = selectedDay;
    final Color primaryColor = Theme.of(context).primaryColor;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isIncome ? 'Yeni Gelir Ekle' : 'Yeni Gider Ekle',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Tutar',
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(left: 15, right: 10),
                      child: Text(
                        '₺',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: 'Açıklama',
                    prefixIcon: Icon(Icons.note),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                if (!isIncome) ...[
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: categories
                        .map((cat) => DropdownMenuItem(
                      value: cat,
                      child: Text(cat),
                    ))
                        .toList(),
                    onChanged: (value) => selectedCategory = value,
                  ),
                ],
                SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: primaryColor,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      selectedDate = picked;
                      setState(() {});
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 20),
                        SizedBox(width: 10),
                        Text(DateFormat('dd.MM.yyyy').format(selectedDate)),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('İptal'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final amount = double.tryParse(_amountController.text);
                          if (amount == null || amount <= 0) return;

                          if (isIncome) {
                            addIncome(amount, _noteController.text, selectedDate);
                          } else {
                            if (selectedCategory == null) return;
                            addExpense(
                              amount,
                              _noteController.text,
                              selectedCategory!,
                              selectedDate,
                            );
                          }
                          Navigator.pop(context);
                        },
                        child: Text('Kaydet'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isIncome ? Colors.green : Colors.red,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}