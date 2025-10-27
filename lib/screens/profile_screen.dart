import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../widgets/custom_button.dart';
import '../screens/auth/sign_in_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _goalController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _goalController = TextEditingController(text: widget.user.goal);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Logged out successfully 🚪")),
        );

        // Clear any navigation stack and go to sign-in
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SignInScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logout failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Your Profile"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
              child: const Icon(Icons.person, size: 60, color: Colors.blueAccent),
            ),

            const SizedBox(height: 16),

            // Username
            isEditing
                ? TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Full Name",
                      border: OutlineInputBorder(),
                    ),
                  )
                : Text(
                    widget.user.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

            const SizedBox(height: 6),
            Text(
              widget.user.email,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 20),

            // Goal or Purpose
            _buildGoalCard(),

            const SizedBox(height: 20),

            // Stats section
            _buildStatRow(),

            const SizedBox(height: 30),

            // Edit or Save button
            CustomButton(
              text: isEditing ? "Save Changes" : "Edit Profile",
              onPressed: () async {
                if (isEditing) {
                  // Save changes to Firestore
                  final userDoc = FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.user.id);
                  await userDoc.update({
                    'name': _nameController.text.trim(),
                    'goal': _goalController.text.trim(),
                  });

                  setState(() {
                    widget.user.name = _nameController.text;
                    widget.user.goal = _goalController.text;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Profile updated ✅")),
                  );
                }
                setState(() => isEditing = !isEditing);
              },
            ),

            const SizedBox(height: 20),

            // Subscription section
            _buildSubscriptionCard(),

            const SizedBox(height: 20),

            // Logout
            TextButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: const Text(
                "Logout",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Your Goal 🎯",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          isEditing
              ? TextField(
                  controller: _goalController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: "Update your goal or focus...",
                    border: OutlineInputBorder(),
                  ),
                )
              : Text(
                  widget.user.goal.isNotEmpty
                      ? widget.user.goal
                      : "Set a goal to focus your journey.",
                  style: TextStyle(
                    fontSize: 15,
                    color: widget.user.goal.isNotEmpty
                        ? Colors.black87
                        : Colors.grey.shade600,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildStatRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _statBox("Level", widget.user.level.toString()),
        _statBox("Joined", "12 Jan 2025"),
        _statBox("Streak", "${widget.user.streak} days"),
      ],
    );
  }

  Widget _statBox(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            widget.user.isPremium ? Icons.star : Icons.lock_open_rounded,
            color: widget.user.isPremium ? Colors.amber : Colors.grey.shade700,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.user.isPremium
                  ? "You are a Premium Member 🌟"
                  : "Upgrade to Premium for advanced tracking",
              style: const TextStyle(fontSize: 15),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/subscription');
            },
            child: Text(
              widget.user.isPremium ? "Manage" : "Upgrade",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
