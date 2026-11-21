# Hybrid Migration Pipeline

1. Loads any legacy Java 8 project into an isolated container and validates baseline assumptions:
   1. **Build Check:** Compiles the project.
   2. **Test Check:** Runs the test suite.

---

## Pipeline Usage

```bash
# Run baseline checks on test dataset (clones test repo in container & runs tests)
./run-java8.sh
# or explicitly:
./run-java8.sh dataset/test.csv

# Run baseline checks on full dataset (processes all repos in dataset.csv)
./run-java8.sh dataset/dataset.csv

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

## Dataset
**Dataset source:**  [AmazonScience/migration-bench-java-selected](https://huggingface.co/datasets/AmazonScience/migration-bench-java-selected)