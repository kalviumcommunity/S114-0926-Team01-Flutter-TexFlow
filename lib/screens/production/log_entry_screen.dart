import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/offline_log.dart';
import '../../models/production_log.dart';
import '../../models/production_stage.dart';
import '../../providers/production_provider.dart';
import '../../services/connectivity_service.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_scaffold.dart';

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

  void _resetForm() {
    _formKey.currentState?.reset();
    _quantityController.clear();
    _notesController.clear();
    setState(() {
      _selectedStage = null;
      _selectedShift = 'morning';
      _selectedUnit = 'meters';
    });
  }

  Future<void> _submitLog() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a production stage'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final connectivity = ref.read(connectivityServiceProvider);
      final isOnline = await connectivity.checkConnection();

      if (isOnline) {
        final productionApi = ref.read(productionApiProvider);
        final request = CreateLogRequest(
          stageId: _selectedStage!.id,
          quantity: int.parse(_quantityController.text),
          unit: _selectedUnit,
          shift: _selectedShift,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );

        await productionApi.createLog(request);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Production logged successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _resetForm();
        }
      } else {
        // Offline mode - queue for later sync.
        final cache = ref.read(cacheServiceProvider);
        final offlineLog = OfflineLog.fromCreateLogRequest(
          _selectedStage!.id,
          int.parse(_quantityController.text),
          _selectedUnit,
          _selectedShift,
          _notesController.text.isEmpty ? null : _notesController.text,
        );

        final queued = await cache.addToOfflineQueue(offlineLog);

        if (!mounted) return;

        if (!queued) {
          // Storage unavailable: keep the form intact and do not claim success,
          // otherwise the entry would be silently lost.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not save offline - local storage unavailable. '
                'Please retry once you are online.',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offline - Production queued for sync when online'),
            backgroundColor: Colors.orange,
          ),
        );
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log production: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stagesAsync = ref.watch(productionStagesProvider);

    return AppScaffold(
      title: 'Log Production',
      subtitle: 'Record stage and shift output',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Production Entry',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
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
                      isExpanded: true,
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
                        if (value == null) {
                          return 'Please select a stage';
                        }
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
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Shift *',
                      prefixIcon: Icon(Icons.access_time_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'morning',
                        child: Text('Morning (6AM-2PM)'),
                      ),
                      DropdownMenuItem(
                        value: 'afternoon',
                        child: Text('Afternoon (2PM-10PM)'),
                      ),
                      DropdownMenuItem(
                        value: 'night',
                        child: Text('Night (10PM-6AM)'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedShift = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedUnit,
                    isExpanded: true,
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
                      if (value != null) {
                        setState(() => _selectedUnit = value);
                      }
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
        ],
      ),
    );
  }
}
