import '../../l10n/app_localizations.dart';
import 'language_provider.dart';

/// Helper extension to provide backward compatibility and easier access
extension LanguageHelper on AppLocalizations {
  /// Get localized options for onboarding screens
  List<LangOption> getOnboardingOptions(String screenKey) {
    switch (screenKey) {
      case 'onboarding_age':
        return [
          LangOption(id: '13_17', label: onboardingAge13_17),
          LangOption(id: '18_24', label: onboardingAge18_24),
          LangOption(id: '25_34', label: onboardingAge25_34),
          LangOption(id: '35_44', label: onboardingAge35_44),
          LangOption(id: '45_54', label: onboardingAge45_54),
          LangOption(id: '55_plus', label: onboardingAge55_plus),
        ];
      case 'onboarding_gender':
        return [
          LangOption(id: 'male', label: onboardingGenderMale),
          LangOption(id: 'female', label: onboardingGenderFemale),
          LangOption(id: 'other', label: onboardingGenderOther),
          LangOption(id: 'prefer_not', label: onboardingGenderPreferNot),
        ];
      case 'onboarding_main':
        return [
          LangOption(id: 'main_today', label: onboardingMainToday),
          LangOption(id: 'main_week', label: onboardingMainWeek),
          LangOption(id: 'main_months', label: onboardingMainMonths),
          LangOption(id: 'main_cant_remember', label: onboardingMainCantRemember),
        ];
      case 'onboarding_life':
        return [
          LangOption(id: 'life_satisfied', label: onboardingLifeSatisfied),
          LangOption(id: 'life_self_improve', label: onboardingLifeSelfImprove),
          LangOption(id: 'life_okay_neutral', label: onboardingLifeOkayNeutral),
          LangOption(id: 'life_often_sad', label: onboardingLifeOftenSad),
          LangOption(id: 'life_lowest_need_help', label: onboardingLifeLowestNeedHelp),
        ];
      case 'onboarding_drive':
        return [
          LangOption(id: 'ambition', label: onboardingDriveAmbition),
          LangOption(id: 'love', label: onboardingDriveLove),
          LangOption(id: 'growth', label: onboardingDriveGrowth),
          LangOption(id: 'peace', label: onboardingDrivePeace),
          LangOption(id: 'curiosity', label: onboardingDriveCuriosity),
        ];
      case 'onboarding_dark':
        return [
          LangOption(id: 'procrastination', label: onboardingDarkProcrastination),
          LangOption(id: 'overthinking', label: onboardingDarkOverthinking),
          LangOption(id: 'negativity', label: onboardingDarkNegativity),
          LangOption(id: 'addiction_phone_social', label: onboardingDarkAddictionPhoneSocial),
          LangOption(id: 'lack_self_discipline', label: onboardingDarkLackSelfDiscipline),
          LangOption(id: 'poor_sleep', label: onboardingDarkPoorSleep),
        ];
      default:
        return [];
    }
  }
  
  /// Format number with localization (for Nepali numbers)
  String formatNumber(dynamic number) {
    // For now, just return as string. Can add Nepali number conversion if needed
    return number.toString();
  }
}

