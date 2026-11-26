import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/production_api.dart';

final employeeProfileProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(productionApiProvider).profile();
});

final attendanceProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(productionApiProvider).attendanceToday();
});

final worksProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(productionApiProvider).works();
});

final calendarWorksProvider =
    FutureProvider.family<
      List<Map<String, dynamic>>,
      ({DateTime from, DateTime to})
    >((ref, range) {
      String day(DateTime value) =>
          '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
      return ref
          .watch(productionApiProvider)
          .works(dateFrom: day(range.from), dateTo: day(range.to));
    });

final payslipsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(productionApiProvider).payslips();
});

final attendanceHistoryProvider =
    FutureProvider.family<List<Map<String, dynamic>>, ({int month, int year})>((
      ref,
      query,
    ) {
      return ref
          .watch(productionApiProvider)
          .attendanceHistory(month: query.month, year: query.year);
    });
