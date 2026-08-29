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
  String get commonTryAgain => 'Try Again';

  @override
  String get commonOk => 'OK';

  @override
  String get commonNotNow => 'Not now';

  @override
  String get commonEnable => 'Enable';

  @override
  String get commonLater => 'Later';

  @override
  String get commonOpenSettings => 'Open Settings';

  @override
  String get commonLoginFirst => 'Please login first';

  @override
  String get commonSessionExpired => 'Session expired. Please login again.';

  @override
  String commonError(String message) {
    return 'Error: $message';
  }

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
      'Could not change language. Please try again.';

  @override
  String get homeLocationDetected => 'Location detected! Start shopping now.';

  @override
  String get homeLowestPrices => 'Lowest Prices, ';

  @override
  String get homeShopNow => 'Shop Now!!';

  @override
  String get authEnterPhone => 'Enter your phone number';

  @override
  String get authOtpSent => 'OTP sent successfully!';

  @override
  String get authEnterOtp => 'Please enter 6-digit OTP';

  @override
  String get authInvalidPhone => 'Please enter a valid 10-digit phone number';

  @override
  String get locationAddManually => 'Add Address Manually';

  @override
  String get locationConfirmContinue => 'Confirm & Continue';

  @override
  String get locationSaved => 'Location saved! Start shopping now.';

  @override
  String get locationRefine => 'Refine Location';

  @override
  String get locationGrantPermission => 'Grant Location Permission';

  @override
  String get locationTurnOn => 'Turn on Location';

  @override
  String get locationRequired => 'Location permission is required';

  @override
  String get locationEnableInSettings =>
      'Please enable location in phone Settings';

  @override
  String get locationUseCurrent => 'Use Current Location';

  @override
  String get locationSelect => 'Select Location';

  @override
  String get locationUnableToGet =>
      'Unable to get your location. Please try again.';

  @override
  String get locationWaitAddress =>
      'Please wait for address to load completely';

  @override
  String get locationWaitLocation =>
      'Please wait for location to load or select a valid location';

  @override
  String get locationCouldNotDetect =>
      'Could not detect location. Try map picker.';

  @override
  String get locationDetectedFillDetails =>
      'Location detected! Fill remaining details.';

  @override
  String get locationSelectedFillDetails =>
      'Location selected! Fill remaining details.';

  @override
  String get locationSelectFirst =>
      'Please select your location first (GPS or Map)';

  @override
  String get locationDetectViaGps => 'Detect via GPS';

  @override
  String get locationPickOnMap => 'Pick on Map';

  @override
  String get locationChooseFromMap => 'Choose from map';

  @override
  String get serviceNotAvailable => 'Service Not Available';

  @override
  String get categoryViewAllProducts => 'View All Products';

  @override
  String get productAboutThis => 'About this product';

  @override
  String get productDeliveryTime => 'Delivery in 5-15 mins';

  @override
  String get productImageNotAvailable => 'Image not available';

  @override
  String get productImageUnavailable => 'Image unavailable';

  @override
  String get productSelectQuantity => 'Select Quantity';

  @override
  String get productSearchHint => 'Search products...';

  @override
  String get productMicPermission => 'Microphone permission needed';

  @override
  String get orderMyOrders => 'My Orders';

  @override
  String get orderCancelOrder => 'Cancel Order';

  @override
  String get orderCancelAnyway => 'Cancel anyway';

  @override
  String get orderCancelQuestion => 'Cancel order?';

  @override
  String get orderCancellationRequested => 'Cancellation requested';

  @override
  String get orderContactDriver => 'Contact Driver';

  @override
  String get orderDeliveringTo => 'Delivering To';

  @override
  String get orderDriverOnWay => 'Driver is on the way!';

  @override
  String get orderStoreName => 'Easy Basket Store';

  @override
  String get orderKeepOrder => 'Keep order';

  @override
  String get orderLiveTracking => 'Live Order Tracking';

  @override
  String get orderMapNotAvailableWeb => 'Map not available on web';

  @override
  String get orderMapNotAvailable => 'Map not available';

  @override
  String get orderDetails => 'Order Details';

  @override
  String get orderPayment => 'Payment';

  @override
  String get orderRefund => 'Refund';

  @override
  String get orderTotalAmount => 'Total Amount';

  @override
  String get orderTrackOrder => 'Track Order';

  @override
  String get orderWhyCancelling => 'Why are you cancelling?';

  @override
  String get orderYourLocation => 'Your Location';

  @override
  String get orderPrevCancelDeclined =>
      'Your previous cancellation request was declined.';

  @override
  String orderReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get paymentTitle => 'Payment';

  @override
  String paymentItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '$count item',
    );
    return '$_temp0';
  }

  @override
  String get paymentNotesHint => 'Any special instructions... (optional)';

  @override
  String get paymentCardsUpi => 'Cards, UPI, Wallets, Netbanking';

  @override
  String get paymentCod => 'Cash on Delivery';

  @override
  String get paymentDeliveryNotes => 'Delivery Notes';

  @override
  String paymentExternalWallet(String wallet) {
    return 'External wallet selected: $wallet';
  }

  @override
  String get paymentInitFailed =>
      'Failed to initialize payment. Please try again.';

  @override
  String get paymentInvalidMissing =>
      'Invalid payment response. Missing payment details.';

  @override
  String get paymentInvalidResponse =>
      'Invalid payment response. Please try again.';

  @override
  String get paymentOnline => 'Online Payment';

  @override
  String get paymentPayOnReceive => 'Pay when you receive';

  @override
  String get paymentWebOnlyCod =>
      'Online payment is currently available on mobile app only. Please use Cash on Delivery or test on Android/iOS.';

  @override
  String get paymentOrderSummary => 'Order Summary';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get paymentLoginToContinue => 'Please login to continue.';

  @override
  String get paymentSelectAddress => 'Please select an address';

  @override
  String get paymentTotal => 'Total';

  @override
  String get paymentUnableIdentifyOrder =>
      'Unable to identify order. Please check your orders.';

  @override
  String get paymentVerifying => 'Verifying payment...';

  @override
  String get paymentTurnOnNotifications => 'Turn On Notifications';

  @override
  String get addressDetails => 'Address Details';

  @override
  String get addressSaved => 'Address saved!';

  @override
  String get addressUpdated => 'Address updated';

  @override
  String get addressSave => 'Save Address';

  @override
  String get addressSaveAs => 'Save as';

  @override
  String get addressLocation => 'Location';

  @override
  String get addressAdd => 'Add Address';

  @override
  String get addressAddNew => 'Add New Address';

  @override
  String get addressAddToStart => 'Add a delivery address to get started';

  @override
  String get addressChooseDelivery => 'Choose Delivery Address';

  @override
  String get addressContinueToPayment => 'Continue to Payment';

  @override
  String get addressNoneFound => 'No addresses found';

  @override
  String get addressSearchHint => 'Search area, street, landmark...';

  @override
  String get addressYourSaved => 'Your Saved Addresses';

  @override
  String addressSavedCount(int count) {
    return '$count saved';
  }

  @override
  String get addressSetDefault => 'Set as default address';

  @override
  String get addressSearchTitle => 'Search Address';

  @override
  String get addressSearchYourArea => 'Search your area, street, sector...';

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

  @override
  String cartPerUnit(String unit) {
    return 'Per $unit';
  }

  @override
  String get profileUpdated => 'Profile updated successfully!';

  @override
  String get profileFullName => 'Full Name';

  @override
  String get profileFullNameHint => 'Enter your full name';

  @override
  String get profileEmail => 'Email';

  @override
  String get profilePhoneNumber => 'Phone Number';

  @override
  String get profileBirthday => 'Birthday';

  @override
  String get profileBirthdayHint => 'Select your birthday';
}
