import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ne.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ne'),
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'Reclaim'**
  String get appTitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next →'**
  String get next;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip →'**
  String get skip;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Reclaim 👋'**
  String get welcome;

  /// Welcome message shown after onboarding
  ///
  /// In en, this message translates to:
  /// **'You\'re all set! Let\'s start your journey to reclaim your life.'**
  String get welcomeMessage;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @namePrompt.
  ///
  /// In en, this message translates to:
  /// **'Let\'s start by knowing your name.'**
  String get namePrompt;

  /// No description provided for @howOld.
  ///
  /// In en, this message translates to:
  /// **'How old are you?'**
  String get howOld;

  /// No description provided for @genderQuestion.
  ///
  /// In en, this message translates to:
  /// **'What\'s your gender?'**
  String get genderQuestion;

  /// No description provided for @chooseCharacter.
  ///
  /// In en, this message translates to:
  /// **'Choose your character'**
  String get chooseCharacter;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @awakeningLine1.
  ///
  /// In en, this message translates to:
  /// **'You were just another face in'**
  String get awakeningLine1;

  /// No description provided for @awakeningLine2.
  ///
  /// In en, this message translates to:
  /// **'the crowd.'**
  String get awakeningLine2;

  /// No description provided for @awakeningLine3.
  ///
  /// In en, this message translates to:
  /// **'Tired. Stuck. Running on\nautopilot... until now.'**
  String get awakeningLine3;

  /// No description provided for @onboardingNameTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your name?'**
  String get onboardingNameTitle;

  /// No description provided for @onboardingNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get onboardingNameHint;

  /// No description provided for @onboardingAgeTitle.
  ///
  /// In en, this message translates to:
  /// **'How old are you?'**
  String get onboardingAgeTitle;

  /// No description provided for @onboardingAge13_17.
  ///
  /// In en, this message translates to:
  /// **'13 to 17'**
  String get onboardingAge13_17;

  /// No description provided for @onboardingAge18_24.
  ///
  /// In en, this message translates to:
  /// **'18 to 24'**
  String get onboardingAge18_24;

  /// No description provided for @onboardingAge25_34.
  ///
  /// In en, this message translates to:
  /// **'25 to 34'**
  String get onboardingAge25_34;

  /// No description provided for @onboardingAge35_44.
  ///
  /// In en, this message translates to:
  /// **'35 to 44'**
  String get onboardingAge35_44;

  /// No description provided for @onboardingAge45_54.
  ///
  /// In en, this message translates to:
  /// **'45 to 54'**
  String get onboardingAge45_54;

  /// No description provided for @onboardingAge55_plus.
  ///
  /// In en, this message translates to:
  /// **'55 or above'**
  String get onboardingAge55_plus;

  /// No description provided for @onboardingGenderTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your gender?'**
  String get onboardingGenderTitle;

  /// No description provided for @onboardingGenderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get onboardingGenderMale;

  /// No description provided for @onboardingGenderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get onboardingGenderFemale;

  /// No description provided for @onboardingGenderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get onboardingGenderOther;

  /// No description provided for @onboardingGenderPreferNot.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to answer'**
  String get onboardingGenderPreferNot;

  /// No description provided for @onboardingMainTitle.
  ///
  /// In en, this message translates to:
  /// **'When did you last feel like the main character?'**
  String get onboardingMainTitle;

  /// No description provided for @onboardingMainToday.
  ///
  /// In en, this message translates to:
  /// **'Today — I\'m on a roll lately!'**
  String get onboardingMainToday;

  /// No description provided for @onboardingMainWeek.
  ///
  /// In en, this message translates to:
  /// **'This week — I\'ve been consistent.'**
  String get onboardingMainWeek;

  /// No description provided for @onboardingMainMonths.
  ///
  /// In en, this message translates to:
  /// **'It\'s been months, I\'ve lost touch.'**
  String get onboardingMainMonths;

  /// No description provided for @onboardingMainCantRemember.
  ///
  /// In en, this message translates to:
  /// **'I can\'t even remember the last time.'**
  String get onboardingMainCantRemember;

  /// No description provided for @onboardingLifeTitle.
  ///
  /// In en, this message translates to:
  /// **'How would you describe your current life?'**
  String get onboardingLifeTitle;

  /// No description provided for @onboardingLifeSatisfied.
  ///
  /// In en, this message translates to:
  /// **'I\'m satisfied with my life now'**
  String get onboardingLifeSatisfied;

  /// No description provided for @onboardingLifeSelfImprove.
  ///
  /// In en, this message translates to:
  /// **'I\'m alright and want to self-improve'**
  String get onboardingLifeSelfImprove;

  /// No description provided for @onboardingLifeOkayNeutral.
  ///
  /// In en, this message translates to:
  /// **'I\'m doing okay, not good or bad'**
  String get onboardingLifeOkayNeutral;

  /// No description provided for @onboardingLifeOftenSad.
  ///
  /// In en, this message translates to:
  /// **'I\'m often sad and rarely happy'**
  String get onboardingLifeOftenSad;

  /// No description provided for @onboardingLifeLowestNeedHelp.
  ///
  /// In en, this message translates to:
  /// **'I\'m at the lowest and need help'**
  String get onboardingLifeLowestNeedHelp;

  /// No description provided for @onboardingDriveTitle.
  ///
  /// In en, this message translates to:
  /// **'What drives your journey every day?'**
  String get onboardingDriveTitle;

  /// No description provided for @onboardingDriveAmbition.
  ///
  /// In en, this message translates to:
  /// **'Ambition — I want to achieve greatness.'**
  String get onboardingDriveAmbition;

  /// No description provided for @onboardingDriveLove.
  ///
  /// In en, this message translates to:
  /// **'Love — I care deeply for the people around me.'**
  String get onboardingDriveLove;

  /// No description provided for @onboardingDriveGrowth.
  ///
  /// In en, this message translates to:
  /// **'Growth — I want to become a better version of myself.'**
  String get onboardingDriveGrowth;

  /// No description provided for @onboardingDrivePeace.
  ///
  /// In en, this message translates to:
  /// **'Peace — I just want balance and calm.'**
  String get onboardingDrivePeace;

  /// No description provided for @onboardingDriveCuriosity.
  ///
  /// In en, this message translates to:
  /// **'Curiosity — I want to explore everything life offers.'**
  String get onboardingDriveCuriosity;

  /// No description provided for @onboardingDarkTitle.
  ///
  /// In en, this message translates to:
  /// **'Any dark habits holding your power back?'**
  String get onboardingDarkTitle;

  /// No description provided for @onboardingDarkProcrastination.
  ///
  /// In en, this message translates to:
  /// **'Procrastination'**
  String get onboardingDarkProcrastination;

  /// No description provided for @onboardingDarkOverthinking.
  ///
  /// In en, this message translates to:
  /// **'Overthinking'**
  String get onboardingDarkOverthinking;

  /// No description provided for @onboardingDarkNegativity.
  ///
  /// In en, this message translates to:
  /// **'Negativity'**
  String get onboardingDarkNegativity;

  /// No description provided for @onboardingDarkAddictionPhoneSocial.
  ///
  /// In en, this message translates to:
  /// **'Addiction to phone/socials'**
  String get onboardingDarkAddictionPhoneSocial;

  /// No description provided for @onboardingDarkLackSelfDiscipline.
  ///
  /// In en, this message translates to:
  /// **'Lack of self-discipline'**
  String get onboardingDarkLackSelfDiscipline;

  /// No description provided for @onboardingDarkPoorSleep.
  ///
  /// In en, this message translates to:
  /// **'Poor sleep routine'**
  String get onboardingDarkPoorSleep;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @journey.
  ///
  /// In en, this message translates to:
  /// **'Journey'**
  String get journey;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @tools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tools;

  /// No description provided for @toDos.
  ///
  /// In en, this message translates to:
  /// **'To-dos'**
  String get toDos;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @skipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get skipped;

  /// No description provided for @noTasksYet.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get noTasksYet;

  /// No description provided for @tapToAddFirstTask.
  ///
  /// In en, this message translates to:
  /// **'Tap the + button to add your first task'**
  String get tapToAddFirstTask;

  /// No description provided for @noTasksToDo.
  ///
  /// In en, this message translates to:
  /// **'No tasks to do'**
  String get noTasksToDo;

  /// No description provided for @noCompletedTasks.
  ///
  /// In en, this message translates to:
  /// **'No completed tasks'**
  String get noCompletedTasks;

  /// No description provided for @noSkippedTasks.
  ///
  /// In en, this message translates to:
  /// **'No skipped tasks'**
  String get noSkippedTasks;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get addTask;

  /// No description provided for @markAsComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark as Complete'**
  String get markAsComplete;

  /// No description provided for @markAsIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Mark as Incomplete'**
  String get markAsIncomplete;

  /// No description provided for @taskCompleted.
  ///
  /// In en, this message translates to:
  /// **'Task Completed'**
  String get taskCompleted;

  /// No description provided for @taskPending.
  ///
  /// In en, this message translates to:
  /// **'Task Pending'**
  String get taskPending;

  /// No description provided for @taskSkipped.
  ///
  /// In en, this message translates to:
  /// **'Task Skipped'**
  String get taskSkipped;

  /// No description provided for @scheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduled;

  /// No description provided for @proofRequired.
  ///
  /// In en, this message translates to:
  /// **'Proof required for this task'**
  String get proofRequired;

  /// No description provided for @submitProof.
  ///
  /// In en, this message translates to:
  /// **'Submit Proof'**
  String get submitProof;

  /// No description provided for @editProof.
  ///
  /// In en, this message translates to:
  /// **'Edit Proof'**
  String get editProof;

  /// No description provided for @deleteTask.
  ///
  /// In en, this message translates to:
  /// **'Delete Task'**
  String get deleteTask;

  /// No description provided for @skipTask.
  ///
  /// In en, this message translates to:
  /// **'Skip Task'**
  String get skipTask;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed to {language}'**
  String languageChanged(String language);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr', 'ne'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ne':
      return AppLocalizationsNe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
