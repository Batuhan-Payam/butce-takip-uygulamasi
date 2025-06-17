import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

class BorsaCanliSayfasi extends StatefulWidget {
  @override
  _BorsaCanliSayfasiState createState() => _BorsaCanliSayfasiState();
}

class _BorsaCanliSayfasiState extends State<BorsaCanliSayfasi> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _kurData;
  Map<String, double>? _oncekiKurData;
  double? _gramAltin, _ceyrekAltin, _btcUsd, _ethUsd;
  bool _loading = true;

  late TabController _tabController;
  final TextEditingController _amountController = TextEditingController();
  String _fromCurrency = 'TRY';
  String _toCurrency = 'USD';
  double? _convertedAmount;
  bool _isCalculatorOpen = false;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchKurData();
    _tabController = TabController(length: 2, vsync: this);

    _gramAltin = 4202.41;
    _ceyrekAltin = 6830.00;
    _btcUsd = 107266.50;
    _ethUsd = 2497.67;

    _timer = Timer.periodic(Duration(minutes: 1), (_) => _fetchKurData());
  }

  Future<void> _fetchKurData() async {
    setState(() => _loading = true);

    try {
      if (_kurData != null) {
        _oncekiKurData = Map<String, double>.from(
            _kurData!.map((key, value) => MapEntry(key, value as double)));
      }

      final response = await http.get(Uri.parse('https://api.frankfurter.app/latest?from=TRY&to=USD,EUR,GBP,JPY'));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        _kurData = {
          'TRY': 1.0,
          'USD': (jsonData['rates']['USD'] as num).toDouble(),
          'EUR': (jsonData['rates']['EUR'] as num).toDouble(),
          'GBP': (jsonData['rates']['GBP'] as num).toDouble(),
          'JPY': (jsonData['rates']['JPY'] as num).toDouble(),
        };
      } else {
        print('Kur verisi gelmedi, status: ${response.statusCode}');
      }

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      print('Hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veri yüklenirken hata oluştu: $e'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _convertCurrency() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || _kurData == null) return;

    final fromRate = _kurData![_fromCurrency];
    final toRate = _kurData![_toCurrency];

    setState(() {
      _convertedAmount = amount / fromRate! * toRate!;
    });
  }

  Widget _buildKurListesi() {
    if (_kurData == null) return Center(child: Text("Veri bulunamadı"));

    return ListView(
      padding: EdgeInsets.all(12),
      children: _kurData!.entries
          .where((e) => e.key != 'TRY')
          .map((e) {
        final currentRate = e.value as double;
        final previousRate = _oncekiKurData != null ? _oncekiKurData![e.key] : null;

        Color? changeColor;
        Icon? icon;
        String changeText = '';

        if (previousRate != null) {
          final diff = currentRate - previousRate;
          final percentChange = (diff / previousRate) * 100;

          if (diff > 0) {
            changeColor = Colors.green[700];
            icon = Icon(Icons.trending_up, color: changeColor, size: 24);
            changeText = '+${percentChange.toStringAsFixed(2)}%';
          } else if (diff < 0) {
            changeColor = Colors.red[700];
            icon = Icon(Icons.trending_down, color: changeColor, size: 24);
            changeText = '${percentChange.toStringAsFixed(2)}%';
          }
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Theme.of(context).cardColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      e.key,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1 ${e.key}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      Text(
                        '${(1 / currentRate).toStringAsFixed(4)} TRY',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (icon != null) icon,
                if (changeText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      changeText,
                      style: TextStyle(
                        color: changeColor ?? Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFinansalListesi() {
    return ListView(
      padding: EdgeInsets.all(12),
      children: [
        _buildKart(
          'Gram Altın',
          _gramAltin,
          'TL',
          Icons.monetization_on,
          Colors.amber[700]!,
          Theme.of(context).brightness == Brightness.dark
              ? Colors.amber[900]!
              : Colors.amber[100]!,
        ),
        _buildKart(
          'Çeyrek Altın',
          _ceyrekAltin,
          'TL',
          Icons.monetization_on,
          Colors.orange[700]!,
          Theme.of(context).brightness == Brightness.dark
              ? Colors.orange[900]!
              : Colors.orange[100]!,
        ),
        _buildKart(
          'Bitcoin (BTC)',
          _btcUsd,
          'USD',
          Icons.currency_bitcoin,
          Colors.orange[700]!,
          Theme.of(context).brightness == Brightness.dark
              ? Colors.orange[900]!
              : Colors.orange[100]!,
        ),
        _buildKart(
          'Ethereum (ETH)',
          _ethUsd,
          'USD',
          Icons.token,
          Colors.blue[700]!,
          Theme.of(context).brightness == Brightness.dark
              ? Colors.blue[900]!
              : Colors.blue[100]!,
        ),
      ],
    );
  }

  Widget _buildKart(
      String baslik,
      double? deger,
      String birim,
      IconData ikon,
      Color iconColor,
      Color bgColor,
      ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(ikon, color: iconColor, size: 24),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    baslik,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  Text(
                    'Son Fiyat',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              deger != null ? '${deger.toStringAsFixed(2)} $birim' : '-',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatorPanel() {
    if (!_isCalculatorOpen || _kurData == null) return SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, -3),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _fromCurrency,
                  decoration: InputDecoration(labelText: 'Çevrilen Birim-'),
                  items: _kurData!.keys
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _fromCurrency = val!;
                      _convertCurrency();
                    });
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _toCurrency,
                  decoration: InputDecoration(labelText: 'Çevrilecek Birim'),
                  items: _kurData!.keys
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _toCurrency = val!;
                      _convertCurrency();
                    });
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Hesapla',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _convertCurrency(),
          ),
          SizedBox(height: 12),
          if (_convertedAmount != null)
            Text(
              '${_convertedAmount!.toStringAsFixed(4)} $_toCurrency',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Theme.of(context).primaryColor,
              ),
            ),
          SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isCalculatorOpen = false;
              });
            },
            child: Text('Hesap Makinesini Kapat'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Canlı Borsa ve Döviz'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Döviz Kurları'),
            Tab(text: 'Finansal Veriler'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _loading
                  ? Center(child: CircularProgressIndicator())
                  : _buildKurListesi(),
              _buildFinansalListesi(),
            ],
          ),
          if (!_isCalculatorOpen)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: () {
                  setState(() {
                    _isCalculatorOpen = true;
                    _convertedAmount = null;
                    _amountController.clear();
                  });
                },
                label: Text('Döviz Hesapla'),
                icon: Icon(Icons.calculate),
              ),
            ),
          if (_isCalculatorOpen)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildCalculatorPanel(),
            ),
        ],
      ),
    );
  }
}
