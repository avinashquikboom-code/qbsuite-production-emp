const productionAccessMessage =
    'This app is only for production team members. Please use the app for your team.';

/// Matches the production-team check used by the CRM employee home.
/// BPO, sales, and visitor accounts stay out even if a job title also
/// mentions production work.
bool isProductionTeamAccount(Map user) {
  final employee = user['employee'] is Map
      ? Map<String, dynamic>.from(user['employee'] as Map)
      : const <String, dynamic>{};
  final department = _label(employee['department'] ?? user['department']);
  final designation = _label(employee['designation'] ?? user['designation']);
  final jobTitle = _label(user['effectiveRole']);
  final category = _label(user['crmCategory'] ?? employee['crmCategory']);
  final permissions = _permissionText(
    user['permissions'] ?? user['permissionKeys'] ?? user['effectivePermissions'],
  );

  if (const {'BPO', 'VISITOR', 'SALES'}.contains(category)) return false;
  final identity = [department, designation, jobTitle].where((value) => value.isNotEmpty);
  if (identity.any(_isBpo) || identity.any(_isVisitor) || identity.any(_isSales)) {
    return false;
  }
  final signals = [department, designation, jobTitle, permissions].join(' ');
  return _productionMarkers.any(signals.contains);
}

String _label(Object? value) {
  if (value is Map) {
    return _label(value['name'] ?? value['code'] ?? value['type']);
  }
  final text = value?.toString().trim().toUpperCase() ?? '';
  if (text.isEmpty || text == 'NULL') return '';
  return text;
}

String _permissionText(Object? value) {
  if (value is List) {
    return value.map((item) {
      if (item is Map) return _label(item['module'] ?? item['key'] ?? item['name']);
      return _label(item);
    }).join(' ');
  }
  return _label(value);
}

bool _isBpo(String value) => value.contains('BPO');

bool _isVisitor(String value) {
  return value.contains('VISITOR') ||
      value == 'VISIT' ||
      value.contains('FIELD VISIT') ||
      value.contains('FIELD OFFICER');
}

bool _isSales(String value) {
  final text = value.replaceAll(RegExp(r'[\s-]+'), '_');
  final telesales =
      text.contains('TELESALES') ||
      text.contains('TELE_SALES') ||
      text.contains('TELECALL') ||
      text.contains('TELE_CALL') ||
      text.contains('TELESELL');
  return value.contains('SALES') && !telesales;
}

const _productionMarkers = [
  'PRODUCTION',
  'CREATIVE',
  'PHOTOGRAPHER',
  'PHOTO',
  'VIDEO',
  'EDITOR',
  'DESIGNER',
  'DESIGN',
  'SSM',
  'CONTENT',
  'ANIMAT',
  'CAMERA',
  'SHOOT',
  'REEL',
  'STUDIO',
  'GRAPHIC',
  'MEDIA',
  'TEAM LEADER',
  'TEAM LEAD',
  'MY_WORK',
  'CREATIVE_WORK',
];
