import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

import 'package:get/get.dart';
import 'package:mzgs_flutter_helper/flutter_helper.dart';

const MONTHLY_ID = "repost_monthly";
const MONTH6_ID = "repost_month6";
const YEARLY_ID = "repost_yearly";

const mainColor = Color.fromARGB(255, 192, 0, 154);
const textColor = Color.fromARGB(255, 30, 50, 79);
var pageBgGradientColors = [
  Color.fromARGB(255, 235, 200, 236),
  Color.fromARGB(255, 226, 83, 239)
];

List<Map<String, dynamic>> _cardData = [];
var products = Get.arguments['products'];
SubscriptionWidget? subscriptionWidget = null;

class PurchasePage extends StatefulWidget {
  const PurchasePage({Key? key}) : super(key: key);

  @override
  _PurchasePageState createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  @override
  void initState() {
    super.initState();
    setProducts();
  }

  void setProducts() {
    _cardData = [];

    IAPItem montly = products['monthly'];
    IAPItem yearly = products['yearly'];
    IAPItem month6 = products['month6'];

    _cardData.add({
      'months': '12',
      'monthName': 'months',
      'topTitle': 'BEST VALUE',
      'price': yearly.localizedPrice,
      'discount':
          (double.parse(montly.price!) * 12 - double.parse(yearly.price!)) /
              (double.parse(montly.price!) * 12) *
              100
    });

    _cardData.add({
      'months': '6',
      'monthName': 'months',
      'topTitle': '⭐MOST POPULAR',
      'price': month6.localizedPrice,
      'discount':
          (double.parse(montly.price!) * 6 - double.parse(month6.price!)) /
              (double.parse(montly.price!) * 6) *
              100
    });

    _cardData.add({
      'months': '1',
      'monthName': 'month',
      'topTitle': '',
      'price': montly.localizedPrice,
      'discount': 0.0
    });

    setState(() {
      subscriptionWidget = SubscriptionWidget();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: pageBgGradientColors),
            ),
            child: SubscriptionWidget()));
  }
}

// SubscriptionWidget

class SubscriptionWidget extends StatefulWidget {
  @override
  _SubscriptionWidgetState createState() => _SubscriptionWidgetState();
}

class _SubscriptionWidgetState extends State<SubscriptionWidget> {
  int _selectedIndex = 1;
  List<Widget> cards = [];

  var _isLoading = false;

  @override
  void initState() {
    super.initState();

    initListeners();
  }

  StreamSubscription? _purchaseUpdatedSubscription = null;
  StreamSubscription? _purchaseErrorSubscription = null;

  void initListeners() {
    StreamSubscription _purchaseUpdatedSubscription =
        FlutterInappPurchase.purchaseUpdated.listen((productItem) async {
      // purchase success
      if (productItem?.transactionStateIOS == TransactionState.purchased ||
          productItem?.purchaseStateAndroid == PurchaseState.purchased) {
        List<PurchasedItem>? history =
            await (FlutterInappPurchase.instance.getPurchaseHistory()) ?? [];

        FlutterInappPurchase.instance.finishTransaction(history[0]);

        itemPurchasedSuccess(productItem);
      }

      setState(() {
        _isLoading = false;
      });
    });

    _purchaseErrorSubscription =
        FlutterInappPurchase.purchaseError.listen((purchaseError) {
      print('purchase-error: $purchaseError');
      setState(() {
        _isLoading = false;

        _purchaseUpdatedSubscription.cancel();
        _purchaseErrorSubscription?.cancel();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/appicon.png',
            fit: BoxFit.cover,
            width: context.heightPercent(20),
          ),
          SizedBox(height: context.heightPercent(2)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Premium',
                textAlign: TextAlign.left,
                style: TextStyle(
                    fontSize: context.width * 0.075,
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontWeight: FontWeight.w700),
              ),
              Text(
                '✓ No ads\n✓ Unlimited Repost\n✓ Unlimited save for later\n✓ stories - igtv - reels - posts',
                textAlign: TextAlign.left,
                style: TextStyle(
                    fontSize: context.widthPercent(context.isTablet ? 3 : 4.5),
                    color: textColor,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          SizedBox(height: context.heightPercent(2)),
          Container(
            padding: EdgeInsets.all(20),
            height: context.heightPercent(27),
            child: Row(
              children: _cardData
                  .asMap()
                  .map(
                    (index, data) => MapEntry(
                      index,
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                          child: buildCard(data, index),
                        ),
                      ),
                    ),
                  )
                  .values
                  .toList(),
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize:
                  Size(context.widthPercent(55), context.heightPercent(6)),
              backgroundColor: mainColor,
            ),
            onPressed: _isLoading
                ? null
                : () {
                    setState(() {
                      _isLoading = true;
                    });

                    var mapKey = "monthly";
                    if (_selectedIndex == 0) {
                      mapKey = "yearly";
                    }
                    if (_selectedIndex == 1) {
                      mapKey = "month6";
                    }

                    // analytics.logEvent(name: "purchase_page_continue");

                    FlutterInappPurchase.instance
                        .requestPurchase(products[mapKey].productId);
                  },
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
                    fontSize: context.width * 0.05)),
          ),
          SizedBox(height: context.heightPercent(1)),
          TextButton(
            child: Text(
              'NO THANKS',
              style: TextStyle(
                  color: Color.fromARGB(255, 65, 64, 64),
                  fontSize: context.widthPercent(context.isTablet ? 2.5 : 3.6)),
            ),
            onPressed: () {
              // analytics.logEvent(name: "purchase_page_no_thanks");

              context.closeActivity();
            },
          ),
        ],
      ),
    );
  }

  Widget buildCard(Map<String, dynamic> data, int index) {
    final bool isSelected = index == _selectedIndex;

    return Container(
      margin: EdgeInsets.only(right: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
            color: index == _selectedIndex
                ? mainColor
                : Color.fromARGB(255, 174, 173, 173),
            width: index == _selectedIndex ? 5 : 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(data['topTitle'],
              style: TextStyle(fontSize: context.width * 0.025)),
          Text(
            data['months'],
            style: TextStyle(
              fontSize: context.width * 0.1,
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            data['monthName'],
            style: TextStyle(color: textColor, fontSize: context.width * 0.03),
          ),
          Text(
            data['discount'] != 0
                ? "SAVE ${(data['discount'] as double).toStringAsFixed(0)}%"
                : "",
            style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: context.width * 0.032),
          ),
          Text(
            data['price'],
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: textColor,
                fontSize: context.width * 0.04),
          ),
        ],
      ),
    );
  }

  void itemPurchasedSuccess(PurchasedItem? productItem) {
    context.closeActivity();

    PurchaseHelper.isPremium = true;

    UI.showSuccessDialog("You are using PREMIUM version of app now.",
        title: "Payment successful");

    // hideBanner();
  }
}

class PurchaseProduct {
  final String id;
  final String topTitle;
  final int months;
  final String price;
  final double discount;

  PurchaseProduct(
      this.id, this.topTitle, this.months, this.price, this.discount);
}
