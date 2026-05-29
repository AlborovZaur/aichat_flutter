import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final Map<String, int> _modelStats = {};
  bool _isLoading = true;

  // Список моделей для проверки статистики
  final List<String> _models = [
    'poolside/laguna-xs.2:free',
    'google/gemma-2-9b-it:free',
    'meta-llama/llama-3-8b-instruct:free',
    'qwen/qwen-2.5-7b-instruct:free',
    'nvidia/nemotron-4-340b-instruct:free',
    'baidu/cobuddy:free',
    'openai/gpt-4.1-nano',
    'anthropic/claude-3-haiku',
    'deepseek/deepseek-v4-pro',
  ];


  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  // Загружаем сохраненную информацию по токенам из памяти
  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    
    for (var model in _models) {
      final int tokens = prefs.getInt('tokens_$model') ?? 0;
      _modelStats[model] = tokens;
    }

    setState(() => _isLoading = false);
  }

  // Кнопка сброса статистики, если пользователь захочет очистить данные
  Future<void> _resetStats() async {
    final prefs = await SharedPreferences.getInstance();
    for (var model in _models) {
      await prefs.remove('tokens_$model');
    }
    _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика токенов'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadStats, // Кнопка обновить данные
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.white),
            onPressed: _resetStats, // Кнопка очистить данные
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: _modelStats.values.every((v) => v == 0)
                  ? const Center(
                      child: Text(
                        'История трат пуста.\nОтправьте сообщения в чате!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _models.length,
                      itemBuilder: (context, index) {
                        final modelName = _models[index];
                        final tokensCount = _modelStats[modelName] ?? 0;
                        
                        // Красивое короткое имя для отображения на экране
                        final cleanName = modelName.split('/').last.split(':').first;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 3,
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.blueAccent,
                              child: Icon(Icons.analytics, color: Colors.white),
                            ),
                            title: Text(
                              cleanName.toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('Полный ID: $modelName'),
                            trailing: Text(
                              '$tokensCount токенов',
                              style: const TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
