// I-Fridge — Gamification Repository
// ===================================
// Handles all updates to user stats (XP, meals cooked, items saved)
// and recipe history logging when completing a meal.

import 'package:supabase_flutter/supabase_flutter.dart';

class GamificationRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// Logs a completed recipe to history and updates gamification stats via RPC.
  ///
  /// [userId] The UUID of the user.
  /// [recipeId] The UUID of the recipe cooked.
  /// [xpGain] The amount of XP awarded for this meal.
  /// [matchedIngredientsCount] The number of owned ingredients used (Items Saved).
  Future<void> completeCookingSession({
    required String userId,
    required String recipeId,
    required int xpGain,
    required int matchedIngredientsCount,
  }) async {
    try {
      // 1. Log recipe history
      await _client.from('user_recipe_history').insert({
        'user_id': userId,
        'recipe_id': recipeId,
        'cooked_at': DateTime.now().toIso8601String(),
        // Default values for future expanding
        'rating': null,
        'tier_used': null,
        'waste_score': null,
        'notes': 'Completed via app',
      });

      // 2. Safely increment stats via RPC
      // The RPC 'increment_gamification_stats' handles XP, level calculation,
      // meals_cooked (+1), items_saved (matched count), and daily streaks.
      await _client.rpc(
        'increment_gamification_stats',
        params: {
          'p_user_id': userId,
          'p_xp_gain': xpGain,
          'p_meals_gain': 1,
          'p_items_saved_gain': matchedIngredientsCount,
        },
      );
    } catch (e) {
      // In a production app, we'd log this error to Crashlytics/Sentry
      print('Error completing cooking session: $e');
      rethrow;
    }
  }
}
