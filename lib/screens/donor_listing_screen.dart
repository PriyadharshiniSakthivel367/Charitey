import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import '../providers/auth_provider.dart'; 
import '../services/firestore_service.dart';
import '../models/ngo_listing_model.dart';
import 'donation_page.dart';

class DonorListingScreen extends StatefulWidget {
  // --- ADDED THIS TO FIX THE ERROR ---
  final String initialSearchQuery;
  
  const DonorListingScreen({Key? key, this.initialSearchQuery = ''}) : super(key: key);

  @override
  State<DonorListingScreen> createState() => _DonorListingScreenState();
}

class _DonorListingScreenState extends State<DonorListingScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _filterContext = 'all'; 
  
  // Controller for the active search bar on this page
  late TextEditingController _searchController;
  String _currentSearchQuery = '';

  final Color themeColor = const Color(0xFFB56F76);

  @override
  void initState() {
    super.initState();
    // Initialize search with what was passed from the Home screen
    _currentSearchQuery = widget.initialSearchQuery;
    _searchController = TextEditingController(text: widget.initialSearchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.currentUserModel?.role;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Browse Requests',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          // --- ACTIVE SEARCH BAR (Lets users change search without going back) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                // Update search instantly as they type
                setState(() {
                  _currentSearchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: "Search requests...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _currentSearchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _currentSearchQuery = '';
                        });
                      },
                    )
                  : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: themeColor),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // --- CUSTOM MODERN FILTER TABS ---
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                Expanded(child: _buildFilterTab('All', 'all')),
                Expanded(child: _buildFilterTab('Food', 'food')),
                Expanded(child: _buildFilterTab('Products', 'product')),
              ],
            ),
          ),
          
          const SizedBox(height: 4),

          // --- LISTINGS STREAM WITH SMART FILTERING ---
          Expanded(
            child: StreamBuilder<List<NgoListingModel>>(
              stream: _firestoreService.getOpenListingsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: themeColor));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.grey.shade600)));
                }
                
                List<NgoListingModel> listings = snapshot.data ?? [];
                
                // 1. Apply Category Filter (All/Food/Product)
                if (_filterContext != 'all') {
                  listings = listings.where((l) => l.type == _filterContext).toList();
                }

                // 2. APPLY SMART SEARCH FILTER
                if (_currentSearchQuery.isNotEmpty) {
                  String query = _currentSearchQuery.toLowerCase();
                  
                  listings = listings.where((listing) {
                    String title = (listing.type == 'food' ? listing.foodType : listing.productName)?.toLowerCase() ?? '';
                    String location = listing.ngoLocation?.toLowerCase() ?? '';
                    String ngoName = listing.ngoName?.toLowerCase() ?? '';
                    String quantity = listing.quantity?.toString() ?? '';
                    String unit = listing.unit?.toLowerCase() ?? '';
                    String fullQuantity = "$quantity $unit".trim();

                    return title.contains(query) || 
                           location.contains(query) || 
                           ngoName.contains(query) || 
                           fullQuantity.contains(query) ||
                           quantity.contains(query); 
                  }).toList();
                }

                // Empty State Design
                if (listings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          _currentSearchQuery.isNotEmpty ? "No matching requests found." : 'No active requests.',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentSearchQuery.isNotEmpty ? "Try a different search term or category." : 'Check back later for new opportunities.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 30),
                  itemCount: listings.length,
                  itemBuilder: (context, index) {
                    final listing = listings[index];
                    return _buildListingCard(listing, userRole);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String title, String value) {
    bool isSelected = _filterContext == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterContext = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? themeColor : Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListingCard(NgoListingModel listing, String? userRole) {
    String title = listing.type == 'food' 
        ? (listing.foodType ?? 'Food Donation') 
        : (listing.productName ?? 'Product Donation');
        
    String quantityBadge = '${listing.quantity ?? ''} ${listing.unit ?? ''}'.trim();
    if (quantityBadge.isEmpty) quantityBadge = '1 Unit'; 
    
    IconData icon = listing.type == 'food' ? Icons.restaurant_rounded : Icons.inventory_2_rounded;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding( 
        padding: const EdgeInsets.all(16.0), 
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.1), 
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Icon(icon, color: themeColor, size: 36)),
            ),
            const SizedBox(width: 16), 
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.15), 
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          quantityBadge,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: themeColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  Text(
                    listing.ngoName ?? 'Unknown NGO', 
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                listing.ngoLocation ?? 'Location unavailable', 
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // --- ROLE-BASED DONATE BUTTON ---
                      if (userRole != 'ngo')
                        SizedBox(
                          height: 32,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DonationPage(listing: listing),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text(
                              'Donate',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}