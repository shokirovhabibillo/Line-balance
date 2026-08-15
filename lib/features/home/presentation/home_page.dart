import 'package:flutter/material.dart';

import '../../time_study/presentation/time_study_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _modules = <_Module>[
    _Module('Time Study', 'Xronometraj va ish vaqtini o‘lchash', Icons.timer_outlined),
    _Module('Line Balance', 'Takt, cycle, workload va bottleneck', Icons.account_tree_outlined),
    _Module('VSM', 'Value Stream va jarayon xaritasi', Icons.route_outlined),
    _Module('Downtime', 'To‘xtalishlarni qayd etish va tahlil', Icons.pause_circle_outline),
    _Module('Learn', 'Instrumentlar bo‘yicha trening', Icons.school_outlined),
    _Module('Reports', 'KPI, Excel va PPTX hisobotlari', Icons.assessment_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Line Balance Platform'),
        actions: [
          IconButton(
            tooltip: 'Security',
            onPressed: () {},
            icon: const Icon(Icons.shield_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WORK • LEARN • ANALYZE • IMPROVE',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Industrial Engineering platform',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Jarayonlarni o‘lchash, tahlil qilish, yaxshilash va natijani boshqaruv hisobotiga aylantirish.',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _ModuleCard(module: _modules[index]),
                  childCount: _modules.length,
                ),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 420,
                  mainAxisExtent: 142,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module});

  final _Module module;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (module.title == 'Time Study') {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const TimeStudyPage(),
              ),
            );
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${module.title}: keyingi bosqichda ochiladi')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(module.icon, color: colors.onPrimaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(module.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _Module {
  const _Module(this.title, this.subtitle, this.icon);

  final String title;
  final String subtitle;
  final IconData icon;
}
