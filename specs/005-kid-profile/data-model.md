# Data Model: Kid Profile

## Entities

### 1. Profile
The core entity storing user settings and aggregated progress.
- `id` (int, primary key)
- `name` (text, max length 20)
- `avatar_path` (text, asset path)
- `total_xp` (int, default 0)
- `current_level` (int, default 1)
- `games_played` (int, default 0)
- `correct_answers` (int, default 0)
- `stars_collected` (int, default 0)
- `current_streak` (int, default 0)
- `best_score` (int, default 0)
- `time_spent_seconds` (int, default 0)
- `last_active_date` (DateTime)

**Validation Rules**:
- Name must not be empty.
- total_xp cannot be negative.

### 2. Badge
Unlockable achievements.
- `id` (int, primary key)
- `badge_key` (text, unique identifier e.g., 'fruit_master')
- `is_unlocked` (bool, default false)
- `unlocked_at` (DateTime, nullable)

### 3. Daily Activity
Tracks activity per day for the weekly progress chart.
- `id` (int, primary key)
- `date` (DateTime, truncated to day)
- `stars_earned` (int)

**State Transitions**:
- When XP is added, check if new XP > threshold for next level. If so, increment level and optionally unlock chest/badge.
- Completing a game updates `Profile` stats (games played, correct answers, time spent) and `Daily Activity` (stars earned today).
