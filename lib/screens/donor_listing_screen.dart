import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/ngo_listing_model.dart';
import 'donation_page.dart';

class DonorListingScreen extends StatefulWidget {
  const DonorListingScreen({Key? key}) : super(key: key);

  @override
  State<DonorListingScreen> createState() => _DonorListingScreenState();
}

class _DonorListingScreenState extends State<DonorListingScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _filterContext = 'all'; // all, food, product

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter Tabs
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _filterContext == 'all',
                onSelected: (_) => setState(() => _filterContext = 'all'),
              ),
              FilterChip(
                label: const Text('Food'),
                selected: _filterContext == 'food',
                onSelected: (_) => setState(() => _filterContext = 'food'),
              ),
              FilterChip(
                label: const Text('Products'),
                selected: _filterContext == 'product',
                onSelected: (_) => setState(() => _filterContext = 'product'),
              ),
            ],
          ),
        ),
        
        // Listings Stream
        Expanded(
          child: StreamBuilder<List<NgoListingModel>>(
            stream: _firestoreService.getOpenListingsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              
              List<NgoListingModel> listings = snapshot.data ?? [];
              
              // Apply Filter
              if (_filterContext != 'all') {
                listings = listings.where((l) => l.type == _filterContext).toList();
              }

              if (listings.isEmpty) {
                return const Center(child: Text('No active donation requests.'));
              }

              return ListView.builder(
                itemCount: listings.length,
                itemBuilder: (context, index) {
                  final listing = listings[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(listing.type == 'food' 
                          ? '${listing.foodType} - ${listing.quantity} ${listing.unit}'
                          : '${listing.productName}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NGO: ${listing.ngoName}'),
                          Text('Location: ${listing.ngoLocation}'),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      isThreeLine: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DonationPage(listing: listing),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
