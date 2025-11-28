/// Proof type constants for project tasks
class ProjectProofTypes {
  static const String timedSession = 'timedSession';
  static const String reflectionNote = 'reflectionNote';
  static const String smallMediaClip = 'smallMediaClip';
  static const String externalOutput = 'externalOutput';
  static const String peerApproval = 'peerApproval';

  /// List of all valid proof types
  static const List<String> all = [
    timedSession,
    reflectionNote,
    smallMediaClip,
    externalOutput,
    peerApproval,
  ];

  /// Check if a proof type is valid
  static bool isValid(String? type) {
    if (type == null) return false;
    return all.contains(type);
  }

  /// Get display name for proof type
  static String getDisplayName(String type) {
    switch (type) {
      case timedSession:
        return 'Timed Session';
      case reflectionNote:
        return 'Reflection Note';
      case smallMediaClip:
        return 'Media Clip';
      case externalOutput:
        return 'External Output';
      case peerApproval:
        return 'Peer Approval';
      default:
        return 'Timed Session';
    }
  }

  /// Get icon data name for proof type
  static String getIconName(String type) {
    switch (type) {
      case timedSession:
        return 'timer';
      case reflectionNote:
        return 'edit_note';
      case smallMediaClip:
        return 'videocam';
      case externalOutput:
        return 'link';
      case peerApproval:
        return 'people';
      default:
        return 'timer';
    }
  }

  /// Get description for proof type
  static String getDescription(String type) {
    switch (type) {
      case timedSession:
        return 'Track your work time with a timer';
      case reflectionNote:
        return 'Answer reflection questions about your work';
      case smallMediaClip:
        return 'Record a short audio or video clip (10-20 seconds)';
      case externalOutput:
        return 'Share a link or screenshot of your work';
      case peerApproval:
        return 'Get approval from a peer';
      default:
        return 'Track your work time with a timer';
    }
  }
}

