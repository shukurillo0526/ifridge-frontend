/// I-Fridge — Gamification Badges Domain
/// =======================================

enum WasteBadge {
  firstMeal('🍳', 'First Meal', 'Cook your first recipe', 0),
  wasteFighter('♻️', 'Waste Fighter', 'Cook 10 Tier 1 meals', 10),
  wasteWarrior('🛡️', 'Waste Warrior', 'Cook 50 Tier 1 meals', 50),
  weekStreak('🔥', 'Week Streak', '7-day cooking streak', 7),
  monthStreak('⭐', 'Iron Chef', '30-day cooking streak', 30),
  explorer('🌍', 'Flavor Explorer', 'Cook 5 different cuisines', 5),
  rescuer('🚨', 'Expiry Rescuer', 'Save 20 items from expiring', 20),
  zeroWasteWeek('💎', 'Zero Waste Week', 'No expired items for 7 days', 7);

  final String emoji;
  final String title;
  final String description;
  final int threshold;

  const WasteBadge(this.emoji, this.title, this.description, this.threshold);
}

/// XP reward table for different actions.
class XpRewards {
  static const int tier1Meal = 50;
  static const int tier2Meal = 40;
  static const int tier3Meal = 20;
  static const int tier4Meal = 20;
  static const int urgentItemUsed = 15;
  static const int weekStreakBonus = 100;
  static const int expiredItemPenalty = -5;
}

/// Calculate user level from XP.
int levelFromXp(int xp) {
  // Each level requires 50% more XP than the previous
  // Level 1: 0 XP, Level 2: 100 XP, Level 3: 250 XP, ...
  if (xp < 100) return 1;
  int level = 1;
  int required = 100;
  int remaining = xp;
  while (remaining >= required) {
    remaining -= required;
    level++;
    required = (required * 1.5).round();
  }
  return level;
}

/// XP progress within current level (0.0 – 1.0).
double levelProgress(int xp) {
  if (xp < 100) return xp / 100.0;
  int required = 100;
  int remaining = xp;
  while (remaining >= required) {
    remaining -= required;
    required = (required * 1.5).round();
  }
  return remaining / required;
}
