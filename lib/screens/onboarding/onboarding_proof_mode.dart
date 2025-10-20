import 'package:flutter/material.dart';

class OnboardingProofMode extends StatefulWidget {
  final Function(bool) onNext;
  const OnboardingProofMode({super.key, required this.onNext});

  @override
  State<OnboardingProofMode> createState() => _OnboardingProofModeState();
}

class _OnboardingProofModeState extends State<OnboardingProofMode> {
  bool _proofMode = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // --- Title ---
              const Text(
                "Proof Mode 🔒",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),

              // --- Subtitle ---
              Text(
                _proofMode
                    ? "Every task you complete will require proof — a short reflection, photo, or summary to stay truly accountable."
                    : "You can still enable proof later for specific habits you choose.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 50),

              // --- Animated illustration ---
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _proofMode
                      ? Colors.blueAccent.withValues(alpha: 0.15)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Icon(
                    _proofMode
                        ? Icons.verified_user_rounded
                        : Icons.lock_outline_rounded,
                    size: 100,
                    color: _proofMode ? Colors.blueAccent : Colors.grey,
                  ),
                ),
              ),

              const SizedBox(height: 50),

              // --- Toggle Switch ---
              SwitchListTile.adaptive(
                title: const Text(
                  "Enable Proof Mode",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  _proofMode
                      ? "Every task will require a completion proof 🧾"
                      : "You can enable proof per habit later 💡",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                value: _proofMode,
                activeThumbColor: Colors.blueAccent,
                activeTrackColor: Colors.blueAccent.withValues(alpha: 0.4),
                onChanged: (value) {
                  setState(() => _proofMode = value);
                },
              ),

              const Spacer(),

              // --- Continue Button ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => widget.onNext(_proofMode),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    "Continue →",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
