import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../models/ngo_listing_model.dart';
import '../models/donation_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class DonationPage extends StatefulWidget {
  final NgoListingModel listing;

  const DonationPage({Key? key, required this.listing}) : super(key: key);

  @override
  State<DonationPage> createState() => _DonationPageState();
}

class _DonationPageState extends State<DonationPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill user data if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUserModel;
      if (user != null) {
        _nameController.text = user.name;
        _locationController.text = user.location;
        _phoneController.text = user.phone;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _donate() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUserModel;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not found. Please log in again.')));
      return;
    }

    String name = _nameController.text.trim();
    String location = _locationController.text.trim();
    String phone = _phoneController.text.trim();

    if (name.isEmpty || location.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      DonationModel donation = DonationModel(
        donationId: FirebaseFirestore.instance.collection('donations').doc().id, // Generate ID
        listingId: widget.listing.listingId,
        ngoId: widget.listing.ngoId,
        donorId: user.uid,
        donorName: name,
        donorPhone: phone,
        donorLocation: location,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await _firestoreService.processDonation(donation);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Donation successful! Thank you.')));
      Navigator.pop(context); // Go back to listings
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Donation failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donate Now')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Listing Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            // Pre-filled Info Container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NGO: ${widget.listing.ngoName}', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 5),
                  Text('Location: ${widget.listing.ngoLocation}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text('Type: ${widget.listing.type.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (widget.listing.type == 'food') ...[
                    Text('Item: ${widget.listing.foodType ?? ""}'),
                    Text('Quantity: ${widget.listing.quantity} ${widget.listing.unit}'),
                  ] else ...[
                    Text('Category: ${widget.listing.category ?? ""}'),
                    Text('Item: ${widget.listing.productName ?? ""}'),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            const Text('Your Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            CustomTextField(
              controller: _nameController,
              hintText: 'Your Name',
            ),
            CustomTextField(
              controller: _locationController,
              hintText: 'Pickup Location',
            ),
            CustomTextField(
              controller: _phoneController,
              hintText: 'Phone Number',
              keyboardType: TextInputType.phone,
            ),
            
            const SizedBox(height: 30),
            CustomButton(
              text: 'Confirm Donation',
              isLoading: _isLoading,
              onPressed: _donate,
            ),
          ],
        ),
      ),
    );
  }
}
