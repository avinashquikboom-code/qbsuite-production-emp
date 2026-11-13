import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/dio_client.dart';

final productionApiProvider = Provider<ProductionApi>((ref) => ProductionApi(ref.watch(dioProvider)));

final myOvertimeProvider = FutureProvider<List<Map<String, dynamic>>>((ref) => ref.watch(productionApiProvider).myOvertime());

class ProductionApi {
  ProductionApi(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> profile() => _object('/employees/profile/me');

  Future<Map<String, dynamic>> attendanceToday() => _object('/attendance/me');

  Future<List<Map<String, dynamic>>> attendanceHistory({
    int? month,
    int? year,
  }) {
    final now = DateTime.now();
    final selectedMonth = month ?? now.month;
    final selectedYear = year ?? now.year;
    final start = DateTime(selectedYear, selectedMonth, 1);
    final end = DateTime(selectedYear, selectedMonth + 1, 0);
    String day(DateTime value) => value.toIso8601String().split('T').first;
    return _list(
      '/attendance/history',
      query: {'dateFrom': day(start), 'dateTo': day(end), 'limit': 50},
    ).then((rows) => rows.map(_historyRow).toList());
  }

  Future<void> punchIn() => _punch('/attendance/check-in');

  Future<void> punchOut() => _punch('/attendance/check-out');

  Future<void> startBreak() => _send('/attendance/break/start');

  Future<void> endBreak() => _send('/attendance/break/end');

  Future<double?> distanceToOffice(Map office) async {
    final lat = double.tryParse('${office['latitude']}');
    final lng = double.tryParse('${office['longitude']}');
    if (lat == null || lng == null) return null;
    final position = await _position();
    return Geolocator.distanceBetween(position.latitude, position.longitude, lat, lng);
  }

  Future<List<Map<String, dynamic>>> myOvertime() => _list('/overtime', query: {'limit': 20});

  Future<Map<String, dynamic>> monthlyReports() => _object('/hrm/my-reports');

  Future<String> monthlyReportUrl(int id) async {
    final body = await _object('/hrm/my-reports/$id/download');
    return body['url']?.toString() ?? '';
  }

  Future<Map<String, dynamic>> applyOvertime(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<Object>('/overtime/my', data: body);
      return _asMap(response.data);
    } on DioException catch (error) {
      final data = error.response?.data;
      final message = data is Map ? data['message'] : null;
      final text = message is List ? message.join('\n') : message?.toString();
      throw AppFailure(text != null && text.isNotEmpty ? text : AppFailure.fromDio(error).message);
    }
  }

  Future<void> markOvertime(int id, {required bool end}) => _send('/overtime/$id/${end ? 'end' : 'start'}');

  Future<void> cancelOvertime(int id, {required String reason, String? remarks}) async {
    try {
      await _dio.post<Object>('/overtime/$id/cancel', data: {
        'reason': reason,
        if (remarks != null && remarks.trim().isNotEmpty) 'remarks': remarks.trim(),
      });
    } on DioException catch (error) {
      final data = error.response?.data;
      final message = data is Map ? data['message'] : null;
      final text = message is List ? message.join('\n') : message?.toString();
      throw AppFailure(text != null && text.isNotEmpty ? text : AppFailure.fromDio(error).message);
    }
  }

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

  Future<void> downloadPayslip(Object id) async {
    try {
      await _dio.get<Object>(
        '/admin/payroll/slips/$id/pdf',
        options: Options(responseType: ResponseType.bytes),
      );
    } on DioException catch (error) {
      final data = error.response?.data;
      final message = data is Map ? data['message'] : null;
      final text = message is List ? message.join('\n') : message?.toString();
      throw AppFailure(text != null && text.isNotEmpty ? text : 'Unable to download the salary slip PDF.');
    }
  }

  Future<List<Map<String, dynamic>>> leaveBalances() => _list('/leaves/balances');

  Future<List<Map<String, dynamic>>> leaveTypes() => _list('/leaves/types');

  Future<List<Map<String, dynamic>>> leaveRequests() =>
      _list('/leaves/requests', query: {'limit': 50});

  Future<void> applyLeave(Map<String, dynamic> body) => _send('/leaves/requests', body: body);

  Future<List<Map<String, dynamic>>> remoteRequests() => _list('/remote-requests');

  Future<void> applyRemote(Map<String, dynamic> body) => _send('/remote-requests', body: body);

  Future<List<Map<String, dynamic>>> claims() => _list('/claims', query: {'limit': 50});

  Future<void> applyClaim(Map<String, dynamic> body) => _send('/claims', body: body);

  Future<void> updateProfile(Map<String, dynamic> body) =>
      _send('/auth/profile', body: body, method: 'PUT');

  Future<void> changePassword(Map<String, dynamic> body) =>
      _send('/auth/profile/password', body: body);

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

  Future<void> _punch(String path) async {
    final position = await _position();
    try {
      await _dio.post<Object>(path, data: {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
      });
    } on DioException catch (error) {
      throw error.error is AppFailure ? error.error! : AppFailure.fromDio(error);
    }
  }

  Future<Position> _position() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) throw const AppFailure('Turn on location to record attendance.');
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw const AppFailure('Location permission is required to record attendance.');
    }
    return Geolocator.getCurrentPosition();
  }

  Future<void> _send(String path, {Map<String, dynamic>? body, String method = 'POST'}) async {
    try {
      await _dio.request<Object>(
        path,
        data: body ?? const <String, dynamic>{},
        options: Options(method: method),
      );
    } on DioException catch (error) {
      final data = error.response?.data;
      final message = data is Map ? data['message'] : null;
      final text = message is List ? message.join('\n') : message?.toString();
      throw AppFailure(text != null && text.isNotEmpty ? text : AppFailure.fromDio(error).message);
    }
  }

  Map<String, dynamic> _historyRow(Map<String, dynamic> row) {
    String clock(Object? value) {
      final parsed = DateTime.tryParse('$value')?.toLocal();
      if (parsed == null) return value == null ? '--' : '$value';
      final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
      final minute = parsed.minute.toString().padLeft(2, '0');
      return '$hour:$minute ${parsed.hour >= 12 ? 'PM' : 'AM'}';
    }
    final office = row['office'];
    final branch = office is Map
        ? '${office['name'] ?? ''} ${office['city'] ?? ''}'.trim()
        : '${row['branch'] ?? row['locationIn'] ?? ''}';
    final date = DateTime.tryParse('${row['date']}')?.toLocal();
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return {
      ...row,
      'checkIn': row['checkIn'] ?? clock(row['punchIn']),
      'checkOut': row['checkOut'] ?? clock(row['punchOut']),
      'workHours': row['workHours'] ?? row['workingDuration'] ?? row['workingHours'],
      'branch': branch,
      'day': row['day'] ?? (date == null ? '' : days[date.weekday - 1]),
      'breakDuration': row['breakDuration'] ?? row['totalBreakDuration'],
    };
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
