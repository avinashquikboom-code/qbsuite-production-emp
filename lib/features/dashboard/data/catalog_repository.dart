import '../domain/feature_entry.dart';

/// Local navigation metadata, not mock business records.
class CatalogRepository implements DashboardRepository {
  @override
  Future<List<FeatureEntry>> features() async => const [
    FeatureEntry('production-orders', 'Production Orders'),
    FeatureEntry('work-orders', 'Work Orders'),
    FeatureEntry('production-planning', 'Production Planning'),
    FeatureEntry('task-management', 'Task Management'),
    FeatureEntry('production-status', 'Production Status'),
    FeatureEntry('quality-control', 'Quality Control'),
    FeatureEntry('inventory-updates', 'Inventory Updates'),
    FeatureEntry('production-reports', 'Production Reports'),
  ];
}
