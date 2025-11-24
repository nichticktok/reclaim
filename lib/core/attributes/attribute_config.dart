/// Configuration for attribute calculation
/// Defines caps, weights, and normalization parameters
class AttributeConfig {
  /// Maximum expected values for each metric (used for normalization)
  final Map<String, double> metricCaps;

  /// Weights for each attribute calculation
  /// Format: {attribute: {metric: weight}}
  final Map<String, Map<String, double>> attributeWeights;

  /// Baseline score for new users (when no metrics available)
  final double baselineScore;

  /// Minimum attribute score (floor)
  final double minScore;

  /// Maximum attribute score (ceiling)
  final double maxScore;

  const AttributeConfig({
    required this.metricCaps,
    required this.attributeWeights,
    this.baselineScore = 40.0,
    this.minScore = 0.0,
    this.maxScore = 100.0,
  });

  /// Default configuration with recommended values
  factory AttributeConfig.defaultConfig() {
    return AttributeConfig(
      metricCaps: {
        // Task metrics
        'tasksCompleted': 1000.0, // Cap at 1000 tasks
        'currentStreak': 365.0, // Cap at 1 year
        'longestStreak': 365.0,
        'taskCompletionRate': 1.0, // Already 0-1
        'consistencyScore': 1.0, // Already 0-1
        'proofSubmitted': 500.0, // Cap at 500 proofs
        
        // Time-based metrics (in minutes)
        'workoutMinutes': 10000.0, // ~166 hours
        'meditationMinutes': 5000.0, // ~83 hours
        'readingMinutes': 5000.0, // ~83 hours
        
        // Quality metrics
        'sleepQuality': 100.0, // Already 0-100
        
        // Engagement metrics
        'socialInteractions': 1000.0,
        'reflectionCount': 500.0,
        'achievementsUnlocked': 100.0,
      },
      attributeWeights: {
        'wisdom': {
          'readingMinutes': 0.30,
          'meditationMinutes': 0.25,
          'reflectionCount': 0.20,
          'tasksCompleted': 0.15,
          'achievementsUnlocked': 0.10,
        },
        'confidence': {
          'socialInteractions': 0.30,
          'achievementsUnlocked': 0.25,
          'currentStreak': 0.20,
          'taskCompletionRate': 0.15,
          'reflectionCount': 0.10,
        },
        'strength': {
          'workoutMinutes': 0.40,
          'currentStreak': 0.25,
          'proofSubmitted': 0.20,
          'consistencyScore': 0.15,
        },
        'discipline': {
          'currentStreak': 0.30,
          'longestStreak': 0.25,
          'consistencyScore': 0.25,
          'taskCompletionRate': 0.20,
        },
        'focus': {
          'taskCompletionRate': 0.30,
          'meditationMinutes': 0.25,
          'consistencyScore': 0.25,
          'tasksCompleted': 0.20,
        },
      },
    );
  }

  /// Create config from remote config (for A/B testing)
  factory AttributeConfig.fromRemote(Map<String, dynamic> remote) {
    return AttributeConfig(
      metricCaps: Map<String, double>.from(remote['metricCaps'] ?? {}),
      attributeWeights: (remote['attributeWeights'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(
                    key,
                    Map<String, double>.from(value as Map),
                  )) ??
          {},
      baselineScore: (remote['baselineScore'] as num?)?.toDouble() ?? 40.0,
      minScore: (remote['minScore'] as num?)?.toDouble() ?? 0.0,
      maxScore: (remote['maxScore'] as num?)?.toDouble() ?? 100.0,
    );
  }

  /// Validate configuration
  bool validate() {
    // Check all weights sum to reasonable values (0.8-1.2 range)
    for (var attribute in attributeWeights.keys) {
      final weights = attributeWeights[attribute]!;
      final sum = weights.values.reduce((a, b) => a + b);
      if (sum < 0.5 || sum > 1.5) {
        return false; // Weights should roughly sum to 1.0
      }
    }
    return true;
  }
}

