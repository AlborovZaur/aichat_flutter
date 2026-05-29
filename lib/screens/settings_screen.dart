import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  String _selectedProvider = 'OpenRouter';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Загрузка настроек при открытии экрана
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedProvider = prefs.getString('api_provider') ?? 'OpenRouter';
      // Подгружаем ключ именно для текущего выбранного провайдера
      _apiKeyController.text = prefs.getString('api_key_$_selectedProvider') ?? '';
    });
  }

  // Сохранение настроек в память телефона
  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('api_provider', _selectedProvider);
    // Записываем ключ в его личную ячейку памяти
    await prefs.setString('api_key_$_selectedProvider', _apiKeyController.text);
    
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Настройки успешно сохранены!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Функция, которая срабатывает при клике по выпадающему списку
  void _onProviderChanged(String? value) async {
    if (value == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedProvider = value;
      // При переключении списка поле ввода само обновляется нужным ключом!
      _apiKeyController.text = prefs.getString('api_key_$value') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки ИИ'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Выберите провайдера API:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedProvider,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'OpenRouter', child: Text('OpenRouter')),
                DropdownMenuItem(value: 'VseGPT', child: Text('VseGPT.ru')),
              ],
              onChanged: _onProviderChanged, // Подключили умное переключение
            ),
            const SizedBox(height: 20),
            const Text(
              'Введите API Ключ:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Введите ваш ключ API',
                prefixIcon: Icon(Icons.key),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveSettings,
                icon: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.save),
                label: const Text('Сохранить настройки', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }
}

