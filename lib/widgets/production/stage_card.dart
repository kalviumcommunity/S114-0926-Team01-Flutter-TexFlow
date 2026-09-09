import 'package:flutter/material.dart';
import '../../models/production_log.dart';

class StageCard extends StatelessWidget {
  final ProductionLog log;

  const StageCard({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(log.stageName ?? 'Unknown Stage'),
        subtitle: Text('${log.quantity} ${log.unit} - ${log.shift}'),
        trailing: Text(
          '${log.logTime.hour}:${log.logTime.minute.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }
}
