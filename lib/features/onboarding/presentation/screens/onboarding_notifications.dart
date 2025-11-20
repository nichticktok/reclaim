import 'package:flutter/material.dart';
import '../widgets/onboarding_header.dart';

/// Notification Settings Screen
/// Shows: Stay on track, Daily ritual, Weekly Recap toggles
class OnboardingNotifications extends StatefulWidget {
  final Function(Map<String, bool>) onNext;
  final VoidCallback? onBack;

  const OnboardingNotifications({
    super.key,
    required this.onNext,
    this.onBack,
  });

  @override
  State<OnboardingNotifications> createState() => _OnboardingNotificationsState();
}

class _OnboardingNotificationsState extends State<OnboardingNotifications> {
  final Map<String, bool> _notifications = {
    'Stay on track': true,
    'Daily ritual': true,
    'Weekly Recap': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OnboardingHeader(
                showBack: widget.onBack != null,
                onBack: widget.onBack,
              ),
              const SizedBox(height: 48),
              const Text(
                'Get daily notifications to keep motivated',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Notification toggle cards
              ..._notifications.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Switch(
                          value: entry.value,
                          onChanged: (value) {
                            setState(() {
                              _notifications[entry.key] = value;
                            });
                          },
                          activeThumbColor: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const Spacer(),
              // Next button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => widget.onNext(_notifications),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

