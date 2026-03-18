import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/volunteer_request_model.dart';
import '../providers/auth_provider.dart';

class VolunteerDashboard extends StatefulWidget {
  const VolunteerDashboard({Key? key}) : super(key: key);

  @override
  State<VolunteerDashboard> createState() => _VolunteerDashboardState();
}

class _VolunteerDashboardState extends State<VolunteerDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<VolunteerRequestModel>> _getPendingRequests() {
    return _firestore
        .collection('volunteer_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VolunteerRequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  void _acceptRequest(String requestId) async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUserModel;
    if (user == null) return;

    try {
      await _firestore.collection('volunteer_requests').doc(requestId).update({
        'status': 'accepted',
        'assignedVolunteer': user.uid,
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request Accepted!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<VolunteerRequestModel>>(
        stream: _getPendingRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(child: Text('Error: ${snapshot.error}'));
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return const Center(child: Text('No pending pickup requests.'));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('Pickup Request'),
                  subtitle: Text('NGO ID: ${request.ngoId}\nStatus: ${request.status}'),
                  trailing: ElevatedButton(
                    onPressed: () => _acceptRequest(request.requestId),
                    child: const Text('Accept'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
