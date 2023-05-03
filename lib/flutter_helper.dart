library flutter_helper;

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info/package_info.dart';

// mzgs_flutter_helper:
//       path: /Users/mustafa/Developer/Flutter/flutter_helper

bool isApple = Platform.isIOS || Platform.isMacOS;
bool isAndroid = Platform.isAndroid;

late GetStorage getStorage;

class MzgsTest {
  static printText() {
    print("object text 222");
  }
}

class Helper {
  static Future init() async {
    await GetStorage.init();
    getStorage = GetStorage();
  }

  static Color Hex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }

    return Color(int.parse(hexColor, radix: 16));
  }

  static Future<String> getPackageName() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.packageName;
  }

  static void hideKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  static void shareFile(String path, String shareText) {
    Share.shareXFiles([XFile(path)], subject: shareText);
  }

// saveFilePath /image.jpg
  static Future downloadFile(String url, String saveFilePath,
      Function(double) onProgress, Function() onFinished,
      {Function(Object e)? onError}) async {
    Dio dio = Dio();
// Download the file
    var _appDocDir = await getAppDataPath();
    try {
      await dio.download(url, _appDocDir + saveFilePath,
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

  static Future<String> getAppDataPath() async {
    final Directory _appDocDir = await getApplicationDocumentsDirectory();
    return _appDocDir.path;
  }

  static Future<List<FileSystemEntity>> getFiles(
      {String folderPath = ""}) async {
    var appPath = await getAppDataPath();
    Directory directory = Directory("$appPath/$folderPath");
    List<FileSystemEntity> files =
        directory.listSync(recursive: true, followLinks: false);
    return files;
  }

  static List<String> convertDynamicListToStringList(List<dynamic> list) {
    return list.map((item) => item as String).toList();
  }

  static bool isFirstOpen() {
    if (!Pref.get("is_first_open", false)) {
      Pref.set("is_first_open", true);
      return true;
    }
    return false;
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
        padding: EdgeInsets.all(5),
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
        style: TextStyle(
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
      'ERROR',
      message,
      icon: const Icon(Icons.error, color: Colors.white),
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  static void showSuccessToast(String message) {
    Get.snackbar(
      'SUCCESS',
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
              SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  primary: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
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
                SizedBox(height: 16),
              ],
              if (message != null) ...[
                message,
                SizedBox(height: 24),
              ],
              if (buttonLabel != null) ...[
                ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blue,
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

  static void showSuccessDialog(String message, {String title = "Successful"}) {
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
              Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 24),
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

  static void showErrorDialog(String message, {String title = "Error"}) {
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
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 24),
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
}

class DailyCredits {
  static int credits = 0;
  static Init(int maxCredits) {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    credits = Pref.get("credit", maxCredits);
    if (!Pref.get("credit" + today, false)) {
      Pref.set("credit" + today, true);
      Pref.set("credit", maxCredits);
      credits = maxCredits;
    }
  }

  static bool hasCredit() {
    // if (PurchaseHelper.isPremium) {
    //   return true;
    // }
    return credits > 0;
  }

  static consumeCredit() {
    credits--;
    Pref.set("credit", credits);
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
                  child: Text('OK!'),
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

class RemoteConfig {
  // COUNTERS
  static var _counterValues = {};
  static var app = {};

  static Future init(String iosAppID) async {
    var package_name = await Helper.getPackageName();
    if (isApple) {
      package_name = iosAppID;
    }
    app = (await HttpHelper.getJsonFromUrl(
                "https://raw.githubusercontent.com/mzgs/Android-Json-Data/master/data.json"))[
            package_name] ??
        {};
  }

  static get(String key, defaultValue) {
    return app[key] ?? defaultValue;
  }

  static void showInterstitialCounter(String name, {int defaultValue = 3}) {
    _counterValues[name] = _counterValues[name] ?? 0;

    if (++_counterValues[name] % (app[name] ?? defaultValue) == 0) {
      print("interstitial showed: $name");
      // ShowInterstitial(name:  "INTERSTITIAL_" + name);
    }
  }
}
