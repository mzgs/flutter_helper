// convert to en,  tr , fr , es, de, it, ja, ar, ru, zh , pt , hi , ms , ko , id, nl
// copy paste json output. write all in one output

class TranslateHelper {
  static Map<String, Map<String, String>> getHelperTranslations() {
    return {
      "en": {
        "Weekly": "Weekly",
        "Yearly": "Yearly",
        "Settings": "Settings",
        "Remove Limits": "Remove Limits",
        "amazingapp": "Check out this amazing app at",
        "Remaining": "Remaining",
        "Daily Limit": "Daily Limit",
        "Share with Friends": "Share with Friends",
        "Rate Us": "Rate Us",
        "Submit": "Submit",
        "Loading": "Loading...",
        "1 Week": "1 Week",
        "1 Year": "1 Year",
        "month": "%s Month",
        "rate_comment": "If you like this app please rate it",
        "Lifetime": "Lifetime",
        "off": "%s% OFF",
        "Privacy": "Privacy Policy",
        "Terms": "Terms of Use",
        "saved": "Image saved to photos",
        "Download": "Download",
        "Save to Photos": "Save to Photos",
        "Search": "Search",
        "Share": "Share",
        "Save": "Save",
        "Cancel Anytime": "Cancel Anytime",
        "Premium": "Premium",
        "pr1": "Unlock Premium",
        "pr2": "Full Access",
        "pr3": "Try Premium",
        "pr4": "Try Premium Free",
        "pr5": "Unlock Unlimited Access",
        "btn1": "Continue",
        "btn2": "Start Free Trial",
        "btn3": "Start 3 Days Free Trial",
        "Watch ad": "Watch ad",
        "CONTINUE": "CONTINUE",
        "free3": "3 DAYS FREE",
        "No payment now": "No payment now",
        "then": "then",
        "Payment successful": "Payment successful",
        "premiumDesc": "You are using PREMIUM version of app now",
        "Success": "Success",
        "SUCCESS": "SUCCESS",
        "ERROR": "ERROR",
        "Error": "Error",
        "nosubs": "You have no active subscription.",
        "buyPremium": "✓ Buy Premium",
        "Buy Premium": "Buy Premium",
        "ALERT": "ALERT",
        "Restore Purchases": "Restore Purchases",
        "premiumuse": "You are using the premium version of this app."
      },
    };
  }

  static Map<String, Map<String, String>> mergeMaps(
      Map<String, Map<String, String>> map1,
      Map<String, Map<String, String>> map2) {
    Map<String, Map<String, String>> mergedMap = {};

    // Add all entries from map1
    mergedMap.addAll(map1);

    // Merge entries from map2
    map2.forEach((key, value) {
      if (mergedMap.containsKey(key)) {
        // If the key exists in both maps, merge the inner maps
        mergedMap[key]?.addAll(value);
      } else {
        // If the key doesn't exist in the merged map, add it
        mergedMap[key] = value;
      }
    });

    return mergedMap;
  }
}
