import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gdpr_dialog/gdpr_dialog.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mzgs_flutter_helper/flutter_helper.dart';

class AdmobHelper {
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

  static String rewardedAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5224354917'
      : 'ca-app-pub-3940256099942544/1712485313';

  static void init({initRewarded = false}) async {
    await MobileAds.instance.initialize();

    if (!showAds()) {
      return;
    }

    if (initRewarded) {
      loadRewarded();
    }
  }

  static bool showAds() {
    if (PurchaseHelper.isPremium) {
      return false;
    }
    return RemoteConfig.get("show_ads", true);
  }

  static void showConsentDialog(
      {bool isTest = true, String testDeviceId = ""}) {
    if (!kDebugMode) {
      isTest = false;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      GdprDialog.instance
          .showDialog(isForTest: isTest, testDeviceId: testDeviceId)
          .then((onValue) {
        print('result === $onValue');
      });
    });
  }

  static Widget getMrecView() {
    if (!showAds()) {
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
    if (!showAds()) {
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
    if (!showAds()) {
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
    if (!showAds()) {
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

  static RewardedAd? _rewardedAd;
  static void loadRewarded() {
    RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          // Called when an ad is successfully received.
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            ad.fullScreenContentCallback = FullScreenContentCallback(
                // Called when the ad showed the full screen content.
                onAdShowedFullScreenContent: (ad) {},
                // Called when an impression occurs on the ad.
                onAdImpression: (ad) {},
                // Called when the ad failed to show full screen content.
                onAdFailedToShowFullScreenContent: (ad, err) {
                  // Dispose the ad here to free resources.
                  ad.dispose();
                },
                // Called when the ad dismissed full screen content.
                onAdDismissedFullScreenContent: (ad) {
                  // Dispose the ad here to free resources.
                  ad.dispose();
                  loadRewarded();
                });
          },

          // Called when an ad request failed.
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('RewardedAd failed to load: $error');
          },
        ));
  }

  static void showRewarded() {
    if (!showAds()) {
      return;
    }

    _rewardedAd?.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) {});
  }
}
