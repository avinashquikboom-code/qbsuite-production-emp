import 'package:flutter/widgets.dart';

import 'core/employee_push_notifications.dart';
import 'app/bootstrap.dart';
export 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EmployeePushNotifications.instance.initialize();
  await bootstrap();
}
