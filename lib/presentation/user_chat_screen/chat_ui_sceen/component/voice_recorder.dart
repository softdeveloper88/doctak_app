import 'package:flutter/material.dart';

class VoiceRecorderField extends StatelessWidget {
  const VoiceRecorderField({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Icon(
                  Icons.mic,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "0:00",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black, // Adjust color as needed
                ),
              ),
            ],
          ),
          Text(
            "◀ Slide to cancel",
            style: TextStyle(
              fontSize: 16,
              color: Colors.black, // Adjust color as needed
            ),
          ),
        ],
      ),
    );
  }
}

class VoiceRecorder extends StatelessWidget {
  const VoiceRecorder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white, // Adjust color as needed
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Include your RecordingVisualiser widget here
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  // Handle delete action
                },
                child: const Icon(
                  Icons.delete,
                  size: 36,
                ),
              ),
              InkWell(
                onTap: () {
                  // Handle pause/resume action
                },
                child: const Icon(
                  Icons.mic,
                  color: Colors.red,
                  size: 30,
                ),
              ),
              InkWell(
                onTap: () {
                  // Handle send action
                },
                child: CircleAvatar(
                  radius: 21,
                  backgroundColor: Colors.green, // Adjust color as needed
                  child: const Icon(
                    Icons.send,
                    color: Colors.white,
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
