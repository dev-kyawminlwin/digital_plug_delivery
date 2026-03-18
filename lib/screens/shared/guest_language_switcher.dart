import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';

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
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'en', child: Text('🇺🇸 English', style: TextStyle(fontWeight: FontWeight.w600))),
            const PopupMenuItem(value: 'th', child: Text('🇹🇭 ภาษาไทย', style: TextStyle(fontWeight: FontWeight.w600))),
            const PopupMenuItem(value: 'zh', child: Text('🇨🇳 中文', style: TextStyle(fontWeight: FontWeight.w600))),
          ],
        );
      },
    );
  }
}
