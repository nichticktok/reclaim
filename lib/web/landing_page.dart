import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Simple marketing landing page shown only on Flutter web builds.
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  static final Uri _appStoreUri = Uri.parse(
    'https://apps.apple.com/app/reclaim/id0000000000',
  );
  static final Uri _playStoreUri = Uri.parse(
    'https://play.google.com/store/apps/details?id=com.example.reclaim',
  );

  Future<void> _launch(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Failed to open $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 720;
              final content = [
                Expanded(
                  flex: isNarrow ? 0 : 5,
                  child: _buildHero(context, isNarrow),
                ),
                const SizedBox(width: 40, height: 40),
                Expanded(
                  flex: isNarrow ? 0 : 4,
                  child: _buildPreviewCard(isNarrow),
                ),
              ];
              return isNarrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: content,
                    )
                  : Row(children: content);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, bool isNarrow) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment:
          isNarrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Reclaim Your Routine',
          style: textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ) ??
              const TextStyle(
                fontSize: 36,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
          textAlign: isNarrow ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 16),
        Text(
          'Proof-based habit tracking that keeps you honest. '
          'Complete challenges, back them up with receipts, and build unstoppable momentum.',
          style: textTheme.titleMedium?.copyWith(
                color: Colors.white70,
                height: 1.5,
              ) ??
              const TextStyle(
                fontSize: 18,
                color: Colors.white70,
                height: 1.5,
              ),
          textAlign: isNarrow ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 28),
        Wrap(
          alignment: isNarrow ? WrapAlignment.center : WrapAlignment.start,
          spacing: 16,
          runSpacing: 16,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              onPressed: () => _launch(_appStoreUri),
              icon: const Icon(Icons.apple),
              label: const Text('Download on the App Store'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DB954),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              onPressed: () => _launch(_playStoreUri),
              icon: const Icon(Icons.android),
              label: const Text('Get it on Google Play'),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Wrap(
          alignment: isNarrow ? WrapAlignment.center : WrapAlignment.start,
          spacing: 12,
          runSpacing: 12,
          children: const [
            _FeatureChip(text: 'Daily habit challenges'),
            _FeatureChip(text: 'Proof-based accountability'),
            _FeatureChip(text: 'Smart reminders'),
          ],
        ),
      ],
    );
  }

  Widget _buildPreviewCard(bool isNarrow) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: AspectRatio(
        aspectRatio: isNarrow ? 9 / 16 : 3 / 5,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFF222931), Color(0xFF0D1216)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 32,
                offset: Offset(0, 20),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '“Reclaim helps me stay accountable to the habits that matter.”',
                style: TextStyle(color: Colors.white, fontSize: 18, height: 1.5),
              ),
              Spacer(),
              Text(
                'Join thousands building resilient routines with Reclaim.',
                style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 13),
      ),
    );
  }
}
