/// Display DTO for clock-in/out history. Constructed from a JOIN query
/// that includes the employee name. Not written to SQLite directly.
class TimeLogDisplay {
  final String id;
  final String employeeId;
  final String employeeName;
  final DateTime clockIn;
  final DateTime? clockOut;

  TimeLogDisplay({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.clockIn,
    required this.clockOut,
  });

  factory TimeLogDisplay.fromMap(Map<String, dynamic> map) {
    return TimeLogDisplay(
      id: map['log_id'] as String,
      employeeId: map['employee_id'] as String,
      employeeName: map['employee_name'] as String,
      clockIn: DateTime.parse(map['clock_in'] as String).toLocal(),
      clockOut: map['clock_out'] != null
          ? DateTime.parse(map['clock_out'] as String).toLocal()
          : null,
    );
  }
}
