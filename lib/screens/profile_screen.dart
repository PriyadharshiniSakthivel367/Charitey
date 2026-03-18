import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUserModel;

    if (user == null) {
      return const Center(child: Text('User not found'));
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundImage: user.profileImage.isNotEmpty ? NetworkImage(user.profileImage) : null,
              child: user.profileImage.isEmpty ? const Icon(Icons.person, size: 50) : null,
            ),
            const SizedBox(height: 16),
            
            // Basic Info
            Text(user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(user.email, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            Text('Role: ${user.role.toUpperCase()}', style: const TextStyle(fontSize: 14, color: Colors.blue)),
            
            const SizedBox(height: 30),
            
            // Statistics logic per role
            if (user.role == 'user') ...[
              _buildStatRow('Total Donations', user.donationsCount.toString()),
              // Add NGOs helped stat logic here
            ] else if (user.role == 'ngo') ...[
               _buildStatRow('Donations Received', user.donationsCount.toString()), // You might want a different stat name
               _buildStatRow('Total Posts', user.postsCount.toString()),
            ] else ...[ // Volunteer
               _buildStatRow('Deliveries Completed', '0'), // Replace with actual stat logic
            ],

            const SizedBox(height: 30),
            
            // Tags/Posts area
            const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            // You would populate this with a stream of activity or tagged posts
             const Center(child: Padding(
               padding: EdgeInsets.all(20.0),
               child: Text('No recent activity.'),
             ))
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
