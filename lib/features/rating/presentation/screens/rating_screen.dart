import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/attributes/attribute_service.dart';

class RatingScreen extends StatefulWidget {
  const RatingScreen({super.key});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  String _selectedTab = 'Current rating'; // Current rating, Day 1 rating, Day 66
  Map<String, int>? _currentRatings;
  Map<String, int>? _day1Ratings;
  Map<String, int>? _day66Ratings;
  bool _loading = true;
  int _level = 1;
  int _totalXP = 0;
  int _xpToNextLevel = 150;

  @override
  void initState() {
    super.initState();
    _loadRatingData();
  }

  Future<void> _loadRatingData() async {
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Use AttributeService to calculate current ratings
      final attributeService = AttributeService();
      final calculatedRatings = await attributeService.calculateUserAttributes();
      
      // Convert to int map
      _currentRatings = {
        'wisdom': calculatedRatings['wisdom']?.round() ?? 40,
        'confidence': calculatedRatings['confidence']?.round() ?? 40,
        'strength': calculatedRatings['strength']?.round() ?? 40,
        'discipline': calculatedRatings['discipline']?.round() ?? 40,
        'focus': calculatedRatings['focus']?.round() ?? 40,
      };

      // Also update Firestore with calculated ratings
      await attributeService.updateUserRatings();

      // Load Day 1 ratings (from onboarding)
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();

        // Load Day 1 ratings (from onboarding)
        final onboardingData = data?['onboardingData'] as Map<String, dynamic>? ?? {};
        final day1Rating = onboardingData['currentRating'] as int? ?? 40;
        _day1Ratings = {
          'wisdom': day1Rating ~/ 5,
          'confidence': day1Rating ~/ 5,
          'strength': day1Rating ~/ 5,
          'discipline': day1Rating ~/ 5,
          'focus': day1Rating ~/ 5,
        };

        // Calculate Day 66 ratings (potential - from onboarding)
        final potentialRating = onboardingData['potentialRating'] as int? ?? 80;
        _day66Ratings = {
          'wisdom': potentialRating ~/ 5,
          'confidence': potentialRating ~/ 5,
          'strength': potentialRating ~/ 5,
          'discipline': potentialRating ~/ 5,
          'focus': potentialRating ~/ 5,
        };

        // Load level and XP
        _level = (data?['level'] ?? 1) as int;
        _totalXP = (data?['totalXP'] ?? 0) as int;
        _xpToNextLevel = _calculateXPToNextLevel(_level, _totalXP);
      }
    } catch (e) {
      debugPrint('Error loading rating data: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  int _calculateXPToNextLevel(int level, int totalXP) {
    // XP required per level increases: 150, 200, 250, etc.
    final xpForCurrentLevel = 150 + ((level - 1) * 50);
    final xpForNextLevel = 150 + (level * 50);
    final xpInCurrentLevel = totalXP % xpForCurrentLevel;
    return xpForNextLevel - xpInCurrentLevel;
  }

  Map<String, int>? _getSelectedRatings() {
    switch (_selectedTab) {
      case 'Current rating':
        return _currentRatings;
      case 'Day 1 rating':
        return _day1Ratings;
      case 'Day 66':
        return _day66Ratings;
      default:
        return _currentRatings;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with back button
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.black,
                                size: 20,
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Row(
                              children: [
                                Text(
                                  'Your Rating',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.auto_awesome,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Tabs
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildTab('Current rating'),
                          const SizedBox(width: 8),
                          _buildTab('Day 1 rating'),
                          const SizedBox(width: 8),
                          _buildTab('Day 66'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Level and XP Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    // Level card
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '$_level',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 36,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Text(
                                            'LEVEL',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // XP earned
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$_totalXP',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'XP earned',
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.7),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Progress bar
                                _buildXPProgressBar(),
                                const SizedBox(height: 8),
                                Text(
                                  '$_xpToNextLevel XP to Lvl ${_level + 1}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                    ),

                    const SizedBox(height: 24),

                    // Attributes List
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => _showAttributeDetails(context, 'Wisdom', _getSelectedRatings()?['wisdom'] ?? 0, const Color(0xFF9C27B0)),
                            child: _buildAttributeItem(
                              'Wisdom',
                              _getSelectedRatings()?['wisdom'] ?? 0,
                              Icons.psychology,
                              const Color(0xFF9C27B0),
                              _getRatingChange('wisdom'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () => _showAttributeDetails(context, 'Confidence', _getSelectedRatings()?['confidence'] ?? 0, const Color(0xFF4CAF50)),
                            child: _buildAttributeItem(
                              'Confidence',
                              _getSelectedRatings()?['confidence'] ?? 0,
                              Icons.self_improvement,
                              const Color(0xFF4CAF50),
                              _getRatingChange('confidence'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () => _showAttributeDetails(context, 'Strength', _getSelectedRatings()?['strength'] ?? 0, const Color(0xFFFF9800)),
                            child: _buildAttributeItem(
                              'Strength',
                              _getSelectedRatings()?['strength'] ?? 0,
                              Icons.fitness_center,
                              const Color(0xFFFF9800),
                              _getRatingChange('strength'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () => _showAttributeDetails(context, 'Discipline', _getSelectedRatings()?['discipline'] ?? 0, const Color(0xFF2196F3)),
                            child: _buildAttributeItem(
                              'Discipline',
                              _getSelectedRatings()?['discipline'] ?? 0,
                              Icons.lock,
                              const Color(0xFF2196F3),
                              _getRatingChange('discipline'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () => _showAttributeDetails(context, 'Focus', _getSelectedRatings()?['focus'] ?? 0, const Color(0xFF00BCD4)),
                            child: _buildAttributeItem(
                              'Focus',
                              _getSelectedRatings()?['focus'] ?? 0,
                              Icons.center_focus_strong,
                              const Color(0xFF00BCD4),
                              _getRatingChange('focus'),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTab(String label) {
    final isSelected = _selectedTab == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: Colors.white, width: 1)
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildXPProgressBar() {
    final progress = _calculateXPProgress();
    final filledBlocks = (progress * 20).round();
    
    return Row(
      children: List.generate(20, (index) {
        final isFilled = index < filledBlocks;
        return Expanded(
          child: Container(
            height: 8,
            margin: EdgeInsets.only(right: index < 19 ? 4 : 0),
            decoration: BoxDecoration(
              color: isFilled ? Colors.orange : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  double _calculateXPProgress() {
    final xpForCurrentLevel = 150 + ((_level - 1) * 50);
    final xpInCurrentLevel = _totalXP % xpForCurrentLevel;
    final xpForNextLevel = 150 + (_level * 50);
    return (xpInCurrentLevel / xpForNextLevel).clamp(0.0, 1.0);
  }

  int? _getRatingChange(String attribute) {
    if (_selectedTab == 'Current rating' && _currentRatings != null && _day1Ratings != null) {
      final current = _currentRatings![attribute] ?? 0;
      final day1 = _day1Ratings![attribute] ?? 0;
      final change = current - day1;
      return change != 0 ? change : null;
    }
    return null;
  }

  Widget _buildAttributeItem(
    String name,
    int value,
    IconData icon,
    Color iconColor,
    int? change,
  ) {
    final hasIncrease = change != null && change > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Name
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Change indicator
          if (change != null) ...[
            Row(
              children: [
                Icon(
                  hasIncrease ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: hasIncrease ? Colors.green : Colors.red,
                  size: 20,
                ),
                Text(
                  change.abs().toString(),
                  style: TextStyle(
                    color: hasIncrease ? Colors.green : Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
          ],
          // Value
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showAttributeDetails(BuildContext context, String attributeName, int score, Color attributeColor) {
    // Define what contributes to each attribute
    final Map<String, Map<String, String>> attributeInfo = {
      'Wisdom': {
        'description': 'Measures your commitment to learning, self-reflection, and knowledge growth.',
        'readingMinutes': 'Read books, articles, or educational content (30% weight)',
        'meditationMinutes': 'Meditate regularly to improve mindfulness (25% weight)',
        'reflectionCount': 'Complete reflections on your progress (20% weight)',
        'tasksCompleted': 'Complete tasks consistently (15% weight)',
        'achievementsUnlocked': 'Unlock achievements to track progress (10% weight)',
      },
      'Confidence': {
        'description': 'Measures your social engagement, achievement recognition, and self-belief.',
        'socialInteractions': 'Engage with the community - post, comment, interact (30% weight)',
        'achievementsUnlocked': 'Unlock achievements to build confidence (25% weight)',
        'currentStreak': 'Maintain your daily streak (20% weight)',
        'taskCompletionRate': 'Complete tasks consistently (15% weight)',
        'reflectionCount': 'Reflect on your progress and growth (10% weight)',
      },
      'Strength': {
        'description': 'Measures your physical activity, workout consistency, and proof submission.',
        'workoutMinutes': 'Exercise and workout regularly (40% weight)',
        'currentStreak': 'Maintain your daily streak (25% weight)',
        'proofSubmitted': 'Submit proof for tasks requiring verification (20% weight)',
        'consistencyScore': 'Be consistent with your routine (15% weight)',
      },
      'Discipline': {
        'description': 'Measures your consistency, long-term commitment, and ability to maintain streaks.',
        'currentStreak': 'Maintain your current daily streak (30% weight)',
        'longestStreak': 'Build your longest streak record (25% weight)',
        'consistencyScore': 'Be consistent day-to-day (25% weight)',
        'taskCompletionRate': 'Complete tasks regularly (20% weight)',
      },
      'Focus': {
        'description': 'Measures your ability to complete tasks, maintain concentration, and stay focused.',
        'taskCompletionRate': 'Complete tasks consistently with high completion rate (30% weight)',
        'meditationMinutes': 'Meditate to improve concentration (25% weight)',
        'consistencyScore': 'Maintain consistency in your routine (25% weight)',
        'tasksCompleted': 'Complete more tasks overall (20% weight)',
      },
    };

    final info = attributeInfo[attributeName] ?? {};
    final description = info['description'] ?? '';
    final contributors = info.entries
        .where((e) => e.key != 'description')
        .map((e) => MapEntry(e.key, e.value))
        .toList()
      ..sort((a, b) {
        // Sort by weight percentage (extract from string)
        final aWeight = double.tryParse(a.value.split('%')[0].split('(').last) ?? 0;
        final bWeight = double.tryParse(b.value.split('%')[0].split('(').last) ?? 0;
        return bWeight.compareTo(aWeight); // Descending order
      });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: attributeColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getAttributeIcon(attributeName),
                      color: attributeColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attributeName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Score: $score',
                          style: TextStyle(
                            color: attributeColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // How to improve section
                    Text(
                      'How to Improve $attributeName:',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Contributors list
                    ...contributors.map((contributor) {
                      final description = contributor.value;
                      final weightMatch = RegExp(r'\((\d+)%').firstMatch(description);
                      final weight = weightMatch?.group(1) ?? '0';
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: attributeColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Weight badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: attributeColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$weight%',
                                style: TextStyle(
                                  color: attributeColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Description
                            Expanded(
                              child: Text(
                                description,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                    // Tips section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: attributeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: attributeColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: attributeColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Focus on the highest weighted activities first for maximum impact!',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAttributeIcon(String attributeName) {
    switch (attributeName) {
      case 'Wisdom':
        return Icons.psychology;
      case 'Confidence':
        return Icons.self_improvement;
      case 'Strength':
        return Icons.fitness_center;
      case 'Discipline':
        return Icons.lock;
      case 'Focus':
        return Icons.center_focus_strong;
      default:
        return Icons.info;
    }
  }
}

