import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../core/localization/translations.dart';
import '../../widgets/glass_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const Map<String, String> _languages = {
    'en': 'English',
    'hi': 'हिन्दी (Hindi)',
    'te': 'తెలుగు (Telugu)',
    'ta': 'தமிழ் (Tamil)',
    'kn': 'ಕನ್ನಡ (Kannada)',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final activeLocale = ref.watch(localeProvider);
    final currentLanguageName = _languages[activeLocale.languageCode] ?? 'English';

    return Scaffold(
      appBar: AppBar(title: Text('Settings'.tr(ref))),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Language Card
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Language'.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(LucideIcons.globe),
                  title: Text('Select Language'.tr(ref)),
                  subtitle: Text(currentLanguageName),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showLanguageSelector(context, ref, activeLocale),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Appearance Card
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Appearance'.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text('Dark Theme'.tr(ref)),
                  subtitle: Text('Enable futuristic dark mode'.tr(ref)),
                  secondary: Icon(isDark ? LucideIcons.moon : LucideIcons.sun),
                  value: isDark,
                  onChanged: (val) {
                    ref.read(themeProvider.notifier).toggleTheme();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Connectivity Card
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Connectivity (Mock)'.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(LucideIcons.wifi),
                  title: Text('MQTT Broker URL'.tr(ref)),
                  subtitle: const Text('mqtt://broker.emqx.io:1883'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(LucideIcons.database),
                  title: Text('FastAPI Endpoint'.tr(ref)),
                  subtitle: const Text('https://api.agronet.ai/v1'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelector(BuildContext context, WidgetRef ref, Locale activeLocale) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Language'.tr(ref)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: _languages.entries.map((entry) {
                return ListTile(
                  title: Text(entry.value),
                  trailing: activeLocale.languageCode == entry.key
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    ref.read(localeProvider.notifier).setLocale(Locale(entry.key));
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
