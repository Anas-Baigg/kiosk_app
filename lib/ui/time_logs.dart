import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kiosk_app/components/time_log_entry.dart';
import 'package:kiosk_app/services/database_service.dart';

class TimeLogs extends StatelessWidget {
  final DatabaseService database;
  final Future<List<TimeLogEntry>> timeLogs;
  const TimeLogs({super.key, required this.timeLogs, required this.database});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TimeLogEntry>>(
      future: timeLogs,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error loading timeLogs: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No timeLogs found for the selected date range.',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          );
        }

        final logs = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Employee Logs',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            Flexible(
              fit: FlexFit.loose,
              child: ListView(
                children: logs.map((log) {
                  final inTime = DateFormat(
                    'yyyy-MM-dd HH:mm',
                  ).format(log.clockIn);
                  final outTime = log.clockOut != null
                      ? DateFormat('yyyy-MM-dd HH:mm').format(log.clockOut!)
                      : 'Still working';

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 8.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(log.employeeName.toUpperCase()),
                      subtitle: Text('IN: $inTime\nOUT: $outTime'),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
