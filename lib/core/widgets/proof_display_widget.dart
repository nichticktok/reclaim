import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/proof_submission_model.dart';
import '../constants/proof_types.dart';

/// Widget to display proof submissions based on their type
class ProofDisplayWidget extends StatelessWidget {
  final ProofSubmission proof;

  const ProofDisplayWidget({
    super.key,
    required this.proof,
  });

  @override
  Widget build(BuildContext context) {
    switch (proof.proofType) {
      case ProofTypes.text:
        return _buildTextProof();
      case ProofTypes.photo:
        return _buildPhotoProof(context);
      case ProofTypes.video:
        return _buildVideoProof(context);
      case ProofTypes.location:
        return _buildLocationProof(context);
      case ProofTypes.file:
        return _buildFileProof(context);
      default:
        return _buildDefaultProof();
    }
  }

  Widget _buildTextProof() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.text_fields, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              proof.textContent ?? 'No text content',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoProof(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: Show full-screen image viewer
        _showImageDialog(context, proof.mediaUrl!);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: proof.mediaUrl != null
              ? Image.network(
                  proof.mediaUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildErrorWidget('Failed to load image');
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.orange),
                      ),
                    );
                  },
                )
              : _buildErrorWidget('No image URL'),
        ),
      ),
    );
  }

  Widget _buildVideoProof(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.videocam, color: Colors.red, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Video Proof',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              if (proof.mediaUrl != null)
                TextButton.icon(
                  onPressed: () {
                    _launchURL(context, proof.mediaUrl!);
                  },
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('View'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange,
                  ),
                ),
            ],
          ),
          if (proof.textContent != null) ...[
            const SizedBox(height: 8),
            Text(
              proof.textContent!,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationProof(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.green, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Location Proof',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              if (proof.locationLat != null && proof.locationLng != null)
                TextButton.icon(
                  onPressed: () {
                    final url =
                        'https://www.google.com/maps?q=${proof.locationLat},${proof.locationLng}';
                    _launchURL(context, url);
                  },
                  icon: const Icon(Icons.map, size: 16),
                  label: const Text('View on Map'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange,
                  ),
                ),
            ],
          ),
          if (proof.locationLat != null && proof.locationLng != null) ...[
            const SizedBox(height: 8),
            Text(
              'Lat: ${proof.locationLat}, Lng: ${proof.locationLng}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFileProof(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_file, color: Colors.purple, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  proof.fileName ?? 'File',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                if (proof.textContent != null)
                  Text(
                    proof.textContent!,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
              ],
            ),
          ),
          if (proof.mediaUrl != null)
            IconButton(
              onPressed: () {
                _launchURL(context, proof.mediaUrl!);
              },
              icon: const Icon(Icons.download, color: Colors.orange),
              tooltip: 'Download',
            ),
        ],
      ),
    );
  }

  Widget _buildDefaultProof() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              proof.textContent ?? 'Proof submitted',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 32),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: Image.network(imageUrl),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open URL'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

