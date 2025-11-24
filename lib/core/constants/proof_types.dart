/// Proof type constants for defining what kind of proof is required for a habit
class ProofTypes {
  static const String text = 'text';
  static const String photo = 'photo';
  static const String video = 'video';
  static const String location = 'location';
  static const String file = 'file';
  static const String any = 'any';

  /// List of all valid proof types
  static const List<String> all = [text, photo, video, location, file, any];

  /// Check if a proof type is valid
  static bool isValid(String? type) {
    if (type == null) return false;
    return all.contains(type);
  }

  /// Get display name for proof type
  static String getDisplayName(String type) {
    switch (type) {
      case text:
        return 'Text';
      case photo:
        return 'Photo';
      case video:
        return 'Video';
      case location:
        return 'Location';
      case file:
        return 'File';
      case any:
        return 'Any';
      default:
        return 'Text';
    }
  }

  /// Get icon data name for proof type
  static String getIconName(String type) {
    switch (type) {
      case text:
        return 'text_fields';
      case photo:
        return 'photo';
      case video:
        return 'videocam';
      case location:
        return 'location_on';
      case file:
        return 'attach_file';
      case any:
        return 'check_circle';
      default:
        return 'text_fields';
    }
  }

  /// Get hint text for proof type
  static String getHintText(String type) {
    switch (type) {
      case text:
        return 'Describe how you completed this task...';
      case photo:
        return 'Take or upload a photo as proof';
      case video:
        return 'Record or upload a video as proof';
      case location:
        return 'Capture your current location';
      case file:
        return 'Upload a file as proof';
      case any:
        return 'Choose a proof type and provide proof';
      default:
        return 'Describe how you completed this task...';
    }
  }
}

