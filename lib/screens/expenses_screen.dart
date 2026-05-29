import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List<FlSpot> _chartData = [];
  List<String> _dates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpensesData();
  }

  // Загружаем статистику токенов по дням за последнюю неделю
  Future<void> _loadExpensesData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final List<FlSpot> spots = [];
    final List<String> loadedDates = [];

    // Генерируем список последних 7 дней
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr = date.toString().split(' ').first; // ГГГГ-ММ-ДД
      
      // Считываем токены за этот день, сохраненные из chat_screen.dart
      final int dayTokens = prefs.getInt('tokens_date_$dateStr') ?? 0;
      
      // Переводим токены в условные расходы (например, 1000 токенов = 1 единица для графика)
      final double expense = dayTokens / 1000.0; 

      spots.add(FlSpot((6 - i).toDouble(), expense));
      // Форматируем дату для подписи на графике (ДД.ММ)
      loadedDates.add('${date.day}.${date.month}');
    }

    setState(() {
      _chartData = spots;
      _dates = loadedDates;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('График расходов'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExpensesData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Условные расходы (в тыс. токенов) за неделю:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 && index < _dates.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(_dates[index], style: const TextStyle(fontSize: 10)),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _chartData.isEmpty ? [const FlSpot(0, 0)] : _chartData,
                            isCurved: true,
                            color: Colors.blueAccent,
                            barWidth: 4,
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.blueAccent.withOpacity(0.2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
