import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_basket/l10n/app_localizations.dart';

Future<AppLocalizations> load(String code) =>
    AppLocalizations.delegate.load(Locale(code));

void main() {
  test('all three locales are supported', () {
    expect(
      AppLocalizations.supportedLocales.map((l) => l.languageCode).toList(),
      containsAll(<String>['en', 'hi', 'pa']),
    );
  });

  test('strings resolve per locale', () async {
    expect((await load('en')).languageTitle, 'Language');
    expect((await load('hi')).languageTitle, 'भाषा');
    expect((await load('pa')).languageTitle, 'ਭਾਸ਼ਾ');
  });

  test('cart plural inflects correctly in each language', () async {
    final en = await load('en');
    final hi = await load('hi');
    final pa = await load('pa');

    expect(en.cartItemCount(1), '1 item');
    expect(en.cartItemCount(3), '3 items');

    // Genuine plural forms, not the same string twice — this is the thing a
    // flat key->string map could not express.
    expect(hi.cartItemCount(1), '1 चीज़');
    expect(hi.cartItemCount(3), '3 चीज़ें');

    expect(pa.cartItemCount(1), '1 ਚੀਜ਼');
    expect(pa.cartItemCount(3), '3 ਚੀਜ਼ਾਂ');
  });

  test('Punjabi is fully translated (no English leaking through)', () async {
    final en = await load('en');
    final pa = await load('pa');

    expect(pa.cartProceedToCheckout, isNot(en.cartProceedToCheckout));
    expect(pa.profileMyOrders, isNot(en.profileMyOrders));
    expect(pa.cartEmpty, isNot(en.cartEmpty));
  });
}
