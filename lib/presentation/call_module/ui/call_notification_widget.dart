import 'package:flutter/material.dart';

class CallNotificationWidget extends StatelessWidget {
  final String callerName;
  final String callerAvatar;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const CallNotificationWidget({
    Key? key,
    required this.callerName,
    required this.callerAvatar,
    required this.onAccept,
    required this.onReject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Incoming Call Flutter',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: callerAvatar.isNotEmpty
                        ? NetworkImage(callerAvatar)
                        : null,
                    child: callerAvatar.isEmpty
                        ? const Icon(Icons.person, size: 60, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    callerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    onPressed: onReject,
                    icon: Icons.call_end,
                    label: 'Decline',
                    backgroundColor: Colors.red,
                  ),
                  _buildActionButton(
                    onPressed: onAccept,
                    icon: Icons.call,
                    label: 'Accept',
                    backgroundColor: Colors.green,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color backgroundColor,
  }) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            // primary: backgroundColor,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(20),
          ),
          child: Icon(icon, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}