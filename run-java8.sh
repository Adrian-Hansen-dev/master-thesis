#!/usr/bin/env bash
# ==============================================================================
# Java 8 Baseline Test Runner (Maven)
# Clones repositories from a dataset CSV inside an isolated Docker container
# and verifies baseline assumptions:
#   1. Build check (mvn clean test-compile)
#   2. Test check  (mvn test)
# ==============================================================================

set -euo pipefail

export PATH="/usr/local/bin:/opt/homebrew/bin:$HOME/.docker/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 1. Locate Docker
if ! command -v docker >/dev/null 2>&1; then
    echo "❌ Error: Docker command not found." >&2
    exit 1
fi

# 2. Check if Docker daemon is running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Error: Docker daemon is not running." >&2
    exit 1
fi

# 3. Build image utility (for initial pipeline setup)
if [ "${1:-}" = "build" ]; then
    echo "Building Java 8 container image..."
    docker compose build
    exit 0
fi

# 4. Resolve CSV dataset target (default: dataset/test.csv)
TARGET="${1:-dataset/test.csv}"

if [ $# -gt 0 ]; then #
    shift
fi

if [[ "$TARGET" != *.csv ]]; then
    echo "❌ Error: Expected a CSV dataset file (e.g. dataset/test.csv or dataset/dataset.csv), got: $TARGET" >&2
    exit 3
fi

if [ ! -f "$TARGET" ]; then
    echo "❌ Error: Dataset CSV file does not exist: $TARGET" >&2
    exit 3
fi

CSV_PATH="$(cd "$(dirname "$TARGET")" && pwd)/$(basename "$TARGET")"
DATASET_DIR="$(cd "$SCRIPT_DIR/dataset" && pwd)"

# 5. Run baseline verification inside container
if [[ "$CSV_PATH" == "$DATASET_DIR"* ]]; then # check if dataset is already mounted to container
    CONTAINER_CSV="/dataset/$(basename "$TARGET")"
    docker compose run --rm -T java8-test /scripts/verify-dataset.sh "$CONTAINER_CSV" "$@"
else
    CONTAINER_CSV="/dataset/$(basename "$TARGET")"
    docker compose run --rm -T -v "$CSV_PATH:$CONTAINER_CSV:ro" java8-test /scripts/verify-dataset.sh "$CONTAINER_CSV" "$@"
fi
