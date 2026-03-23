import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../main.dart'; // Import AuthWrapper

class ProfileSetupScreen extends StatefulWidget {
  final String role; // donor / ngo / volunteer / travel_agency

  const ProfileSetupScreen({super.key, required this.role});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController licenseController = TextEditingController();

  File? _selectedImage;
  
  // The Dusty Rose Theme Color
  final Color themeColor = const Color(0xFFB56F76);

  @override
  void dispose() {
    _pageController.dispose();
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    licenseController.dispose();
    super.dispose();
  }

  /// Calculates the total number of pages based on role
  int get _totalPages {
    if (widget.role == "ngo" || widget.role == "travel_agency") return 5;
    if (widget.role == "volunteer") return 4;
    return 3;
  }

  bool get _isCurrentPageValid {
    if (_currentPage == 0) return true; // Photo is always valid (optional)
    if (_currentPage == 1) return nameController.text.trim().isNotEmpty;
    if (_currentPage == 2) return phoneController.text.trim().isNotEmpty;

    if (widget.role == "ngo" || widget.role == "travel_agency") { 
      if (_currentPage == 3) return addressController.text.trim().isNotEmpty;
      if (_currentPage == 4) return licenseController.text.trim().isNotEmpty;
    } else if (widget.role == "volunteer") {
      if (_currentPage == 3) return licenseController.text.trim().isNotEmpty;
    }

    return true;
  }

  void _onFieldChanged(String value) {
    setState(() {}); // Trigger rebuild to update Next button state
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      FocusScope.of(context).unfocus();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutQuart,
      );
    } else {
      saveProfile();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      FocusScope.of(context).unfocus();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutQuart,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = _buildPages();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        title: Text(
          "${widget.role.toUpperCase().replaceAll('_', ' ')} SETUP",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2),
        ),
        centerTitle: true,
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: _previousPage,
              )
            : null,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthWrapper()),
                (Route<dynamic> route) => false,
              );
            },
            child: Text("Skip", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
          )
        ],
      ),
      body: Stack(
        children: [
          // Background Blobs for styling
          Positioned(
            top: -100, right: -80,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(color: themeColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            ),
          ),
          Positioned(
            bottom: 50, left: -100,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(color: themeColor.withValues(alpha: 0.05), shape: BoxShape.circle),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Custom Progress Indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  child: Row(
                    children: List.generate(
                      _totalPages,
                      (index) => Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          height: 8,
                          decoration: BoxDecoration(
                            color: index <= _currentPage ? themeColor : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Form Content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    children: pages,
                  ),
                ),

                // Bottom Navigation Area
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 20,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade500,
                          elevation: _isCurrentPageValid ? 4 : 0,
                          shadowColor: themeColor.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: _isCurrentPageValid ? _nextPage : null,
                        child: Text(
                          _getButtonText(),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getButtonText() {
    if (_currentPage == 0 && _selectedImage == null) return "SKIP PHOTO";
    if (_currentPage == _totalPages - 1) return "COMPLETE SETUP";
    return "CONTINUE";
  }

  List<Widget> _buildPages() {
    List<Widget> pages = [
      _buildImageStep(),
      _buildNameStep(),
      _buildPhoneStep(),
    ];

    if (widget.role == "ngo" || widget.role == "travel_agency") { 
      pages.add(_buildAddressStep());
      pages.add(_buildLicenseStep());
    } else if (widget.role == "volunteer") {
      pages.add(_buildLicenseStep());
    }

    return pages;
  }

  Widget _buildStepContainer({required String title, required String subtitle, required Widget child, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5)),
                ]
              ),
              child: Icon(icon, size: 50, color: themeColor),
            ),
            const SizedBox(height: 30),
          ],
          Text(
            title,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF2D3142), height: 1.2),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 50),
          child,
        ],
      ),
    );
  }

  Widget _buildImageStep() {
    return _buildStepContainer(
      title: "Add a Photo",
      subtitle: "Help your community recognize you easily",
      child: Center(
        child: GestureDetector(
          onTap: () {
            // TODO: Image Picker Action
          },
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: themeColor.withValues(alpha: 0.2), width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: _selectedImage == null
                    ? Icon(Icons.person_rounded, size: 80, color: Colors.grey.shade300)
                    : const CircleAvatar(
                        radius: 80,
                        backgroundImage: AssetImage('assets/images/user_placeholder.png'), // placeholder
                      ),
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: themeColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(color: themeColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
                  ]
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: _onFieldChanged,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: Colors.grey.shade500),
          hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
          prefixIcon: Icon(icon, color: themeColor, size: 22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
      ),
    );
  }

  Widget _buildNameStep() {
    String label = widget.role == "ngo" ? "NGO Name" : (widget.role == "travel_agency" ? "Agency Name" : "Full Name");
    return _buildStepContainer(
      title: "What's your name?",
      subtitle: "Let us know how to address you",
      icon: Icons.badge_rounded,
      child: _buildTextField(
        controller: nameController,
        label: label,
        hint: "Enter $label",
        icon: Icons.person_outline_rounded,
      ),
    );
  }

  Widget _buildPhoneStep() {
    return _buildStepContainer(
      title: "Phone Number",
      subtitle: "We'll use this to keep your account secure and for contact",
      icon: Icons.phone_android_rounded,
      child: _buildTextField(
        controller: phoneController,
        label: "Phone Number",
        hint: "Enter Mobile Number",
        icon: Icons.phone_outlined,
        keyboardType: TextInputType.phone,
      ),
    );
  }

  Widget _buildAddressStep() {
    return _buildStepContainer(
      title: "Location",
      subtitle: "Where is your base of operations located?",
      icon: Icons.location_on_rounded,
      child: _buildTextField(
        controller: addressController,
        label: "City / Area",
        hint: "Enter city name",
        icon: Icons.home_outlined,
      ),
    );
  }

  Widget _buildLicenseStep() {
    String label = widget.role == "volunteer" ? "Driving License ID" : (widget.role == "travel_agency" ? "Registration No." : "NGO License ID");
    return _buildStepContainer(
      title: "Verification",
      subtitle: "Please provide your $label for trust and verification",
      icon: Icons.verified_user_rounded,
      child: _buildTextField(
        controller: licenseController,
        label: label,
        hint: "Enter $label",
        icon: Icons.credit_card_outlined,
      ),
    );
  }

  void saveProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    await authProvider.updateProfile(
      name: nameController.text.trim().isNotEmpty ? nameController.text.trim() : null,
      phone: phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : null,
      location: (widget.role == "ngo" || widget.role == "travel_agency") && addressController.text.trim().isNotEmpty ? addressController.text.trim() : null,
      license: licenseController.text.trim().isNotEmpty ? licenseController.text.trim() : null,
    );

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (Route<dynamic> route) => false,
      );
    }
  }
}