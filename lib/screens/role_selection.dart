import 'package:flutter/material.dart';
import 'dart:async';
import 'donor_login_screen.dart';
import 'ngo_login_screen.dart';
import 'travel_agency_login_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _carouselTimer;

  // The Dusty Rose Theme Color
  final Color themeColor = const Color(0xFFB56F76);

  final List<String> _donationImages = [
    'https://i.postimg.cc/Wp5Sk0N2/kowsi2.jpg',
    'https://i.postimg.cc/NjkxQXzg/kowsi1.jpg',
    'https://i.postimg.cc/9QQDqqfm/kowsi4.jpg',
    'https://i.postimg.cc/VLY63bnq/kowsi5.jpg',
    'https://i.postimg.cc/qqQkkjyy/kowsi6.jpg',
    'https://i.postimg.cc/qv39w1qY/kowsi7.jpg',
    'https://i.postimg.cc/d1y5TPsW/kowsi9.png',
  ];

  @override
  void initState() {
    super.initState();
    // Full width for the cinematic poster look
    _pageController = PageController(initialPage: 1000, viewportFraction: 1.0);

    _carouselTimer = Timer.periodic(const Duration(milliseconds: 3500), (
      Timer timer,
    ) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 1000),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // --- TOP SECTION: Netflix-Style Hero Image Carousel ---
          Expanded(
            flex: 6, // Takes up 60% of the screen
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. The Auto-Scrolling Images (Crisp and Clear)
                PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final imageIndex = index % _donationImages.length;
                    return Image.network(
                      _donationImages[imageIndex],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(color: Colors.grey.shade200);
                      },
                    );
                  },
                ),

                // 2. Soft, subtle gradient at top ONLY to make the system status bar readable
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Crisp white fade at the very bottom edge
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.white,
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),

                // 4. Page Indicator Dots sitting right above the roles
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_donationImages.length, (index) {
                      int actualIndex = _currentPage % _donationImages.length;
                      bool isActive = actualIndex == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        height: 6.0,
                        width: isActive ? 20.0 : 6.0,
                        decoration: BoxDecoration(
                          color: isActive ? themeColor : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(3.0),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          // --- BOTTOM SECTION: Horizontal Role Selection ---
          Expanded(
            flex: 4, // Takes up the remaining 40%
            child: Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.only(top: 10, bottom: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      'Select your Role to make an Impact',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade800,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Horizontal Row of Professional Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfessionalRoleCard(
                          title: 'Donor',
                          icon: Icons.volunteer_activism_rounded,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DonorLoginScreen(),
                              ),
                            );
                          },
                        ),
                        _buildProfessionalRoleCard(
                          title: 'NGO',
                          icon: Icons.foundation_rounded,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NgoLoginScreen(),
                              ),
                            );
                          },
                        ),
                        _buildProfessionalRoleCard(
                          title: 'Delivery',
                          icon: Icons.airport_shuttle_rounded,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const TravelAgencyLoginScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Professional Card Builder ---
  Widget _buildProfessionalRoleCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 105, // Fixed width so all cards are perfectly uniform
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: themeColor, size: 32),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
