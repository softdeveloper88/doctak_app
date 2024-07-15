import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:share_plus/share_plus.dart';

createDynamicLink(postTitle, postUrl, imageUrl) async {
  final dynamicLinkParams = DynamicLinkParameters(
    link: Uri.parse(postUrl),
   navigationInfoParameters: const NavigationInfoParameters(
     forcedRedirectEnabled: true
   ),
    uriPrefix: "https://doctak.page.link",
    androidParameters:  AndroidParameters(
      packageName: "com.kt.doctak",
      fallbackUrl:Uri.parse(postUrl),
      minimumVersion: 41,
    ),
    iosParameters:  IOSParameters(
      bundleId: "com.doctak.ios",
      appStoreId: "6448684340",
      minimumVersion: "2.0.8",
      fallbackUrl:Uri.parse(postUrl),
    ),
    // googleAnalyticsParameters: const GoogleAnalyticsParameters(
    //   source: "twitter",
    //   medium: "social",
    //   campaign: "example-promo",
    // ),
    socialMetaTagParameters: SocialMetaTagParameters(
      title: postTitle,
      imageUrl: Uri.parse(imageUrl),
    ),
  );
  final dynamicLink =
  await FirebaseDynamicLinks.instance.buildShortLink(dynamicLinkParams);
  Share.share(dynamicLink.shortUrl.toString());
}
