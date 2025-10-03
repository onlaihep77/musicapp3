import 'package:flutter/material.dart';
import 'theme_controller.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeController.instance.mode,
        builder: (context, mode, _) {
          final isDark = mode == ThemeMode.dark;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Toggle nhanh Dark/Light
              SwitchListTile(
                title: const Text('Dark mode'),
                subtitle: const Text('Bật/tắt nhanh'),
                secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                value: isDark,
                onChanged: ThemeController.instance.toggle,
              ),
              const SizedBox(height: 16),

              // Chọn chính xác: System / Light / Dark bằng SegmentedButton
              Text('Theme mode', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('System'),
                    icon: Icon(Icons.phone_android),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (s) =>
                    ThemeController.instance.set(s.first),
                // (Tuỳ chọn) cho phép bấm lại không đổi giá trị
                // multiSelectionEnabled: false,
                // emptySelectionAllowed: false,
              ),
            ],
          );
        },
      ),
    );
  }
}
