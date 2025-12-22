#!/usr/bin/env bash
#
# test-run.sh - Test Execution Wrapper for SAGE
#
# This script wraps test framework execution for consistent orchestrator
# integration. It auto-detects test frameworks and provides structured
# JSON output for metrics collection.
#
# Usage:
#   ./test-run.sh [options]
#
# Commands:
#   run            Run tests (default)
#   detect         Detect test framework only
#   report         Generate report from last run
#
# Options:
#   --framework    Force specific framework (jest, pytest, go, bats, npm)
#   --path         Test path or pattern
#   --coverage     Enable coverage collection
#   --output       Output file for results (default: stdout)
#   --nix          Use nix develop --command wrapper
#
# Exit codes:
#   0 - All tests passed
#   1 - Some tests failed
#   2 - Test framework error
#   3 - No tests found
#   4 - Invalid arguments
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------

# Test framework detection patterns
declare -A FRAMEWORK_FILES=(
    ["jest"]="jest.config.js jest.config.ts jest.config.mjs package.json"
    ["pytest"]="pytest.ini pyproject.toml setup.py conftest.py"
    ["go"]="go.mod"
    ["bats"]="test/*.bats tests/*.bats"
    ["npm"]="package.json"
    ["cargo"]="Cargo.toml"
)

# Default commands per framework
declare -A FRAMEWORK_COMMANDS=(
    ["jest"]="npx jest --json"
    ["pytest"]="python -m pytest --tb=short -q"
    ["go"]="go test -json ./..."
    ["bats"]="bats --formatter tap"
    ["npm"]="npm test"
    ["cargo"]="cargo test --message-format json"
)

# Coverage flags per framework
declare -A COVERAGE_FLAGS=(
    ["jest"]="--coverage --coverageReporters=json-summary"
    ["pytest"]="--cov --cov-report=json"
    ["go"]="-cover -coverprofile=coverage.out"
    ["cargo"]=""
)

# State
USE_NIX=false
COVERAGE_ENABLED=false
FORCED_FRAMEWORK=""
TEST_PATH=""
OUTPUT_FILE=""
LAST_RUN_FILE=".sage/test-last-run.json"

#------------------------------------------------------------------------------
# Framework Detection
#------------------------------------------------------------------------------

# Detect test framework from project files
# Usage: detect_framework [path]
detect_framework() {
    local search_path="${1:-.}"

    log_verbose "Detecting test framework in: $search_path"

    # Check for each framework's indicator files
    for framework in jest pytest go bats cargo npm; do
        local files="${FRAMEWORK_FILES[$framework]}"

        for file in $files; do
            if [[ "$file" == *"*"* ]]; then
                # Glob pattern
                if compgen -G "$search_path/$file" > /dev/null 2>&1; then
                    log_info "Detected framework: $framework (found $file)"
                    echo "$framework"
                    return 0
                fi
            else
                if [[ -f "$search_path/$file" ]]; then
                    # Special case for package.json - check for test script
                    if [[ "$framework" == "npm" && "$file" == "package.json" ]]; then
                        if jq -e '.scripts.test' "$search_path/$file" &>/dev/null; then
                            log_info "Detected framework: npm (has test script)"
                            echo "npm"
                            return 0
                        fi
                        continue
                    fi

                    # Special case for jest in package.json
                    if [[ "$framework" == "jest" && "$file" == "package.json" ]]; then
                        if jq -e '.devDependencies.jest or .dependencies.jest' "$search_path/$file" &>/dev/null; then
                            log_info "Detected framework: jest (in package.json)"
                            echo "jest"
                            return 0
                        fi
                        continue
                    fi

                    log_info "Detected framework: $framework (found $file)"
                    echo "$framework"
                    return 0
                fi
            fi
        done
    done

    log_warn "No test framework detected"
    echo "unknown"
    return 3
}

#------------------------------------------------------------------------------
# Test Execution
#------------------------------------------------------------------------------

# Build test command
# Usage: build_test_command <framework>
build_test_command() {
    local framework="$1"
    local cmd=""

    if [[ -z "${FRAMEWORK_COMMANDS[$framework]:-}" ]]; then
        log_error "Unknown framework: $framework"
        return 4
    fi

    cmd="${FRAMEWORK_COMMANDS[$framework]}"

    # Add coverage flags
    if [[ "$COVERAGE_ENABLED" == "true" ]]; then
        local cov_flag="${COVERAGE_FLAGS[$framework]:-}"
        if [[ -n "$cov_flag" ]]; then
            cmd="$cmd $cov_flag"
        fi
    fi

    # Add test path
    if [[ -n "$TEST_PATH" ]]; then
        case "$framework" in
            jest|pytest)
                cmd="$cmd $TEST_PATH"
                ;;
            go)
                cmd="go test -json $TEST_PATH"
                ;;
            bats)
                cmd="bats --formatter tap $TEST_PATH"
                ;;
        esac
    fi

    # Wrap with nix develop if requested
    if [[ "$USE_NIX" == "true" ]]; then
        cmd="nix develop --command bash -c '$cmd'"
    fi

    echo "$cmd"
}

# Run tests and capture output
# Usage: run_tests [framework]
run_tests() {
    local framework="${1:-}"

    # Detect framework if not specified
    if [[ -z "$framework" ]]; then
        framework=$(detect_framework)
        if [[ "$framework" == "unknown" ]]; then
            return 3
        fi
    fi

    log_info "Running tests with framework: $framework"

    local cmd
    cmd=$(build_test_command "$framework")

    log_verbose "Test command: $cmd"

    # Create temp files for output
    local stdout_file
    local stderr_file
    stdout_file=$(mktemp)
    stderr_file=$(mktemp)

    # Track timing
    local start_time
    start_time=$(date +%s)

    # Execute tests
    local exit_code=0
    if [[ "$USE_NIX" == "true" ]]; then
        eval "$cmd" > "$stdout_file" 2> "$stderr_file" || exit_code=$?
    else
        eval "$cmd" > "$stdout_file" 2> "$stderr_file" || exit_code=$?
    fi

    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))

    # Parse output based on framework
    local results
    results=$(parse_test_output "$framework" "$stdout_file" "$stderr_file" "$exit_code")

    # Add metadata
    local timestamp
    timestamp=$(date -Iseconds)

    local final_result
    final_result=$(cat << EOF
{
  "framework": "$framework",
  "timestamp": "$timestamp",
  "duration_seconds": $duration,
  "exit_code": $exit_code,
  "command": $(echo "$cmd" | jq -Rs '.'),
  "results": $results
}
EOF
)

    # Save last run
    mkdir -p "$(dirname "$LAST_RUN_FILE")"
    echo "$final_result" > "$LAST_RUN_FILE"

    # Output
    if [[ -n "$OUTPUT_FILE" ]]; then
        echo "$final_result" > "$OUTPUT_FILE"
        log_info "Results written to: $OUTPUT_FILE"
    else
        echo "$final_result"
    fi

    # Cleanup
    rm -f "$stdout_file" "$stderr_file"

    # Return based on test results
    if [[ $exit_code -eq 0 ]]; then
        log_success "All tests passed"
        return 0
    else
        log_warn "Some tests failed (exit code: $exit_code)"
        return 1
    fi
}

#------------------------------------------------------------------------------
# Output Parsing
#------------------------------------------------------------------------------

# Parse test output based on framework
# Usage: parse_test_output <framework> <stdout_file> <stderr_file> <exit_code>
parse_test_output() {
    local framework="$1"
    local stdout_file="$2"
    local stderr_file="$3"
    local exit_code="$4"

    local passed=0
    local failed=0
    local skipped=0
    local total=0
    local error_output=""

    case "$framework" in
        jest)
            # Jest JSON output
            if [[ -s "$stdout_file" ]]; then
                local jest_json
                jest_json=$(cat "$stdout_file" | jq -c '.' 2>/dev/null || echo "{}")

                if [[ "$jest_json" != "{}" ]]; then
                    passed=$(echo "$jest_json" | jq -r '.numPassedTests // 0')
                    failed=$(echo "$jest_json" | jq -r '.numFailedTests // 0')
                    skipped=$(echo "$jest_json" | jq -r '.numPendingTests // 0')
                    total=$((passed + failed + skipped))

                    # Extract failure messages
                    error_output=$(echo "$jest_json" | jq -r '
                        .testResults[]?.assertionResults[]? |
                        select(.status == "failed") |
                        "\(.ancestorTitles | join(" > ")) > \(.title): \(.failureMessages[0] // "unknown")"
                    ' 2>/dev/null | head -10)
                fi
            fi
            ;;

        pytest)
            # Parse pytest output
            local output
            output=$(cat "$stdout_file")

            # Try to extract from summary line: "X passed, Y failed, Z skipped"
            if echo "$output" | grep -qE "[0-9]+ passed"; then
                passed=$(echo "$output" | grep -oE "[0-9]+ passed" | grep -oE "[0-9]+" || echo "0")
            fi
            if echo "$output" | grep -qE "[0-9]+ failed"; then
                failed=$(echo "$output" | grep -oE "[0-9]+ failed" | grep -oE "[0-9]+" || echo "0")
            fi
            if echo "$output" | grep -qE "[0-9]+ skipped"; then
                skipped=$(echo "$output" | grep -oE "[0-9]+ skipped" | grep -oE "[0-9]+" || echo "0")
            fi
            total=$((passed + failed + skipped))

            # Get error output
            error_output=$(grep -A 5 "FAILED\|ERROR" "$stdout_file" 2>/dev/null | head -20 || echo "")
            ;;

        go)
            # Parse go test -json output
            if [[ -s "$stdout_file" ]]; then
                while IFS= read -r line; do
                    local action
                    action=$(echo "$line" | jq -r '.Action // ""' 2>/dev/null)
                    case "$action" in
                        pass) ((passed++)) ;;
                        fail) ((failed++)) ;;
                        skip) ((skipped++)) ;;
                    esac
                done < "$stdout_file"
                total=$((passed + failed + skipped))

                # Get failure output
                error_output=$(cat "$stdout_file" | jq -r 'select(.Action == "fail") | .Output // ""' 2>/dev/null | head -20 || echo "")
            fi
            ;;

        bats)
            # Parse TAP output
            local output
            output=$(cat "$stdout_file")

            passed=$(echo "$output" | grep -c "^ok " || echo "0")
            failed=$(echo "$output" | grep -c "^not ok " || echo "0")
            skipped=$(echo "$output" | grep -c "# skip" || echo "0")
            total=$((passed + failed + skipped))

            error_output=$(grep "^not ok " "$stdout_file" 2>/dev/null | head -10 || echo "")
            ;;

        npm|cargo|*)
            # Generic parsing - check exit code
            if [[ $exit_code -eq 0 ]]; then
                passed=1
                total=1
            else
                failed=1
                total=1
                error_output=$(cat "$stderr_file" | head -20)
            fi
            ;;
    esac

    # Build JSON result
    local error_json
    error_json=$(echo "$error_output" | jq -Rs '.' 2>/dev/null || echo '""')

    cat << EOF
{
  "passed": $passed,
  "failed": $failed,
  "skipped": $skipped,
  "total": $total,
  "success": $(if [[ $failed -eq 0 && $exit_code -eq 0 ]]; then echo "true"; else echo "false"; fi),
  "error_output": $error_json
}
EOF
}

#------------------------------------------------------------------------------
# Report Generation
#------------------------------------------------------------------------------

# Generate report from last run
# Usage: generate_report [--format FORMAT]
generate_report() {
    local format="${1:-json}"

    if [[ ! -f "$LAST_RUN_FILE" ]]; then
        log_error "No previous test run found"
        return 3
    fi

    local data
    data=$(cat "$LAST_RUN_FILE")

    case "$format" in
        json)
            echo "$data"
            ;;
        summary)
            local framework passed failed skipped total duration
            framework=$(echo "$data" | jq -r '.framework')
            passed=$(echo "$data" | jq -r '.results.passed')
            failed=$(echo "$data" | jq -r '.results.failed')
            skipped=$(echo "$data" | jq -r '.results.skipped')
            total=$(echo "$data" | jq -r '.results.total')
            duration=$(echo "$data" | jq -r '.duration_seconds')

            echo "Test Summary ($framework)"
            echo "========================"
            echo "Total:   $total"
            echo "Passed:  $passed"
            echo "Failed:  $failed"
            echo "Skipped: $skipped"
            echo "Duration: ${duration}s"

            if [[ $failed -gt 0 ]]; then
                echo ""
                echo "Failures:"
                echo "$data" | jq -r '.results.error_output' | head -20
            fi
            ;;
        *)
            log_error "Unknown format: $format"
            return 4
            ;;
    esac

    return 0
}

#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------

usage() {
    cat << 'EOF'
test-run.sh - Test Execution Wrapper for SAGE

Usage:
  test-run.sh [command] [options]

Commands:
  run              Run tests (default)
  detect           Detect test framework only
  report           Generate report from last run

Options:
  --framework FW   Force framework (jest, pytest, go, bats, npm, cargo)
  --path PATH      Test path or pattern
  --coverage       Enable coverage collection
  --output FILE    Write results to file
  --nix            Use nix develop --command wrapper
  --format FMT     Report format (json, summary)
  -v, --verbose    Enable verbose output
  -h, --help       Show this help

Exit Codes:
  0 - All tests passed
  1 - Some tests failed
  2 - Test framework error
  3 - No tests found
  4 - Invalid arguments

Supported Frameworks:
  - jest     (Node.js)
  - pytest   (Python)
  - go       (Go)
  - bats     (Bash)
  - npm      (generic npm test)
  - cargo    (Rust)

Examples:
  # Auto-detect and run tests
  test-run.sh run

  # Run with coverage
  test-run.sh run --coverage

  # Force pytest with specific path
  test-run.sh run --framework pytest --path tests/unit/

  # Run in NixOS environment
  test-run.sh run --nix

  # Get summary from last run
  test-run.sh report --format summary

  # Just detect framework
  test-run.sh detect

EOF
}

main() {
    local command="run"
    local report_format="json"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            run|detect|report)
                command="$1"
                shift
                ;;
            --framework)
                FORCED_FRAMEWORK="$2"
                shift 2
                ;;
            --path)
                TEST_PATH="$2"
                shift 2
                ;;
            --coverage)
                COVERAGE_ENABLED=true
                shift
                ;;
            --output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            --nix)
                USE_NIX=true
                shift
                ;;
            --format)
                report_format="$2"
                shift 2
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                exit 4
                ;;
            *)
                # Treat as test path if no path specified
                if [[ -z "$TEST_PATH" ]]; then
                    TEST_PATH="$1"
                fi
                shift
                ;;
        esac
    done

    # Initialize (don't require git for test running)
    sage_init

    # Dispatch command
    case "$command" in
        run)
            run_tests "$FORCED_FRAMEWORK"
            ;;
        detect)
            detect_framework
            ;;
        report)
            generate_report "$report_format"
            ;;
        *)
            log_error "Unknown command: $command"
            usage
            exit 4
            ;;
    esac
}

# Run if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
