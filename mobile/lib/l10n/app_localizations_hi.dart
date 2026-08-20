// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get commonCancel => 'रद्द करें';

  @override
  String get commonRemove => 'हटाएं';

  @override
  String get commonSave => 'सहेजें';

  @override
  String get commonRetry => 'फिर कोशिश करें';

  @override
  String get languageTitle => 'भाषा';

  @override
  String get languageSubtitle =>
      'ऐप में जो भाषा इस्तेमाल करना चाहते हैं वह चुनें';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिंदी';

  @override
  String get languagePunjabi => 'ਪੰਜਾਬੀ';

  @override
  String get languageUpdated => 'भाषा बदल दी गई';

  @override
  String get languageChangeFailed => 'भाषा नहीं बदल सकी। कृपया फिर कोशिश करें।';

  @override
  String get profileCustomer => 'ग्राहक';

  @override
  String get profileOrders => 'ऑर्डर';

  @override
  String get profileAddresses => 'पते';

  @override
  String get profileRating => 'रेटिंग';

  @override
  String get profileAccount => 'खाता';

  @override
  String get profileEditProfile => 'प्रोफ़ाइल संपादित करें';

  @override
  String get profileMyOrders => 'मेरे ऑर्डर';

  @override
  String get profileMyAddresses => 'मेरे पते';

  @override
  String get profilePreferences => 'प्राथमिकताएं';

  @override
  String get profileSupport => 'सहायता';

  @override
  String get profileHelpSupport => 'मदद और सहायता';

  @override
  String get profileHelpComingSoon => 'मदद और सहायता जल्द आ रही है';

  @override
  String get profileAbout => 'जानकारी';

  @override
  String get profileAboutApp => 'ईज़ी बास्केट के बारे में';

  @override
  String get profileLogout => 'लॉगआउट';

  @override
  String get profileLogoutConfirm => 'क्या आप वाकई लॉगआउट करना चाहते हैं?';

  @override
  String get cartTitle => 'मेरी कार्ट';

  @override
  String cartItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count चीज़ें',
      one: '$count चीज़',
    );
    return '$_temp0';
  }

  @override
  String get cartEmpty => 'आपकी कार्ट खाली है';

  @override
  String get cartEmptySubtitle => 'शुरू करने के लिए कार्ट में सामान जोड़ें';

  @override
  String get cartStartShopping => 'खरीदारी शुरू करें';

  @override
  String get cartRemoveItem => 'सामान हटाएं';

  @override
  String get cartSubtotal => 'उप-योग';

  @override
  String get cartDeliveryFee => 'डिलीवरी शुल्क';

  @override
  String get cartTotal => 'कुल';

  @override
  String get cartAddressRequired => 'डिलीवरी का पता ज़रूरी है';

  @override
  String get cartAddAddressToProceed => 'आगे बढ़ने के लिए पता जोड़ें';

  @override
  String get cartAddAddressFirst => 'कृपया पहले डिलीवरी का पता जोड़ें';

  @override
  String get cartStoreClosed => 'स्टोर बंद है';

  @override
  String get cartLoginToCheckout => 'चेकआउट के लिए लॉगिन करें';

  @override
  String get cartAddAddressToCheckout => 'चेकआउट के लिए पता जोड़ें';

  @override
  String get cartProceedToCheckout => 'चेकआउट पर जाएं';
}
