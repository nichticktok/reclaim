class UserModel {
  String id;
  String name;
  String email;
  String goal;
  bool proofMode;
  List<String> habits;
  int level;
  int streak;
  bool isPremium;

  // 👇 New fields for onboarding tracking
  int onboardingStep;
  bool onboardingCompleted;
  Map<String, dynamic> onboardingData;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.goal,
    this.proofMode = true,
    this.habits = const [],
    this.level = 1,
    this.streak = 0,
    this.isPremium = false,
    this.onboardingStep = 0,
    this.onboardingCompleted = false,
    this.onboardingData = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'goal': goal,
      'proofMode': proofMode,
      'habits': habits,
      'level': level,
      'streak': streak,
      'isPremium': isPremium,
      'onboardingStep': onboardingStep,
      'onboardingCompleted': onboardingCompleted,
      'onboardingData': onboardingData,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      goal: map['goal'] ?? '',
      proofMode: map['proofMode'] ?? true,
      habits: List<String>.from(map['habits'] ?? []),
      level: map['level'] ?? 1,
      streak: map['streak'] ?? 0,
      isPremium: map['isPremium'] ?? false,
      onboardingStep: map['onboardingStep'] ?? 0,
      onboardingCompleted: map['onboardingCompleted'] ?? false,
      onboardingData: Map<String, dynamic>.from(map['onboardingData'] ?? {}),
    );
  }
}
