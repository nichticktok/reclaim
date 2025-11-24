import '../models/curated_book_summary.dart';

/// Service that provides curated book summaries
class CuratedBookSummariesService {
  static List<CuratedBookSummary> getCuratedSummaries() {
    return [
      CuratedBookSummary(
        id: 'atomic_habits',
        bookTitle: 'Atomic Habits',
        author: 'James Clear',
        year: 2018,
        category: 'self_improvement',
        summary: '''
Atomic Habits by James Clear is a comprehensive guide to building good habits and breaking bad ones. The book emphasizes that small, incremental changes can lead to remarkable results over time. Clear introduces the concept of "atomic habits" - tiny changes that are easy to make and compound into significant improvements.

The core philosophy revolves around four laws of behavior change: make it obvious, make it attractive, make it easy, and make it satisfying. Clear explains how to design your environment to support good habits, how to use habit stacking to build new routines, and how to overcome the common obstacles that prevent habit formation.

The book emphasizes that success isn't about making massive changes overnight, but about making small improvements consistently. Clear provides practical strategies for identity-based habits, where you focus on becoming the type of person who naturally performs the desired behavior, rather than just focusing on outcomes.
''',
        keyPoints: [
          'Small changes (1% improvements) compound into remarkable results over time',
          'Focus on systems, not goals - the process matters more than the outcome',
          'Habits are formed through a four-step pattern: cue, craving, response, reward',
          'Make good habits obvious, attractive, easy, and satisfying',
          'Use habit stacking to link new habits to existing ones',
          'Design your environment to make good habits easier and bad habits harder',
          'Focus on identity change - become the type of person who naturally performs the desired behavior',
          'Track your habits to maintain awareness and motivation',
          'Never miss twice - one mistake doesn\'t ruin your progress',
          'Focus on the process, not the outcome'
        ],
        actionableInsights: [
          'Start with a "2-minute rule" - make new habits so easy you can\'t say no',
          'Use implementation intentions: "I will [BEHAVIOR] at [TIME] in [LOCATION]"',
          'Join a culture where your desired behavior is the normal behavior',
          'Use a habit tracker to visualize your progress',
          'Reframe your mindset: "I don\'t have to, I get to"',
          'Make bad habits invisible, unattractive, difficult, and unsatisfying',
          'Use temptation bundling to make habits more attractive',
          'Optimize for the starting line, not the finish line'
        ],
      ),
      CuratedBookSummary(
        id: 'the_7_habits',
        bookTitle: 'The 7 Habits of Highly Effective People',
        author: 'Stephen R. Covey',
        year: 1989,
        category: 'self_improvement',
        summary: '''
The 7 Habits of Highly Effective People by Stephen R. Covey is a foundational work in personal development that presents a principle-centered approach to solving personal and professional problems. The book is organized around seven habits that move from dependence to independence to interdependence.

The first three habits focus on private victory (independence): Be Proactive, Begin with the End in Mind, and Put First Things First. These habits help individuals develop character and personal effectiveness. The next three habits focus on public victory (interdependence): Think Win-Win, Seek First to Understand, Then to Be Understood, and Synergize. The final habit, Sharpen the Saw, emphasizes continuous improvement and renewal.

Covey emphasizes that true effectiveness comes from aligning with universal principles rather than following quick-fix techniques. The book teaches that character ethics (who you are) is more important than personality ethics (how others perceive you). It's about being, not just appearing to be effective.
''',
        keyPoints: [
          'Effectiveness comes from aligning with universal principles, not quick fixes',
          'Private victory (independence) must come before public victory (interdependence)',
          'Be proactive - take responsibility for your responses and actions',
          'Begin with the end in mind - have a clear vision of what you want to achieve',
          'Put first things first - prioritize important but not urgent activities',
          'Think win-win - seek mutual benefit in all interactions',
          'Seek first to understand, then to be understood - listen empathetically',
          'Synergize - create solutions that are better than individual contributions',
          'Sharpen the saw - continuously renew yourself in four dimensions: physical, mental, social/emotional, and spiritual',
          'Focus on your Circle of Influence, not your Circle of Concern'
        ],
        actionableInsights: [
          'Use the Time Management Matrix to prioritize tasks (Quadrant II: Important, Not Urgent)',
          'Develop a personal mission statement to clarify your values and goals',
          'Practice empathic listening - listen to understand, not to reply',
          'Identify your roles and set goals for each role weekly',
          'Focus on what you can control (Circle of Influence)',
          'Seek win-win solutions in negotiations and relationships',
          'Schedule time for Quadrant II activities (prevention, planning, relationship building)',
          'Renew yourself regularly in all four dimensions of life'
        ],
      ),
      CuratedBookSummary(
        id: 'thinking_fast_slow',
        bookTitle: 'Thinking, Fast and Slow',
        author: 'Daniel Kahneman',
        year: 2011,
        category: 'psychology',
        summary: '''
Thinking, Fast and Slow by Daniel Kahneman explores the two systems that drive the way we think. System 1 is fast, intuitive, and emotional. System 2 is slower, more deliberative, and more logical. Kahneman reveals the extraordinary capabilities and biases of both systems and how they shape our judgments and decisions.

The book delves into various cognitive biases and heuristics that affect our decision-making, such as anchoring, availability heuristic, loss aversion, and overconfidence. Kahneman explains how these mental shortcuts can lead to systematic errors in judgment. He also explores prospect theory, which describes how people make decisions under uncertainty, and how we often make irrational choices that deviate from standard economic theory.

Throughout the book, Kahneman demonstrates that while System 1 is efficient, it's prone to errors, and System 2, though more accurate, is lazy and often defers to System 1. Understanding these systems helps us make better decisions and avoid common cognitive pitfalls.
''',
        keyPoints: [
          'Two systems govern our thinking: System 1 (fast, intuitive) and System 2 (slow, deliberate)',
          'System 1 operates automatically and quickly with little effort, while System 2 requires attention and effort',
          'Cognitive biases are systematic errors in thinking that affect our judgments',
          'Anchoring effect: we rely too heavily on the first piece of information',
          'Availability heuristic: we judge probability by how easily examples come to mind',
          'Loss aversion: losses loom larger than equivalent gains',
          'Overconfidence: we overestimate our abilities and knowledge',
          'Prospect theory explains how people make decisions under uncertainty',
          'The framing effect: how information is presented affects our decisions',
          'We often substitute difficult questions with easier ones without realizing it'
        ],
        actionableInsights: [
          'Slow down important decisions to engage System 2 thinking',
          'Question your first instinct on important matters',
          'Seek outside perspectives to counter overconfidence',
          'Consider the base rate when making probability judgments',
          'Be aware of anchoring effects in negotiations',
          'Reframe losses as opportunities to avoid loss aversion bias',
          'Use checklists and algorithms for important decisions',
          'Recognize when you\'re in "cognitive ease" and may be making errors'
        ],
      ),
      CuratedBookSummary(
        id: 'sapiens',
        bookTitle: 'Sapiens: A Brief History of Humankind',
        author: 'Yuval Noah Harari',
        year: 2014,
        category: 'history',
        summary: '''
Sapiens by Yuval Noah Harari provides a sweeping overview of the history of Homo sapiens from the Stone Age to the present. Harari argues that three major revolutions shaped human history: the Cognitive Revolution (70,000 years ago), the Agricultural Revolution (12,000 years ago), and the Scientific Revolution (500 years ago).

The book explores how Homo sapiens came to dominate the world through the ability to create and believe in shared fictions - concepts like money, nations, and corporations that exist only in our collective imagination. Harari challenges conventional narratives about human progress, questioning whether the Agricultural Revolution actually improved human happiness and examining the costs of our species\' success.

Harari also looks forward, considering how biotechnology, artificial intelligence, and other technologies might reshape humanity in the future. The book raises profound questions about happiness, meaning, and what makes humans unique.
''',
        keyPoints: [
          'Three revolutions shaped human history: Cognitive, Agricultural, and Scientific',
          'Homo sapiens dominated through the ability to create and believe in shared fictions',
          'The Agricultural Revolution may have decreased individual happiness despite increasing population',
          'Money, empires, and religions are all shared fictions that enable large-scale cooperation',
          'The Scientific Revolution was driven by admitting ignorance and seeking new knowledge',
          'Capitalism and science formed a powerful alliance that transformed the world',
          'Modern humans may be less happy than hunter-gatherers despite material wealth',
          'Biotechnology and AI may soon allow us to redesign ourselves',
          'The ability to cooperate flexibly in large numbers is uniquely human',
          'History doesn\'t guarantee progress toward greater happiness'
        ],
        actionableInsights: [
          'Understand that many social constructs (money, nations, laws) are shared fictions',
          'Question whether material progress truly increases happiness',
          'Recognize the power of collective belief in enabling cooperation',
          'Consider the long-term consequences of technological revolutions',
          'Appreciate the unique human ability to cooperate flexibly',
          'Reflect on what gives life meaning beyond material success',
          'Understand that history is shaped by chance and contingency',
          'Consider how future technologies might reshape human nature'
        ],
      ),
      CuratedBookSummary(
        id: 'the_power_of_now',
        bookTitle: 'The Power of Now',
        author: 'Eckhart Tolle',
        year: 1997,
        category: 'spirituality',
        summary: '''
The Power of Now by Eckhart Tolle is a guide to spiritual enlightenment through living in the present moment. Tolle argues that most human suffering comes from being trapped in the mind - either dwelling on the past or worrying about the future. True peace and happiness can only be found by connecting with the eternal present moment.

Tolle explains the difference between the mind (ego) and consciousness (awareness). The mind creates problems, anxiety, and suffering through constant thinking and identification with thoughts. By becoming aware of the present moment and disidentifying from the mind, we can access a deeper state of peace and presence.

The book teaches practical techniques for staying present, such as watching the thinker, accepting the present moment, and finding the space between thoughts. Tolle emphasizes that the present moment is all we ever have, and by fully embracing it, we can transcend suffering and find true joy.
''',
        keyPoints: [
          'Most human suffering comes from being trapped in the mind (past/future thinking)',
          'The present moment is all we ever have - it\'s the only time we can experience life',
          'The mind (ego) creates problems and suffering through constant thinking',
          'True peace comes from disidentifying from thoughts and connecting with awareness',
          'Acceptance of the present moment is the key to transcending suffering',
          'Pain is inevitable, but suffering is optional - it comes from resistance to what is',
          'The space between thoughts is where consciousness and peace reside',
          'Watching the thinker allows you to step back from your mind',
          'Time is an illusion - only the present moment is real',
          'Enlightenment is realizing you are not your thoughts or emotions'
        ],
        actionableInsights: [
          'Practice watching your thoughts without judgment or identification',
          'Accept the present moment completely, even if it\'s uncomfortable',
          'When feeling anxious, ask: "What problem do I have right now, in this moment?"',
          'Find the space between thoughts through meditation or mindfulness',
          'Stop waiting for the future to be happy - happiness is available now',
          'Disidentify from your mind by observing it as an external phenomenon',
          'Practice presence during daily activities (washing dishes, walking, etc.)',
          'Recognize that resistance to what is causes suffering, not the situation itself'
        ],
      ),
      CuratedBookSummary(
        id: 'the_lean_startup',
        bookTitle: 'The Lean Startup',
        author: 'Eric Ries',
        year: 2011,
        category: 'business',
        summary: '''
The Lean Startup by Eric Ries presents a methodology for developing businesses and products that aims to shorten product development cycles and rapidly discover if a proposed business model is viable. The methodology advocates for creating "minimum viable products" (MVPs) and using validated learning through continuous experimentation.

Ries introduces the Build-Measure-Learn feedback loop, where entrepreneurs build a minimum viable product, measure how customers respond, and learn whether to pivot or persevere. The book emphasizes the importance of validated learning over traditional business planning and the need to pivot when necessary.

The Lean Startup methodology helps entrepreneurs avoid building products nobody wants, reduce waste, and increase the chances of success. It applies not just to startups but to any organization that needs to innovate and adapt quickly.
''',
        keyPoints: [
          'Build-Measure-Learn feedback loop is the core of the Lean Startup methodology',
          'Minimum Viable Product (MVP) allows you to test hypotheses with minimum effort',
          'Validated learning is more important than traditional business planning',
          'Pivot when your current strategy isn\'t working, persevere when it is',
          'Innovation accounting measures progress when traditional metrics don\'t apply',
          'Startups exist to learn how to build a sustainable business',
          'Avoid building products nobody wants by testing assumptions early',
          'Continuous deployment and split testing enable rapid learning',
          'The goal is to find a sustainable business model, not just to build a product',
          'Small batches allow for faster learning and adaptation'
        ],
        actionableInsights: [
          'Start with an MVP to test your riskiest assumptions',
          'Use the Build-Measure-Learn loop for all product decisions',
          'Define your leap-of-faith assumptions and test them first',
          'Measure actionable metrics, not vanity metrics',
          'Know when to pivot (change strategy) vs. persevere (stay the course)',
          'Use split testing to validate product features',
          'Practice continuous deployment to learn faster',
          'Focus on learning milestones, not just product milestones'
        ],
      ),
    ];
  }

  static List<CuratedBookSummary> getSummariesByCategory(String category) {
    return getCuratedSummaries().where((summary) => summary.category == category).toList();
  }

  static CuratedBookSummary? getSummaryById(String id) {
    try {
      return getCuratedSummaries().firstWhere((summary) => summary.id == id);
    } catch (e) {
      return null;
    }
  }
}

