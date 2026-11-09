import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';

/// Device preference, independent of account credentials and backend content.
class LocaleController extends ValueNotifier<Locale> {
  LocaleController._() : super(const Locale('vi'));
  static final instance = LocaleController._();
  static const preferenceKey = 'vexgo.ui.locale.v1';
  Future<void>? _writes;

  @visibleForTesting
  void resetForTesting() {
    _writes = null;
    value = const Locale('vi');
  }

  Future<void> get pendingWrites => _writes ?? Future.value();

  Future<void> restore() async {
    try {
      final code = (await SharedPreferences.getInstance()).getString(
        preferenceKey,
      );
      value = Locale(code == 'en' ? 'en' : 'vi');
    } catch (_) {
      value = const Locale('vi');
    }
  }

  Future<void> select(String code) {
    if (code != 'vi' && code != 'en') {
      return Future.error(ArgumentError.value(code, 'code'));
    }
    value = Locale(code);
    Future<void> persist() async {
      final saved = await (await SharedPreferences.getInstance()).setString(
        preferenceKey,
        code,
      );
      if (!saved) throw StateError('Locale preference could not be saved');
    }

    final previous = _writes;
    final write = previous == null
        ? persist()
        : previous.catchError((Object _) {}).then((_) => persist());
    _writes = write;
    return write;
  }

  static AppLocalizations get strings => lookupAppLocalizations(instance.value);
}

extension LocalizedContext on BuildContext {
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ?? LocaleController.strings;
}
