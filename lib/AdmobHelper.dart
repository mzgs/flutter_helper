import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdmobHelper {
  static bool showAds = true;
  static InterstitialAd? _interstitialAd;
  static String interstitialAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';

  static String interstitialOnStartAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';

  static String bannerAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-3940256099942544/2934735716';

  static String mrecAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-3940256099942544/2934735716';

  static void init() {
    MobileAds.instance.initialize();
  }

  static Widget getMrecView() {
    if (kDebugMode && !showAds) {
      return const SizedBox();
    }

    var _bannerAd = BannerAd(
      adUnitId: mrecAdUnitId,
      request: const AdRequest(),
      size: AdSize.mediumRectangle,
      listener: BannerAdListener(
        // Called when an ad is successfully received.
        onAdLoaded: (ad) {},
        // Called when an ad request failed.
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    )..load();

    return SizedBox(
      width: _bannerAd.size.width.toDouble(),
      height: _bannerAd.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd),
    );
  }

  static Widget getBannerView() {
    if (kDebugMode && !showAds) {
      return const SizedBox();
    }
    var _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        // Called when an ad is successfully received.
        onAdLoaded: (ad) {},
        // Called when an ad request failed.
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    )..load();

    return SizedBox(
      width: _bannerAd.size.width.toDouble(),
      height: _bannerAd.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd),
    );
  }

  static void showInterstitial() {
    if (kDebugMode && !showAds) {
      return;
    }
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        // Called when an ad is successfully received.
        onAdLoaded: (ad) {
          print('ADMOB: $ad loaded.');
          // Keep a reference to the ad so you can show it later.
          _interstitialAd = ad;
          _interstitialAd?.show();
        },
        // Called when an ad request failed.
        onAdFailedToLoad: (LoadAdError error) {
          print('ADMOB: InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  static void showInterstitialOnStart() {
    if (kDebugMode && !showAds) {
      return;
    }
    InterstitialAd.load(
      adUnitId: interstitialOnStartAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        // Called when an ad is successfully received.
        onAdLoaded: (ad) {
          print('ADMOB: $ad loaded.');
          // Keep a reference to the ad so you can show it later.
          _interstitialAd = ad;
          _interstitialAd?.show();
        },
        // Called when an ad request failed.
        onAdFailedToLoad: (LoadAdError error) {
          print('ADMOB: InterstitialAd failed to load: $error');
        },
      ),
    );
  }
}
