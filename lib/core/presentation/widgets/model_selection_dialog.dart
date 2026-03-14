import 'package:dragon_center_linux/models/fan_config.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dragon_center_linux/models/msi_config.dart';

class ModelSelectionDialog extends StatefulWidget {
  const ModelSelectionDialog({super.key});

  @override
  State<ModelSelectionDialog> createState() => _ModelSelectionDialogState();
}

class _ModelSelectionDialogState extends State<ModelSelectionDialog> {
  String? _selectedModel;
  List<String> get _availableModels => MSIConfig.availableModels..sort();

  @override
  void initState() {
    super.initState();
    _loadSavedModel();
  }

  Future<void> _loadSavedModel() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedModel = prefs.getString('selected_model');
    });
  }

  Future<void> _saveModelSelection() async {
    if (_selectedModel != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_model', _selectedModel!);
      MSIConfig.currentModel = _selectedModel!;
      await FanConfig
          .loadConfig(); // Reload fan config to apply new model addresses
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Your Laptop Model'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please select your MSI laptop model to ensure proper fan control and system monitoring.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey(_selectedModel ?? 'default'),
              initialValue:
                  _selectedModel, // Changed from value to initialValue per deprecation warning
              decoration: const InputDecoration(
                labelText: 'Laptop Model',
                border: OutlineInputBorder(),
              ),
              items: _availableModels.map((String model) {
                return DropdownMenuItem<String>(
                  value: model,
                  child: Text(model),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedModel = newValue;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedModel == null
              ? null
              : () async {
                  await _saveModelSelection();
                  if (mounted && context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
