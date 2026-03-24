import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/theme_constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final provider = context.read<UserProvider>();
    final success = await provider.signUp(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
      displayName: _nameCtrl.text,
    );

    if (success && mounted) {
      // Go to home first, then push health-profile to keep home in back stack
      context.go('/home');
      Future.microtask(() {
        if (mounted) context.push('/health-profile');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.primary),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// ── Heading ───────────────────────────────────────────────
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: AppColors.primary,
                        size: 30,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Create account',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Join IngreSafe for personalized ingredient safety',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 28),

                  /// ── Form ─────────────────────────────────────────────────
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        /// Name
                        TextFormField(
                          controller: _nameCtrl,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          decoration: _inputDeco(
                            label: 'Full name',
                            icon: Icons.person_outline,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Enter your name';
                            }
                            if (v.trim().length < 2) {
                              return 'Name must be at least 2 characters';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        /// Email
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDeco(
                            label: 'Email address',
                            icon: Icons.email_outlined,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Enter your email';
                            }
                            if (!v.contains('@') || !v.contains('.')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        /// Password
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDeco(
                            label: 'Password',
                            icon: Icons.lock_outline,
                          ).copyWith(
                            helperText: 'Minimum 6 characters',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Enter a password';
                            }
                            if (v.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        /// Confirm Password
                        TextFormField(
                          controller: _confirmCtrl,
                          obscureText: _obscureConfirm,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: _inputDeco(
                            label: 'Confirm password',
                            icon: Icons.lock_outline,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Confirm your password';
                            }
                            if (v != _passwordCtrl.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// ── Error Banner ──────────────────────────────────────────
                  if (userProvider.errorMessage != null)
                    _ErrorBanner(message: userProvider.errorMessage!),

                  const SizedBox(height: 8),

                  /// ── Register Button ───────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: userProvider.isLoading ? null : _submit,
                      child: userProvider.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// ── Login Link ────────────────────────────────────────────
                  Center(
                    child: TextButton(
                      onPressed: () => context.pop(),
                      child: RichText(
                        text: TextSpan(
                          text: 'Already have an account? ',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          children: const [
                            TextSpan(
                              text: 'Sign In',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: Colors.grey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
