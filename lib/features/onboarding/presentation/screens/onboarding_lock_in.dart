import 'package:flutter/material.dart';
import '../widgets/onboarding_header.dart';

/// Lock In Screen (Onboarding)
/// Shows: "Are you ready to lock in?" with tap and hold interaction
/// This screen is shown during onboarding as final commitment step
class OnboardingLockIn extends StatefulWidget {
  final Function()? onNext;
  final VoidCallback? onBack;

  const OnboardingLockIn({
    super.key,
    this.onNext,
    this.onBack,
  });

  @override
  State<OnboardingLockIn> createState() => _OnboardingLockInState();
}

class _OnboardingLockInState extends State<OnboardingLockIn> {
  double _progress = 0.0;
  bool _isHolding = false;

  void _startHold() {
    setState(() => _isHolding = true);
    _updateProgress();
  }

  void _stopHold() {
    setState(() {
      _isHolding = false;
      _progress = 0.0;
    });
  }

  void _updateProgress() {
    if (!_isHolding) return;
    if (_progress >= 1.0) {
      widget.onNext?.call();
      return;
    }
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted && _isHolding) {
        setState(() => _progress = (_progress + 0.05).clamp(0.0, 1.0));
        _updateProgress();
      }
    });
  }

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
              const Spacer(),
              const Text(
                'Are you ready to lock in?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'The path has been revealed to you. Will you take the first step into the unknown?',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              // Tap and hold button
              Center(
                child: GestureDetector(
                  onTapDown: (_) => _startHold(),
                  onTapUp: (_) => _stopHold(),
                  onTapCancel: () => _stopHold(),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.orange.withValues(alpha: 0.2),
                      border: Border.all(
                        color: Colors.orange,
                        width: 4,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: CircularProgressIndicator(
                            value: _progress,
                            strokeWidth: 4,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        Text(
                          _progress >= 1.0 ? 'Locked!' : 'Hold',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

