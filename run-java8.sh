#!/usr/bin/env bash
# ==============================================================================
# Java 8 Baseline Test Runner (Maven)
# Loads a provided Java 8 Maven project into the container and verifies:
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

# 4. Resolve target project directory
TARGET_PATH="${1:-}"

if [ -z "$TARGET_PATH" ]; then
    if [ -f "./smoke-test/pom.xml" ]; then
        TARGET_PATH="./smoke-test"
    else
        TARGET_PATH="."
    fi
fi

if [ ! -d "$TARGET_PATH" ]; then
    echo "❌ Error: Target project directory does not exist: $TARGET_PATH" >&2
    exit 3
fi

export PROJECT_DIR="$(cd "$TARGET_PATH" && pwd)"

# Verify project has a pom.xml
if [ ! -f "$PROJECT_DIR/pom.xml" ]; then
    echo "❌ Error: No pom.xml found in $PROJECT_DIR" >&2
    exit 3
fi

# Shift project argument if provided
if [ $# -gt 0 ]; then
    shift
fi

# 5. Run baseline verification or custom command inside container
if [ $# -eq 0 ]; then
    docker compose run --rm -T java8-test /scripts/verify-baseline.sh
else
    docker compose run --rm -T java8-test "$@"
fi
