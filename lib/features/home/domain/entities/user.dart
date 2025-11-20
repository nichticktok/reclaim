/// User entity - Business model
/// This represents the domain concept of a user
class User {
  final String id;
  final String name;
  final String email;
  final String goal;
  final bool proofMode;
  final int level;
  final int streak;
  final bool isPremium;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.goal = '',
    this.proofMode = true,
    this.level = 1,
    this.streak = 0,
    this.isPremium = false,
  });
}

