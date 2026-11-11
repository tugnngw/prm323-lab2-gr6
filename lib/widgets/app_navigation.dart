import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelected,
    this.dueSoonCount = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  /// Pending tasks due within three days, shown on the "Việc cần làm" tab.
  final int dueSoonCount;

  @override
  Widget build(BuildContext context) => NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onSelected,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          const NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Lộ trình',
          ),
          NavigationDestination(
            icon: Badge.count(
              count: dueSoonCount,
              isLabelVisible: dueSoonCount > 0,
              child: const Icon(Icons.task_alt_outlined),
            ),
            selectedIcon: Badge.count(
              count: dueSoonCount,
              isLabelVisible: dueSoonCount > 0,
              child: const Icon(Icons.task_alt),
            ),
            label: 'Việc cần làm',
          ),
          const NavigationDestination(
            icon: Icon(Icons.notes_outlined),
            selectedIcon: Icon(Icons.notes),
            label: 'Ghi chú',
          ),
        ],
      );
}
