import 'package:doctak_app/data/models/post_model/post_data_model.dart';
import 'package:flutter/material.dart';



class SharePostBottomDialog extends StatelessWidget {
  SharePostBottomDialog(this.postList, {super.key});
  Post postList;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Share',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage('assets/images/person.png'), // Replace with actual image
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Write something here...',
                      border: InputBorder.none,
                    ),
                    maxLines: 3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(140, 40),
                ),
                child: const Text('Send'),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(140, 40),
                ),
                child: const Text('Share Now'),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          const Divider(),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Send in Messenger',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16.0),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(4, (index) => _buildAvatar()),
            ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildIconColumn(Icons.message, 'Instagram',postList,() async {
              }),
              _buildIconColumn(Icons.group, 'Twitter',postList,() async {
              }),
              _buildIconColumn(Icons.link, 'Copy',postList,(){}),
            ],
          ),
          const SizedBox(height: 10.0),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: AssetImage('assets/images/person.png'), // Replace with actual image
          ),
          SizedBox(height: 8),
          Text('Pakistan Khan', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildIconColumn(IconData icon, String label, Post postList,onTap) {
    return GestureDetector(
      onTap:()=>onTap,
      child: Column(
        children: [
          Icon(icon, size: 30),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}