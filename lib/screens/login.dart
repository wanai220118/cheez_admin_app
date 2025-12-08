import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/password_field.dart';
import 'dashboard.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final LocalStorageService _storageService = LocalStorageService();
  bool loading = false;
  bool rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadRememberedCredentials() async {
    final credentials = await _storageService.getRememberedCredentials();
    if (credentials['email'] != null && credentials['password'] != null) {
      setState(() {
        emailController.text = credentials['email']!;
        passwordController.text = credentials['password']!;
        rememberMe = true;
      });
    }
  }

  void login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => loading = true);
      try {
        await _authService.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        
        // Save or clear remember me
        if (rememberMe) {
          await _storageService.saveRememberMe(
            emailController.text.trim(),
            passwordController.text.trim(),
          );
        } else {
          await _storageService.clearRememberMe();
        }
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardScreen()),
        );
        Fluttertoast.showToast(msg: "Login successful");
      } catch (e) {
        Fluttertoast.showToast(msg: "Login failed: ${e.toString()}");
      } finally {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Cheez n' Cream Co. Admin Login")),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo - Bigger and centered
                Image.asset(
                  'assets/images/cnc.jpg',
                  height: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/images/cnc.jpg',
                      height: 200,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.lock_outline, size: 150, color: Theme.of(context).colorScheme.primary);
                      },
                    );
                  },
                ),
                SizedBox(height: 40),
                // Email Field - Centered
                SizedBox(
                  width: double.infinity,
                  child: CustomTextField(
                    controller: emailController,
                    label: "Email",
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 16),
                // Password Field with Eye Icon - Centered
                SizedBox(
                  width: double.infinity,
                  child: PasswordField(
                    controller: passwordController,
                    label: "Password",
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 12),
                // Remember Me Checkbox - Right aligned
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Checkbox(
                      value: rememberMe,
                      onChanged: (value) {
                        setState(() {
                          rememberMe = value ?? false;
                        });
                      },
                    ),
                    Text('Remember me'),
                  ],
                ),
                SizedBox(height: 24),
                // Login Button - Centered
                SizedBox(
                  width: double.infinity,
                  child: loading
                      ? Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: login,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text("Login"),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
