import 'package:flutter/material.dart';

class EmployeeDropdown extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> activeEmployeesFuture;

  final String? selectedEmployeeId;

  final ValueChanged<String?> onChanged;

  final VoidCallback onRefresh;

  const EmployeeDropdown({
    super.key,
    required this.activeEmployeesFuture,
    required this.selectedEmployeeId,
    required this.onChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: activeEmployeesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load active employees.\n${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        }

        final rows = snapshot.data ?? const <Map<String, dynamic>>[];

        if (rows.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Active Employee',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const InputDecorator(
                decoration: InputDecoration(
                  labelText: 'No one is clocked in',
                  border: OutlineInputBorder(),
                ),
                child: Text('Ask staff to clock in first.'),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Check again'),
              ),
            ],
          );
        }

        return Center(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 700,
            ), // Limits the whole form width
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: selectedEmployeeId,

                  decoration: const InputDecoration(
                    labelText: 'Active Employee',
                    border: OutlineInputBorder(),
                  ),

                  items: rows
                      .map(
                        (m) => DropdownMenuItem<String>(
                          value: m['id'],
                          child: Text(m['name']),
                        ),
                      )
                      .toList(),
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
