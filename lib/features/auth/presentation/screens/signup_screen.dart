import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flashai/features/auth/presentation/screens/login_screen.dart';
import 'package:flashai/features/auth/data/firebase_auth_service.dart';
import 'package:flashai/features/auth/presentation/providers/auth_provider.dart';
import 'package:flashai/main.dart' show MainNavigationShell;
import 'package:flashai/core/theme/app_theme.dart';
import 'package:flashai/core/theme/theme_provider.dart';
import 'package:flashai/features/auth/presentation/widgets/glass_container.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = FirebaseAuthService();
  bool _obscurePassword = true;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleSignUp() async {
    // Validate inputs
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showErrorSnackBar('Please fill in all fields');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showErrorSnackBar('Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Use AuthProvider to sign up
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.signUpWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
        displayName: _nameController.text,
      );

      if (!mounted) return;

      if (success) {
        // Set first login completed
        await _authService.setFirstLoginCompleted();
        if (mounted) {
          context.read<ThemeProvider>().setThemeMode(ThemeMode.light);
        }

        // Navigate to main app
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainNavigationShell()),
          );
        }
      } else {
        if (mounted) {
          _showErrorSnackBar(authProvider.errorMessage ?? 'Sign up failed');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleGoogleSignUp() async {
    setState(() => _isLoading = true);

    try {
      // Use AuthProvider to sign up with Google
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.signInWithGoogle();

      if (!mounted) return;

      if (success) {
        // Set first login completed
        await _authService.setFirstLoginCompleted();
        if (mounted) {
          context.read<ThemeProvider>().setThemeMode(ThemeMode.light);
        }

        // Navigate to main app
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainNavigationShell()),
          );
        }
      } else {
        if (mounted) {
          _showErrorSnackBar(
            'Google sign-up failed: ${authProvider.errorMessage}',
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(_slideAnimation),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 40),
                    // Logo with glassmorphism effect
                    Center(
                      child: GlassContainer(
                        borderRadius: 24,
                        opacity: 0.85,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 30,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              'assets/icons/Layer 2.png',
                              fit: BoxFit.contain,
                              width: 100,
                              height: 100,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 32),
                    // Welcome text
                    Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Start your AI learning journey today',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 14),
                    // Name field
                    GlassContainer(
                      borderRadius: 20,
                      opacity: 0.9,
                      child: TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Full Name',
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: AppTheme.primaryColor,
                          ),
                          border: InputBorder.none,
                          filled: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                        ),
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    SizedBox(height: 20),
                    // Email field
                    GlassContainer(
                      borderRadius: 20,
                      opacity: 0.9,
                      child: TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: 'Email address',
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: AppTheme.primaryColor,
                          ),
                          border: InputBorder.none,
                          filled: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    SizedBox(height: 20),
                    // Password field
                    GlassContainer(
                      borderRadius: 20,
                      opacity: 0.9,
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: AppTheme.primaryColor,
                          ),
                          suffixIcon: GestureDetector(
                            onTap: () {
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              transform: Matrix4.rotationZ(
                                _obscurePassword ? 0 : 0.5,
                              ),
                              child: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey.shade600,
                                size: 20,
                              ),
                            ),
                          ),
                          border: InputBorder.none,
                          filled: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                        ),
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    SizedBox(height: 24),
                    // Create account button
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        gradient: _isLoading
                            ? const LinearGradient(
                                colors: [Colors.grey, Colors.grey],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: _isLoading ? 0 : 12,
                            offset: Offset(0, _isLoading ? 0 : 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                  strokeWidth: 3,
                                ),
                              )
                            : const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 32),
                    // Google sign up button
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isLoading ? null : _handleGoogleSignUp,
                          borderRadius: BorderRadius.circular(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isLoading)
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.blue.shade600,
                                    ),
                                    strokeWidth: 2,
                                  ),
                                )
                              else ...[
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4285F4),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'G',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Sign up with Google',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 32),
                    // Login link
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: Center(
                        child: RichText(
                          text: TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 15,
                            ),
                            children: [
                              TextSpan(
                                text: 'Log In',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
