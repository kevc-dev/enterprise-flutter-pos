import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../core/theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> 
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  late AnimationController _shakeController;
  late AnimationController _successController;
  late AnimationController _fadeInController;
  
  late Animation<double> _shakeAnimation;
  late Animation<double> _successScaleAnimation;
  late Animation<double> _successOpacityAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _loginSuccess = false;

  // Mock credentials
  final Map<String, String> _mockCredentials = {
    'admin@efppay.com': 'admin123',
    'cashier@efppay.com': 'cashier123',
    'manager@efppay.com': 'manager123',
    'demo@efppay.com': 'demo123',
  };

  @override
  void initState() {
    super.initState();
    
    // Shake animation for errors
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    // Success animation
    _successController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _successScaleAnimation = Tween<double>(
      begin: 0,
      end: 100,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    ));
    
    _successOpacityAnimation = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: const Interval(0.8, 1.0),
    ));

    // Fade in animation
    _fadeInController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeInController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _fadeInController,
      curve: Curves.easeIn,
    ));

    _fadeInController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _shakeController.dispose();
    _successController.dispose();
    _fadeInController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      // Trigger shake animation
      _shakeController.forward().then((_) {
        _shakeController.reverse();
      });
      
      // Haptic feedback
      HapticFeedback.mediumImpact();
      return;
    }

    setState(() => _isLoading = true);

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    final email = _emailController.text.toLowerCase();
    final password = _passwordController.text;

    if (_mockCredentials[email] == password) {
      // Success animation
      setState(() {
        _loginSuccess = true;
        _isLoading = false;
      });
      
      HapticFeedback.heavyImpact();
      
      await _successController.forward();
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      // Error handling
      setState(() => _isLoading = false);
      
      _shakeController.forward().then((_) {
        _shakeController.reverse();
      });
      
      HapticFeedback.mediumImpact();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid email or password'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryBlue,
                  Color(0xFF0D47A1),
                ],
              ),
            ),
          ),
          
          // Login form
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_shakeAnimation.value, 0),
                          child: Card(
                            elevation: 12,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 400),
                              padding: const EdgeInsets.all(32),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Logo
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryBlue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(
                                        Icons.point_of_sale,
                                        size: 40,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 20),
                                    
                                    // Title
                                    const Text(
                                      'Welcome to EFP Pay',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 8),
                                    
                                    Text(
                                      'Sign in to continue',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 32),
                                    
                                    // Email field
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      decoration: InputDecoration(
                                        labelText: 'Email',
                                        prefixIcon: const Icon(Icons.email_outlined),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        if (!value.contains('@')) {
                                          return 'Please enter a valid email';
                                        }
                                        return null;
                                      },
                                    ),
                                    
                                    const SizedBox(height: 20),
                                    
                                    // Password field
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _handleLogin(),
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        prefixIcon: const Icon(Icons.lock_outline),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword = !_obscurePassword;
                                            });
                                          },
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your password';
                                        }
                                        if (value.length < 6) {
                                          return 'Password must be at least 6 characters';
                                        }
                                        return null;
                                      },
                                    ),
                                    
                                    const SizedBox(height: 12),
                                    
                                    // Remember me & Forgot password
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            // Show demo credentials
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Demo Credentials'),
                                                content: const Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text('Admin:', style: TextStyle(fontWeight: FontWeight.bold)),
                                                    Text('admin@efppay.com / admin123'),
                                                    SizedBox(height: 8),
                                                    Text('Manager:', style: TextStyle(fontWeight: FontWeight.bold)),
                                                    Text('manager@efppay.com / manager123'),
                                                    SizedBox(height: 8),
                                                    Text('Cashier:', style: TextStyle(fontWeight: FontWeight.bold)),
                                                    Text('cashier@efppay.com / cashier123'),
                                                    SizedBox(height: 8),
                                                    Text('Demo:', style: TextStyle(fontWeight: FontWeight.bold)),
                                                    Text('demo@efppay.com / demo123'),
                                                  ],
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text('Close'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          child: const Text('Demo Credentials'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Reset link sent to your email'),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          },
                                          child: const Text('Forgot Password?'),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 24),
                                    
                                    // Login button
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _handleLogin,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primaryBlue,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          elevation: 4,
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              )
                                            : const Text(
                                                'Sign In',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 20),
                                    
                                    // Divider
                                    Row(
                                      children: [
                                        Expanded(child: Divider(color: Colors.grey[300])),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Text(
                                            'OR',
                                            style: TextStyle(color: Colors.grey[500]),
                                          ),
                                        ),
                                        Expanded(child: Divider(color: Colors.grey[300])),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 20),
                                    
                                    // Quick access buttons
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        // Quick login as demo user
                                        _emailController.text = 'demo@efppay.com';
                                        _passwordController.text = 'demo123';
                                        _handleLogin();
                                      },
                                      icon: const Icon(Icons.person_outline),
                                      label: const Text('Continue as Demo User'),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(double.infinity, 45),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
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
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Success animation overlay
          if (_loginSuccess)
            AnimatedBuilder(
              animation: _successController,
              builder: (context, child) {
                return Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                      child: Center(
                        child: Opacity(
                          opacity: _successOpacityAnimation.value,
                          child: Container(
                            width: _successScaleAnimation.value * 3,
                            height: _successScaleAnimation.value * 3,
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                width: _successScaleAnimation.value,
                                height: _successScaleAnimation.value,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 50,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}