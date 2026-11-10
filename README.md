# Hybrid Migration Pipeline

1. Loads any legacy Java 8 project into an isolated container and validates baseline assumptions:
   1. **Build Check:** Compiles the project.
   2. **Test Check:** Runs the test suite.

---

## Pipeline Usage

```bash
# Run baseline checks on a specific legacy project
./run-java8.sh /path/to/legacy-java8-project

# Run baseline checks on the built-in smoke-test project
./run-java8.sh ./smoke-test

# Build the container image before pipeline execution
./run-java8.sh build
```

---

## Exit Codes (Pipeline Branching)

| Exit Code | Meaning | Workflow Decision |
|---|---|---|
| `0` | **`BASELINE_OK`** | Project compiled and all tests passed. Proceed to migration step. |
| `1` | **`BUILD_FAILED`** | Compilation error. Abort or trigger compilation error handler. |
| `2` | **`TESTS_FAILED`** | Unit test failure. Baseline assumption violated (tests must be green). |
| `3` | **`CONFIG_ERROR`** | Missing directory or missing `pom.xml`. |

---