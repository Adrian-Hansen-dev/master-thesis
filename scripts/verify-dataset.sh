#!/usr/bin/env bash
# ==============================================================================
# Dataset Baseline Verification Runner (runs inside Java 8 container)
# Iterates through a CSV of repositories, clones each at base_commit,
# and performs baseline verification (build + tests).
# ==============================================================================

set -uo pipefail

CSV_FILE="${1:-/dataset/test.csv}"

if [ ! -f "$CSV_FILE" ]; then
    echo "❌ [BASELINE_ERROR] CSV file not found: $CSV_FILE" >&2
    exit 3
fi

# Configure git inside container
git config --global advice.detachedHead false #mute console output
git config --global --add safe.directory '*'

export MAVEN_OPTS="${MAVEN_OPTS:--Dfile.encoding=UTF-8}"

echo "============================================================"
echo "[BASELINE] Dataset Verification Runner"
echo "Dataset file: $CSV_FILE"
echo "Java:  $(java -version 2>&1 | head -n 1)"
echo "Maven: $(mvn -version 2>&1 | head -n 1)"
echo "============================================================"

# Count non-empty repo rows (excluding header)
TOTAL_REPOS=$(tail -n +2 "$CSV_FILE" | grep -v '^[[:space:]]*$' | wc -l | tr -d ' ')

if [ "$TOTAL_REPOS" -eq 0 ]; then
    echo "⚠️  [BASELINE_WARNING] No repositories found in $CSV_FILE"
    exit 0
fi

PASSED_COUNT=0
BUILD_FAILED_COUNT=0
TESTS_FAILED_COUNT=0
CLONE_FAILED_COUNT=0
CONFIG_ERROR_COUNT=0
OTHER_FAILED_COUNT=0
CURRENT_INDEX=0
LAST_EXIT_CODE=0

while IFS=',' read -r repo base_commit rest || [ -n "$repo" ]; do
    # Skip header
    if [ "$repo" = "repo" ]; then
        continue
    fi

    # Trim carriage returns and whitespace
    repo=$(echo "$repo" | tr -d '\r' | xargs)
    base_commit=$(echo "$base_commit" | tr -d '\r' | xargs)

    if [ -z "$repo" ]; then
        continue
    fi

    CURRENT_INDEX=$((CURRENT_INDEX + 1))
    echo ""
    echo "============================================================"
    echo "[$CURRENT_INDEX/$TOTAL_REPOS] Repository: $repo @ $base_commit"
    echo "============================================================"

    TARGET_DIR="/workspace/current_repo"
    rm -rf "$TARGET_DIR"

    # Step 1: Clone
    echo "--- [1/3] CLONE: Cloning https://github.com/${repo}.git ---"
    if ! git clone "https://github.com/${repo}.git" "$TARGET_DIR"; then
        echo "❌ [BASELINE_RESULT] CLONE: FAILED (Could not clone repository)" >&2
        CLONE_FAILED_COUNT=$((CLONE_FAILED_COUNT + 1))
        LAST_EXIT_CODE=3
        rm -rf "$TARGET_DIR"
        continue
    fi

    # Step 2: Checkout base_commit
    echo ""
    echo "--- [2/3] CHECKOUT: Checking out commit $base_commit ---"
    if ! (cd "$TARGET_DIR" && git checkout --force "$base_commit"); then
        echo "❌ [BASELINE_RESULT] CHECKOUT: FAILED (Commit $base_commit not found)" >&2
        CLONE_FAILED_COUNT=$((CLONE_FAILED_COUNT + 1))
        LAST_EXIT_CODE=3
        rm -rf "$TARGET_DIR"
        continue
    fi

    # Step 3: Locate pom.xml
    PROJECT_DIR="$TARGET_DIR"
    if [ ! -f "$PROJECT_DIR/pom.xml" ]; then
        FOUND_POM=$(find "$TARGET_DIR" -maxdepth 2 -name "pom.xml" | head -n 1)
        if [ -n "$FOUND_POM" ]; then
            PROJECT_DIR="$(dirname "$FOUND_POM")"
            echo "ℹ️  Found pom.xml in subdirectory: $PROJECT_DIR"
        else
            echo "❌ [BASELINE_RESULT] CONFIG_ERROR: No pom.xml found in repository" >&2
            CONFIG_ERROR_COUNT=$((CONFIG_ERROR_COUNT + 1))
            LAST_EXIT_CODE=3
            rm -rf "$TARGET_DIR"
            continue
        fi
    fi

    # Step 4: Run baseline verification (build + test)
    echo ""
    echo "--- [3/3] VERIFY: Running baseline checks (mvn clean test-compile & mvn test) ---"
    (
        cd "$PROJECT_DIR"
        echo ""
        echo "Compiling (mvn clean test-compile)..."
        if ! mvn clean test-compile -B; then
            echo "❌ [BASELINE_RESULT] BUILD: FAILED (Compilation error)" >&2
            exit 1
        fi
        echo "✅ [BASELINE_RESULT] BUILD: SUCCESS"

        echo ""
        echo "Running tests (mvn test)..."
        if ! mvn test -B; then
            echo "❌ [BASELINE_RESULT] TESTS: FAILED (One or more tests failed)" >&2
            exit 2
        fi
        echo "✅ [BASELINE_RESULT] TESTS: SUCCESS (All tests green)"
        exit 0
    )
    REPO_STATUS=$?

    case $REPO_STATUS in
        0)
            echo "✅ [BASELINE_RESULT] $repo: PASSED"
            PASSED_COUNT=$((PASSED_COUNT + 1))
            LAST_EXIT_CODE=0
            ;;
        1)
            echo "❌ [BASELINE_RESULT] $repo: BUILD_FAILED"
            BUILD_FAILED_COUNT=$((BUILD_FAILED_COUNT + 1))
            LAST_EXIT_CODE=1
            ;;
        2)
            echo "❌ [BASELINE_RESULT] $repo: TESTS_FAILED"
            TESTS_FAILED_COUNT=$((TESTS_FAILED_COUNT + 1))
            LAST_EXIT_CODE=2
            ;;
        *)
            echo "❌ [BASELINE_RESULT] $repo: FAILED (Exit code $REPO_STATUS)"
            OTHER_FAILED_COUNT=$((OTHER_FAILED_COUNT + 1))
            LAST_EXIT_CODE=$REPO_STATUS
            ;;
    esac

    # Clean up cloned repo between runs to conserve container disk space
    if [ "${KEEP_REPOS:-0}" != "1" ] || [ "$TOTAL_REPOS" -gt 1 ]; then
        rm -rf "$TARGET_DIR"
    fi

done < "$CSV_FILE"

echo ""
echo "============================================================"
echo "[BASELINE] DATASET VERIFICATION SUMMARY"
echo "============================================================"
echo "Total repositories processed: $TOTAL_REPOS"
echo "  ✅ Passed:         $PASSED_COUNT"
echo "  ❌ Build Failed:   $BUILD_FAILED_COUNT"
echo "  ❌ Tests Failed:   $TESTS_FAILED_COUNT"
echo "  ❌ Clone/Checkout: $CLONE_FAILED_COUNT"
echo "  ❌ Config Errors:  $CONFIG_ERROR_COUNT"
if [ "$OTHER_FAILED_COUNT" -gt 0 ]; then
    echo "  ❌ Other Errors:   $OTHER_FAILED_COUNT"
fi
echo "============================================================"

# Return single repo exit code if only 1 repo was tested, or 0/1 for dataset
if [ "$TOTAL_REPOS" -eq 1 ]; then
    exit "$LAST_EXIT_CODE"
fi

if [ "$PASSED_COUNT" -eq "$TOTAL_REPOS" ]; then
    exit 0
else
    exit 1
fi
