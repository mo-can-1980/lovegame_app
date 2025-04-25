/*
 * @Descripttion: 
 * @Author: ouchao
 * @Email: ouchao@sendpalm.com
 * @version: 1.0
 * @Date: 2025-04-15 14:23:17
 * @LastEditors: ouchao
 * @LastEditTime: 2025-04-21 17:21:58
 */
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // 添加这一行导入 SynchronousFuture

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'Tennis Match Tracker',
      'live': 'LIVE',
      'watch': 'Watch',
      'service': 'SERVICE',
      'round_of': 'round of',
    },
    'es': {
      'app_title': 'Seguimiento de Partidos de Tenis',
      'live': 'EN VIVO',
      'watch': 'Ver',
      'service': 'SERVICIO',
      'round_of': 'ronda de',
    },
  };

  String get appTitle =>
      _localizedValues[locale.languageCode]?['app_title'] ?? '';
  String get live => _localizedValues[locale.languageCode]?['live'] ?? '';
  String get watch => _localizedValues[locale.languageCode]?['watch'] ?? '';
  String get service => _localizedValues[locale.languageCode]?['service'] ?? '';
  String get roundOf =>
      _localizedValues[locale.languageCode]?['round_of'] ?? '';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'es'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
