// FILE: motorent/lib/screens/login_page.dart
// UPDATED: Added MotoRent logo

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import 'customer/vehicle_listing_page.dart';
import 'register_page.dart';
import 'driver/driver_dashboard_page.dart';
import 'owner/owner_dashboard_page.dart';
import 'admin/admin_dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _useMockLogin = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final result = _useMockLogin
            ? await _authService.mockLogin(
                _emailController.text.trim(),
                _passwordController.text,
              )
            : await _authService.login(
                _emailController.text.trim(),
                _passwordController.text,
              );

        setState(() {
          _isLoading = false;
        });

        if (result['success']) {
          final User user = result['user'];
          
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome back, ${user.name}!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          _navigateToUserPage(user);
        } else {
          if (!mounted) return;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _navigateToUserPage(User user) {
    Widget destinationPage;

    switch (user.userType.toLowerCase()) {
      case 'admin':
        destinationPage = const AdminDashboardPage();
        break;
      case 'driver':
        destinationPage = DriverDashboardPage(driver: user);
        break;
      case 'owner':
        destinationPage = OwnerDashboardPage(
          ownerId: user.userId is int ? user.userId : int.tryParse(user.userIdString) ?? 0,
          ownerName: user.name,
        );
        break;
      case 'customer':
      default:
        destinationPage = VehicleListingPage(user: user);
        break;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destinationPage),
    );
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await _authService.resetPassword(_emailController.text.trim());

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']),
        backgroundColor: result['success'] ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ✅ UPDATED: Use logo image instead of icon
                  Image.asset(
                    'assets/images/logo.png',
                    height: 150,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to icon if logo not found
                      return const Icon(
                        Icons.directions_car,
                        size: 100,
                        color: const Color(0xFF1E88E5),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  const Text(
                    'MotoRent',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E88E5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    'Your Trusted Car Rental Partner',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 50),
                  
                  const Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Log in to continue',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF1E88E5),
                          width: 2,
                        ),
                      ),
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
                  
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
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
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF1E88E5),
                          width: 2,
                        ),
                      ),
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
                  
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _handleForgotPassword,
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Color(0xFF1E88E5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SpinKitThreeBounce(
                              color: Colors.white,
                              size: 24.0,
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 16,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterPage(),
                            ),
                          );
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Color(0xFF1E88E5),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}