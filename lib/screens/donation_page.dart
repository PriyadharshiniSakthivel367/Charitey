//donation_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/firestore_service.dart';
import '../models/ngo_listing_model.dart';
import '../models/donation_model.dart';
import '../models/notification_model.dart';
import '../providers/auth_provider.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart';

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
  final Color themeColor = const Color(0xFF7D444C); 

  int totalNeeded = 0;
  int alreadyFulfilled = 0;
  int remainingNeeded = 0;
  
  // NEW: Variable to track the interactive slider
  double _sliderValue = 0.0; 

  @override
  void initState() {
    super.initState();
    // Load bird image and rebuild slider when ready
    BirdImageCache().load().then((_) {
      if (mounted) setState(() {});
    });
    totalNeeded = widget.listing.quantity ?? 0;
    alreadyFulfilled = widget.listing.fulfilledQuantity ?? 0;
    remainingNeeded = totalNeeded - alreadyFulfilled;
    if (remainingNeeded < 0) remainingNeeded = 0;

    if (widget.listing.type == 'product') {
      _donationQuantityController.text = remainingNeeded.toString();
      _sliderValue = remainingNeeded.toDouble(); // Set initial slider value
    }

    // NEW: Add listener to sync typing with the slider
    _donationQuantityController.addListener(_updateSliderFromText);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUserModel;
      if (user != null) {
        _nameController.text = user.name;
        _locationController.text = user.location;
        _phoneController.text = user.phone;
      }
    });
  }

  // NEW: Sync function for the slider
  void _updateSliderFromText() {
    if (_donationQuantityController.text.isEmpty) {
      setState(() => _sliderValue = 0.0);
      return;
    }
    double? val = double.tryParse(_donationQuantityController.text);
    if (val != null) {
      if (val > remainingNeeded) val = remainingNeeded.toDouble();
      if (val < 0) val = 0.0;
      setState(() => _sliderValue = val!);
    }
  }

  @override
  void dispose() {
    _donationQuantityController.removeListener(_updateSliderFromText);
    _nameController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _donationQuantityController.dispose();
    super.dispose();
  }

  Future<void> donate() async {
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
    int inputDonatedAmount = remainingNeeded; 

    if (name.isEmpty || location.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields'))
      );
      return;
    }

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

      String itemName = widget.listing.type == 'food'
          ? (widget.listing.foodType ?? "Food")
          : "$inputDonatedAmount ${widget.listing.unit ?? 'Items'} of ${widget.listing.productName ?? 'Products'}";

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
        isRead: false,
      );

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
        isRead: false,
      );

      // Backend transaction
      await _firestoreService.processDonation(
        donation: donation,
        notification: alertForNGO,
      );

      // Force the quantity field so ProfileScreen can read it
      await FirebaseFirestore.instance.collection('donations').doc(newDonationId).update({
        'quantity': inputDonatedAmount,
      });

      await _firestoreService.sendNotification(alertForDonor);

      if (!mounted) return;

      showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.6),
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) => const SizedBox(),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return ScaleTransition(
            scale: Tween<double>(begin: 0.4, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.elasticOut),
            ),
            child: FadeTransition(
              opacity: animation,
              child: AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                contentPadding: const EdgeInsets.all(30),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.volunteer_activism_rounded, color: themeColor, size: 60),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Donation Confirmed! ✅",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Your generosity is making a real difference. An NGO will review this shortly.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text("Awesome!", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Donation failed: ${e.toString().replaceAll('Exception: ', '')}'))
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildInputField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
                  colors: [themeColor.withOpacity(0.12), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 20),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          
                          // --- "RECEIPT" SUMMARY CARD
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
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
                                    color: themeColor.withOpacity(0.05),
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
                                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                              Text(
                                                widget.listing.type == 'food' ? 'Quantity' : 'Total Request',
                                                style: TextStyle(fontSize: 13, color: Colors.grey.shade500)
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: themeColor.withOpacity(0.1),
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

                          // --- NEW: INTERACTIVE SLIDER SECTION
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
                              hint: 'Enter quantity (Max: $remainingNeeded)',
                              icon: Icons.numbers_rounded,
                              controller: _donationQuantityController,
                              keyboardType: TextInputType.number,
                            ),
                            
                            const SizedBox(height: 8),
                    // The Interactive Slider with Bird Thumb
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: themeColor,
                inactiveTrackColor: themeColor.withOpacity(0.2),
                thumbColor: themeColor,
                overlayColor: themeColor.withOpacity(0.1),
                trackHeight: 8.0,
                thumbShape: BirdSliderThumb(
                  thumbRadius: 20.0,
                  thumbColor: themeColor,
                ),
              ),
              child: Slider(
                value: _sliderValue,
                min: 0,
                max: remainingNeeded > 0 ? remainingNeeded.toDouble() : 1.0,
                divisions: remainingNeeded > 0 ? remainingNeeded : 1,
                onChanged: remainingNeeded > 0 ? (value) {
                  setState(() {
                    _sliderValue = value;
                    _donationQuantityController.value = TextEditingValue(
                      text: value.toInt().toString(),
                      selection: TextSelection.collapsed(
                          offset: value.toInt().toString().length),
                    );
                  });
                } : null,
              ),
            ),
                            
                            const SizedBox(height: 24),
                          ],

                          // --- FORM HEADER
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

                          // --- VOLUNTEER ALERT BANNER
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
                                          widget.listing.type == 'product'
                                              ? "This NGO has a volunteer ready to pick up your donation. Since they are coming to you, please consider donating as many items as possible! Just confirm your address below."
                                              : "This NGO has a volunteer ready to pick up your donation. Just confirm your address below.",
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

                          // --- INPUT FIELDS
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

                          // --- WARM IMPACT NOTE
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: themeColor.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: themeColor.withOpacity(0.1),
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
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const Spacer(),
                          const SizedBox(height: 20),

                          // --- SUBMIT BUTTON
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : donate,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeColor,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                elevation: 4,
                                shadowColor: themeColor.withOpacity(0.4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                  : const Text(
                                      'CONFIRM DONATION',
                                      style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                    ),
                            ),
                          ),

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
}

// ============================================================
// BIRD IMAGE LOADER — loads once, notifies listeners when ready
// ============================================================
class BirdImageCache extends ChangeNotifier {
  static final BirdImageCache _instance = BirdImageCache._internal();
  factory BirdImageCache() => _instance;
  BirdImageCache._internal();

  ui.Image? image;
  bool _isLoading = false;

  Future<void> load() async {
    if (image != null || _isLoading) return;
    _isLoading = true;
    try {
      final ByteData data =
          await rootBundle.load('assets/charitey_bird.png');
      final Uint8List bytes = data.buffer.asUint8List();
      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(bytes, completer.complete);
      image = await completer.future;
      notifyListeners(); // ← triggers rebuild when image is ready
    } catch (e) {
      debugPrint('Bird image load error: $e');
    }
    _isLoading = false;
  }
}

// ============================================================
// BIRD THUMB SHAPE
// ============================================================
class BirdSliderThumb extends SliderComponentShape {
  final double thumbRadius;
  final Color thumbColor;

  const BirdSliderThumb({
    required this.thumbRadius,
    required this.thumbColor,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    final double size = thumbRadius * 5;
    final ui.Image? img = BirdImageCache().image;

    if (img != null) {
      final Paint paint = Paint()
        ..colorFilter = ColorFilter.mode(thumbColor, BlendMode.srcIn);

      final Rect srcRect = Rect.fromLTWH(
        0, 0,
        img.width.toDouble(),
        img.height.toDouble(),
      );
      final Rect dstRect = Rect.fromCenter(
        center: center,
        width: size,
        height: size,
      );
      canvas.drawImageRect(img, srcRect, dstRect, paint);
    } else {
      // Fallback circle only on very first frame before image loads
      final Paint fallback = Paint()..color = thumbColor;
      canvas.drawCircle(center, thumbRadius, fallback);
    }
  }
}