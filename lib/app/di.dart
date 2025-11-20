import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../features/home/presentation/controllers/home_controller.dart';
import '../features/onboarding/presentation/controllers/onboarding_controller.dart';
import '../features/tasks/presentation/controllers/tasks_controller.dart';
import '../features/progress/presentation/controllers/progress_controller.dart';
import '../features/profile/presentation/controllers/profile_controller.dart';
import '../features/community/presentation/controllers/community_controller.dart';
import '../features/reflection/presentation/controllers/reflection_controller.dart';
import '../features/subscription/presentation/controllers/subscription_controller.dart';
import '../features/program/presentation/controllers/program_controller.dart';
import '../features/journey/presentation/controllers/journey_controller.dart';
import '../features/mastery/presentation/controllers/mastery_controller.dart';
import '../features/penalty/presentation/controllers/penalty_controller.dart';

/// Dependency Injection / Providers Setup
/// Centralized provider configuration for the app
class AppProviders {
  static List<ChangeNotifierProvider> get providers => [
        // Global Providers
        ChangeNotifierProvider<LanguageProvider>(
          create: (_) => LanguageProvider(),
          lazy: false,
        ),
        
        // Feature Controllers - lazy loading to avoid initialization during build
        ChangeNotifierProvider<HomeController>(
          create: (_) => HomeController(),
          lazy: true,
        ),
        ChangeNotifierProvider<OnboardingController>(
          create: (_) => OnboardingController(),
          lazy: true,
        ),
        ChangeNotifierProvider<TasksController>(
          create: (_) => TasksController(),
          lazy: true,
        ),
        ChangeNotifierProvider<ProgressController>(
          create: (_) => ProgressController(),
          lazy: true,
        ),
        ChangeNotifierProvider<ProfileController>(
          create: (_) => ProfileController(),
          lazy: true,
        ),
        ChangeNotifierProvider<CommunityController>(
          create: (_) => CommunityController(),
          lazy: true,
        ),
        ChangeNotifierProvider<ReflectionController>(
          create: (_) => ReflectionController(),
          lazy: true,
        ),
        ChangeNotifierProvider<SubscriptionController>(
          create: (_) => SubscriptionController(),
          lazy: true,
        ),
        // New feature controllers
        ChangeNotifierProvider<ProgramController>(
          create: (_) => ProgramController(),
          lazy: true,
        ),
        ChangeNotifierProvider<JourneyController>(
          create: (_) => JourneyController(),
          lazy: true,
        ),
        ChangeNotifierProvider<MasteryController>(
          create: (_) => MasteryController(),
          lazy: true,
        ),
        ChangeNotifierProvider<PenaltyController>(
          create: (_) => PenaltyController(),
          lazy: true,
        ),
      ];
}

