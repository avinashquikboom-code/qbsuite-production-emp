import 'package:flutter_riverpod/flutter_riverpod.dart';

/// UI-only workspace data. Production screens do not call the network.
final uiPunchedInProvider = NotifierProvider<UiPunchedIn, bool>(UiPunchedIn.new);

class UiPunchedIn extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final employeeProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return const {
    'name': 'Sumit Parmar',
    'employeeCode': 'EMP-011',
    'designation': 'Senior Photographer',
    'department': 'Production',
    'branch': 'QUIKBOOM MARKETING AGENCY',
    'email': 'sumitparmar@quikboom.in',
    'status': 'ACTIVE',
    'supervisoryAccess': true,
  };
});

final attendanceProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final punchedIn = ref.watch(uiPunchedInProvider);
  return {
    'status': {
      'isPunchedIn': punchedIn,
      'punchInTime': punchedIn ? '09:00' : null,
      'punchOutTime': null,
      'workingHours': punchedIn ? '0h 1m' : null,
      'breakDuration': null,
    },
    'assignedOffice': {
      'name': 'QUIKBOOM MARKETING AGENCY',
      'city': 'GP',
    },
  };
});

final worksProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return const [];
});

final payslipsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return const [];
});

final attendanceHistoryProvider =
    FutureProvider.family<List<Map<String, dynamic>>, ({int month, int year})>((
      ref,
      query,
    ) async {
      if (query.month != 11 || query.year != 2026) return const [];
      return const [
        {
          'date': '2026-11-05',
          'day': 'Thursday',
          'status': 'HALF DAY',
          'checkIn': '10:03 AM',
          'checkOut': '01:00 PM',
          'workHours': '2h 56m',
          'branch': 'QUIKBOOM MARKETING AGENCY (173m)',
          'breakDuration': '0h 0m',
        },
        {
          'date': '2026-11-04',
          'day': 'Wednesday',
          'status': 'PRESENT',
          'checkIn': '10:14 AM',
          'checkOut': '07:01 PM',
          'workHours': '8h 46m',
          'branch': 'QUIKBOOM MARKETING AGENCY (55m)',
          'breakDuration': '0h 0m',
        },
        {
          'date': '2026-11-02',
          'day': 'Monday',
          'status': 'HALF DAY',
          'checkIn': '10:03 AM',
          'checkOut': '01:00 PM',
          'workHours': '2h 56m',
          'branch': 'QUIKBOOM MARKETING AGENCY',
          'breakDuration': '0h 0m',
        },
      ];
    });
