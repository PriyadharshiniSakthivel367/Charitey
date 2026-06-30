// base_register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'profile_setup_screen.dart';

class BaseRegisterScreen extends StatefulWidget {
  final String role; // 'donor', 'ngo', or 'travel_agency'

  const BaseRegisterScreen({super.key, required this.role});

  @override
  State<BaseRegisterScreen> createState() => _BaseRegisterScreenState();
}

class _BaseRegisterScreenState extends State<BaseRegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final Color themeColor = const Color(0xFFB56F76);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Configuration map to dynamically resolve layout content based on target role
  Map<String, dynamic> get _roleConfig {
    switch (widget.role) {
      case 'ngo':
        return {
          'title': 'NGO Sign Up',
          'subtitle': 'Create an account to start receiving support.',
          'nameHint': 'NGO Name',
          'nameIcon': Icons.domain_rounded,
          'loginScreen': 'NgoLoginScreen', // Replace with type context mapping or instantiation if necessary
        };
      case 'travel_agency':
        return {
          'title': 'Agency Sign Up',
          'subtitle': 'Create an account to join the logistics network.',
          'nameHint': 'Agency Name',
          'nameIcon': Icons.local_shipping_outlined,
          'loginScreen': 'TravelAgencyLoginScreen',
        };
      case 'donor':
      default:
        return {
          'title': 'Sign Up',
          'subtitle': 'Create an account to start giving.',
          'nameHint': 'Full Name',
          'nameIcon': Icons.person_outline_rounded,
          'loginScreen': 'DonorLoginScreen',
        };
    }
  }

  void _register() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields to sign up.')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters long.')),
      );
      return;
    }

    bool success = await authProvider.signUp(
      name: name,
      email: email,
      password: password,
      phone: '',
      location: '',
      role: widget.role, // Safe and dynamic role handling
    );

    if (!context.mounted) return;

    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => ProfileSetupScreen(role: widget.role)),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration failed. Email might already be in use.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final config = _roleConfig;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // --- Background Decorative Blobs ---
          Positioned(
            top: -80, right: -60,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(color: themeColor.withValues(alpha: 0.8), shape: BoxShape.circle),
            ),
          ),
          Positioned(
            top: 40, right: -120,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(color: themeColor.withValues(alpha: 0.3), shape: BoxShape.circle),
            ),
          ),
          Positioned(
            bottom: -150, left: -50,
            child: Container(
              width: 350, height: 350,
              decoration: BoxDecoration(color: themeColor.withValues(alpha: 0.15), shape: BoxShape.circle),
            ),
          ),

          // --- Main Content ---
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(flex: 1),
                          Text(
                            config['title'],
                            style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            config['subtitle'],
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 30),
                          
                          _buildInputField(hint: config['nameHint'], icon: config['nameIcon'], controller: _nameController),
                          const SizedBox(height: 16),
                          _buildInputField(hint: 'Email Address', icon: Icons.email_outlined, controller: _emailController, keyboardType: TextInputType.emailAddress),
                          const SizedBox(height: 16),
                          _buildInputField(hint: 'Create Password', icon: Icons.lock_outline_rounded, controller: _passwordController, isPassword: true),
                          const SizedBox(height: 30),

                          // MAIN SIGN UP BUTTON
                          ElevatedButton(
                            onPressed: authProvider.isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              elevation: 4,
                              shadowColor: themeColor.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: authProvider.isLoading
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : const Text(
                                    'SIGN UP',
                                    style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                  ),
                          ),
                          const SizedBox(height: 24),

                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text('OR', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                              ),
                              Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // GOOGLE BUTTON (Fixed role allocation here!)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              elevation: 2,
                              shadowColor: Colors.black12,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            onPressed: () async {
                              bool success = await authProvider.signInWithGoogle(role: widget.role);
                              if (!context.mounted) return;

                              if (success) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (_) => ProfileSetupScreen(role: widget.role)),
                                  (route) => false,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Google sign up failed.")),
                                );
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.network(
                                  'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/24px-Google_%22G%22_logo.svg.png',
                                  height: 24,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, color: Colors.red, size: 30),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  "Continue with Google",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                          
                          const Spacer(flex: 2),

                          // BOTTOM LOGIN LINK
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Already have an account? ", style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
                              GestureDetector(
                                onTap: () {
                                  // Simply pop back or use string identifier mapping to link specific Login Screens
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  'Log in',
                                  style: TextStyle(fontSize: 15, color: themeColor, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
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

  Widget _buildInputField({required String hint, required IconData icon, required TextEditingController controller, bool isPassword = false, TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
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