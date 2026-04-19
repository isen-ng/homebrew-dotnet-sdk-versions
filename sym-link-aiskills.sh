#!/bin/bash

# --- Configuration ---
SOURCE_DIR=".aiskills"

TARGETS=(
  ".claude/skills"
  ".windsurf/skills"
  ".cursor/skills"
  ".agents/skills"
  ".factory/skills"
)

# --- Logic ---
if [ ! -d "$SOURCE_DIR" ]; then
  echo "❌ Error: Source directory '$SOURCE_DIR' not found."
  exit 1
fi

echo "--- Refreshing AI Skills from $SOURCE_DIR ---"

# Automatically find all skill subdirectories in SOURCE_DIR
# This means you don't even need to update a SKILLS array anymore!
SKILLS=$(find "$SOURCE_DIR" -maxdepth 1 -mindepth 1 -type d -exec basename {} \;)

for DIR in "${TARGETS[@]}"; do
  # Wipe and recreate
  rm -rf "$DIR"
  mkdir -p "$DIR"
  
  for SKILL in $SKILLS; do
    # Link using the relative path from the target dir back to source
    ln -s "../../$SOURCE_DIR/$SKILL" "$DIR/$SKILL"
  done
  echo "✅ $DIR refreshed."
done

echo "--- All agents synced ---"
