import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  // Список бесплатных моделей из OpenRouter / VseGPT
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
  String _selectedModel = 'poolside/laguna-xs.2:free';

  // Функция отправки запроса к ИИ
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });

    // Читаем ключ и провайдера из настроек
    final prefs = await SharedPreferences.getInstance();
    final provider = prefs.getString('api_provider') ?? 'OpenRouter';
    final apiKey = prefs.getString('api_key_$provider') ?? '';

    if (apiKey.isEmpty) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'Ошибка: API-ключ не найден! Пожалуйста, задайте его в Настройках.'
        });
        _isLoading = false;
      });
      return;
    }

    // Определяем URL в зависимости от выбранного провайдера
    final url = provider == 'VseGPT'
        ? 'https://api.vsegpt.ru/v1/chat/completions'
        : 'https://openrouter.ai/api/v1/chat/completions';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json; charset=UTF-8',
          if (provider == 'OpenRouter') 'HTTP-Referer': 'https://localhost',
          if (provider == 'OpenRouter') 'X-Title': 'AI Chat Flutter',
        },
        body: jsonEncode({
          'model': _selectedModel,
          'messages': _messages.map((m) => {'role': m['role'], 'content': m['content']}).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> choices = data['choices'] ?? [];
        
        if (choices.isNotEmpty) {
          final aiResponse = choices[0]['message']['content'].toString().trim();
          setState(() {
            _messages.add({'role': 'assistant', 'content': aiResponse});
          });

          // Сохраняем токены в память телефона для экранов Статистики и Расходов
          final usage = data['usage'];
          if (usage != null) {
            final int promptTokens = usage['prompt_tokens'] ?? 0;
            final int completionTokens = usage['completion_tokens'] ?? 0;
            final int totalTokens = promptTokens + completionTokens;

            // 1. Сохраняем общую сумму токенов для конкретной модели
            final int savedTokens = prefs.getInt('tokens_$_selectedModel') ?? 0;
            await prefs.setInt('tokens_$_selectedModel', savedTokens + totalTokens);

            // 2. Сохраняем расходы по дням (ГГГГ-ММ-ДД) для графика
            final String today = DateTime.now().toString().split(' ').first; 
            final int savedDayTokens = prefs.getInt('tokens_date_$today') ?? 0;
            await prefs.setInt('tokens_date_$today', savedDayTokens + totalTokens);
          }
        }
      } else {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': 'Ошибка сервера: Код ${response.statusCode}'
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': 'Ошибка сети: $e'});
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Чат с ИИ'),
        backgroundColor: Colors.blueAccent,
        actions: [
          // Выпадающий список выбора моделей прямо в шапке чата
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: DropdownButton<String>(
              value: _selectedModel,
              dropdownColor: Colors.blueAccent,
              style: const TextStyle(color: Colors.white),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              underline: Container(),
              items: _models.map((model) {
                return DropdownMenuItem<String>(
                  value: model,
                  child: Text(model.split('/').last.split(':').first),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedModel = value);
                }
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Список сообщений чата
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blueAccent : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg['content'] ?? '',
                      style: TextStyle(color: isUser ? Colors.white : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ),
          // Поле ввода и кнопка отправки
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Введите сообщение...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
