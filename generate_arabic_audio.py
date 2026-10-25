import json
import os
import sys
from pathlib import Path

# Ensure UTF-8 output on Windows
if sys.stdout.encoding != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')

from voicetut_tts import VoiceTutTTS

OUTPUT_DIR = Path("assets/audio/human_body")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# Load Arabic strings from ar.json
ar_json_path = Path("assets/lang/ar.json")
with open(ar_json_path, "r", encoding="utf-8") as f:
    strings = json.load(f)

# Part ID mapping matching lib/features/HumanBody/body_parts.dart
BODY_PARTS = [
    ("leftEye", "العين الشمال"),
    ("rightEye", "العين اليمين"),
    ("nose", "المناخير"),
    ("mouth", "الفم"),
    ("leftEar", "الودن الشمال"),
    ("rightEar", "الودن اليمين"),
    ("head", "الراس"),
    ("hair", "الشعر"),
    ("neck", "الرقبة"),
    ("shoulders", "الكتفين"),
    ("arms", "الدراعين"),
    ("hands", "الإيدين"),
    ("fingers", "صوابع الإيد"),
    ("stomach", "البطن"),
    ("legs", "الرجلين"),
    ("knees", "الركبتين"),
    ("feet", "القدمين"),
    ("toes", "صوابع الرجل"),
]

# Build dictionary of all utterances to synthesize
# Format: filename -> exact Arabic text
utterances = {
    "body_welcome.wav": strings["bodyWelcome"],
    "body_stage1_intro.wav": strings["bodyStage1Intro"],
    "body_stage2_intro.wav": strings["bodyStage2Intro"],
    "body_stage3_intro.wav": strings["bodyStage3Intro"],
    "body_stage_finished.wav": strings["bodyStageFinished"],
    "body_finished.wav": strings["bodyFinished"],
}

# Contextual lines for each part
for part_id, part_ar in BODY_PARTS:
    utterances[f"body_find_{part_id}.wav"] = strings["bodyFind"].replace("{part}", part_ar)
    utterances[f"body_correct_{part_id}.wav"] = strings["bodyCorrect"].replace("{part}", part_ar)
    utterances[f"body_retry_{part_id}.wav"] = strings["bodyRetry"].replace("{part}", part_ar)
    utterances[f"body_hint_{part_id}.wav"] = strings["bodyHint"].replace("{part}", part_ar)
    utterances[f"body_part_{part_id}.wav"] = part_ar

print(f"Total Arabic utterances to process: {len(utterances)}")

# Load model once
print("Loading VoiceTut-TTS model...")
tts = VoiceTutTTS.from_pretrained("mohammedaly22/VoiceTut-TTS")

generated_count = 0
skipped_count = 0
failed = []

for filename, text in utterances.items():
    output_path = OUTPUT_DIR / filename
    if output_path.exists() and output_path.stat().st_size > 0:
        skipped_count += 1
        continue

    try:
        tts.synthesize(text, speaker="Yasmin", output=str(output_path))
        if output_path.exists() and output_path.stat().st_size > 0:
            generated_count += 1
            print(f"[{generated_count + skipped_count}/{len(utterances)}] Generated: {filename}")
        else:
            failed.append((filename, "Generated file is empty or missing"))
    except Exception as e:
        failed.append((filename, str(e)))
        print(f"Failed to generate {filename}: {e}")

# Save manifest mapping exact text to relative asset path
manifest = {
    "engine": "voicetut-tts",
    "speaker": "Yasmin",
    "format": "wav",
    "sample_rate": 24000,
    "clips": {text: f"audio/human_body/{filename}" for filename, text in utterances.items()}
}
with open(OUTPUT_DIR / "manifest.json", "w", encoding="utf-8") as f:
    json.dump(manifest, f, ensure_ascii=False, indent=2)

dart_clips_path = Path("lib/features/HumanBody/body_audio_clips.dart")
with open(dart_clips_path, "w", encoding="utf-8") as dart_f:
    dart_f.write("// Generated audio clips mapping for VoiceTut-TTS (Yasmin)\n")
    dart_f.write("const Map<String, String> bodyArabicAudioClips = {\n")
    for filename, text in sorted(utterances.items(), key=lambda x: x[0]):
        escaped = text.replace("'", "\\'")
        dart_f.write(f"  '{escaped}': 'audio/human_body/{filename}',\n")
    dart_f.write("};\n")
print(f"Generated Dart clips mapping: {dart_clips_path}")

print("\n=== Generation Summary ===")
print(f"Total files: {len(utterances)}")
print(f"Newly generated: {generated_count}")
print(f"Already existed (skipped): {skipped_count}")
print(f"Failed: {len(failed)}")
if failed:
    for fname, err in failed:
        print(f"  - {fname}: {err}")
