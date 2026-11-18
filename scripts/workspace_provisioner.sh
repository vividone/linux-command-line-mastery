#!/usr/bin/env bash
# Purpose: Automates project directory scaffolding, permission hardening, and audit logging.
# Usage: ./scripts/workspace_provisioner.sh

set -euo pipefail

BASE_DIR="./artifacts/automated_env"
SUBDIRS=("bin" "config" "logs" "tmp")
LOG_FILE="./artifacts/provisioner.log"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

echo "[$TIMESTAMP] Starting environment provisioning..." | tee -a "$LOG_FILE"

# Conditional check: create base directory if missing
if [ ! -d "$BASE_DIR" ]; then
    mkdir -p "$BASE_DIR"
    echo "[$TIMESTAMP] Created base directory: $BASE_DIR" | tee -a "$LOG_FILE"
else
    echo "[$TIMESTAMP] Base directory already exists: $BASE_DIR" | tee -a "$LOG_FILE"
fi

# Loop through required subdirectories and set strict permissions
for dir in "${SUBDIRS[@]}"; do
    TARGET="$BASE_DIR/$dir"
    mkdir -p "$TARGET"
    chmod 750 "$TARGET"
    touch "$TARGET/.keep"
    echo "[$TIMESTAMP] Provisioned $TARGET (mode 750)" | tee -a "$LOG_FILE"
done

echo "[$TIMESTAMP] Provisioning complete." | tee -a "$LOG_FILE"
