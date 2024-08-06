// import 'package:doctak_app/core/utils/app/AppData.dart';
// import 'package:pusher_client/pusher_client.dart';
// class PusherService {
//   late PusherClient pusher;
//   late Channel channel;
//   PusherService(String userId) {
//     try {
//       PusherOptions options = PusherOptions(
//         host:'doctak.net',
//         cluster: 'ap2',
//         encrypted: true,
//       );
//
//       pusher = PusherClient(
//         '8c57d1a09617aace9be6',
//         options,
//         autoConnect: false,
//       );
//       pusher.onConnectionStateChange((state) {
//         print("previousState: ${state!.previousState}, currentState: ${state
//             .currentState}");
//       });
//
//       pusher.onConnectionError((error) {
//         print("error: ${error!.message}");
//       });
//
//       connect(userId);
//     }catch(e){
//       print(e);
//     }
//   }
//
//   void connect(String userId) {
//     pusher.connect();
//     channel = pusher.subscribe('user.$userId');
//
//     // Bind to the event name, not the fully qualified class name
//     channel.bind('NotificationEvent', (PusherEvent? event) {
//       print(event!.data);
//       // Handle the notification here
//     });
//   }
//
//   void disconnect() {
//     pusher.unsubscribe('user.${AppData.logInUserId}');
//     pusher.disconnect();
//   }
// }
