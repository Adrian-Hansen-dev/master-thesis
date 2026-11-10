#!/usr/bin/env bash
# ==============================================================================
# Baseline Verification Script (runs inside Java 8 container)
# 1. Compiles the project: mvn clean test-compile
# 2. Runs the test suite:  mvn test
# ==============================================================================

set -euo pipefail

echo "============================================================"
echo "[BASELINE] Verifying Java 8 Maven Project"
echo "Workspace: $(pwd)"
echo "Java: $(java -version 2>&1 | head -n 1)"
echo "Maven: $(mvn -version 2>&1 | head -n 1)"
echo "============================================================"

# Ensure pom.xml exists
if [ ! -f "pom.xml" ]; then
    echo "❌ [BASELINE_ERROR] No pom.xml found in workspace." >&2
    exit 3
fi

# Step 1: Build / Compilation Check
echo ""
echo "--- [STEP 1/2] BUILD: Compiling (mvn clean test-compile) ---"
if ! mvn clean test-compile -B; then
    echo ""
    echo "❌ [BASELINE_RESULT] BUILD: FAILED (Compilation error)" >&2
    exit 1
fi
echo "✅ [BASELINE_RESULT] BUILD: SUCCESS"

# Step 2: Test Execution Check
echo ""
echo "--- [STEP 2/2] TEST: Running tests (mvn test) ---"
if ! mvn test -B; then
    echo ""
    echo "❌ [BASELINE_RESULT] TESTS: FAILED (One or more tests failed)" >&2
    exit 2
fi
echo "✅ [BASELINE_RESULT] TESTS: SUCCESS (All tests green)"

echo ""
echo "============================================================"
echo "[BASELINE_RESULT] OVERALL: PASSED"
echo "============================================================"
exit 0
