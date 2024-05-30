import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mzgs_flutter_helper/flutter_helper.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:storekit2helper/storekit2helper.dart';

class Paywall1 extends StatefulWidget {
  @override
  _Paywall1State createState() => _Paywall1State();
}

class _Paywall1State extends State<Paywall1> {
  int selectedIndex =
      PurchaseHelper.paywall.selectedIndex; // Initially selected item index
  var _isLoading = false;

  // List<PurchaseItem> purchaseItems = [];

  List<Widget> features = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

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

  void itemPurchasedSuccess(
      ProductDetail product, Map<String, dynamic>? transaction) async {
    PurchaseHelper.setPremium(true);

    int transactionId = transaction?["transactionId"] ?? 0;
    int originalTransactionId = transaction?["originalTransactionId"] ?? 0;

    if (mounted) {
      context.closeActivity();
    }
    UI.showSuccessDialog("premiumDesc".tr, title: "Payment successful".tr);

    eventBus.fire(EventObject("purchase_success", ""));

    // if (kDebugMode) {
    //   return;
    // }

    PurchaseHelper.setAnalyticData(
        "installed_hour", Helper.getElapsedTimeInHours());

    PurchaseHelper.setAnalyticData("trial", product.introductoryOffer);

    PurchaseHelper.setAnalyticData("transactionId", transactionId);
    PurchaseHelper.setAnalyticData(
        "originalTransactionId", originalTransactionId);

    try {
      HttpHelper.postRequest("https://apps.mzgs.net/add-payment", {
        "platform": Platform.operatingSystem,
        "date":
            DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now().toUtc()),
        "subscription_id": product.productId.toString(),
        "price": product.price.toString(),
        "country": Get.deviceLocale?.countryCode ?? "",
        "lang": Get.deviceLocale?.languageCode ?? "",
        "localePrice": product.localizedPrice.toString(),
        "package_name": (await Helper.getPackageName()),
        "app_name": (await Helper.getAppName()),
        "data": PurchaseHelper.analyticData,
        "asa": PurchaseHelper.asaData
      });
    } catch (e) {}

    Helper.updateUser(transactionId: transactionId.toString());

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
                      Positioned(
                        top: 40,
                        right: 10,
                        child: TextButton(
                          onPressed: () {
                            Helper.restorePurchase(closePage: context);
                          },
                          child: Text(
                            "Restore",
                            style: TextStyle(
                              color: const Color.fromARGB(255, 202, 202, 202),
                            ),
                          ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          SizedBox(height: 12),
                          Text(
                            RemoteConfig.get("premiumTitle", "pr5")
                                .toString()
                                .tr,
                            style: TextStyle(
                                fontSize: context.isTablet ? 38 : 28.0,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -1),
                            textAlign: TextAlign.left,
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
                            itemCount: PurchaseHelper.products.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedIndex = index;
                                  });
                                },
                                child: PurchaseItemCard(
                                  item: PurchaseHelper.products[index],
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
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _isLoading = true;
                          });

                          var selectedProduct =
                              PurchaseHelper.products[selectedIndex];

                          Storekit2Helper.buyProduct(selectedProduct.productId,
                              (success, transaction, errorMessage) {
                            if (success) {
                              itemPurchasedSuccess(
                                  selectedProduct, transaction);
                            } else {
                              if (mounted) {
                                setState(() {
                                  _isLoading = false;
                                });
                              }
                            }
                          });
                        },
                  child: Container(
                    width: double.infinity,
                    height: context.heightPercent(6.5),
                    decoration: BoxDecoration(
                      color: PurchaseHelper.paywall.btnColor,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Center(
                      child: _isLoading
                          ? Container(
                              width: 24,
                              height: 24,
                              padding: const EdgeInsets.all(2.0),
                              child: const CupertinoActivityIndicator(
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              (PurchaseHelper.products[selectedIndex].isTrial
                                      ? RemoteConfig.get(
                                          "buttonTextTrial", "btn2")
                                      : RemoteConfig.get("buttonText", "btn1"))
                                  .toString()
                                  .tr,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: context.widthPercent(5)),
                            ),
                    ),
                  ),
                )),
          ),
          SizedBox(height: 10),

          // Three Text Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () {
                      Helper.openUrlInWebview(SettingsHelper.termsUrl,
                          title: 'Terms'.tr);
                    },
                    child: Text(
                      "Terms",
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Text('|', style: TextStyle(color: Colors.grey)),
                  TextButton(
                    onPressed: () {
                      Helper.openUrlInWebview(SettingsHelper.privacyUrl,
                          title: 'Privacy'.tr);
                    },
                    child: Text(
                      "Privacy",
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text(
                  "Cancel Anytime",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
          SizedBox(height: context.heightPercent(3))
        ],
      ),
    );
  }

  Widget feature(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          CupertinoIcons.check_mark_circled_solid,
          color: PurchaseHelper.paywall.checkColor,
          size: context.isTablet ? 28.0 : 20.0,
        ),
        SizedBox(width: 10.0),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: context.isTablet ? 24 : 16.0,
              fontWeight: FontWeight.w500,
              color: CupertinoColors.black,
            ),
          ),
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
  final ProductDetail item;
  final bool isSelected;

  PurchaseItemCard({
    required this.item,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
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
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.isTrial ? "free3".tr : item.periodTitle.tr,
                          style: TextStyle(
                              fontSize: context.isTablet ? 28 : 20.0,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.5),
                        ),
                        Text(
                          item.isTrial
                              ? "${"then".tr} ${item.localizedPrice} / ${item.periodTitle.tr}"
                              : item.localizedPrice,
                          style: TextStyle(
                            fontSize: context.isTablet
                                ? item.isTrial
                                    ? 24
                                    : 28
                                : item.isTrial
                                    ? 14
                                    : 16.0,
                          ),
                        ),
                      ],
                    ),
                    if (item.periodTitle == "Yearly")
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 4.0),
                        child: Text(
                          "off".trArgs(["70"]),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.isTablet ? 18 : 12.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          )),
      Positioned(
        right: 0,
        top: 8,
        child: item.isTrial
            ? Container(
                decoration: BoxDecoration(
                  color: Color(0xFF10A37F),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.checkmark_shield_fill,
                      color: Colors.white,
                      size: context.isTablet ? 26 : 18,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "No payment now".tr,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: context.isTablet ? 18 : 13.0,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )
            : SizedBox(),
      )
    ]);
  }
}
