import 'package:dio/dio.dart';

import '../../../core/errors/app_failure.dart';

class ProductionApi {
  ProductionApi(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> profile() => _object('/employees/profile/me');

  Future<Map<String, dynamic>> attendanceToday() => _object('/attendance/me');

  Future<List<Map<String, dynamic>>> attendanceHistory({
    int? month,
    int? year,
  }) {
    return _list(
      '/attendance/history',
      query: {
        if (month != null) 'month': month,
        if (year != null) 'year': year,
      },
    );
  }

  Future<void> punchIn() => _send('/attendance/check-in');

  Future<void> punchOut() => _send('/attendance/check-out');

  Future<List<Map<String, dynamic>>> works({String? date, String? month}) {
    return _list(
      '/works/employee/calendar',
      query: {
        if (date != null && date.isNotEmpty) 'date': date,
        if (month != null && month.isNotEmpty) 'month': month,
      },
    );
  }

  Future<Map<String, dynamic>> updateWork(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch<Object>('/works/$id', data: data);
    return _asMap(response.data);
  }

  Future<List<Map<String, dynamic>>> payslips() =>
      _list('/admin/payroll/slips');

  Future<Map<String, dynamic>> _object(String path) async {
    try {
      final response = await _dio.get<Object>(path);
      return _asMap(response.data);
    } on DioException catch (error) {
      throw error.error is AppFailure ? error.error! : AppFailure.fromDio(error);
    }
  }

  Future<List<Map<String, dynamic>>> _list(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _dio.get<Object>(path, queryParameters: query);
      return _asList(response.data);
    } on DioException catch (error) {
      throw error.error is AppFailure ? error.error! : AppFailure.fromDio(error);
    }
  }

  Future<void> _send(String path) async {
    try {
      await _dio.post<Object>(path, data: const <String, dynamic>{});
    } on DioException catch (error) {
      throw error.error is AppFailure ? error.error! : AppFailure.fromDio(error);
    }
  }

  Map<String, dynamic> _asMap(Object? raw) {
    if (raw is Map && raw['data'] is Map) {
      return Map<String, dynamic>.from(raw['data'] as Map);
    }
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  List<Map<String, dynamic>> _asList(Object? raw) {
    final payload = raw is Map ? (raw['data'] ?? raw['items'] ?? raw) : raw;
    final items = payload is Map
        ? (payload['items'] ?? payload['records'] ?? payload['data'])
        : payload;
    if (items is List) {
      return items
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return const [];
  }
}
