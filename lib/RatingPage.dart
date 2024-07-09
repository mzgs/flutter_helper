import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mzgs_flutter_helper/flutter_helper.dart';

class RatingPage extends StatelessWidget {
  final Color backgroundColor;
  final Color btnColor;
  final String rateText;
  final String iosAPpId;
  final Function onPressed;

  RatingPage({
    required this.backgroundColor,
    required this.rateText,
    required this.iosAPpId,
    required this.btnColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 24),
                  Text(
                    'FREE'.tr,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'ONE TIME OFFER'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      height: 1.2,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return Icon(
                        Icons.star,
                        color: index < 5 ? Colors.yellow : Colors.white,
                        size: 32,
                      );
                    }),
                  ),
                  SizedBox(height: 24),
                  Text(
                    rateText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      height: 1.2,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: context.widthPercent(80),
                    child: ElevatedButton(
                      onPressed: () {
                        Helper.rateApp(iosAPpId);
                        onPressed();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: btnColor,
                        padding:
                            EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'Rate'.tr,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  ActionCounter.increase("click_rating_offer_close");

                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
