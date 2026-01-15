// Make sure to import the http package
// Import the crypto package

class PusherConfig {
  static const appId = "1635728";
  static const key = "8c57d1a09617aace9be6";
  static const secret = "f67fbf9db9891a179abb";
  static const cluster = "ap2";
}

//
// Future<PusherChannelsFlutter?> createPusherClient() async {
//   try {
//
//     PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
//
//     pusher?.init(
//         apiKey: PusherConfig.key,
//         cluster: PusherConfig.cluster,
//         useTLS: false,
//         onConnectionStateChange: onConnectionStateChange,
//         onError: onError,
//         onSubscriptionSucceeded: onSubscriptionSucceeded,
//         onEvent: onEvent,
//         onSubscriptionError: onSubscriptionError,
//         onDecryptionFailure: onDecryptionFailure,
//         onMemberAdded: onMemberAdded,
//         onMemberRemoved: onMemberRemoved,
//         onSubscriptionCount: onSubscriptionCount,
//
//
//         onAuthorizer: onAuthorizer
//
//     );
//
//     await pusher.connect();
//     //
//     // // Now you can subscribe to channels and return the pusher instance
//     return pusher;
//   } catch (e) {
//     print("ERROR: $e");
//     return null; // Handle the error as needed
//   }
// }
//
//
// void onConnectionStateChange(String currentState, String previousState) {
//   print("Connection State Changed: $previousState -> $currentState");
//   // You can handle the connection state change here
// }
//
// void onError(String message, int? code, error) {
//   print("WebSocket Error - Message: $message, Code: $code, Error: $error");
//   // You can handle the error as needed, e.g., show an error message to the user
// }
//
// void onSubscriptionSucceeded(String channelName, data) {
//   print("Subscribed to channel: $channelName");
//   // You can handle the subscription success here
// }
//
// void onEvent(PusherEvent event) {
//   print(
//       "Received event '${event.eventName}' on channel '${event.channelName}' with data: ${event.data}");
//   // You can handle the received event data here
// }
//
//
// void onSubscriptionError(String message, error) {
//   print(error);
//   // You can handle the subscription error here
// }
//
// void onDecryptionFailure(String event, String reason) {
//   print("Decryption of event '$event' failed: $reason");
//   // You can handle the decryption failure here
// }
//
// void onMemberAdded(String channelName, PusherMember member) {
//   print("Member added to channel '$channelName': ${member.userId}");
//   // You can handle the member addition here
// }
//
// void onMemberRemoved(String channelName, PusherMember member) {
//   print("Member removed from channel '$channelName': ${member.userId}");
//   // You can handle the member removal here
// }
//
// void onSubscriptionCount(String channelName, int subscriptionCount) {
//   print(
//       "Subscription count changed on channel '$channelName' to $subscriptionCount");
//   // You can handle the subscription count change here
// }
//
// Future<dynamic> onAuthorizer(String channelName, String socketId, dynamic options) async {
//   final Uri uri = Uri.parse(AppData.chatifyUrl + "chat/auth");
//
//   // Build query parameters
//   final Map<String, String> queryParams = {
//     'socket_id': socketId,
//     'channel_name': channelName,
//   };
//
//   final response = await http.post(
//     uri.replace(queryParameters: queryParams),
//     headers: {
//       'Authorization': 'Bearer ' + AppData.userToken!,
//     },
//   );
//
//   if (response.statusCode == 200) {
//     final String data = response.body;
//
//     return jsonDecode(data);
//   } else {
//     throw Exception('Failed to fetch Pusher auth data');
//   }
// }
