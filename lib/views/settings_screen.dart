import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/app_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _notificationsKey = 'notificationsEnabled';

  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
    });
  }

  Future<void> _saveNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, value);

    setState(() {
      _notificationsEnabled = value;
    });
  }

  Future<void> _selectTheme() async {
    final selected = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose Theme'),
        children: [
          RadioGroup<ThemeMode>(
            groupValue: AppSettings.instance.themeMode,
            onChanged: (value) {
              if (value != null) Navigator.pop(context, value);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _themeOption(
                  context,
                  ThemeMode.light,
                  'Light',
                  Icons.light_mode,
                ),
                _themeOption(
                  context,
                  ThemeMode.dark,
                  'Dark',
                  Icons.dark_mode,
                ),
                _themeOption(
                  context,
                  ThemeMode.system,
                  'System Default',
                  Icons.brightness_auto_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (selected != null) {
      await AppSettings.instance.setThemeMode(selected);
    }
  }

  Widget _themeOption(
    BuildContext context,
    ThemeMode mode,
    String label,
    IconData icon,
  ) {
    final isSelected = AppSettings.instance.themeMode == mode;

    return RadioListTile<ThemeMode>(
      value: mode,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
      secondary: isSelected
          ? const Icon(Icons.check_circle, color: Colors.green)
          : null,
    );
  }

  Future<void> _selectLanguage() async {
    await showDialog<void>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Language'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context),
            child: const Row(
              children: [
                Text('🇬🇧  English  (current)'),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context),
            child: const Row(
              children: [
                Text('🇪🇸  Español  (coming soon)'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'HomeStyle',
      applicationVersion: 'v1.1.0',
      applicationIcon: const Icon(
        Icons.home_work_rounded,
        size: 42,
        color: Color(0xFF5D4037),
      ),
      children: [
        const Text(
          'Design your dream home with AI.\n'
          'Shop furniture, save favorites and track orders.',
        ),
      ],
    );
  }

  String get _themeLabel {
    switch (AppSettings.instance.themeMode) {
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System Default';
      case ThemeMode.light:
        return 'Light';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              secondary:
                  const Icon(Icons.notifications_active_outlined),
              title: const Text('Push Notifications'),
              subtitle: const Text('Get notified about orders and offers'),
              value: _notificationsEnabled,
              onChanged: _saveNotifications,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListenableBuilder(
              listenable: AppSettings.instance,
              builder: (context, _) {
                return Column(
                  children: [
                    ListTile(
                      onTap: _selectLanguage,
                      leading: const Icon(Icons.language_outlined),
                      title: const Text('Language'),
                      subtitle: const Text('English'),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      onTap: _selectTheme,
                      leading: const Icon(Icons.color_lens_outlined),
                      title: const Text('Theme'),
                      subtitle: Text('HomeStyle · $_themeLabel'),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              onTap: _showAbout,
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              subtitle: const Text('HomeStyle v1.1.0'),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        ],
      ),
    );
  }
}