import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../utils/theme.dart';

/// Language picker.
///
/// Each option is labelled in its own script, so someone who reads only
/// Gurmukhi can still find Punjabi without reading any English.
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  Future<void> _select(
    BuildContext context,
    LocaleProvider provider,
    AppLanguage language,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await provider.setLanguage(language);

    if (!context.mounted) return;

    // Read strings AFTER the switch so the confirmation itself appears in the
    // language just chosen.
    final l10n = AppLocalizations.of(context);

    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? l10n.languageUpdated : l10n.languageChangeFailed),
        duration: const Duration(seconds: 2),
      ),
    );

    if (!ok) return;

    // Land the user on home in the new language. `go` (not `push`) so the
    // whole navigation stack is discarded — any screen still sitting under
    // this one was built in the previous language, and popping back to it
    // would show a half-translated app.
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = context.watch<LocaleProvider>();

    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        title: Text(l10n.languageTitle),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: AppTheme.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16, left: 4),
            child: Text(
              l10n.languageSubtitle,
              style: const TextStyle(fontSize: 14, color: AppTheme.grey),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                for (final language in AppLanguage.values)
                  _LanguageTile(
                    language: language,
                    selected: provider.language == language,
                    isLast: language == AppLanguage.values.last,
                    onTap: () => _select(context, provider, language),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.language,
    required this.selected,
    required this.isLast,
    required this.onTap,
  });

  final AppLanguage language;
  final bool selected;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(
            language.nativeName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: AppTheme.darkGrey,
            ),
          ),
          subtitle: language.nativeName == language.englishName
              ? null
              : Text(
                  language.englishName,
                  style: const TextStyle(fontSize: 12, color: AppTheme.grey),
                ),
          trailing: selected
              ? const Icon(Icons.check_circle_rounded,
                  color: AppTheme.primaryGreen)
              : const Icon(Icons.circle_outlined, color: AppTheme.grey),
        ),
        if (!isLast)
          const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}
