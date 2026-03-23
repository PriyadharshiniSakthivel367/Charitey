import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'create_listing_screen.dart';

class NgoDashboard extends StatefulWidget {
  const NgoDashboard({super.key});

  @override
  State<NgoDashboard> createState() => _NgoDashboardState();
}

class _NgoDashboardState extends State<NgoDashboard> {
  // The Dusty Rose Theme Color
  final Color themeColor = const Color(0xFFB56F76);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUserModel;

    if (user == null) {
      return Center(child: CircularProgressIndicator(color: themeColor));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ]
              ),
              child: Icon(Icons.photo_library_outlined, size: 60, color: Colors.grey.shade300),
            ),
            const SizedBox(height: 24),
            const Text(
              "Impact Gallery",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Text(
              "Photos of completed donations\nwill appear here.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade500, height: 1.4),
            ),
          ],
        ),
      ),
      
      // --- Themed Floating Action Button ---
      floatingActionButton: FloatingActionButton(
        backgroundColor: themeColor,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateListingScreen(),
            ),
          );
        },
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}