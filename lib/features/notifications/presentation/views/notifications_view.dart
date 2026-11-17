import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remixicon/remixicon.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_widgets.dart';

class NotificationsView extends ConsumerStatefulWidget {
  const NotificationsView({super.key});
  @override
  ConsumerState<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends ConsumerState<NotificationsView> {
  bool loading = true;
  bool busy = false;
  String? error;
  List<Map<String, dynamic>> rows = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final response = await ref
          .read(dioProvider)
          .get<Object?>(
            '/notifications',
            queryParameters: {'page': 1, 'limit': 50},
          );
      final body = response.data;
      final payload = body is Map && body['data'] is Map
          ? body['data'] as Map
          : body;
      final items = payload is Map && payload['data'] is List
          ? payload['data'] as List
          : payload is Map && payload['items'] is List
          ? payload['items'] as List
          : payload is List
          ? payload
          : const [];
      if (!mounted) return;
      setState(
        () => rows = items
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(),
      );
    } on DioException catch (e) {
      if (mounted) {
        setState(
          () => error =
              (e.error is AppFailure
                      ? e.error! as AppFailure
                      : AppFailure.fromDio(e))
                  .message,
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  bool unread(Map<String, dynamic> row) => row['isRead'] == false;

  Future<void> markAll() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await ref.read(dioProvider).patch<Object?>('/notifications/read-all');
      if (mounted) {
        setState(
          () => rows = rows.map((row) => {...row, 'isRead': true}).toList(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update notifications: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> open(Map<String, dynamic> row) async {
    final id = row['id']?.toString();
    if (id != null && unread(row)) {
      try {
        await ref.read(dioProvider).patch<Object?>('/notifications/$id/read');
        if (mounted) {
          setState(
            () => rows = rows
                .map(
                  (item) => item['id'].toString() == id
                      ? {...item, 'isRead': true}
                      : item,
                )
                .toList(),
          );
        }
      } catch (_) {}
    }
    final type = '${row['type'] ?? ''}'.toUpperCase();
    if (type.contains('ATTENDANCE') || type.contains('LATE')) {
      if (mounted) context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = rows.where(unread).length;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        title: 'Notifications',
        onBack: () => context.goNamed('dashboard'),
      ),
      body: loading
          ? const AppLoader()
          : error != null && rows.isEmpty
          ? AppErrorWidget(message: error!, onRetry: load)
          : RefreshIndicator(
              onRefresh: load,
              child: rows.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        AppEmptyState(
                          title: 'No notifications',
                          message:
                              'Attendance and work updates will appear here.',
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (unreadCount > 0)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: busy ? null : markAll,
                              icon: const Icon(Remix.check_double_line),
                              label: const Text('Mark all read'),
                            ),
                          ),
                        for (final row in rows) ...[
                          Card(
                            color: unread(row)
                                ? AppColors.lightPrimary
                                : AppColors.surface,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => open(row),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      unread(row)
                                          ? Remix.notification_3_fill
                                          : Remix.notification_3_line,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${row['title'] ?? 'QB Suite'}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${row['message'] ?? row['body'] ?? ''}',
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${row['createdAt'] ?? ''}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (unread(row))
                                      const Padding(
                                        padding: EdgeInsets.only(
                                          left: 8,
                                          top: 4,
                                        ),
                                        child: CircleAvatar(
                                          radius: 4,
                                          backgroundColor: AppColors.primary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
            ),
    );
  }
}
