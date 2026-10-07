import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'session.dart';
import 'login_page.dart';
import 'main.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool isGoogleLoading = false;
  String? errorMessage;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '1020535180382-16o21mmp7bp1cl1pb6j7qjq9fn5ku6f7.apps.googleusercontent.com',
  );

  Future<void> signUpWithGoogle() async {
    setState(() {
      isGoogleLoading = true;
      errorMessage = null;
    });

    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => isGoogleLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        setState(() => errorMessage = 'Could not get Google credentials. Please try again.');
        return;
      }

      final response = await http.post(
        Uri.parse('$kApiBaseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id_token': idToken}),
      );
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final user = data['user'];
        await Session.save(
          id: user['id'],
          name: user['name'],
          email: user['email'],
          phone: user['phone'],
          token: user['token'],
        );

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      } else {
        setState(() => errorMessage = data['error'] ?? 'Google sign-up failed');
      }
    } catch (e) {
      setState(() => errorMessage = 'Google sign-in error: $e');
    } finally {
      if (mounted) setState(() => isGoogleLoading = false);
    }
  }

  Future<void> register() async {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      setState(() => errorMessage = 'Please fill all fields');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$kApiBaseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'phone': phoneController.text.trim(),
          'password': passwordController.text,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        final user = data['user'];
        await Session.save(
          id: user['id'],
          name: user['name'],
          email: user['email'],
          phone: user['phone'],
          token: user['token'],
        );

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      } else {
        setState(() => errorMessage = data['error'] ?? 'Could not create account');
      }
    } catch (e) {
      setState(() => errorMessage = 'Could not connect to server. Please try again.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F3),
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: const Color(0xFFFF6B35),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Text(
                'Join Babu\'s Food',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C2C2C)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Create an account to order and track your food',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              if (errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Text(errorMessage!, style: TextStyle(color: Colors.red[800], fontSize: 13)),
                ),

              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: isLoading ? null : register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[300])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('OR', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ),
                  Expanded(child: Divider(color: Colors.grey[300])),
                ],
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: isGoogleLoading ? null : signUpWithGoogle,
                icon: isGoogleLoading
                    ? const SizedBox(
                        height: 16, width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Image.asset('assets/google_logo.png', height: 20, width: 20),
                label: const Text('Continue with Google', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                    children: [
                      TextSpan(text: 'Already have an account? '),
                      TextSpan(
                        text: 'Login',
                        style: TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
