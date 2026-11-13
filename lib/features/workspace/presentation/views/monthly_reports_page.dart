import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/production_api.dart';

class MonthlyReportsPage extends ConsumerStatefulWidget {
  const MonthlyReportsPage({super.key});

  @override
  ConsumerState<MonthlyReportsPage> createState() => _MonthlyReportsPageState();
}

class _MonthlyReportsPageState extends ConsumerState<MonthlyReportsPage> {
  bool loading = true;
  String error = '';
  List reports = [];
  Map commission = {};

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() { loading = true; error = ''; });
    try {
      final body = await ref.read(productionApiProvider).monthlyReports();
      final payload = body['reports'] is List ? body : (body['data'] is Map ? body['data'] as Map : body);
      setState(() {
        reports = payload['reports'] is List ? payload['reports'] as List : [];
        commission = payload['commission'] is Map ? Map<String, dynamic>.from(payload['commission'] as Map) : {};
        loading = false;
      });
    } catch (_) {
      setState(() { error = 'Unable to load monthly reports.'; loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Monthly Reports', style: AppTypography.inter(fontWeight: FontWeight.w700))),
      backgroundColor: AppColors.background,
      body: loading ? const Center(child: CircularProgressIndicator()) : error.isNotEmpty ? Center(child: Text(error)) : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Commission earned ${commission['netEarned'] ?? 0} · paid ${commission['paid'] ?? 0} · outstanding ${commission['outstanding'] ?? 0}', style: AppTypography.inter(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (reports.isEmpty) const Text('No monthly PDFs have been generated yet.'),
          ...reports.map((report) => Card(child: ListTile(
            title: Text(report['fileName']?.toString() ?? 'Report'),
            subtitle: Text('${report['reportType']} · ${report['status']}'),
            onTap: () async {
              final url = await ref.read(productionApiProvider).monthlyReportUrl(int.parse('${report['id']}'));
              if (!context.mounted || url.isEmpty) return;
              await Clipboard.setData(ClipboardData(text: url));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report link copied.')));
            },
          ))),
        ],
      ),
    );
  }
}
