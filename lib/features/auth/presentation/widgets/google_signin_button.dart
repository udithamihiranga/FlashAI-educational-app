import 'package:flutter/material.dart';
import 'package:flashai/features/auth/data/firebase_auth_service.dart';

/// Google Sign-In Button Widget
class GoogleSignInButton extends StatefulWidget {
  final VoidCallback? onSuccess;
  final Function(String)? onError;
  final bool isLoading;

  const GoogleSignInButton({
    Key? key,
    this.onSuccess,
    this.onError,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  late FirebaseAuthService _authService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _authService = FirebaseAuthService();
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading || widget.isLoading) return;

    setState(() => _isLoading = true);

    try {
      await _authService.signInWithGoogle();
      widget.onSuccess?.call();
    } catch (e) {
      widget.onError?.call(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign-in failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (_isLoading || widget.isLoading) ? null : _handleGoogleSignIn,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading || widget.isLoading)
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
                SizedBox(width: 12),
                Text(
                  'Sign in with Google',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
