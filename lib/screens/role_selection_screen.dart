// lib/screens/role_selection_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'donor_login_screen.dart';
import 'ngo_login_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _bgController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const Color primary = Color(0xFF8C4149);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(
                  math.cos(_bgController.value * 2 * math.pi),
                  math.sin(_bgController.value * 2 * math.pi),
                ),
                end: Alignment(
                  math.cos((_bgController.value + 0.5) * 2 * math.pi),
                  math.sin((_bgController.value + 0.5) * 2 * math.pi),
                ),
                colors: const [
                  Color(0xFF8C4149),
                  Color(0xFF7A3540),
                  Color(0xFFA05060),
                  Color(0xFF8C4149),
                ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: isWide
                  ? _buildWideLayout(context, size)
                  : _buildNarrowLayout(context, size),
            ),
          ),
        ),
      ),
    );
  }

  // ── MOBILE LAYOUT ─────────────────────────────────────────────────────
  Widget _buildNarrowLayout(BuildContext context, Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 90),
            // Title Section
            _buildCenteredTitle(),
            const SizedBox(height: 24),
            // Decorative Line with Heart
            _buildDecorativeLine(),
            const SizedBox(height: 80),

            // ── ROLE CARDS ──────────────────────────────────────────────
            _roleCard(
              title: "Donor",
              icon: Icons.volunteer_activism,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DonorLoginScreen()),
              ),
            ),
            const SizedBox(height: 24),
            _roleCard(
              title: "NGO",
              icon: Icons.home_work_rounded,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NgoLoginScreen()),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── WIDE LAYOUT ───────────────────────────────────────────────────────
  Widget _buildWideLayout(BuildContext context, Size size) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildCenteredTitle(),
              const SizedBox(height: 24),
              _buildDecorativeLine(),
              const SizedBox(height: 56),
              _roleCard(
                title: "Donor",
                icon: Icons.volunteer_activism,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DonorLoginScreen()),
                ),
              ),
              const SizedBox(height: 24),
              _roleCard(
                title: "NGO",
                icon: Icons.home_work_rounded,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NgoLoginScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDecorativeLine() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 75, height: 2, color: const Color(0xffD99AA2)),
        const SizedBox(width: 12),
        const Icon(Icons.favorite, color: Color(0xffD99AA2), size: 20),
        const SizedBox(width: 12),
        Container(width: 75, height: 2, color: const Color(0xffD99AA2)),
      ],
    );
  }

  Widget _buildCenteredTitle() {
    return Column(
      children: [
        Text(
          'WE\nDONATE,',
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontSize: 46,
            height: 1.1, // Tightens the spacing between the two lines
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            shadows: const [
              Shadow(
                blurRadius: 12,
                color: Colors.black26,
                offset: Offset(0, 5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          "Where Kindness finds its\nDestination",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xffF9E9EA),
            fontSize: 21,
            height: 1.3, // Adds a little breathing room to the subtitle lines
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _roleCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 68, // <-- Reduced box height from 78 to 68
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            25,
          ), // <-- Slightly reduced border radius
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Main Icon Container
              Container(
                width: 48, // <-- Reduced from 54
                height: 48, // <-- Reduced from 54
                decoration: const BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24, // <-- Reduced from 28
                ),
              ),
              const SizedBox(width: 16),
              // Text
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22, // <-- Reduced font size from 24 to 22
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
              ),
              // Trailing Arrow Container
              Container(
                width: 34, // <-- Reduced from 38
                height: 34, // <-- Reduced from 38
                decoration: const BoxDecoration(
                  color: Color(0xffF7ECEC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: primary,
                  size: 14, // <-- Reduced from 16
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
