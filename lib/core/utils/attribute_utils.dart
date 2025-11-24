import 'package:flutter/material.dart';

/// Centralized utility for attribute colors and information
/// Used throughout the app to ensure consistent color coding
class AttributeUtils {
  /// Get color for an attribute
  static Color getAttributeColor(String attribute) {
    switch (attribute.toLowerCase()) {
      case 'wisdom':
        return const Color(0xFF9C27B0); // Purple
      case 'confidence':
        return const Color(0xFF4CAF50); // Green
      case 'strength':
        return const Color(0xFFFF9800); // Orange
      case 'discipline':
        return const Color(0xFF2196F3); // Blue
      case 'focus':
        return const Color(0xFF00BCD4); // Teal
      default:
        return Colors.orange;
    }
  }

  /// Get icon for an attribute
  static IconData getAttributeIcon(String attribute) {
    switch (attribute.toLowerCase()) {
      case 'wisdom':
        return Icons.psychology;
      case 'confidence':
        return Icons.self_improvement;
      case 'strength':
        return Icons.fitness_center;
      case 'discipline':
        return Icons.lock;
      case 'focus':
        return Icons.center_focus_strong;
      default:
        return Icons.info;
    }
  }

  /// Get gradient colors for an attribute
  static List<Color> getAttributeGradient(String attribute) {
    final color = getAttributeColor(attribute);
    return [
      color,
      color.withValues(alpha: 0.7),
    ];
  }

  /// Determine attribute from task title, description, and category
  /// This is used as a fallback if attribute is not in database
  static String determineAttribute({
    required String title,
    required String description,
    required String category,
  }) {
    final titleLower = title.toLowerCase();
    final descLower = description.toLowerCase();
    final categoryLower = category.toLowerCase();
    
    // Wisdom: Reading, learning, meditation, reflection, journaling
    if (titleLower.contains('read') || 
        titleLower.contains('learn') || 
        titleLower.contains('meditate') || 
        titleLower.contains('journal') ||
        titleLower.contains('gratitude') ||
        descLower.contains('read') ||
        descLower.contains('learn') ||
        descLower.contains('knowledge') ||
        descLower.contains('reflect')) {
      return 'Wisdom';
    }
    
    // Strength: Workout, exercise, physical activity, cold shower
    if (titleLower.contains('workout') || 
        titleLower.contains('exercise') || 
        titleLower.contains('gym') ||
        titleLower.contains('run') ||
        titleLower.contains('cold shower') ||
        descLower.contains('physical') ||
        descLower.contains('fitness') ||
        descLower.contains('strength')) {
      return 'Strength';
    }
    
    // Focus: Meditation, planning, organization, deep breathing
    if (titleLower.contains('meditate') ||
        titleLower.contains('plan') ||
        titleLower.contains('breathing') ||
        titleLower.contains('focus') ||
        descLower.contains('concentration') ||
        descLower.contains('focus') ||
        descLower.contains('planning')) {
      return 'Focus';
    }
    
    // Discipline: Wake up early, consistency tasks, routine tasks
    if (titleLower.contains('wake up') ||
        titleLower.contains('early') ||
        titleLower.contains('routine') ||
        titleLower.contains('consistent') ||
        descLower.contains('discipline') ||
        descLower.contains('routine') ||
        descLower.contains('consistent')) {
      return 'Discipline';
    }
    
    // Confidence: Social interactions, community, achievements
    if (titleLower.contains('social') ||
        titleLower.contains('connect') ||
        titleLower.contains('community') ||
        descLower.contains('social') ||
        descLower.contains('connect') ||
        categoryLower.contains('social')) {
      return 'Confidence';
    }
    
    // Default based on category
    if (categoryLower.contains('health') || categoryLower.contains('fitness')) {
      return 'Strength';
    } else if (categoryLower.contains('mindfulness') || categoryLower.contains('mental')) {
      return 'Wisdom';
    } else if (categoryLower.contains('productivity') || categoryLower.contains('learning')) {
      return 'Wisdom';
    } else if (categoryLower.contains('personal') || categoryLower.contains('development')) {
      return 'Discipline';
    }
    
    // Default to Focus for general tasks
    return 'Focus';
  }
}

