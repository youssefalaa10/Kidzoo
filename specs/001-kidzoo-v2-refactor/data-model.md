# Data Model: kidzoo-v2-refactor

## Database Entities (Drift)

### Profile
Represents a user.
- `id` (Int, AutoIncrement)
- `name` (Text)
- `avatarIndex` (Int, default 0)
- `totalPoints` (Int, default 0)
- `createdAt` (DateTime)

### GameScore
Represents a score achieved by a Profile.
- `id` (Int, AutoIncrement)
- `profileId` (Int, references Profile.id)
- `gameKey` (Text)
- `score` (Int)
- `level` (Int, nullable)
- `playedAt` (DateTime)

## App Models

### QuizQuestion
Represents a question in the unified engine.
- `id` (String)
- `prompt` (String): The question text (e.g., "Which vehicle can fly in the sky?").
- `imageOrScenePath` (String): The path to the background scene or main image.
- `options` (List<QuizOption>): The multiple choice answers.

### QuizOption
Represents a possible answer.
- `id` (String)
- `text` (String): Text to display.
- `imagePath` (String?): Optional image to display alongside text.
- `isCorrect` (bool): Whether this is the right answer.
