import 'dart:math';

// flutter pub add applovin_max

import 'package:applovin_max/applovin_max.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mzgs_flutter_helper/flutter_helper.dart';

class ApplovinHelper {
  static var _interstitialRetryAttempt = 0;
  static var _rewardedAdRetryAttempt = 0;

  static String interstitialID = "";
  static String rewardedID = "";
  static String bannerID = "";
  static String mrecID = "";
  static String appopenID = "";

  static bool isFirstInterstitialShowed = false;
  static bool showInterstitialOnStart = false;
  static bool showAdsInDebug = true;
  static bool showAppOpenAds = true;

  static void init(
    String sdkKey, {
    bool showAdsInDebug = true,
    String interstitialID = "",
    String rewardedID = "",
    String bannerID = "",
    String mrecID = "",
    String appopenID = "",
    bool showInterstitialOnStart = false,
  }) async {
    ApplovinHelper.interstitialID = interstitialID;
    ApplovinHelper.rewardedID = rewardedID;
    ApplovinHelper.appopenID = appopenID;
    ApplovinHelper.bannerID = bannerID;
    ApplovinHelper.mrecID = mrecID;
    ApplovinHelper.showInterstitialOnStart = showInterstitialOnStart;
    ApplovinHelper.showAdsInDebug = showAdsInDebug;

    Map? sdkConfiguration = await AppLovinMAX.initialize(sdkKey);

    if (PurchaseHelper.isPremium) {
      return;
    }

    if (interstitialID != "") {
      initializeInterstitialAds();
    }

    if (rewardedID != "") {
      initializeRewardedAds();
    }
  }

  static void loadAppOpen() async {
    if (PurchaseHelper.isPremium || appopenID == "") {
      return;
    }
    var ready = await AppLovinMAX.isAppOpenAdReady(appopenID) ?? false;
    if (!ready) {
      AppLovinMAX.loadAppOpenAd(appopenID);
    }
  }

  static void showAppOpen() async {
    if (!showAppOpenAds) {
      return;
    }
    if (PurchaseHelper.isPremium || appopenID == "") {
      return;
    }
    if (kDebugMode && !showAdsInDebug) {
      return;
    }
    var ready = await AppLovinMAX.isAppOpenAdReady(appopenID) ?? false;
    if (ready) {
      AppLovinMAX.showAppOpenAd(appopenID);
    }
  }

  static void initializeInterstitialAds() {
    AppLovinMAX.setInterstitialListener(InterstitialListener(
      onAdLoadedCallback: (ad) {
        // Interstitial ad is ready to be shown. AppLovinMAX.isInterstitialReady(_interstitial_ad_unit_id) will now return 'true'
        print('Interstitial ad loaded from ${ad.networkName}');

        if (!isFirstInterstitialShowed && showInterstitialOnStart) {
          ShowInterstitial();
        }

        // Reset retry attempt
        _interstitialRetryAttempt = 0;
      },
      onAdLoadFailedCallback: (adUnitId, error) {
        // Interstitial ad failed to load
        // We recommend retrying with exponentially higher delays up to a maximum delay (in this case 64 seconds)
        _interstitialRetryAttempt = _interstitialRetryAttempt + 1;

        int retryDelay = pow(2, min(6, _interstitialRetryAttempt)).toInt();

        print(
            'Interstitial ad failed to load with code ${error.code} - retrying in ${retryDelay}s');

        Future.delayed(Duration(milliseconds: retryDelay * 1000), () {
          AppLovinMAX.loadInterstitial(interstitialID);
        });
      },
      onAdDisplayedCallback: (ad) {
        print("display from ads");
        isFirstInterstitialShowed = true;
      },
      onAdDisplayFailedCallback: (ad, error) {
        AppLovinMAX.loadInterstitial(interstitialID);
      },
      onAdClickedCallback: (ad) {},
      onAdHiddenCallback: (ad) {
        AppLovinMAX.loadInterstitial(interstitialID);
      },
    ));

    // Load the first interstitial
    AppLovinMAX.loadInterstitial(interstitialID);
  }

  static void initializeRewardedAds() {
    AppLovinMAX.setRewardedAdListener(RewardedAdListener(
        onAdLoadedCallback: (ad) {
          // Rewarded ad is ready to be shown. AppLovinMAX.isRewardedAdReady(_rewarded_ad_unit_id) will now return 'true'
          print('Rewarded ad loaded from ${ad.networkName}');

          // Reset retry attempt
          _rewardedAdRetryAttempt = 0;
        },
        onAdLoadFailedCallback: (adUnitId, error) {
          // Rewarded ad failed to load
          // We recommend retrying with exponentially higher delays up to a maximum delay (in this case 64 seconds)
          _rewardedAdRetryAttempt = _rewardedAdRetryAttempt + 1;

          int retryDelay = pow(2, min(6, _rewardedAdRetryAttempt)).toInt();
          print(
              'Rewarded ad failed to load with code ${error.code} - retrying in ${retryDelay}s');

          Future.delayed(Duration(milliseconds: retryDelay * 1000), () {
            AppLovinMAX.loadRewardedAd(rewardedID);
          });
        },
        onAdDisplayedCallback: (ad) {},
        onAdDisplayFailedCallback: (ad, error) {
          AppLovinMAX.loadRewardedAd(rewardedID);
        },
        onAdClickedCallback: (ad) {},
        onAdHiddenCallback: (ad) {
          AppLovinMAX.loadRewardedAd(rewardedID);
        },
        onAdReceivedRewardCallback: (ad, reward) {}));

    AppLovinMAX.loadRewardedAd(rewardedID);
  }

  static void ShowRewarded({String name = "REWARDED"}) async {
    if (kDebugMode && !showAdsInDebug) {
      return;
    }

    if (PurchaseHelper.isPremium) {
      return;
    }
    bool isReady = (await AppLovinMAX.isRewardedAdReady(rewardedID))!;
    if (isReady) {
      AppLovinMAX.showRewardedAd(rewardedID, placement: name);
    }
  }

  static Widget _getBannerView(String bannerID,
      {AdFormat format = AdFormat.banner}) {
    if (PurchaseHelper.isPremium || (kDebugMode && !showAdsInDebug)) {
      return const SizedBox();
    }
    return MaxAdView(
        adUnitId: bannerID,
        adFormat: format,
        listener: AdViewAdListener(
            onAdLoadedCallback: (ad) {
              AppLovinMAX.showBanner(bannerID);
            },
            onAdLoadFailedCallback: (adUnitId, error) {
              print("banner ad load error $error");
            },
            onAdClickedCallback: (ad) {},
            onAdExpandedCallback: (ad) {},
            onAdCollapsedCallback: (ad) {}));
  }

  static Widget getBannerView() {
    return _getBannerView(bannerID);
  }

  static Widget getMrecView() {
    return _getBannerView(mrecID, format: AdFormat.mrec);
  }

  static void ShowInterstitial({String name = "INTERSTITIAL"}) async {
    if (kDebugMode && !showAdsInDebug) {
      return;
    }

    if (PurchaseHelper.isPremium) {
      return;
    }
    bool isReady = (await AppLovinMAX.isInterstitialReady(interstitialID))!;
    if (isReady) {
      AppLovinMAX.showInterstitial(interstitialID, placement: name);
    }
  }
}
