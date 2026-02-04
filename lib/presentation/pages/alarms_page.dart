import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../../data/datasources/local_notifications.dart';

class AlarmsPage extends ConsumerStatefulWidget {
  const AlarmsPage({super.key});

  @override
  ConsumerState<AlarmsPage> createState() => _AlarmsPageState();
}

class _AlarmsPageState extends ConsumerState<AlarmsPage> {
  final _notificationService = NotificationService();
  TimeOfDay _breakfastTime = const TimeOfDay(hour: 8, minute: 0);
  bool _breakfastEnabled = true;

  @override
  void initState() {
    super.initState();
    _notificationService.init();
  }

  Future<void> _updateAlarm() async {
    if (_breakfastEnabled) {
      await _notificationService.scheduleDailyNotification(
        id: 1,
        title: '¡Hora de desayunar!',
        body: 'Un buen desayuno es la clave para un día saludable.',
        hour: _breakfastTime.hour,
        minute: _breakfastTime.minute,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alarma programada correctamente')),
      );
    } else {
      await _notificationService.cancelNotification(1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alarma cancelada')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recordatorios')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Desayuno', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Switch(
                        value: _breakfastEnabled,
                        onChanged: (val) {
                          setState(() => _breakfastEnabled = val);
                          _updateAlarm();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final time = await showTimePicker(context: context, initialTime: _breakfastTime);
                      if (time != null) {
                        setState(() => _breakfastTime = time);
                        _updateAlarm();
                      }
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          _breakfastTime.format(context),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nota: Las notificaciones te ayudarán a mantener tus hábitos saludables día a día.',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
