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

final payslipsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(productionApiProvider).payslips();
});

final attendanceHistoryProvider =
    FutureProvider.family<List<Map<String, dynamic>>, ({int month, int year})>((
      ref,
      query,
    ) {
      return ref.watch(productionApiProvider).attendanceHistory(
        month: query.month,
        year: query.year,
      );
    });
