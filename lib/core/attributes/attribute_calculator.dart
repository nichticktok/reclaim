import 'dart:math' as math;
import 'attribute_config.dart';

/// Calculates user attributes (Wisdom, Confidence, Strength, Discipline, Focus)
/// from raw metrics (tasks completed, streaks, exercise time, etc.)
///
/// Thread-safe and stateless. All calculations are pure functions.
class AttributeCalculator {
  final AttributeConfig _config;

  /// Create calculator with custom configuration
  AttributeCalculator({AttributeConfig? config})
      : _config = config ?? AttributeConfig.defaultConfig();

  /// Calculate all attributes from raw metrics
  ///
  /// [metrics] - Map of metric names to values
  /// Returns Map of attribute names to scores (0-100)
  Map<String, double> calculate(Map<String, double> metrics) {
    // Normalize and clamp all input metrics
    final normalizedMetrics = _normalizeMetrics(metrics);

    // Calculate each attribute
    return {
      'wisdom': _calculateAttribute('wisdom', normalizedMetrics),
      'confidence': _calculateAttribute('confidence', normalizedMetrics),
      'strength': _calculateAttribute('strength', normalizedMetrics),
      'discipline': _calculateAttribute('discipline', normalizedMetrics),
      'focus': _calculateAttribute('focus', normalizedMetrics),
    };
  }

  /// Normalize metrics to 0-1 range using caps
  Map<String, double> _normalizeMetrics(Map<String, double> metrics) {
    final normalized = <String, double>{};

    for (var entry in metrics.entries) {
      final metricName = entry.key;
      final value = entry.value;

      // Handle invalid values
      if (value.isNaN || value.isInfinite) {
        normalized[metricName] = 0.0;
        continue;
      }

      // Clamp negative values to 0
      final clampedValue = math.max(0.0, value);

      // Get cap for this metric
      final cap = _config.metricCaps[metricName] ?? 1.0;

      // Normalize to 0-1 range
      if (cap <= 0) {
        normalized[metricName] = 0.0;
      } else {
        normalized[metricName] = (clampedValue / cap).clamp(0.0, 1.0);
      }
    }

    return normalized;
  }

  /// Calculate a single attribute using weighted average
  double _calculateAttribute(
    String attributeName,
    Map<String, double> normalizedMetrics,
  ) {
    final weights = _config.attributeWeights[attributeName];
    if (weights == null || weights.isEmpty) {
      return _config.baselineScore;
    }

    // If no metrics provided at all, return baseline
    if (normalizedMetrics.isEmpty) {
      return _config.baselineScore;
    }

    double weightedSum = 0.0;
    double totalWeight = 0.0;
    bool hasAnyMetric = false;

    for (var entry in weights.entries) {
      final metricName = entry.key;
      final weight = entry.value;

      // Get normalized metric value (default to 0 if missing)
      final metricValue = normalizedMetrics[metricName] ?? 0.0;
      
      // Track if we have at least one metric
      if (normalizedMetrics.containsKey(metricName)) {
        hasAnyMetric = true;
      }

      // Add weighted contribution
      weightedSum += metricValue * weight;
      totalWeight += weight;
    }

    // If no relevant metrics were provided, return baseline
    if (!hasAnyMetric || totalWeight <= 0) {
      return _config.baselineScore;
    }

    final rawScore = (weightedSum / totalWeight) * 100.0;

    // Clamp to valid range
    return rawScore.clamp(_config.minScore, _config.maxScore);
  }

  /// Get current configuration (read-only)
  AttributeConfig get config => _config;
}

