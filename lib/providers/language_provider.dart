import 'package:flutter/material.dart';

class LangOption {
  final String id;     // stable id, e.g. "18_24"
  final String label;  // localized label
  const LangOption({required this.id, required this.label});
}

class LanguageProvider extends ChangeNotifier {
  String _currentLang = 'English';
  String get currentLang => _currentLang;

  void setLanguage(String newLang) {
    if (_currentLang == newLang) return;
    _currentLang = newLang;
    notifyListeners();
  }

  // 🔢 Nepali number map
  static const Map<String, String> _nepaliNumbers = {
    '0': '०', '1': '१', '2': '२', '3': '३', '4': '४',
    '5': '५', '6': '६', '7': '७', '8': '८', '9': '९',
  };

  // 👉 Option ordering per screen (UI order is language-agnostic)
  static const Map<String, List<String>> _screenOptionOrder = {
    'onboarding_age'   : ['13_17','18_24','25_34','35_44','45_54','55_plus'],
    'onboarding_gender': ['male','female','other','prefer_not'],
    'onboarding_main'  : ['main_today','main_week','main_months','main_cant_remember'],
    'onboarding_life'  : [
      'life_satisfied',
      'life_self_improve',
      'life_okay_neutral',
      'life_often_sad',
      'life_lowest_need_help',
    ],
    // Journey Drive screen
    'onboarding_drive' : ['ambition','love','growth','peace','curiosity'],
    // ✅ Dark Habits screen
    'onboarding_dark'  : [
      'procrastination',
      'overthinking',
      'negativity',
      'addiction_phone_social',
      'lack_self_discipline',
      'poor_sleep',
    ],
  };

  /// 🔤 Translations
  final Map<String, Map<String, String>> _translations = {
    'English': {
      // Common
      'word_step': 'Step',
      'word_of'  : 'of',
      'language' : 'Language',
      'next'     : 'Next →',
      'confirm'  : 'Confirm',
      'continue' : 'Continue',
      'skip'     : 'Skip →',
      'welcome'  : 'Welcome to Reclaim 👋',
      'namePrompt': "Let's start by knowing your name.",
      'howOld'   : 'How old are you?',
      'genderQuestion': "What's your gender?",
      'chooseCharacter': 'Choose your character',
      'female'   : 'Female',
      'male'     : 'Male',
      'awakening_line1': 'You were just another face in',
      'awakening_line2': 'the crowd.',
      'awakening_line3': 'Tired. Stuck. Running on\nautopilot... until now.',

      // Age screen
      'onboarding_age.title'   : 'How old are you?',
      'onboarding_age.13_17'   : '13 to 17',
      'onboarding_age.18_24'   : '18 to 24',
      'onboarding_age.25_34'   : '25 to 34',
      'onboarding_age.35_44'   : '35 to 44',
      'onboarding_age.45_54'   : '45 to 54',
      'onboarding_age.55_plus' : '55 or above',

      // Gender screen
      'onboarding_gender.title'     : "What's your gender?",
      'onboarding_gender.male'      : 'Male',
      'onboarding_gender.female'    : 'Female',
      'onboarding_gender.other'     : 'Other',
      'onboarding_gender.prefer_not': 'Prefer not to answer',

      // Main Character screen
      'onboarding_main.title'             : 'When did you last feel like the main character?',
      'onboarding_main.main_today'        : 'Today — I’m on a roll lately!',
      'onboarding_main.main_week'         : 'This week — I’ve been consistent.',
      'onboarding_main.main_months'       : 'It’s been months, I’ve lost touch.',
      'onboarding_main.main_cant_remember': 'I can’t even remember the last time.',

      // Life Description screen
      'onboarding_life.title'                : 'How would you describe your current life?',
      'onboarding_life.life_satisfied'       : "I'm satisfied with my life now",
      'onboarding_life.life_self_improve'    : "I'm alright and want to self-improve",
      'onboarding_life.life_okay_neutral'    : "I'm doing okay, not good or bad",
      'onboarding_life.life_often_sad'       : "I'm often sad and rarely happy",
      'onboarding_life.life_lowest_need_help': "I'm at the lowest and need help",

      // Journey Drive screen
      'onboarding_drive.title'     : 'What drives your journey every day?',
      'onboarding_drive.ambition'  : 'Ambition — I want to achieve greatness.',
      'onboarding_drive.love'      : 'Love — I care deeply for the people around me.',
      'onboarding_drive.growth'    : 'Growth — I want to become a better version of myself.',
      'onboarding_drive.peace'     : 'Peace — I just want balance and calm.',
      'onboarding_drive.curiosity' : 'Curiosity — I want to explore everything life offers.',

      // ✅ Dark Habits screen
      'onboarding_dark.title'                    : 'Any dark habits holding your power back?',
      'onboarding_dark.procrastination'          : 'Procrastination',
      'onboarding_dark.overthinking'             : 'Overthinking',
      'onboarding_dark.negativity'               : 'Negativity',
      'onboarding_dark.addiction_phone_social'   : 'Addiction to phone/socials',
      'onboarding_dark.lack_self_discipline'     : 'Lack of self-discipline',
      'onboarding_dark.poor_sleep'               : 'Poor sleep routine',
    },

    'Nepali': {
      // Common
      'word_step': 'चरण',
      'word_of'  : 'को',
      'language' : 'भाषा',
      'next'     : 'अर्को →',
      'confirm'  : 'पुष्टि गर्नुहोस्',
      'continue' : 'जारी राख्नुहोस्',
      'skip'     : 'छोड्नुहोस् →',
      'welcome'  : 'Reclaim मा स्वागत छ 👋',
      'namePrompt': 'तपाईंको नाम बताउनुहोस्।',
      'howOld'   : 'तपाईंको उमेर कति हो?',
      'genderQuestion': 'तपाईंको लिङ्ग के हो?',
      'chooseCharacter': 'तपाईंको पात्र छान्नुहोस्',
      'female'   : 'महिला',
      'male'     : 'पुरुष',
      'awakening_line1': 'तपाईं भीडमा अरू जस्तै मात्र हुनुहुन्थ्यो',
      'awakening_line2': 'भीडमा हराउनु भएको थियो।',
      'awakening_line3': 'थकित। रोकिएका। स्वत: ढंगले बाँचिरहेका... अब होइन।',

      // Age screen
      'onboarding_age.title'   : 'तपाईंको उमेर कति हो?',
      'onboarding_age.13_17'   : '१३ देखि १७',
      'onboarding_age.18_24'   : '१८ देखि २४',
      'onboarding_age.25_34'   : '२५ देखि ३४',
      'onboarding_age.35_44'   : '३५ देखि ४४',
      'onboarding_age.45_54'   : '४५ देखि ५४',
      'onboarding_age.55_plus' : '५५ वा माथि',

      // Gender screen
      'onboarding_gender.title'     : 'तपाईंको लिङ्ग के हो?',
      'onboarding_gender.male'      : 'पुरुष',
      'onboarding_gender.female'    : 'महिला',
      'onboarding_gender.other'     : 'अन्य',
      'onboarding_gender.prefer_not': 'भन्न चाहन्न',

      // Main Character screen
      'onboarding_main.title'             : 'तपाईंले अन्तिम पटक मुख्य पात्र भएको महसुस कहिले गर्नुभयो?',
      'onboarding_main.main_today'        : 'आज — म राम्रो लयमा छु!',
      'onboarding_main.main_week'         : 'यो हप्ता — म लगातार छु।',
      'onboarding_main.main_months'       : 'महिनौं भयो, म आफैंसँग हराएको छु।',
      'onboarding_main.main_cant_remember': 'मलाई अन्तिम पटक याद छैन।',

      // Life Description screen
      'onboarding_life.title'                : 'तपाईं अहिलेको जीवनलाई कसरी वर्णन गर्नुहुन्छ?',
      'onboarding_life.life_satisfied'       : 'म अहिलेको जीवनबाट सन्तुष्ट छु',
      'onboarding_life.life_self_improve'    : 'म ठीक छु र आफूलाई सुधार्न चाहन्छु',
      'onboarding_life.life_okay_neutral'    : 'म ठीकै छु, न राम्रो न नराम्रो',
      'onboarding_life.life_often_sad'       : 'म प्रायः दुःखी हुन्छु र खुशी कमै हुन्छु',
      'onboarding_life.life_lowest_need_help': 'म धेरै कठिन अवस्थामा छु र सहयोग चाहिन्छ',

      // Journey Drive screen
      'onboarding_drive.title'     : 'हरेक दिन तपाईंको यात्रालाई के चलाउँछ?',
      'onboarding_drive.ambition'  : 'महत्त्वाकांक्षा — म ठूलो उपलब्धि हासिल गर्न चाहन्छु।',
      'onboarding_drive.love'      : 'माया — म वरपरका मानिसहरूलाई गहिरो माया गर्छु।',
      'onboarding_drive.growth'    : 'विकास — म आफैँलाई अझ राम्रो बनाउन चाहन्छु।',
      'onboarding_drive.peace'     : 'शान्ति — म सन्तुलन र शान्ति चाहन्छु।',
      'onboarding_drive.curiosity' : 'जिज्ञासा — जीवनले दिने सबै कुरा अन्वेषण गर्न चाहन्छु।',

      // ✅ Dark Habits screen
      'onboarding_dark.title'                    : 'केही खराब बानीहरूले तपाईंको शक्ति घटाइरहेका छन्?',
      'onboarding_dark.procrastination'          : 'काम टार्ने बानी',
      'onboarding_dark.overthinking'             : 'अत्यधिक सोचाइ',
      'onboarding_dark.negativity'               : 'नकारात्मकता',
      'onboarding_dark.addiction_phone_social'   : 'फोन/सोसलमा लत',
      'onboarding_dark.lack_self_discipline'     : 'आत्मअनुशासनको कमी',
      'onboarding_dark.poor_sleep'               : 'नराम्रो निद्रा बानी',
    },
  };

  /// Basic translation getter
  String t(String key) => _translations[_currentLang]?[key] ?? key;

  /// Alias for t(): some screens call text()
  String text(String keyPath) => t(keyPath);

  /// 🔢 Number localization (public)
  String n(num value) => localizeNumber(value);

  /// 🔢 Number localization (existing)
  String localizeNumber(dynamic number) {
    final text = number.toString();
    if (_currentLang == 'Nepali') {
      return text.split('').map((c) => _nepaliNumbers[c] ?? c).join('');
    }
    return text;
  }

  /// 📋 Return localized options for a given screen key using the order map
  List<LangOption> options(String screenKey) {
    final langMap = _translations[_currentLang] ?? const {};
    final order = _screenOptionOrder[screenKey];

    // Gather keys like "<screen>.<id>" except ".title"
    final Map<String, String> byId = {};
    for (final entry in langMap.entries) {
      if (entry.key.startsWith('$screenKey.') && entry.key != '$screenKey.title') {
        final id = entry.key.substring(screenKey.length + 1); // part after the dot
        byId[id] = entry.value;
      }
    }

    // Honor explicit order if present; otherwise fall back to discovered ids
    final List<String> ids = order?.where(byId.containsKey).toList() ?? byId.keys.toList();

    return ids.map((id) => LangOption(id: id, label: byId[id]!)).toList();
  }
}
