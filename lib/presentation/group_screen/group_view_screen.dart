import 'package:doctak_app/presentation/groups_module/screens/group_detail_screen.dart';
import 'package:flutter/material.dart';

/// Legacy entry point — routes to the v1 group profile screen.
class GroupViewScreen extends StatelessWidget {
  final String? id;

  const GroupViewScreen(this.id, {super.key});

  @override
  Widget build(BuildContext context) {
    final groupId = id?.trim() ?? '';
    if (groupId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Invalid group')),
      );
    }
    return GroupDetailScreen(groupId: groupId);
  }
}
