import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../models/user_model.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../../../auth/presentation/screens/sign_in_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Consumer<HomeController>(
        builder: (context, controller, child) {
          final user = controller.currentUser;
          
          if (user == null) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Section
                _buildProfileSection(user),
                const SizedBox(height: 30),

                // Account Settings
                _buildSectionTitle("Account"),
                const SizedBox(height: 16),
                _buildSettingTile(
                  icon: Icons.person,
                  title: "Edit Profile",
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Profile editing coming soon! ✏️"),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                ),
                _buildSettingTile(
                  icon: Icons.email,
                  title: "Email",
                  subtitle: user.email.isNotEmpty ? user.email : "Not set",
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Email editing coming soon! 📧"),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),

                // App Settings
                _buildSectionTitle("App Settings"),
                const SizedBox(height: 16),
                _buildSettingTile(
                  icon: Icons.notifications,
                  title: "Notifications",
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Notification settings coming soon! 🔔"),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                ),
                _buildSettingTile(
                  icon: Icons.dark_mode,
                  title: "Theme",
                  subtitle: "Dark",
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Theme settings coming soon! 🎨"),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),

                // About
                _buildSectionTitle("About"),
                const SizedBox(height: 16),
                _buildSettingTile(
                  icon: Icons.info,
                  title: "App Version",
                  subtitle: "1.0.0",
                  onTap: () {},
                ),
                _buildSettingTile(
                  icon: Icons.help,
                  title: "Help & Support",
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1A1A1A),
                        title: const Text(
                          "Help & Support",
                          style: TextStyle(color: Colors.white),
                        ),
                        content: const Text(
                          "For support, please contact us at:\n\nsupport@reclaim.app\n\nWe're here to help! 💪",
                          style: TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close', style: TextStyle(color: Colors.orange)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),

                // Logout
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const SignInScreen()),
                            (route) => false,
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Logout failed: $e")),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text("Logout"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileSection(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.orange,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : "U",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (user.goal.isNotEmpty)
                  Text(
                    user.goal,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.orange),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              )
            : null,
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        onTap: onTap,
      ),
    );
  }
}

