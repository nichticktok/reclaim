import 'package:flutter_test/flutter_test.dart';
import 'package:recalim/core/attributes/attribute_calculator.dart';
import 'package:recalim/core/attributes/attribute_config.dart';

void main() {
  group('AttributeCalculator', () {
    late AttributeCalculator calculator;

    setUp(() {
      calculator = AttributeCalculator();
    });

    test('should return baseline scores for empty input', () {
      final result = calculator.calculate({});
      
      expect(result['wisdom'], equals(40.0));
      expect(result['confidence'], equals(40.0));
      expect(result['strength'], equals(40.0));
      expect(result['discipline'], equals(40.0));
      expect(result['focus'], equals(40.0));
    });

    test('should handle missing metrics gracefully', () {
      final result = calculator.calculate({
        'tasksCompleted': 100.0,
        // Other metrics missing
      });

      // Should still calculate with available metrics
      expect(result['wisdom'], isA<double>());
      expect(result['confidence'], isA<double>());
      expect(result['strength'], isA<double>());
      expect(result['discipline'], isA<double>());
      expect(result['focus'], isA<double>());
    });

    test('should clamp all outputs to 0-100 range', () {
      // Use extreme values to test clamping
      final result = calculator.calculate({
        'tasksCompleted': 100000.0,
        'currentStreak': 10000.0,
        'workoutMinutes': 100000.0,
        'meditationMinutes': 100000.0,
        'readingMinutes': 100000.0,
        'taskCompletionRate': 1.0,
        'consistencyScore': 1.0,
        'proofSubmitted': 10000.0,
      });

      for (var value in result.values) {
        expect(value, greaterThanOrEqualTo(0.0));
        expect(value, lessThanOrEqualTo(100.0));
      }
    });

    test('should handle NaN values', () {
      final result = calculator.calculate({
        'tasksCompleted': double.nan,
        'currentStreak': 10.0,
      });

      // Should not crash and should produce valid outputs
      for (var value in result.values) {
        expect(value.isNaN, isFalse);
        expect(value.isInfinite, isFalse);
      }
    });

    test('should handle negative values', () {
      final result = calculator.calculate({
        'tasksCompleted': -100.0,
        'currentStreak': -10.0,
      });

      // Should clamp negatives to 0
      for (var value in result.values) {
        expect(value, greaterThanOrEqualTo(0.0));
      }
    });

    test('should handle infinite values', () {
      final result = calculator.calculate({
        'tasksCompleted': double.infinity,
        'currentStreak': 10.0,
      });

      // Should not crash
      for (var value in result.values) {
        expect(value.isNaN, isFalse);
        expect(value.isInfinite, isFalse);
      }
    });

    test('should produce higher scores with better metrics', () {
      final lowMetrics = {
        'tasksCompleted': 10.0,
        'currentStreak': 1.0,
        'taskCompletionRate': 0.3,
      };

      final highMetrics = {
        'tasksCompleted': 500.0,
        'currentStreak': 30.0,
        'taskCompletionRate': 0.9,
      };

      final lowResult = calculator.calculate(lowMetrics);
      final highResult = calculator.calculate(highMetrics);

      // High metrics should generally produce higher scores
      expect(highResult['discipline']! >= lowResult['discipline']!, isTrue);
      expect(highResult['focus']! >= lowResult['focus']!, isTrue);
    });

    test('should be consistent (same input = same output)', () {
      final metrics = {
        'tasksCompleted': 100.0,
        'currentStreak': 10.0,
        'workoutMinutes': 500.0,
        'meditationMinutes': 200.0,
        'readingMinutes': 300.0,
        'taskCompletionRate': 0.8,
        'consistencyScore': 0.7,
      };

      final result1 = calculator.calculate(metrics);
      final result2 = calculator.calculate(metrics);

      expect(result1, equals(result2));
    });

    test('should work with custom configuration', () {
      final customConfig = AttributeConfig(
        metricCaps: {'tasksCompleted': 200.0},
        attributeWeights: {
          'wisdom': {'tasksCompleted': 1.0},
          'confidence': {'tasksCompleted': 1.0},
          'strength': {'tasksCompleted': 1.0},
          'discipline': {'tasksCompleted': 1.0},
          'focus': {'tasksCompleted': 1.0},
        },
      );

      final customCalculator = AttributeCalculator(config: customConfig);
      final result = customCalculator.calculate({
        'tasksCompleted': 100.0, // 100/200 = 0.5 normalized
      });

      // Should be around 50 (0.5 * 100)
      expect(result['wisdom'], closeTo(50.0, 1.0));
    });

    test('should normalize metrics correctly', () {
      final config = AttributeConfig.defaultConfig();
      final testCalculator = AttributeCalculator(config: config);

      // Test with metric at cap
      final atCap = testCalculator.calculate({
        'tasksCompleted': config.metricCaps['tasksCompleted']!,
      });

      // Test with metric at half cap
      final atHalfCap = testCalculator.calculate({
        'tasksCompleted': config.metricCaps['tasksCompleted']! / 2,
      });

      // At cap should produce higher scores than at half cap
      expect(atCap['wisdom']! >= atHalfCap['wisdom']!, isTrue);
    });

    test('should handle all required metrics', () {
      final allMetrics = {
        'tasksCompleted': 100.0,
        'currentStreak': 10.0,
        'longestStreak': 15.0,
        'workoutMinutes': 500.0,
        'meditationMinutes': 200.0,
        'readingMinutes': 300.0,
        'sleepQuality': 80.0,
        'taskCompletionRate': 0.8,
        'consistencyScore': 0.7,
        'proofSubmitted': 50.0,
        'socialInteractions': 20.0,
        'reflectionCount': 10.0,
        'achievementsUnlocked': 5.0,
      };

      final result = calculator.calculate(allMetrics);

      // All attributes should be calculated
      expect(result.length, equals(5));
      expect(result.containsKey('wisdom'), isTrue);
      expect(result.containsKey('confidence'), isTrue);
      expect(result.containsKey('strength'), isTrue);
      expect(result.containsKey('discipline'), isTrue);
      expect(result.containsKey('focus'), isTrue);

      // All should be in valid range
      for (var value in result.values) {
        expect(value, greaterThanOrEqualTo(0.0));
        expect(value, lessThanOrEqualTo(100.0));
      }
    });
  });
}

