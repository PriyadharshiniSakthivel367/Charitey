// lib/screens/role_selection_screen.dart
import 'package:flutter/material.dart';
import 'donor_login_screen.dart';
import 'ngo_login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  static const Color primary = Color(0xFF8C4149);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      body: Stack(
        children: [
          // ── BACKGROUND IMAGE ──────────────────────────────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/image.png',
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: isWide
                ? _buildWideLayout(context, size)
                : _buildNarrowLayout(context, size),
          ),
        ],
      ),
    );
  }

  // ── MOBILE LAYOUT ─────────────────────────────────────────────────────
  Widget _buildNarrowLayout(BuildContext context, Size size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: size.height * 0.06),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'WE DONATE,\n',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: primary,
                    letterSpacing: 3.5,
                    height: 1.25,
                    shadows: const [
                      Shadow(
                        color: Color(0x44000000),
                        offset: Offset(0, 3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                TextSpan(
                  text: 'Where Kindness\nfinds its Destination',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: primary.withValues(alpha: 0.85),
                    letterSpacing: 1.2,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                    shadows: const [
                      Shadow(
                        color: Color(0x33000000),
                        offset: Offset(0, 2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── MASCOT ──────────────────────────────────────────────────────
        Expanded(
          child: Align(
            alignment: const Alignment(0, 0.0),
            child: Image.asset(
              'assets/mascot.png',
              width: size.width * 0.55,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.person_outline_rounded,
                size: 150,
                color: primary.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),

        // ── BUTTONS ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50),
          child: _stackedRoleButtons(context),
        ),
        SizedBox(height: size.height * 0.05),
      ],
    );
  }

  // ── WIDE LAYOUT ───────────────────────────────────────────────────────
  Widget _buildWideLayout(BuildContext context, Size size) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.only(left: 32, bottom: 32),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Image.asset(
                'assets/mascot.png',
                width: size.width * 0.38,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.person_outline_rounded,
                  size: 160,
                  color: primary.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'WE DONATE,\n',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: primary,
                              letterSpacing: 3.5,
                              height: 1.25,
                            ),
                          ),
                          TextSpan(
                            text: 'Where Kindness\nfinds its Destination',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: primary.withValues(alpha: 0.85),
                              letterSpacing: 1.2,
                              height: 1.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 44),
                    _stackedRoleButtons(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── STACKED BUTTONS ───────────────────────────────────────────────────
  Widget _stackedRoleButtons(BuildContext context) {
    return Column(
      children: [
        _pillButton(
          context: context,
          title: 'Donor',
          icon: Icons.volunteer_activism_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DonorLoginScreen()),
          ),
        ),
        const SizedBox(height: 14),
        _pillButton(
          context: context,
          title: 'NGO',
          icon: Icons.foundation_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NgoLoginScreen()),
          ),
        ),
      ],
    );
  }

  Widget _pillButton({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        splashColor: Colors.white.withValues(alpha: 0.15),
        child: Ink(
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}