import 'dart:math' as math;
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

class _BaseRegisterScreenState extends State<BaseRegisterScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  late AnimationController _rotationController;

  static const Color themeColor = Color(0xFF8C4149);

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  // Configuration map to dynamically resolve layout content based on target role
  Map<String, dynamic> get roleConfig {
    switch (widget.role) {
      case 'ngo':
        return {
          'title': 'Create NGO Account',
          'subtitle': 'We\'re here to help you get support.',
          'nameHint': 'Enter NGO name',
          'nameIcon': Icons.domain_rounded,
        };
      case 'travel_agency':
        return {
          'title': 'Create Agency Account',
          'subtitle': 'Join our logistics network to help out.',
          'nameHint': 'Enter Agency name',
          'nameIcon': Icons.local_shipping_outlined,
        };
      case 'donor':
      default:
        return {
          'title': 'Create Your Account',
          'subtitle': 'We\'re here to help you make a difference.',
          'nameHint': 'Enter full name',
          'nameIcon': Icons.person_outline_rounded,
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
      role: widget.role,
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
    final config = roleConfig;

    return Scaffold(
      backgroundColor: themeColor,
      // Prevents the background from shrinking when keyboard opens
      resizeToAvoidBottomInset: true, 
      body: Column(
        children: [
          // ── TOP HEADER (Compact Animated Gradient) ──
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.18, // Fixed short height
            child: AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(
                        math.cos(_rotationController.value * 2 * math.pi),
                        math.sin(_rotationController.value * 2 * math.pi),
                      ),
                      end: Alignment(
                        math.cos((_rotationController.value + 0.5) * 2 * math.pi),
                        math.sin((_rotationController.value + 0.5) * 2 * math.pi),
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
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: const Text(
                        'Back',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── BOTTOM WHITE CARD (Single Page View) ──
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(36),
                  topRight: Radius.circular(36),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    // Clamping physics removes the bouncy scroll effect
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      // Forces the content to take exactly the screen height
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // --- TOP SECTION ---
                            Column(
                              children: [
                                Text(
                                  config['title'],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E1E1E),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade500,
                                      height: 1.4,
                                    ),
                                    
                                  ),
                                ),
                              ],
                            ),

                            // --- MIDDLE SECTION (Forms) ---
                            Column(
                              children: [
                                _buildInputField(
                                  hint: config['nameHint'],
                                  icon: config['nameIcon'],
                                  controller: _nameController,
                                ),
                                const SizedBox(height: 12),
                                _buildInputField(
                                  hint: 'Enter email',
                                  icon: Icons.email_outlined,
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 12),
                                _buildPasswordField(),

                                // Forgot Password
                                

                                

                                // GET STARTED Button
                                Container(
                                  width: double.infinity,
                                  height: 50, // Shorter height
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(25),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFE58D96), Color(0xFF8C4149)],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: themeColor.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: authProvider.isLoading ? null : _register,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                    ),
                                    child: authProvider.isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                                color: Colors.white, strokeWidth: 2.5),
                                          )
                                        : const Text(
                                            'Get Started',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),

                            // --- BOTTOM SECTION ---
                            Column(
                              children: [
                                // Sign up with divider
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Row(
                                    children: [
                                      Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Text(
                                          'Sign up with',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                                        ),
                                      ),
                                      Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                                    ],
                                  ),
                                ),

                                // Google Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: OutlinedButton(
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
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Colors.grey.shade300),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      backgroundColor: Colors.white,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Image.network(
                                          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/24px-Google_%22G%22_logo.svg.png',
                                          height: 18,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Icon(Icons.g_mobiledata, color: Colors.red, size: 24),
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          "Continue with Google",
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 24), // Spacer before very bottom

                                // Already have an account
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Already have an account? ",
                                      style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: const Text(
                                        'Log In',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: themeColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Stylish, Compact Input Field
  Widget _buildInputField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  // Stylish, Compact Password Field
  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        decoration: InputDecoration(
          hintText: 'Enter password',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.lock_outline_rounded, color: Colors.grey.shade400, size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: Colors.grey.shade400,
              size: 20,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }
}