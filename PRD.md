# Project: Local AI-First Fitness & Coaching Companion

## 1. Vision & Architecture
- **Framework:** Flutter (Single codebase targeting Flutter Web for admin curation and Android/Pixel 10 for mobile execution).
- **Dual-AI Model Architecture:**
  - **Cloud Gemini API (Web Admin):** For bulk exercise ingestion, formatting raw descriptions, and master library generation.
  - **On-Device Gemma (Pixel 10 via MediaPipe / LiteRT):** For hyper-private, offline-capable workout generation, stats interpretation, progressive overload logic, and nutrition/health Q&A.
- **Data Source of Truth:** Local SQLite (via Drift) database on the mobile device. Deterministic calculations (PRs, volume, trends) happen in code; Gemma handles reasoning, coaching tone, and adjustments.

## 2. Core Functional Modules
1. **Web Admin Portal:** Interface to manage exercise master list, sync updates down to local storage.
2. **Mobile Execution App:** Offline-first workout logger, handling warm-ups, working sets, cool-downs, RPE, and timers.
3. **Voice & Audio Layer:** Speech-to-text (STT) for post-set voice logs and Text-to-Speech (TTS) for active workout audio pacing and form cues.

## 3. Relational Schema Hierarchy
- **exercises:** Master table (id, name, category, primary_muscle, equipment, instructions, default_phase).
- **workouts / sessions:** Active logs (id, date_started, date_ended, notes, ai_summary).
- **session_exercises:** Junction mapping sessions to exercises with explicit phase tags (`warmup`, `working`, `cooldown`).
- **workout_sets:** Granular tracking (id, session_exercise_id, set_number, set_type, weight, reps, rpe).