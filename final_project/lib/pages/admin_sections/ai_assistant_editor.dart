import 'package:flutter/material.dart';
import '../../utils/database_service.dart';

class AIAssistantEditor extends StatefulWidget {
  const AIAssistantEditor({Key? key}) : super(key: key);

  @override
  State<AIAssistantEditor> createState() => _AIAssistantEditorState();
}

class _AIAssistantEditorState extends State<AIAssistantEditor> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = true;
  Map<String, dynamic>? _aiSettings;

  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _promptsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAISettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _modelController.dispose();
    _promptsController.dispose();
    super.dispose();
  }

  Future<void> _loadAISettings() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final settings = await _databaseService.getAISettings();

      if (settings != null) {
        _apiKeyController.text = settings['api_key'] ?? '';
        _modelController.text = settings['model'] ?? 'gpt-3.5-turbo';
        _promptsController.text = settings['training_prompts'] ?? '';
      }

      setState(() {
        _aiSettings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage('Failed to load AI settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final updates = {
        'api_key': _apiKeyController.text,
        'model': _modelController.text,
        'training_prompts': _promptsController.text,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (_aiSettings != null && _aiSettings!.containsKey('id')) {
        updates['id'] = _aiSettings!['id'];
      }

      final success = await _databaseService.updateAISettings(updates);

      setState(() {
        _isLoading = false;
      });

      if (success) {
        _showMessage('Settings saved successfully', isError: false);
        _loadAISettings();
      } else {
        _showMessage('Failed to save settings');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage('Error saving settings: $e');
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF5B041), Color(0xFFE67E22)],
            ),
          ),
        ),
        title: const Text(
          'AI Assistant Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 2,
                color: Colors.black26,
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configure AI Assistant',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Set up your OpenAI integration to power the AI assistant',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    label: 'API Key',
                    controller: _apiKeyController,
                    isSecret: true,
                    hint: 'Enter your OpenAI API key',
                  ),
                  _buildTextField(
                    label: 'Model',
                    controller: _modelController,
                    hint: 'e.g., gpt-3.5-turbo',
                  ),
                  _buildTextField(
                    label: 'Training Prompts',
                    controller: _promptsController,
                    hint: 'Enter instructions for your AI assistant',
                    maxLines: 8,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Save Settings',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool isSecret = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: hint,
              contentPadding: const EdgeInsets.all(16),
            ),
            obscureText: isSecret,
            maxLines: maxLines,
          ),
        ],
      ),
    );
  }
}
