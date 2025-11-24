import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:recalim/core/network/service_registry.dart';
import 'package:recalim/core/providers/language_provider.dart';
import '../features/home/presentation/controllers/home_controller.dart';
import '../features/onboarding/presentation/controllers/onboarding_controller.dart';
import '../features/tasks/presentation/controllers/tasks_controller.dart';
import '../features/tasks/domain/repositories/proof_repository.dart';
import '../features/tasks/data/repositories/firestore_proof_repository.dart';
import '../features/tasks/domain/repositories/deletion_request_repository.dart';
import '../features/tasks/data/repositories/firestore_deletion_request_repository.dart';
import '../features/tasks/data/services/accountability_service.dart';
import '../features/progress/presentation/controllers/progress_controller.dart';
import '../features/profile/presentation/controllers/profile_controller.dart';
import '../features/community/presentation/controllers/community_controller.dart';
import '../features/reflection/presentation/controllers/reflection_controller.dart';
import '../features/subscription/presentation/controllers/subscription_controller.dart';
import '../features/program/presentation/controllers/program_controller.dart';
import '../features/journey/presentation/controllers/journey_controller.dart';
import '../features/mastery/presentation/controllers/mastery_controller.dart';
import '../features/penalty/presentation/controllers/penalty_controller.dart';
import '../features/milestone/presentation/controllers/milestone_controller.dart';
import '../features/achievements/presentation/controllers/achievements_controller.dart';
import '../features/projects/presentation/controllers/projects_controller.dart';
import '../features/workouts/presentation/controllers/workouts_controller.dart';
import '../features/diet/presentation/controllers/diet_controller.dart';
import '../features/book_summary/presentation/controllers/book_summary_controller.dart';
import '../features/workout_counter/presentation/controllers/workout_counter_controller.dart';
import '../features/tools/presentation/controllers/screen_blocker_controller.dart';

/// Dependency Injection / Providers Setup
/// Centralized provider configuration for the app
class AppProviders {
  static List<SingleChildWidget> get providers => [
    Provider<ServiceRegistry>(create: (_) => ServiceRegistry()),
    Provider<http.Client>(
      create: (_) => http.Client(),
      dispose: (_, client) => client.close(),
    ),
    // Global Providers
    ChangeNotifierProvider<LanguageProvider>(
      create: (_) => LanguageProvider()..initialize(),
      lazy: false,
    ),
    // Repositories
    Provider<ProofRepository>(
      create: (_) => FirestoreProofRepository(),
    ),
    Provider<DeletionRequestRepository>(
      create: (_) => FirestoreDeletionRequestRepository(),
    ),
    Provider<AccountabilityService>(
      create: (_) => AccountabilityServiceImpl(),
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
      create: (context) {
        final controller = TasksController();
        final proofRepository = context.read<ProofRepository>();
        final deletionRequestRepository = context.read<DeletionRequestRepository>();
        final accountabilityService = context.read<AccountabilityService>();
        controller.setProofRepository(proofRepository);
        controller.setDeletionRequestRepository(deletionRequestRepository);
        controller.setAccountabilityService(accountabilityService);
        return controller;
      },
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
    ChangeNotifierProvider<MilestoneController>(
      create: (_) => MilestoneController(),
      lazy: true,
    ),
    ChangeNotifierProvider<AchievementsController>(
      create: (_) => AchievementsController(),
      lazy: true,
    ),
    ChangeNotifierProvider<ProjectsController>(
      create: (context) {
        final controller = ProjectsController();
        final deletionRequestRepository = context.read<DeletionRequestRepository>();
        final accountabilityService = context.read<AccountabilityService>();
        controller.setDeletionRequestRepository(deletionRequestRepository);
        controller.setAccountabilityService(accountabilityService);
        return controller;
      },
      lazy: true,
    ),
    ChangeNotifierProvider<WorkoutsController>(
      create: (context) {
        final controller = WorkoutsController();
        final deletionRequestRepository = context.read<DeletionRequestRepository>();
        final accountabilityService = context.read<AccountabilityService>();
        controller.setDeletionRequestRepository(deletionRequestRepository);
        controller.setAccountabilityService(accountabilityService);
        return controller;
      },
      lazy: true,
    ),
    ChangeNotifierProvider<DietController>(
      create: (_) => DietController(),
      lazy: true,
    ),
    ChangeNotifierProvider<BookSummaryController>(
      create: (_) => BookSummaryController(),
      lazy: true,
    ),
    ChangeNotifierProvider<WorkoutCounterController>(
      create: (_) => WorkoutCounterController(),
      lazy: true,
    ),
    ChangeNotifierProvider<ScreenBlockerController>(
      create: (_) => ScreenBlockerController(),
      lazy: false, // Not lazy so it's available globally
    ),
  ];
}
