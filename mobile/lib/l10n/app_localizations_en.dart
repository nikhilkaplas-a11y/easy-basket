// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonSave => 'Save';

  @override
  String get commonRetry => 'Retry';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSubtitle =>
      'Choose the language you want to use in the app';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'Hindi';

  @override
  String get languagePunjabi => 'Punjabi';

  @override
  String get languageUpdated => 'Language updated';

  @override
  String get languageChangeFailed =>
      'Couldn\'t change language. Please try again.';

  @override
  String get profileCustomer => 'Customer';

  @override
  String get profileOrders => 'Orders';

  @override
  String get profileAddresses => 'Addresses';

  @override
  String get profileRating => 'Rating';

  @override
  String get profileAccount => 'Account';

  @override
  String get profileEditProfile => 'Edit Profile';

  @override
  String get profileMyOrders => 'My Orders';

  @override
  String get profileMyAddresses => 'My Addresses';

  @override
  String get profilePreferences => 'Preferences';

  @override
  String get profileSupport => 'Support';

  @override
  String get profileHelpSupport => 'Help & Support';

  @override
  String get profileHelpComingSoon => 'Help & Support coming soon';

  @override
  String get profileAbout => 'About';

  @override
  String get profileAboutApp => 'About Easy Basket';

  @override
  String get profileLogout => 'Logout';

  @override
  String get profileLogoutConfirm => 'Are you sure you want to logout?';

  @override
  String get cartTitle => 'My Cart';

  @override
  String cartItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '$count item',
    );
    return '$_temp0';
  }

  @override
  String get cartEmpty => 'Your cart is empty';

  @override
  String get cartEmptySubtitle => 'Add items to your cart to get started';

  @override
  String get cartStartShopping => 'Start Shopping';

  @override
  String get cartRemoveItem => 'Remove Item';

  @override
  String get cartSubtotal => 'Subtotal';

  @override
  String get cartDeliveryFee => 'Delivery Fee';

  @override
  String get cartTotal => 'Total';

  @override
  String get cartAddressRequired => 'Delivery address required';

  @override
  String get cartAddAddressToProceed => 'Add address to proceed';

  @override
  String get cartAddAddressFirst => 'Please add a delivery address first';

  @override
  String get cartStoreClosed => 'Store Closed';

  @override
  String get cartLoginToCheckout => 'Login to Checkout';

  @override
  String get cartAddAddressToCheckout => 'Add Address to Checkout';

  @override
  String get cartProceedToCheckout => 'Proceed to Checkout';
}
