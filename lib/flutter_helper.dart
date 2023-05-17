library flutter_helper;

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:mzgs_flutter_helper/applovin_helper.dart';
import 'package:mzgs_flutter_helper/web.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:in_app_review/in_app_review.dart';
import 'inapp_purchase_helper.dart';

// mzgs_flutter_helper:
//       path: /Users/mustafa/Developer/Flutter/flutter_helper

bool isApple = Platform.isIOS || Platform.isMacOS;
bool isAndroid = Platform.isAndroid;
final InAppReview inAppReview = InAppReview.instance;

late GetStorage getStorage;

class Helper {
  static Future init() async {
    await GetStorage.init();
    getStorage = GetStorage();
  }

  static Color Hex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }

    return Color(int.parse(hexColor, radix: 16));
  }

  static String getPhoneCountryCode() {
    if (Platform.isAndroid) {
      // Retrieve the phone country code on Android
      final locale = Platform.localeName;
      final parts = locale.split('_');
      if (parts.length == 2) {
        return parts[1].toUpperCase();
      }
    } else if (Platform.isIOS) {
      // Retrieve the phone country code on iOS
      final locale = Platform.localeName;
      final parts = locale.split('_');
      if (parts.length == 2) {
        return parts[0].toUpperCase();
      }
    }
    return 'Unknown';
  }

  static Future<String> getPackageName() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.packageName;
  }

  static Future<String> getAppName() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.appName;
  }

  static void hideKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  static bool isFirstOpen() {
    if (!Pref.get("is_first_open", false)) {
      Pref.set("is_first_open", true);
      return true;
    }
    return false;
  }

  static void shareApp(String isoAppID, {String message = ""}) async {
    if (message == "") {
      message = "Check out this amazing app at".tr;
    }
    String appLink = 'https://apps.apple.com/app/id$isoAppID';
    if (isAndroid) {
      var packageName = await Helper.getPackageName();

      appLink = "https://play.google.com/store/apps/details?id=$packageName";
    }
    Share.share('$message $appLink');
  }

  static void rateApp(String iosAppID) {
    inAppReview.openStoreListing(appStoreId: iosAppID);
  }

  static void showInAppRate() async {
    if (await inAppReview.isAvailable()) {
      inAppReview.requestReview();
    }
  }

  static void showInappRateOnce() {
    var key = "in_App_rate_showed";
    if (!Pref.get(key, false)) {
      Pref.set(key, true);
      showInAppRate();
    }
  }

  static showInappRateWithActionCount(int mustCountValue) {
    var key = "count_inapprate";
    var nextValue = Pref.get(key, 0) + 1;
    Pref.set(key, nextValue);
    if (nextValue >= mustCountValue) {
      Helper.showInappRateOnce();
    }
  }

  static void openUrlInWebview(String url, {String title = ""}) {
    Get.to(() => WebPage(
          url,
          title: title,
        ));
  }
}

class HttpHelper {
  static Future<String> getStringFromUrl(String url) async {
    var result = await http.Client().get(Uri.parse(url));

    return result.body;
  }

// return parsed json
  static Future<dynamic> getJsonFromUrl(String url) async {
    return jsonDecode(await getStringFromUrl(url));
  }

  static Future<http.Response> postRequest(
      String url, Map<String, String> body) async {
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return response;
  }

  static List<String> convertDynamicListToStringList(List<dynamic> list) {
    return list.map((item) => item as String).toList();
  }

  static getBody(http.Response response) {
    return json.decode(utf8.decode(response.bodyBytes));
  }
}

class Pref {
  static get(String key, dynamic defaultValue) {
    return getStorage.read(key) ?? defaultValue;
  }

  static set(String key, dynamic value) {
    getStorage.write(key, value);
  }

  static keys() {
    return getStorage.getKeys();
  }

  static List<String> keysByPrefix() {
    return keys()
        .where((String key) => key.startsWith('item_'))
        .toList()
        .reversed;
  }
}

class UI {
  static cardListTile(IconData icon, Color iconColor, String title,
      {String subtitle = "", void Function()? onTap, Widget? trailing}) {
    var iconSize = 24.0;

    if (subtitle.isEmpty) {
      iconSize = 18.0;
    }

    var tile2 = ListTile(
      leading: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: iconColor,
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: Colors.white,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
        ),
      ),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: trailing,
      dense: true,
      onTap: onTap,
      minLeadingWidth: 12,
    );

    return Card(
      elevation: 5,
      child: tile2,
    );
  }

  static void showErrorToast(String message) {
    Get.snackbar(
      'ERROR'.tr,
      message,
      icon: const Icon(Icons.error, color: Colors.white),
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  static void showSuccessToast(String message) {
    Get.snackbar(
      'SUCCESS'.tr,
      message,
      icon: const Icon(Icons.check, color: Colors.white),
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  static void showFirstTimeDialog(String title, String message) {
    if (Helper.isFirstOpen()) {
      showDialog(title, message);
    }
  }

  static void showDialog(String title, String message) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 12.0,
                  ),
                  child: Text(
                    'OK',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  static void showDialogWithWidgets({
    Widget? title,
    Widget? message,
    Widget? buttonLabel,
  }) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null) ...[
                title,
                const SizedBox(height: 16),
              ],
              if (message != null) ...[
                message,
                const SizedBox(height: 24),
              ],
              if (buttonLabel != null) ...[
                ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 12.0,
                    ),
                    child: buttonLabel,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  static void showSuccessDialog(String message, {String title = ""}) {
    if (title == "") {
      title = "SUCCESS".tr;
    }
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 12.0,
                  ),
                  child: Text(
                    'OK',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  static void showErrorDialog(String message, {String title = ""}) {
    if (title == "") {
      title = "ERROR".tr;
    }
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 12.0,
                  ),
                  child: Text(
                    'OK',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  static ElevatedButton rewardedButton(String title, void Function() onPressed,
      {IconData icon = Icons.star, Color color = Colors.blue}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: color),
      onPressed: () {
        ApplovinHelper.ShowRewarded();
        onPressed();
      },
      icon: Icon(icon),
      label: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 17)),
          if (!PurchaseHelper.isPremium) ...{
            Text('Watch ad'.tr, style: TextStyle(fontSize: 11)),
            SizedBox(height: 5)
          },
        ],
      ),
    );
  }

  static Widget DailyLimitRemainingCard(
      int totalDailyLimit, int remaining, String message,
      {Color color = Colors.blue}) {
    return Card(
      elevation: 4,
      color: Colors.grey[200],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Limit'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ),
                const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.blueGrey,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              backgroundColor: Colors.grey[300],
              value: remaining / totalDailyLimit,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Remaining'.tr,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                Text(
                  remaining.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check),
                onPressed: () {
                  PurchaseHelper.showPaywall();
                },
                label: Text(
                  'Remove Limits'.tr,
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsHelper {
  static Widget terms() {
    return UI.cardListTile(
      Icons.feed,
      Colors.blue,
      "Terms of Use (EULA)".tr,
      onTap: () => {
        Helper.openUrlInWebview('https://mzgs.net/terms.html',
            title: 'Terms of Use (EULA)'.tr)
      },
    );
  }

  static Widget privacy() {
    return UI.cardListTile(
      Icons.privacy_tip,
      Colors.red,
      "Privacy Policy".tr,
      onTap: () => {
        Helper.openUrlInWebview('https://mzgs.net/privacy.html',
            title: 'Privacy Policy'.tr)
      },
    );
  }

  static Widget buyPremiumAndRestoreButton() {
    return Visibility(
        visible: !PurchaseHelper.isPremium,
        child: Column(
          children: [
            UI.cardListTile(
              Icons.shopping_cart,
              Colors.lightBlueAccent,
              "Buy Premium".tr,
              onTap: () => {PurchaseHelper.showPaywall()},
            ),
            UI.cardListTile(
              Icons.restore,
              Colors.green,
              "Restore Purchases".tr,
              onTap: () => {
                if (PurchaseHelper.isPremium)
                  {
                    Get.snackbar(
                      "Success".tr,
                      "Purchases restored successfully.",
                      icon: const Icon(Icons.check, color: Colors.green),
                      snackPosition: SnackPosition.BOTTOM,
                    )
                  }
                else
                  {
                    Get.snackbar(
                      "Error".tr,
                      "You have no active subscription.".tr,
                      icon: const Icon(Icons.error, color: Colors.red),
                      snackPosition: SnackPosition.BOTTOM,
                    )
                  }
              },
            ),
          ],
        ));
  }

  static Widget share(String appID) {
    return UI.cardListTile(
      Icons.share,
      Colors.purple,
      "Share with Friends".tr,
      onTap: () {
        Helper.shareApp(appID);
      },
    );
  }

  static Widget rateUs(String appID) {
    return UI.cardListTile(
      Icons.star,
      Colors.green,
      "Rate Us".tr,
      onTap: () => {
        Helper.rateApp(appID)
        // Helper.inAppRate()
      },
    );
  }

  static Widget premiumCard() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 16),
          Icon(Icons.star, color: Colors.yellow, size: 48),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Premium",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "You are using the premium version of this app.".tr,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
        ],
      ),
    );
  }

  static Widget dailyLimitCard(int dailyLimit, String description,
      {Color color = Colors.blue}) {
    return Column(children: [
      if (!PurchaseHelper.isPremium) ...[
        const SizedBox(height: 12),
        UI.DailyLimitRemainingCard(
            dailyLimit, DailyCredits.credits, description,
            color: color),
        const SizedBox(height: 16),
      ] else ...[
        Padding(
          padding: EdgeInsets.all(4.0),
          child: premiumCard(),
        ),
      ],
    ]);
  }

  static List<Widget> usualItems(String appID) {
    return [
      SettingsHelper.share(appID),
      SettingsHelper.rateUs(appID),
      const SizedBox(height: 16),
      SettingsHelper.terms(),
      SettingsHelper.privacy(),
      const SizedBox(height: 16),
      SettingsHelper.buyPremiumAndRestoreButton()
    ];
  }
}

class DailyCredits {
  static int credits = 0;
  static void init(int maxCredits) {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    credits = Pref.get("credit", maxCredits);
    if (!Pref.get("credit$today", false)) {
      Pref.set("credit$today", true);
      Pref.set("credit", maxCredits);
      credits = maxCredits;
    }
  }

  static bool hasCredit() {
    if (PurchaseHelper.isPremium) {
      return true;
    }
    var has = credits > 0;

    if (!has) {
      PurchaseHelper.showPaywall();
    }
    return has;
  }

  static void consumeCredit({bool setPurchaseAnalytic = false}) {
    credits--;
    Pref.set("credit", credits);

    if (setPurchaseAnalytic) {
      PurchaseHelper.setAnalyticData("dailyCredits", DailyCredits.credits);
    }
  }

  static void addCredits(int creditToAdd) {
    if (kDebugMode) {
      credits = creditToAdd;
      Pref.set("credit", credits);
    }
  }
}

class FileHelper {
  static void shareFile(String path, String shareText) {
    Share.shareXFiles([XFile(path)], subject: shareText);
  }

// saveFilePath /image.jpg
  static Future downloadFile(String url, String saveFilePath,
      Function(double) onProgress, Function() onFinished,
      {Function(Object e)? onError}) async {
    Dio dio = Dio();
// Download the file
    var appDocDir = await getAppDataPath();
    try {
      await dio.download(url, appDocDir + saveFilePath,
          onReceiveProgress: (received, total) {
        if (total != -1) {
          var progress = received / total;
          onProgress(progress);

          if (progress == 1) {
            onFinished();
          }
        }
      });
    } catch (e) {
      onError ?? (e);
    }
  }

  static Future<void> deleteAllFilesInFolder(String path) async {
    Directory directory = Directory(path);
    if (await directory.exists()) {
      List<FileSystemEntity> files = directory.listSync();
      for (FileSystemEntity file in files) {
        if (file is File) {
          await file.delete();
        }
      }
    }
  }

  static Future<String> getAppDataPath({String file = ""}) async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    return appDocDir.path + file;
  }

  static Future<List<FileSystemEntity>> getFiles(
      {String folderPath = ""}) async {
    var appPath = await getAppDataPath();
    Directory directory = Directory("$appPath/$folderPath");
    List<FileSystemEntity> files =
        directory.listSync(recursive: true, followLinks: false);
    return files;
  }
}

class PurchaseHelper {
  static var isPremium = false;
  static Map<String, IAPItem> products = {};
  static PurchaseConfig purchaseConfig = PurchaseConfig();

  static String YEARLY_ID = "";
  static String MONTH6_ID = "";
  static String MONTHLY_ID = "";
  static bool initOnDebug = true;

  static Future<void> init(
    PurchaseConfig purchaseConfig, {
    bool initOnDebug = true,
    String monthlyID = "",
    String month6ID = "",
    String yearlyID = "",
  }) async {
    MONTHLY_ID = monthlyID;
    MONTH6_ID = month6ID;
    YEARLY_ID = yearlyID;
    PurchaseHelper.initOnDebug = initOnDebug;
    PurchaseHelper.purchaseConfig = purchaseConfig;

    if (kDebugMode && !initOnDebug) {
      return;
    }

    isPremium = Pref.get("is_premium", false);

    await FlutterInappPurchase.instance.initialize();
    PurchaseHelper.checkSubscription();
  }

  static Future<Map<String, IAPItem>> getPurchaseProducts() async {
    var products = <String, IAPItem>{};

    List<IAPItem> items = await FlutterInappPurchase.instance
        .getSubscriptions([YEARLY_ID, MONTH6_ID, MONTHLY_ID]);

    for (var item in items) {
      var key = "monthly";

      if (item.subscriptionPeriodNumberIOS == "6" ||
          item.subscriptionPeriodAndroid == "P6M") {
        key = "month6";
      }
      if (item.subscriptionPeriodUnitIOS == "YEAR" ||
          item.subscriptionPeriodAndroid == "P1Y") {
        key = "yearly";
      }

      products[key] = item;
    }

    return products;
  }

  static Future checkSubscription() async {
    try {
      var montly =
          await FlutterInappPurchase.instance.checkSubscribed(sku: MONTHLY_ID);
      var month6 = await FlutterInappPurchase.instance
          .checkSubscribed(sku: MONTH6_ID, duration: const Duration(days: 180));
      var yearly = await FlutterInappPurchase.instance
          .checkSubscribed(sku: YEARLY_ID, duration: const Duration(days: 360));
      var hasSubscription = montly || month6 || yearly;
      isPremium = hasSubscription;
      Pref.set("is_premium", isPremium);
    } catch (e) {
      print("checkSubscription error: $e");
    }
  }

  static Future<void> setProducts() async {
    products = await getPurchaseProducts();
  }

  static void showPaywall() async {
    if (kDebugMode && !initOnDebug) {
      return;
    }

    if (isPremium) {
      return;
    }
    if (products.isEmpty) {
      await setProducts();
    }

    if (products.isEmpty) {
      return;
    }

    Get.to(() => const PurchasePage(), arguments: {'products': products});
  }

  static void showPaywallOnce() {
    if (isPremium) {
      return;
    }
    bool isShowedPurchaseFirstTime =
        Pref.get("isShowedPurchaseFirstTime", false);

    if (!isShowedPurchaseFirstTime) {
      Pref.set("isShowedPurchaseFirstTime", true);
      showPaywall();
    }
  }

  static Future<List<PurchasedItem>> getPurchaseHistory() async {
    List<PurchasedItem>? history =
        await FlutterInappPurchase.instance.getPurchaseHistory();
    return history ?? [];
  }

  static void setAnalyticData(String key, value) {
    var data = jsonDecode(purchaseConfig.analyticData);
    data[key] = value;
    purchaseConfig.analyticData = jsonEncode(data);
  }
}

class PurchaseConfig {
  String title;
  String description;
  Color mainColor;
  Color textColor;
  Color gradientColor1;
  Color gradientColor2;
  bool iconIsOval;
  String image;
  String analyticData;
  bool showTrialYearly;

  PurchaseConfig(
      {this.title = 'Premium',
      this.description = '✓ Unlimited Genarate\n✓ No Ads',
      this.mainColor = const Color.fromARGB(255, 16, 190, 36),
      this.textColor = const Color.fromARGB(255, 30, 50, 79),
      this.gradientColor1 = const Color.fromARGB(255, 244, 255, 198),
      this.gradientColor2 = const Color.fromARGB(255, 198, 229, 61),
      this.iconIsOval = true,
      this.image = 'app.png',
      this.analyticData = "{}",
      this.showTrialYearly = false});
}

class RemoteConfig {
  // COUNTERS
  static final _counterValues = {};
  static var app = {};

  static Future init(String iosAppID) async {
    var packageName = await Helper.getPackageName();
    if (isApple) {
      packageName = iosAppID;
    }
    app = (await HttpHelper.getJsonFromUrl(
                "https://raw.githubusercontent.com/mzgs/Android-Json-Data/master/data.json"))[
            packageName] ??
        {};
  }

  static get(String key, defaultValue) {
    return app[key] ?? defaultValue;
  }

  static void showInterstitialCounter(String name, {int defaultValue = 3}) {
    _counterValues[name] = _counterValues[name] ?? 0;

    if (++_counterValues[name] % (app[name] ?? defaultValue) == 0) {
      print("interstitial showed: $name");
      ApplovinHelper.ShowInterstitial(name: "INTERSTITIAL_$name");
    }
  }
}

class ActionCounter {
  static void increase(String key) {
    var oldValue = Pref.get(key, 0);
    Pref.set(key, ++oldValue);
  }

  static void increaseAndSetPurchaseAnalyticData(String key) {
    var oldValue = Pref.get(key, 0);
    oldValue++;

    Pref.set(key, oldValue);
    PurchaseHelper.setAnalyticData(key, oldValue);
  }

  static int get(String key) {
    return Pref.get(key, 0);
  }
}

extension BuildContextExt on BuildContext {
  ThemeData get theme => Theme.of(this);

  double heightPercent(double value) =>
      MediaQuery.of(this).size.height * value / 100;
  double widthPercent(double value) =>
      MediaQuery.of(this).size.width * value / 100;

  ShowDialog(
    Widget title,
    Widget content,
  ) {
    showDialog(
        context: this,
        builder: (context) => AlertDialog(
              title: title,
              content: content,
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK!'),
                )
              ],
            ));
  }

  closeActivity() {
    if (Navigator.canPop(this)) {
      Navigator.of(this, rootNavigator: true).pop();
    } else {
      SystemNavigator.pop();
    }
  }
}
