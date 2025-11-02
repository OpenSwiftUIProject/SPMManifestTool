#!/bin/bash

# sync.sh
# Synchronizes EnvManager to multiple target directories listed in a config file
#
# Usage: ./sync.sh [config_file]
# Default config file: sync_targets.txt (in repo root)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEFAULT_CONFIG_FILE="$REPO_ROOT/sync_targets.txt"
CONFIG_FILE="${1:-$DEFAULT_CONFIG_FILE}"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not found: $CONFIG_FILE"
    echo ""
    echo "Usage: $0 [config_file]"
    echo "Default: $0 $DEFAULT_CONFIG_FILE"
    echo ""
    echo "Create a config file with one target directory per line"
    exit 1
fi

echo "📋 Reading targets from: $CONFIG_FILE"
echo ""

# Counter for success/failures
success_count=0
failure_count=0
failed_targets=()

# Read each line from the config file
while IFS= read -r target_dir || [ -n "$target_dir" ]; do
    # Skip empty lines and comments
    if [[ -z "$target_dir" || "$target_dir" =~ ^[[:space:]]*# ]]; then
        continue
    fi

    # Trim whitespace
    target_dir=$(echo "$target_dir" | xargs)

    echo "🔄 Syncing to: $target_dir"

    # Call sync_env_manager.sh
    if "$SCRIPT_DIR/sync_env_manager.sh" "$target_dir"; then
        ((success_count++))
    else
        ((failure_count++))
        failed_targets+=("$target_dir")
    fi

    echo ""
done < "$CONFIG_FILE"

# Print summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Summary:"
echo "  ✅ Successful: $success_count"
echo "  ❌ Failed: $failure_count"

if [ $failure_count -gt 0 ]; then
    echo ""
    echo "Failed targets:"
    for target in "${failed_targets[@]}"; do
        echo "  - $target"
    done
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All targets synchronized successfully!"
