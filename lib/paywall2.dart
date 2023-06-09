import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mzgs_flutter_helper/flutter_helper.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class Paywall2 extends StatefulWidget {
  @override
  _Paywall2State createState() => _Paywall2State();
}

class _Paywall2State extends State<Paywall2> {
  int selectedIndex = 1; // Initially selected item index
  var _isLoading = false;

  StreamSubscription? _purchaseUpdatedSubscription;
  StreamSubscription? _purchaseErrorSubscription;
  IAPItem? selectedItem;

  List<PurchaseItem> purchaseItems = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    initListeners();
    setProducts();
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

    IAPItem weekly = products['weekly']!;
    IAPItem yearly = products['yearly']!;
    selectedItem = yearly;

    setState(() {
      purchaseItems.add(
        PurchaseItem(
          duration: '1 Week',
          price: weekly.localizedPrice!,
          discount: '',
        ),
      );

      var weekToYearPrice = double.parse(weekly.price!) * 48;
      purchaseItems.add(
        PurchaseItem(
          duration: '1 Year',
          price: yearly.localizedPrice!,
          discount: (((weekToYearPrice - double.parse(yearly.price!)) /
                          weekToYearPrice) *
                      100)
                  .toStringAsFixed(0) +
              "% OFF",
        ),
      );
    });
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
    PurchaseHelper.isPremium = true;
    Pref.set("is_premium", true);

    if (mounted) {
      context.closeActivity();
    }
    UI.showSuccessDialog("You are using PREMIUM version of app now".tr,
        title: "Payment successful".tr);

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
        "data": PurchaseHelper.purchaseConfig.analyticData,
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
                            image: AssetImage('assets/p1.jpg'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 30,
                        left: 10,
                        child: IconButton(
                          icon: const Icon(
                            CupertinoIcons.xmark,
                            color: Colors.grey,
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
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          SizedBox(height: 12),
                          Text(
                            'Unlock Premium Content',
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
                                children: [
                                  feature("Remove ads"),
                                  feature("Remove ads"),
                                  feature("Remove ads"),
                                  feature("Unlimited image generation"),
                                ],
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
          Align(
            alignment: Alignment.center,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize:
                    Size(context.widthPercent(70), context.heightPercent(6)),
                backgroundColor: Colors.blue,
              ),
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
                  : Icon(Icons.check, size: context.widthPercent(6)),
              label: Text('CONTINUE',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: context.widthPercent(5))),
              onPressed: _isLoading
                  ? null
                  : () {
                      setState(() {
                        _isLoading = true;
                      });

                      selectedItem = PurchaseHelper
                          .products[selectedIndex == 0 ? "weekly" : "yearly"];

                      FlutterInappPurchase.instance
                          .requestPurchase(selectedItem!.productId!);
                    },
            ),
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
          Icons.check,
          color: Colors.green,
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
          margin: EdgeInsets.symmetric(vertical: 10.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
            side: BorderSide(
              color:
                  isSelected ? Colors.lightBlue.shade300 : Colors.grey.shade200,
              width: isSelected ? 3.0 : 1.5,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24, horizontal: 24),
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
