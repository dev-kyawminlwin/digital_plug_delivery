import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';

/// Light variant — used on auth screens (white card background)
class GuestLanguageSwitcher extends StatelessWidget {
  const GuestLanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return PopupMenuButton<String>(
          offset: const Offset(0, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
              ]
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language_rounded, size: 18, color: Color(0xFF1F2937)),
                const SizedBox(width: 8),
                Text(
                  localeProvider.locale.languageCode.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1F2937)),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.grey),
              ],
            ),
          ),
          onSelected: (code) {
            localeProvider.setLocale(Locale(code));
          },
          itemBuilder: (context) => _menuItems,
        );
      },
    );
  }
}

/// Dark/glass variant — used on role dashboards with dark/gradient headers
class DashboardLanguageSwitcher extends StatelessWidget {
  const DashboardLanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return PopupMenuButton<String>(
          offset: const Offset(0, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: const Icon(Icons.language_rounded, color: Colors.white, size: 20),
          ),
          onSelected: (code) {
            localeProvider.setLocale(Locale(code));
          },
          itemBuilder: (context) => _menuItems,
        );
      },
    );
  }
}

const _menuItems = [
  PopupMenuItem(value: 'en', child: Text('🇺🇸 English', style: TextStyle(fontWeight: FontWeight.w600))),
  PopupMenuItem(value: 'my', child: Text('🇲🇲 မြန်မာ', style: TextStyle(fontWeight: FontWeight.w600))),
  PopupMenuItem(value: 'th', child: Text('🇹🇭 ภาษาไทย', style: TextStyle(fontWeight: FontWeight.w600))),
  PopupMenuItem(value: 'zh', child: Text('🇨🇳 中文', style: TextStyle(fontWeight: FontWeight.w600))),
];
