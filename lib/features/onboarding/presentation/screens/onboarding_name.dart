import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../../../../l10n/app_localizations.dart';
import '../widgets/onboarding_header.dart';

/// Reclaim — Onboarding Name Input
class OnboardingName extends StatefulWidget {
  final Function(String) onNext;
  final VoidCallback? onBack;
  final VoidCallback? onSkip; // Debug skip callback

  const OnboardingName({
    super.key,
    required this.onNext,
    this.onBack,
    this.onSkip,
  });

  @override
  State<OnboardingName> createState() => _OnboardingNameState();
}

class _OnboardingNameState extends State<OnboardingName> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateName);
    // Auto-focus the text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _validateName() {
    final name = _nameController.text.trim();
    setState(() {
      _isValid = name.isNotEmpty && name.length >= 2;
    });
  }

  void _handleNext() {
    if (_isValid) {
      widget.onNext(_nameController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header (no back button on first screen)
              OnboardingHeader(
                showBack: widget.onBack != null,
                onBack: widget.onBack,
              ),

              // Debug Skip Button (only in debug mode)
              if (kDebugMode && widget.onSkip != null) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: widget.onSkip,
                    icon: const Icon(
                      Icons.skip_next,
                      color: Colors.orange,
                      size: 18,
                    ),
                    label: const Text(
                      'Skip Onboarding (Debug)',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Title
              Text(
                l10n.onboardingNameTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 32),

              // Name Input Field
              TextField(
                controller: _nameController,
                focusNode: _focusNode,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: l10n.onboardingNameHint,
                  hintStyle: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.07),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _isValid
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.transparent,
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                ),
                onSubmitted: (_) => _handleNext(),
              ),

              const Spacer(),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isValid ? _handleNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isValid
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.15),
                    foregroundColor: _isValid
                        ? Colors.black
                        : Colors.white.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.continueButton,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _isValid
                          ? Colors.black
                          : Colors.white.withValues(alpha: 0.5),
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

