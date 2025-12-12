import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../services/notification_service.dart';
import '../../utils/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isOtpSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (_phoneController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit phone number')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.sendOTP(_phoneController.text);

    setState(() => _isLoading = false);

    if (authProvider.error == null) {
      setState(() => _isOtpSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent successfully! Use 1234 for testing')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.error ?? 'Failed to send OTP')),
      );
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter 4-digit OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.verifyOTP(
      _phoneController.text,
      _otpController.text,
    );

    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        // Initialize notification service after successful login (mobile only)
        if (!kIsWeb) {
          try {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final adminProvider = Provider.of<AdminProvider>(context, listen: false);
            
            debugPrint('📱 [LOGIN] Initializing notification service after login...');
            await NotificationService().initialize(
              context: context,
              adminProvider: adminProvider,
              authProvider: authProvider,
            );
            debugPrint('✅ [LOGIN] Notification service initialized');
          } catch (e) {
            debugPrint('❌ [LOGIN] Error initializing notification service: $e');
          }
        }
        
        // Let router handle redirect based on user role
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userRole = authProvider.user?.role;
        
        if (userRole == 'admin') {
          context.go('/admin/dashboard');
        } else if (userRole == 'delivery') {
          context.go('/delivery/dashboard');
        } else {
          context.go('/home');
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.error ?? 'Invalid OTP')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.shopping_basket,
                size: 100,
                color: AppTheme.primaryGreen,
              ),
              const SizedBox(height: 32),
              const Text(
                'Welcome to Easy Basket',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'RoundedSans',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your phone number to continue',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.grey,
                  fontFamily: 'RoundedSans',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                enabled: !_isOtpSent && !_isLoading,
                readOnly: _isOtpSent || _isLoading,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '9876543210',
                  hintStyle: TextStyle(
                    color: AppTheme.grey.withOpacity(0.5),
                  ),
                  prefixIcon: const Icon(Icons.phone),
                  prefixText: '+91 ',
                  counterText: '', // Hide character counter
                ),
                autofocus: false,
              ),
              if (_isOtpSent) ...[
                const SizedBox(height: 24),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: InputDecoration(
                    labelText: 'Enter OTP',
                    hintText: '1234',
                    hintStyle: TextStyle(
                      color: AppTheme.grey.withOpacity(0.5),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOTP,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Verify OTP'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isOtpSent = false;
                      _otpController.clear();
                    });
                  },
                  child: const Text('Change Phone Number'),
                ),
              ] else ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendOTP,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send OTP'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

