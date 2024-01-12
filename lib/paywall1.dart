import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mzgs_flutter_helper/flutter_helper.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:package_info_plus/package_info_plus.dart';

class Paywall1 extends StatefulWidget {
  @override
  _Paywall1State createState() => _Paywall1State();
}

class _Paywall1State extends State<Paywall1> {
  int selectedIndex =
      PurchaseHelper.paywall.selectedIndex; // Initially selected item index
  var _isLoading = false;

  StreamSubscription? _purchaseUpdatedSubscription;
  StreamSubscription? _purchaseErrorSubscription;
  IAPItem? selectedItem;

  List<PurchaseItem> purchaseItems = [];

  List<Widget> features = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    initListeners();
    setProducts();
    setFeatures();
  }

  void setFeatures() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        for (var element in PurchaseHelper.paywall.features) {
          features.add(feature(element));
        }
      });
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _purchaseUpdatedSubscription?.cancel();
    _purchaseErrorSubscription?.cancel();
  }

  void setProducts() {
    Map<String, IAPItem> products = PurchaseHelper.products;

    bool hasLifetime = false;
    for (var item in PurchaseHelper.paywall.items) {
      var p = products[item]!;
      if (p.subscriptionPeriodNumberIOS == "0") {
        hasLifetime = true;
      }
    }

    for (var item in PurchaseHelper.paywall.items) {
      var p = products[item]!;

      var duration = "";
      if (p.subscriptionPeriodUnitIOS == "DAY") {
        duration =
            p.subscriptionPeriodNumberIOS == "0" ? "Lifetime".tr : "1 Week".tr;
      }

      if (p.subscriptionPeriodUnitIOS == "MONTH") {
        duration = "month".trArgs([p.subscriptionPeriodNumberIOS!]);
      }

      if (p.subscriptionPeriodUnitIOS == "YEAR") {
        duration = "1 Year".tr;
      }

      if (p.subscriptionPeriodAndroid == "P1W") {
        duration = "1 Week".tr;
      }
      if (p.subscriptionPeriodAndroid == "P1Y") {
        duration = "1 Year".tr;
      }

      setState(() {
        purchaseItems.add(
          PurchaseItem(
              duration: duration,
              price: p.localizedPrice!,
              discount: p.subscriptionPeriodNumberIOS == "0"
                  ? "off".trArgs(["80"])
                  : (p.subscriptionPeriodUnitIOS == "YEAR" && !hasLifetime)
                      ? "off".trArgs(["84"])
                      : ""),
        );
      });
    }
  }

  void initListeners() {
    _purchaseUpdatedSubscription =
        FlutterInappPurchase.purchaseUpdated.listen((productItem) async {
      // purchase success
      if (productItem?.transactionStateIOS == TransactionState.purchased ||
          productItem?.purchaseStateAndroid == PurchaseState.purchased) {
        List<PurchasedItem>? history =
            await (FlutterInappPurchase.instance.getPurchaseHistory()) ?? [];

        FlutterInappPurchase.instance.finishTransaction(history[0]);

        itemPurchasedSuccess(productItem);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });

    _purchaseErrorSubscription =
        FlutterInappPurchase.purchaseError.listen((purchaseError) {
      print('purchase-error: $purchaseError');
      setState(() {
        _isLoading = false;
      });
    });
  }

  void itemPurchasedSuccess(PurchasedItem? productItem) async {
    PurchaseHelper.setPremium(true);

    if (mounted) {
      context.closeActivity();
    }
    UI.showSuccessDialog("premiumDesc".tr, title: "Payment successful".tr);

    eventBus.fire(EventObject("purchase_success", ""));

    PurchaseHelper.setAnalyticData(
        "installed_hour", Helper.getElapsedTimeInHours());

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String appVersion = packageInfo.version;
    PurchaseHelper.setAnalyticData("version", appVersion);

    try {
      HttpHelper.postRequest("https://apps.mzgs.net/add-payment", {
        "platform": Platform.operatingSystem,
        "date":
            DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now().toUtc()),
        "subscription_id": selectedItem!.productId.toString(),
        "price": selectedItem!.price.toString(),
        "country": Get.deviceLocale?.countryCode ?? "",
        "lang": Get.deviceLocale?.languageCode ?? "",
        "localePrice": selectedItem!.localizedPrice.toString(),
        "package_name": (await Helper.getPackageName()),
        "app_name": (await Helper.getAppName()),
        "data": PurchaseHelper.analyticData,
        "asa": PurchaseHelper.asaData
      });
    } catch (e) {}

    // hideBanner();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        height: context.heightPercent(40),
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(
                                'assets/${PurchaseHelper.paywall.image}'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 40,
                        left: 10,
                        child: IconButton(
                          icon: Icon(
                            CupertinoIcons.xmark,
                            color: PurchaseHelper.paywall.closeColor,
                          ),
                          onPressed: () {
                            context.closeActivity();
                          },
                        ),
                      ),
                    ],
                  ),
                  Transform.translate(
                    offset: Offset(0, -20.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20.0),
                          topRight: Radius.circular(20.0),
                        ),
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        children: [
                          SizedBox(height: 12),
                          Text(
                            PurchaseHelper.paywall.title,
                            style: TextStyle(
                              fontSize: context.isTablet ? 32 : 24.0,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10.0),
                          Center(
                            child: SizedBox(
                              width: context.widthPercent(80),
                              child: Column(
                                children: features,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.all(0),
                            itemCount: purchaseItems.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedIndex = index;
                                  });
                                },
                                child: PurchaseItemCard(
                                  item: purchaseItems[index],
                                  isSelected: selectedIndex == index,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Align(
              alignment: Alignment.center,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    minimumSize: Size.fromHeight(context.heightPercent(6.5)),
                    backgroundColor: PurchaseHelper.paywall.btnColor,
                    foregroundColor: Colors.white),
                icon: _isLoading
                    ? Container(
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(2.0),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Icon(CupertinoIcons.check_mark,
                        size: context.widthPercent(6)),
                label: Text('CONTINUE'.tr,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: context.widthPercent(6))),
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _isLoading = true;
                        });

                        selectedItem = PurchaseHelper.products[
                            PurchaseHelper.productsIds[selectedIndex]];

                        FlutterInappPurchase.instance
                            .requestPurchase(selectedItem!.productId!);
                      },
              ),
            ),
          ),
          SizedBox(height: context.heightPercent(2)), // Add some spacing

          // Three Text Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  Helper.openUrlInWebview(SettingsHelper.termsUrl,
                      title: 'Terms'.tr);
                },
                child: Text(
                  "Terms".tr,
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),
              SizedBox(
                  width:
                      context.widthPercent(5)), // Add spacing between buttons
              TextButton(
                onPressed: () {
                  Helper.openUrlInWebview(SettingsHelper.privacyUrl,
                      title: 'Privacy'.tr);
                },
                child: Text(
                  "Privacy".tr,
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),
              SizedBox(
                  width:
                      context.widthPercent(5)), // Add spacing between buttons
              TextButton(
                onPressed: () {
                  Helper.restorePurchase(closePage: context);
                },
                child: Text(
                  "Restore".tr,
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.heightPercent(6))
        ],
      ),
    );
  }

  Widget feature(String text) {
    return Row(
      children: [
        Icon(
          Icons.check_circle_rounded,
          color: PurchaseHelper.paywall.checkColor,
        ),
        SizedBox(width: 5.0),
        Text(
          text,
          style: TextStyle(fontSize: context.isTablet ? 24 : 16.0),
        ),
      ],
    );
  }
}

class PurchaseItem {
  final String duration;
  final String price;
  final String discount;

  PurchaseItem({
    required this.duration,
    required this.price,
    required this.discount,
  });
}

class PurchaseItemCard extends StatelessWidget {
  final PurchaseItem item;
  final bool isSelected;

  PurchaseItemCard({
    required this.item,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Card(
          margin: EdgeInsets.symmetric(
              vertical: PurchaseHelper.paywall.items.length == 2 ? 10 : 5.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
            side: BorderSide(
              color: isSelected
                  ? PurchaseHelper.paywall.selectedColor
                  : Colors.grey.shade200,
              width: isSelected ? 3.0 : 1.5,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
                vertical: PurchaseHelper.paywall.items.length == 2 ? 24 : 18,
                horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.duration,
                      style: TextStyle(
                        fontSize: context.isTablet ? 26 : 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      item.price,
                      style: TextStyle(
                        fontSize: context.isTablet ? 28 : 16.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        item.discount.isEmpty
            ? SizedBox()
            : Positioned(
                top: 0,
                right: 10.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Text(
                    item.discount,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.isTablet ? 18 : 12.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}
