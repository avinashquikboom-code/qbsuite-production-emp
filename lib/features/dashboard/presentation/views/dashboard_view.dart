export '../../../workspace/presentation/views/production_shell.dart'
    show ProductionShell;

import 'package:material_ui/material_ui.dart';

import '../../../workspace/presentation/views/production_shell.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) => const ProductionShell();
}
