import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/production_log.dart';
import '../../models/production_stage.dart';
import '../../providers/production_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';

class LogEntryScreen extends ConsumerStatefulWidget {
  const LogEntryScreen({super.key});

  @override
  ConsumerState<LogEntryScreen> createState() => _LogEntryScreenState();
}

class _LogEntryScreenState extends ConsumerState<LogEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  ProductionStage? _selectedStage;
  String _selectedShift = 'morning';
  String _selectedUnit = 'meters';
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitLog() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a production stage'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final productionService = ref.read(productionServiceProvider);
      final log = ProductionLog(
        id: '',
        stageId: _selectedStage!.id,
        userId: '',
        quantity: int.parse(_quantityController.text),
        unit: _selectedUnit,
        shift: _selectedShift,
        logTime: DateTime.now(),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        stageName: _selectedStage!.name,
      );

      await productionService.createLog(log);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Production logged successfully'), backgroundColor: Colors.green),
        );
        _formKey.currentState!.reset();
        _quantityController.clear();
        _notesController.clear();
        setState(() {
          _selectedStage = null;
          _selectedShift = 'morning';
          _selectedUnit = 'meters';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log production: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stagesAsync = ref.watch(productionStagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Production'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Production Entry',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Record production output for a specific stage and shift',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              AppCard(
                title: 'Production Details',
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      stagesAsync.when(
                        data: (stages) => DropdownButtonFormField<ProductionStage>(
                          initialValue: _selectedStage,
                          decoration: const InputDecoration(
                            labelText: 'Production Stage *',
                            prefixIcon: Icon(Icons.factory_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: stages.map((stage) {
                            return DropdownMenuItem(
                              value: stage,
                              child: Text(stage.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedStage = value);
                          },
                          validator: (value) {
                            if (value == null) return 'Please select a stage';
                            return null;
                          },
                        ),
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (err, _) => Text(
                          'Failed to load stages: $err',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedShift,
                        decoration: const InputDecoration(
                          labelText: 'Shift *',
                          prefixIcon: Icon(Icons.access_time_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'morning', child: Text('Morning (6AM-2PM)')),
                          DropdownMenuItem(value: 'afternoon', child: Text('Afternoon (2PM-10PM)')),
                          DropdownMenuItem(value: 'night', child: Text('Night (10PM-6AM)')),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _selectedShift = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedUnit,
                        decoration: const InputDecoration(
                          labelText: 'Unit *',
                          prefixIcon: Icon(Icons.straighten_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'meters', child: Text('Meters')),
                          DropdownMenuItem(value: 'kg', child: Text('Kilograms')),
                          DropdownMenuItem(value: 'pieces', child: Text('Pieces')),
                          DropdownMenuItem(value: 'rolls', child: Text('Rolls')),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _selectedUnit = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity *',
                          prefixIcon: Icon(Icons.numbers_outlined),
                          border: OutlineInputBorder(),
                          hintText: 'Enter quantity produced',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter quantity';
                          }
                          final qty = int.tryParse(value);
                          if (qty == null || qty <= 0) {
                            return 'Please enter a valid positive number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                          prefixIcon: Icon(Icons.note_outlined),
                          border: OutlineInputBorder(),
                          hintText: 'Any additional notes...',
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Log Production',
                  onPressed: _submitLog,
                  isLoading: _isLoading,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Back to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}