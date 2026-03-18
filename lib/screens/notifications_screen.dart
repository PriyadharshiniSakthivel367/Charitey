import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // In a real app, this would use a StreamBuilder to fetch notifications from Firestore subcollection 'notifications'
    
    return const Scaffold(
      body: Center(
        child: Text('No new notifications.'),
      ),
    );
  }
}
