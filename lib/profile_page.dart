import 'package:flutter/material.dart';
import 'session.dart';
import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  final Map<String, dynamic> currentUser;

  const ProfilePage({Key? key, required this.currentUser}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    await Session.clear();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF6B35), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F3),
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFFFF6B35),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE0D0),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  (currentUser['name'] ?? '?').toString().trim().isNotEmpty
                      ? currentUser['name'].toString().trim()[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B35),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  _infoRow(Icons.person_outline, 'Full Name', currentUser['name'] ?? '-'),
                  const Divider(height: 1),
                  _infoRow(Icons.email_outlined, 'Email', currentUser['email'] ?? '-'),
                  const Divider(height: 1),
                  _infoRow(Icons.phone_outlined, 'Phone', currentUser['phone'] ?? '-'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Logout', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
