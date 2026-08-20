// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Panjabi Punjabi (`pa`).
class AppLocalizationsPa extends AppLocalizations {
  AppLocalizationsPa([String locale = 'pa']) : super(locale);

  @override
  String get commonCancel => 'ਰੱਦ ਕਰੋ';

  @override
  String get commonRemove => 'ਹਟਾਓ';

  @override
  String get commonSave => 'ਸੰਭਾਲੋ';

  @override
  String get commonRetry => 'ਫਿਰ ਕੋਸ਼ਿਸ਼ ਕਰੋ';

  @override
  String get languageTitle => 'ਭਾਸ਼ਾ';

  @override
  String get languageSubtitle => 'ਐਪ ਵਿੱਚ ਜਿਹੜੀ ਭਾਸ਼ਾ ਵਰਤਣੀ ਚਾਹੁੰਦੇ ਹੋ ਉਹ ਚੁਣੋ';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिंदी';

  @override
  String get languagePunjabi => 'ਪੰਜਾਬੀ';

  @override
  String get languageUpdated => 'ਭਾਸ਼ਾ ਬਦਲ ਦਿੱਤੀ ਗਈ';

  @override
  String get languageChangeFailed =>
      'ਭਾਸ਼ਾ ਨਹੀਂ ਬਦਲ ਸਕੀ। ਕਿਰਪਾ ਕਰਕੇ ਫਿਰ ਕੋਸ਼ਿਸ਼ ਕਰੋ।';

  @override
  String get profileCustomer => 'ਗਾਹਕ';

  @override
  String get profileOrders => 'ਆਰਡਰ';

  @override
  String get profileAddresses => 'ਪਤੇ';

  @override
  String get profileRating => 'ਰੇਟਿੰਗ';

  @override
  String get profileAccount => 'ਖਾਤਾ';

  @override
  String get profileEditProfile => 'ਪ੍ਰੋਫਾਈਲ ਸੋਧੋ';

  @override
  String get profileMyOrders => 'ਮੇਰੇ ਆਰਡਰ';

  @override
  String get profileMyAddresses => 'ਮੇਰੇ ਪਤੇ';

  @override
  String get profilePreferences => 'ਤਰਜੀਹਾਂ';

  @override
  String get profileSupport => 'ਸਹਾਇਤਾ';

  @override
  String get profileHelpSupport => 'ਮਦਦ ਅਤੇ ਸਹਾਇਤਾ';

  @override
  String get profileHelpComingSoon => 'ਮਦਦ ਅਤੇ ਸਹਾਇਤਾ ਜਲਦੀ ਆ ਰਹੀ ਹੈ';

  @override
  String get profileAbout => 'ਜਾਣਕਾਰੀ';

  @override
  String get profileAboutApp => 'ਈਜ਼ੀ ਬਾਸਕਟ ਬਾਰੇ';

  @override
  String get profileLogout => 'ਲਾਗਆਊਟ';

  @override
  String get profileLogoutConfirm => 'ਕੀ ਤੁਸੀਂ ਸੱਚਮੁੱਚ ਲਾਗਆਊਟ ਕਰਨਾ ਚਾਹੁੰਦੇ ਹੋ?';

  @override
  String get cartTitle => 'ਮੇਰੀ ਕਾਰਟ';

  @override
  String cartItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ਚੀਜ਼ਾਂ',
      one: '$count ਚੀਜ਼',
    );
    return '$_temp0';
  }

  @override
  String get cartEmpty => 'ਤੁਹਾਡੀ ਕਾਰਟ ਖਾਲੀ ਹੈ';

  @override
  String get cartEmptySubtitle => 'ਸ਼ੁਰੂ ਕਰਨ ਲਈ ਕਾਰਟ ਵਿੱਚ ਸਮਾਨ ਪਾਓ';

  @override
  String get cartStartShopping => 'ਖਰੀਦਦਾਰੀ ਸ਼ੁਰੂ ਕਰੋ';

  @override
  String get cartRemoveItem => 'ਸਮਾਨ ਹਟਾਓ';

  @override
  String get cartSubtotal => 'ਉਪ-ਜੋੜ';

  @override
  String get cartDeliveryFee => 'ਡਿਲੀਵਰੀ ਫੀਸ';

  @override
  String get cartTotal => 'ਕੁੱਲ';

  @override
  String get cartAddressRequired => 'ਡਿਲੀਵਰੀ ਦਾ ਪਤਾ ਜ਼ਰੂਰੀ ਹੈ';

  @override
  String get cartAddAddressToProceed => 'ਅੱਗੇ ਵਧਣ ਲਈ ਪਤਾ ਪਾਓ';

  @override
  String get cartAddAddressFirst => 'ਕਿਰਪਾ ਕਰਕੇ ਪਹਿਲਾਂ ਡਿਲੀਵਰੀ ਦਾ ਪਤਾ ਪਾਓ';

  @override
  String get cartStoreClosed => 'ਸਟੋਰ ਬੰਦ ਹੈ';

  @override
  String get cartLoginToCheckout => 'ਚੈੱਕਆਊਟ ਲਈ ਲਾਗਇਨ ਕਰੋ';

  @override
  String get cartAddAddressToCheckout => 'ਚੈੱਕਆਊਟ ਲਈ ਪਤਾ ਪਾਓ';

  @override
  String get cartProceedToCheckout => 'ਚੈੱਕਆਊਟ \'ਤੇ ਜਾਓ';
}
