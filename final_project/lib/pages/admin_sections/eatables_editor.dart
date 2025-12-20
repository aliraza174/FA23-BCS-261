import 'package:flutter/material.dart';
import '../../utils/database_service.dart';

class EatablesEditor extends StatefulWidget {
  const EatablesEditor({Key? key}) : super(key: key);

  @override
  State<EatablesEditor> createState() => _EatablesEditorState();
}

class _EatablesEditorState extends State<EatablesEditor> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _eatables = [];

  @override
  void initState() {
    super.initState();
    _loadEatables();
  }

  Future<void> _loadEatables() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final eatables = await _databaseService.getEatables();

      setState(() {
        _eatables = eatables;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage('Failed to load eatables: $e');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
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
          'Eatables Editor',
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
          : _eatables.isEmpty
              ? const Center(
                  child: Text('No eatables found'),
                )
              : ListView.builder(
                  itemCount: _eatables.length,
                  itemBuilder: (context, index) {
                    final eatable = _eatables[index];
                    return ListTile(
                      title: Text(eatable['name'] ?? 'Unnamed'),
                      subtitle:
                          Text(eatable['description'] ?? 'No description'),
                    );
                  },
                ),
    );
  }
}
