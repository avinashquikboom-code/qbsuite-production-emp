export '../../../workspace/presentation/views/production_shell.dart'
    show ProductionShell;

import 'package:flutter/material.dart';

import '../../../workspace/presentation/views/production_shell.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) => const ProductionShell();
}
