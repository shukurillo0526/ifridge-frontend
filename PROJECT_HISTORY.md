# I-Fridge Project History & Architecture Log

This document serves as a comprehensive history of the development of the **I-Fridge** application, a smart inventory, recipe recommendation, and automated cooking platform designed to evolve from software to robotic hardware integration.

---

## The Vision
I-Fridge was born from the frustration that generic AI cannot accurately track physical food inventory or provide practical, hyper-personalized recipes without knowing exactly what is in a user's fridge. The ultimate goal is:
1. Complete digital mapping of physical inventory (via smart fridge integration and automated receipt scanning).
2. Advanced algorithmic recipe recommendations (Tiered matching based on exact ingredients and past cooking history).
3. Final execution via a robotic kitchen chef using precise JSON-based robot commands.

---

## Phase 1: Database Foundation
Built the core Supabase PostgreSQL schema to support ingredients, user inventory, recipes, and detailed gamification stats. We opted to structure logic and definitions heavily in the backend.

- `ingredients`: The global catalog of 100+ standard food items (UUID, canonical name, shelf life days).
- `inventory_items`: Junction table mapping users to ingredients, tracking exact quantities, expiration dates, and physical storage zones (Fridge/Freezer/Pantry).
- `recipes` & `recipe_ingredients`: The structured cookbook containing difficulty, cuisine, and ingredients required (with `is_optional` flags). 

---

## Phase 2: Core Feature Skeleton
Initialized a new Flutter project and built out the overarching architecture, including state management loops and the four main application hubs:

1. **Living Shelf Tab**: Visual representation of the fridge, tracking items nearing expiration.
2. **Cook Tab**: The recommendation engine.
3. **Scan Tab**: UI prototype for camera-based ML scanning of grocery receipts or physical fridge contents.
4. **Profile Tab**: Gamification and flavor profiling statistics.

---

## Phase 3: Live Data Connection (The Living Shelf)
Integrated the `supabase_flutter` SDK to fetch live database records directly into the UI.
- Seeded test users and diverse ingredients into the Supabase project.
- Wired the **Living Shelf** screen to stream `inventory_items`.
- Built the `FreshnessOverlay` visual indicator (Green/Yellow/Red/Grey) based on calculating the days until expiration against a dynamic timestamp.

---

## Phase 4: Data-Driven Matching Engine (Cook & Profile)
This phase realized the original vision of the app: suggesting recipes based exactly on what is owned.

- **Cook Screen Algorithm**:
  - Fetched all `recipes` and cross-referenced their required `recipe_ingredients` against the user's `inventory_items`.
  - Calculated an exact percentage match (`Owned / Required`).
  - Categorized the results into five specific UX tiers: Perfect (100%), Discover (80-99%), Almost (60-79%), Try (40-59%), and Global (<40%).
- **Profile Screen**: Tied gamified statistics (`meals_cooked`, `items_saved`, `xp`) and unlocking logic directly to the live backend data.

---

## Phase 5: UI/UX Polish & Modern Aethestics
Elevated the application from a basic prototype to a modern, premium experience.
- Implemented a custom glassmorphic bottom navigation bar with `BackdropFilter` blurring and animated icon transitions.
- Replaced basic loading spinners with custom shimmer/skeleton UI components (`ShimmerBox`).
- Incorporated `SlideInItem` staggered list animations across the Living Shelf and Recipe cards.
- Restyled the `_RecipeCard` components to use cohesive gradient tier colors representing the exact tier of the recipe recommendation.

---

## Phase 6: Recipe Detail Screen & Hardware Prep
Filled the gap between tapping a recommended recipe and actually cooking it.
- Seeded the `recipe_steps` SQL table with a critical twist: alongside `human_text` instructions, every step requires a backend `robot_action` JSON payload containing execution parameters (e.g., `{"action": "HEAT", "target": "wok", "params": {"temp_c": 220}}`).
- Built the `RecipeDetailScreen` showing a hero header and an ingredient checklist indicating what is currently owned (✅) vs what needs to be bought from a store (🛒).

---

## Phase 7: Active Cooking Mode & Gamification Loop
Completed the core user journey by bringing the user through the physical act of cooking using the app.
- **Active Cooking Screen (`CookingRunScreen`)**: A distraction-free swipeable UI displaying the specific cooking step. It decodes the JSON payload into visual "Simulated Backend Actions," categorized by 👨‍🍳 `Manual Action Required` vs 🤖 `Automated Robot Action`.
- **Backend RPC Gamification (`increment_gamification_stats`)**: Wrote a secure SQL function to atomically add XP, log history, calculate "days streak", and level up the user.
- **Celebration Screen (`CookingRewardScreen`)**: An animated post-cooking flow that summarizes XP gained and items saved from expiration, tying the user actions back to the gamification hub.

---

*Document updated automatically by I-Fridge architecture logs.*
