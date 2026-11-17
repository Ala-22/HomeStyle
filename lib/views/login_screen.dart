import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/preferences_service.dart';
import '../viewmodels/auth_viewmodel.dart';

const Color _brown = Color(0xFF6D4C41);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final AuthViewModel authViewModel = AuthViewModel();

  bool obscurePassword = true;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    final curved = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _fadeAnimation = curved;
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(curved);

    _animationController.forward();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    authViewModel.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }

    final emailRegex = RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email';
    }

    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    return null;
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await authViewModel.login(
      email: emailController.text.trim(),
      password: passwordController.text,
    );

    if (!mounted) return;

    if (success && authViewModel.user != null) {
      final loggedUser = authViewModel.user!;

      await PreferencesService.saveUser(
        userId: loggedUser.id ?? 0,
        name: loggedUser.name,
        email: loggedUser.email,
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authViewModel.errorMessage ?? 'Login failed',
          ),
        ),
      );
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        bool loading = false;
        String? error;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reset Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Enter the email of your HomeStyle account and we '
                    'will send you a reset link.',
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'example@email.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          final email = controller.text.trim();

                          if (email.isEmpty) {
                            setDialogState(() {
                              error = 'Please enter your email';
                            });
                            return;
                          }

                          setDialogState(() {
                            loading = true;
                            error = null;
                          });

                          try {
                            final response =
                                await ApiService()
                                    .forgotPassword(email: email);

                            if (!context.mounted) return;

                            Navigator.pop(
                              context,
                              response['message']?.toString() ??
                                  'Reset link sent to your email',
                            );
                          } catch (_) {
                            setDialogState(() {
                              loading = false;
                              error =
                                  'Could not reach the server.\n'
                                  'Make sure XAMPP is running.';
                            });
                          }
                        },
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('Send Reset Link'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: authViewModel,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors:
                    Theme.of(context).brightness == Brightness.dark
                        ? const [
                            Color(0xFF1D140E),
                            Color(0xFF2A2018),
                            Color(0xFF1D140E),
                          ]
                        : const [
                            Color(0xFF2E1B14),
                            Color(0xFF5D4037),
                            Color(0xFFF7EFE5),
                          ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ================================================
                  // HEADER IMAGE + LOGO
                  // ================================================
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
                    child: SizedBox(
                      height: 230,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'assets/images/welcome.jpg',
                            fit: BoxFit.cover,
                          ),
                          // gradient overlay
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  _brown.withValues(alpha: 0.85),
                                ],
                              ),
                            ),
                          ),
                          // logo + title
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 74,
                                  height: 74,
                                  decoration: BoxDecoration(
                                    color: Colors.white
                                        .withValues(alpha: 0.92),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.home_work_outlined,
                                    size: 38,
                                    color: _brown,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'HomeStyle',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 29,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ================================================
                  // CARD
                  // ================================================
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: _brown.withValues(alpha: 0.10),
                                blurRadius: 22,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Welcome Back',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 27,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  'Login to continue to HomeStyle',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),

                                const SizedBox(height: 26),

                                TextFormField(
                                  controller: emailController,
                                  keyboardType:
                                      TextInputType.emailAddress,
                                  validator: validateEmail,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    hintText: 'example@email.com',
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                TextFormField(
                                  controller: passwordController,
                                  obscureText: obscurePassword,
                                  validator: validatePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    hintText: 'Enter your password',
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color: colorScheme.primary,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          obscurePassword =
                                              !obscurePassword;
                                        });
                                      },
                                      icon: Icon(
                                        obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed:
                                        _showForgotPasswordDialog,
                                    child: Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // ==================================
                                // LOGIN BUTTON
                                // ==================================
                                SizedBox(
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: authViewModel.isLoading
                                        ? null
                                        : login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: authViewModel.isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Login',
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight:
                                                  FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account?",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/signup',
                                        );
                                      },
                                      child: const Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
}