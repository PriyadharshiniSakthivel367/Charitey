import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/firestore_service.dart';
import '../models/ngo_listing_model.dart';
import '../models/donation_model.dart';
import '../models/notification_model.dart';
import '../providers/auth_provider.dart';

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
  final TextEditingController _donationQuantityController = TextEditingController();

  bool _isLoading = false;
  final Color themeColor = const Color(0xFF7D444C); // Dark theme palette configuration

  // Helper variables to track balance mechanics
  int totalNeeded = 0;
  int alreadyFulfilled = 0;
  int remainingNeeded = 0;

  @override
  void initState() {
    super.initState();
    
    // Calculate quantities for products
    totalNeeded = widget.listing.quantity ?? 0;
    alreadyFulfilled = widget.listing.fulfilledQuantity ?? 0;
    remainingNeeded = totalNeeded - alreadyFulfilled;
    if (remainingNeeded < 0) remainingNeeded = 0;

    // Default the donation capability field to full remaining balance for easier user experience
    if (widget.listing.type == 'product') {
      _donationQuantityController.text = remainingNeeded.toString();
    }

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
    _donationQuantityController.dispose();
    super.dispose();
  }

  Future<void> _donate() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false); 
    final user = authProvider.currentUserModel; 
    if (user == null) { 
      ScaffoldMessenger.of(context).showSnackBar( 
        const SnackBar(content: Text('User not found. Please log in again.')) 
      );
      return; 
    }

    String name = _nameController.text.trim(); 
    String location = _locationController.text.trim(); 
    String phone = _phoneController.text.trim(); 
    int inputDonatedAmount = remainingNeeded; // Default whole amount for non-products (food) 

    if (name.isEmpty || location.isEmpty || phone.isEmpty) { 
      ScaffoldMessenger.of(context).showSnackBar( 
        const SnackBar(content: Text('Please fill all fields')) 
      );
      return; 
    }

    // Validation rule block for product partial capabilities
    if (widget.listing.type == 'product') { 
      final inputQty = int.tryParse(_donationQuantityController.text.trim()); 
      if (inputQty == null || inputQty <= 0) { 
        ScaffoldMessenger.of(context).showSnackBar( 
          const SnackBar(content: Text('Please enter a valid donation quantity')) 
        );
        return; 
      }
      if (inputQty > remainingNeeded) { 
        ScaffoldMessenger.of(context).showSnackBar( 
          SnackBar(content: Text('You cannot donate more than remaining items needed ($remainingNeeded)')) 
        );
        return; 
      }
      inputDonatedAmount = inputQty; 
    }

    setState(() { 
      _isLoading = true; 
    });

    try { 
      String newDonationId = FirebaseFirestore.instance.collection('donations').doc().id; 
      String newNotificationId = FirebaseFirestore.instance.collection('notifications').doc().id; 

      // 1. Instantiating Donation record object payload
      DonationModel donation = DonationModel( 
        donationId: newDonationId, 
        listingId: widget.listing.listingId, 
        ngoId: widget.listing.ngoId, 
        donorId: user.uid, 
        donorName: name, 
        donorPhone: phone, 
        donorLocation: location, 
        status: 'pending', 
        createdAt: DateTime.now(), 
        donatedQuantity: inputDonatedAmount, 
      );

      // Extract context metadata parsing for targeted notifications
      String itemName = widget.listing.type == 'food' 
          ? (widget.listing.foodType ?? "Food") 
          : "$inputDonatedAmount ${widget.listing.unit ?? 'Items'} of ${widget.listing.productName ?? 'Products'}"; 

      // 2. Instantiating Alert payload for the NGO
      NotificationModel alertForNGO = NotificationModel( 
        id: newNotificationId, 
        receiverId: widget.listing.ngoId, 
        senderId: user.uid, 
        senderName: name, 
        type: 'donation_offer', 
        title: 'New Donation Offer! 🎉', 
        message: '$name wants to donate $itemName to you. Tap to view details and start chatting.', 
        relatedItemId: newDonationId, 
        createdAt: DateTime.now(), 
      );

      // Instantiating Digital Receipt Alert payload for the Donor
      NotificationModel alertForDonor = NotificationModel( 
        id: FirebaseFirestore.instance.collection('notifications').doc().id, 
        receiverId: user.uid, 
        senderId: widget.listing.ngoId, 
        senderName: widget.listing.ngoName, 
        type: 'donation_offer', 
        title: 'Donation Confirmed! ✅', 
        message: 'Thank you for offering $itemName! Tap to view details and start a chat with the NGO.', 
        relatedItemId: newDonationId, 
        createdAt: DateTime.now(), 
      );

      // Fixed: Prepended the underscore to call your correct class field variable
      await _firestoreService.processDonation( 
        donation: donation, 
        notification: alertForNGO, 
      );

      // Fixed: Prepended the underscore here as well
      await _firestoreService.sendNotification(alertForDonor); 

      if (!mounted) return;

      // SUCCESS ANIMATION DIALOG
      showGeneralDialog( // [cite: 189]
        context: context, // [cite: 190]
        barrierDismissible: false, // [cite: 191]
        barrierColor: Colors.black.withValues(alpha: 0.6), // [cite: 192]
        transitionDuration: const Duration(milliseconds: 500), // [cite: 192]
        pageBuilder: (context, animation, secondaryAnimation) => const SizedBox(), // [cite: 192, 193]
        transitionBuilder: (context, animation, secondaryAnimation, child) { // [cite: 194, 195]
          return ScaleTransition( // [cite: 196]
            scale: Tween<double>(begin: 0.4, end: 1.0).animate( // [cite: 197]
              CurvedAnimation(parent: animation, curve: Curves.elasticOut), // [cite: 198]
            ), // [cite: 199]
            child: FadeTransition( // [cite: 200]
              opacity: animation, // [cite: 201]
              child: AlertDialog( // [cite: 202]
                backgroundColor: Colors.white, // [cite: 203]
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // [cite: 204, 205]
                contentPadding: const EdgeInsets.all(30), // [cite: 206]
                content: Column( // [cite: 207]
                  mainAxisSize: MainAxisSize.min, // [cite: 208]
                  children: [ // [cite: 209]
                    Container( // [cite: 210]
                      padding: const EdgeInsets.all(20), // [cite: 211]
                      decoration: BoxDecoration( // [cite: 212]
                        color: themeColor.withValues(alpha: 0.1), // [cite: 213]
                        shape: BoxShape.circle, // [cite: 214]
                      ),
                      child: Icon(Icons.volunteer_activism_rounded, color: themeColor, size: 60), // [cite: 215, 217]
                    ), // [cite: 216]
                    const SizedBox(height: 24), // [cite: 218]
                    const Text( // [cite: 219]
                      "Donation Confirmed!", // [cite: 220]
                      textAlign: TextAlign.center, // [cite: 221]
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87), // [cite: 222, 223]
                    ),
                    const SizedBox(height: 12), // [cite: 224]
                    Text( // [cite: 225]
                      "Your generosity is making a real difference. An NGO will review this shortly.", // [cite: 226, 227]
                      textAlign: TextAlign.center, // [cite: 228]
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4), // [cite: 229, 230]
                    ), // [cite: 231]
                    const SizedBox(height: 30), // [cite: 232]
                    SizedBox( // [cite: 233]
                      width: double.infinity, // [cite: 234]
                      child: ElevatedButton( // [cite: 235]
                        onPressed: () { // [cite: 236]
                          Navigator.pop(context); // [cite: 238]
                          Navigator.pop(context); // [cite: 239]
                        }, // [cite: 237]
                        style: ElevatedButton.styleFrom( // [cite: 240]
                          backgroundColor: themeColor, // [cite: 241]
                          foregroundColor: Colors.white, // [cite: 243]
                          padding: const EdgeInsets.symmetric(vertical: 16), // [cite: 244]
                          elevation: 0, // [cite: 245]
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // [cite: 246, 247]
                        ),
                        child: const Text("Awesome!", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)), // [cite: 249, 250]
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (e) { // [cite: 255]
      if (!mounted) return; // [cite: 256]
      ScaffoldMessenger.of(context).showSnackBar( // [cite: 257]
        SnackBar(content: Text('Donation failed: ${e.toString().replaceAll('Exception: ', '')}')) // [cite: 257, 258]
      ); // [cite: 259]
    } finally { // [cite: 260]
      if (mounted) { // [cite: 261]
        setState(() { // [cite: 262]
          _isLoading = false; // [cite: 263]
        }); // [cite: 265]
      } // [cite: 264]
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E4E8),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Confirm Donation',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // BACKGROUND GRADIENT
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    themeColor.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // FOREGROUND CONTENT
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 20,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),

                          // --- "RECEIPT" SUMMARY CARD ---
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: themeColor.withValues(alpha: 0.05),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'TARGET NGO',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: themeColor, letterSpacing: 1.0),
                                      ),
                                      Icon(Icons.verified_rounded, size: 16, color: themeColor),
                                    ],
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.listing.ngoName,
                                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              widget.listing.ngoLocation,
                                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 20.0),
                                        child: Divider(height: 1, thickness: 1.5),
                                      ),

                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Item to Donate', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                                              const SizedBox(height: 4),
                                              Text(
                                                widget.listing.type == 'food'
                                                    ? (widget.listing.foodType ?? "Food")
                                                    : (widget.listing.productName ?? "Product"),
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(widget.listing.type == 'food' ? 'Quantity' : 'Total Request', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: themeColor.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  '${widget.listing.quantity ?? ""} ${widget.listing.unit ?? ""}'.trim(),
                                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: themeColor),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      // --- NEW: Product Balance Tracking Visual Sub-block ---
                                      if (widget.listing.type == 'product') ...[
                                        const SizedBox(height: 16),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade50,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.grey.shade200),
                                          ),
                                          child: Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text('Already Received:', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                                  Text('$alreadyFulfilled ${widget.listing.unit ?? ""}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text('Remaining Needed:', style: TextStyle(fontSize: 12, color: themeColor, fontWeight: FontWeight.w600)),
                                                  Text('$remainingNeeded ${widget.listing.unit ?? ""}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: themeColor)),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(10),
                                                child: LinearProgressIndicator(
                                                  value: totalNeeded > 0 ? (alreadyFulfilled / totalNeeded) : 0,
                                                  backgroundColor: Colors.grey.shade200,
                                                  valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                                                  minHeight: 6,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          // --- NEW: USER CAPABILITY QUANTITY INPUT BLOCK (Products Only) ---
                          if (widget.listing.type == 'product') ...[
                            const Text(
                              'Specify Your Donation Quantity',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'How many ${widget.listing.unit ?? "items"} are you able to provide today?',
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                            ),
                            const SizedBox(height: 12),
                            _buildInputField(
                              hint: 'Enter quantity you can give (Max: $remainingNeeded)',
                              icon: Icons.numbers_rounded,
                              controller: _donationQuantityController,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 24),
                          ],

                          // --- FORM HEADER ---
                          const Text(
                            'Your Pickup Details',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Where should the NGO meet you?',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 16),

                          // --- VOLUNTEER ALERT BANNER ---
                          if (widget.listing.isVolunteerAvailable == true) ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.directions_run_rounded, color: Colors.white, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Good News! Volunteer Available",
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "This NGO has a volunteer ready to pick up your donation. Just confirm your address below.",
                                          style: TextStyle(fontSize: 12, color: Colors.green.shade800),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // --- INPUT FIELDS ---
                          _buildInputField(
                            hint: 'Your Full Name',
                            icon: Icons.person_outline_rounded,
                            controller: _nameController,
                          ),
                          const SizedBox(height: 12),

                          _buildInputField(
                            hint: 'Exact Pickup Location',
                            icon: Icons.location_on_outlined,
                            controller: _locationController,
                          ),
                          const SizedBox(height: 12),

                          _buildInputField(
                            hint: 'Contact Phone Number',
                            icon: Icons.phone_outlined,
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                          ),

                          const SizedBox(height: 24),

                          // --- WARM IMPACT NOTE ---
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: themeColor.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: themeColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.favorite_rounded, color: themeColor, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    widget.listing.type == 'food'
                                      ? "Your donation will directly help reduce food waste and feed those in need. Thank you!"
                                      : "Your donation helps fulfill this request piece by piece. Every item makes a big impact!",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),
                          const SizedBox(height: 20),

                          // --- SUBMIT BUTTON ---
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _donate,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeColor,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                elevation: 4,
                                shadowColor: themeColor.withValues(alpha: 0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                  : const Text(
                                      'CONFIRM DONATION',
                                      style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                    ),
                            ),
                          ),

                          // Small security configuration banner footer
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0, bottom: 20.0),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.lock_outline_rounded, size: 12, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Your details are shared securely with the NGO",
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({required String hint, required IconData icon, required TextEditingController controller, TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
          prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}