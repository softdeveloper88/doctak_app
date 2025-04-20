// import 'package:doctak_app/core/call_service/callkit_service.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:uuid/uuid.dart';
//
// class CallKitScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter CallKit Demo',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: CallHomePage(),
//     );
//   }
// }
//
// class CallHomePage extends StatefulWidget {
//   @override
//   _CallHomePageState createState() => _CallHomePageState();
// }
//
// class _CallHomePageState extends State<CallHomePage> {
//   final _callKitService = CallKitService();
//   final _uuid = Uuid();
//   RTCVideoRenderer _localRenderer = RTCVideoRenderer();
//
//   @override
//   void initState() {
//     super.initState();
//     _localRenderer.initialize();
//     _callKitService.listenToCallEvents(
//       onAccept: _onAcceptCall,
//       onDecline: _onDeclineCall,
//     );
//   }
//
//   Future<void> _onAcceptCall() async {
//     await _webRTCService.initializeWebRTC();
//     _localRenderer.srcObject = _webRTCService.localStream;
//   }
//
//   void _onDeclineCall() {
//     print("Call declined");
//   }
//
//   void _simulateIncomingCall() {
//     String uuid = _uuid.v4();
//     // _callKitService.displayIncomingCall(
//     //   uuid: uuid,
//     //   callerName: 'John Doe',
//     //   callerId: 'user123',
//     //   hasVideo: true,
//     // );
//   }
//
//   Future<void> _makeCall() async {
//     await _webRTCService.initializeWebRTC();
//     _localRenderer.srcObject = _webRTCService.localStream;
//   }
//
//   @override
//   void dispose() {
//     _localRenderer.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Call Interface')),
//       body: Column(
//         children: [
//           Expanded(
//             child: RTCVideoView(_localRenderer, mirror: true),
//           ),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               ElevatedButton(
//                 onPressed: _makeCall,
//                 child: Text('Make Call'),
//               ),
//               ElevatedButton(
//                 onPressed: _simulateIncomingCall,
//                 child: Text('Simulate Incoming'),
//               ),
//             ],
//           ),
//           SizedBox(height: 20),
//         ],
//       ),
//     );
//   }
// }