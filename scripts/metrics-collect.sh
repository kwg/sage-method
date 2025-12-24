#!/usr/bin/env bash
#
# metrics-collect.sh - Metrics Collection for SAGE
#
# This script collects metrics during epic/story execution:
# - Git statistics (commits, files changed, lines)
# - Time/duration tracking
# - Test results summary
# - Session information
#
# Usage:
#   ./metrics-collect.sh <command> [options]
#
# Commands:
#   git           Collect git metrics
#   time          Track time/duration
#   test          Collect test metrics
#   session       Session information
#   full          Full metrics collection
#   write         Write metrics to file
#
# Exit codes:
#   0 - Success
#   1 - Invalid arguments
#   2 - Collection error
#   3 - Write error
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------

METRICS_DIR="docs/sprint-artifacts"
DEFAULT_METRICS_FILE="metrics.json"

#------------------------------------------------------------------------------
# Git Metrics
#------------------------------------------------------------------------------

# Collect git metrics for a branch/range
# Usage: collect_git_metrics [--base BASE] [--head HEAD] [--json]
collect_git_metrics() {
    local base="main"
    local head="HEAD"
    local json_output=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --base)
                base="$2"
                shift 2
                ;;
            --head)
                head="$2"
                shift 2
                ;;
            --json)
                json_output=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    log_verbose "Collecting git metrics: $base..$head"

    # Commit count
    local commit_count
    commit_count=$(git rev-list --count "$base..$head" 2>/dev/null || echo "0")

    # Files changed
    local files_changed
    files_changed=$(git diff --name-only "$base..$head" 2>/dev/null | wc -l || echo "0")

    # Lines added/removed
    local lines_added=0
    local lines_removed=0
    local diffstat
    diffstat=$(git diff --shortstat "$base..$head" 2>/dev/null || echo "")

    if [[ -n "$diffstat" ]]; then
        lines_added=$(echo "$diffstat" | grep -oE "[0-9]+ insertion" | grep -oE "[0-9]+" || echo "0")
        lines_removed=$(echo "$diffstat" | grep -oE "[0-9]+ deletion" | grep -oE "[0-9]+" || echo "0")
    fi

    # Authors
    local authors
    authors=$(git log "$base..$head" --format='%an' 2>/dev/null | sort -u | wc -l || echo "0")

    # First and last commit timestamps
    local first_commit last_commit
    first_commit=$(git log "$base..$head" --format='%aI' --reverse 2>/dev/null | head -1 || echo "")
    last_commit=$(git log "$base..$head" --format='%aI' 2>/dev/null | head -1 || echo "")

    # File types breakdown
    local file_types
    file_types=$(git diff --name-only "$base..$head" 2>/dev/null |
        sed 's/.*\.//' |
        sort | uniq -c | sort -rn | head -5 |
        awk '{print "{\"ext\": \"." $2 "\", \"count\": " $1 "}"}' |
        paste -sd "," - || echo "")

    if [[ -z "$file_types" ]]; then
        file_types="{}"
    else
        file_types="[$file_types]"
    fi

    if [[ "$json_output" == "true" ]]; then
        cat << EOF
{
  "commits": $commit_count,
  "files_changed": $files_changed,
  "lines_added": ${lines_added:-0},
  "lines_removed": ${lines_removed:-0},
  "authors": $authors,
  "first_commit": $(if [[ -n "$first_commit" ]]; then echo "\"$first_commit\""; else echo "null"; fi),
  "last_commit": $(if [[ -n "$last_commit" ]]; then echo "\"$last_commit\""; else echo "null"; fi),
  "file_types": $file_types
}
EOF
    else
        echo "Git Metrics ($base..$head)"
        echo "=========================="
        echo "Commits:       $commit_count"
        echo "Files changed: $files_changed"
        echo "Lines added:   ${lines_added:-0}"
        echo "Lines removed: ${lines_removed:-0}"
        echo "Authors:       $authors"
    fi

    return 0
}

#------------------------------------------------------------------------------
# Time Metrics
#------------------------------------------------------------------------------

# Calculate duration between timestamps
# Usage: collect_time_metrics --start ISO_TIME --end ISO_TIME [--json]
collect_time_metrics() {
    local start_time=""
    local end_time=""
    local json_output=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --start)
                start_time="$2"
                shift 2
                ;;
            --end)
                end_time="$2"
                shift 2
                ;;
            --json)
                json_output=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    # Default end time to now
    if [[ -z "$end_time" ]]; then
        end_time=$(date -Iseconds)
    fi

    # If no start time, try to get from checkpoint
    if [[ -z "$start_time" ]]; then
        if [[ -f ".sage/state/current-checkpoint.json" ]]; then
            start_time=$(jq -r '.started_at // empty' .sage/state/current-checkpoint.json 2>/dev/null || echo "")
        fi
    fi

    if [[ -z "$start_time" ]]; then
        log_warn "No start time available"
        if [[ "$json_output" == "true" ]]; then
            echo '{"duration_seconds": null, "duration_human": "unknown"}'
        else
            echo "Duration: unknown"
        fi
        return 0
    fi

    # Calculate duration
    local start_epoch end_epoch duration_seconds
    start_epoch=$(date -d "$start_time" +%s 2>/dev/null || echo "0")
    end_epoch=$(date -d "$end_time" +%s 2>/dev/null || echo "0")
    duration_seconds=$((end_epoch - start_epoch))

    # Human-readable format
    local hours minutes seconds duration_human
    hours=$((duration_seconds / 3600))
    minutes=$(((duration_seconds % 3600) / 60))
    seconds=$((duration_seconds % 60))

    if [[ $hours -gt 0 ]]; then
        duration_human="${hours}h ${minutes}m ${seconds}s"
    elif [[ $minutes -gt 0 ]]; then
        duration_human="${minutes}m ${seconds}s"
    else
        duration_human="${seconds}s"
    fi

    if [[ "$json_output" == "true" ]]; then
        cat << EOF
{
  "start_time": "$start_time",
  "end_time": "$end_time",
  "duration_seconds": $duration_seconds,
  "duration_human": "$duration_human"
}
EOF
    else
        echo "Time Metrics"
        echo "============"
        echo "Start:    $start_time"
        echo "End:      $end_time"
        echo "Duration: $duration_human"
    fi

    return 0
}

#------------------------------------------------------------------------------
# Test Metrics
#------------------------------------------------------------------------------

# Collect test metrics from last test run
# Usage: collect_test_metrics [--file FILE] [--json]
collect_test_metrics() {
    local test_file=".sage/test-last-run.json"
    local json_output=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --file)
                test_file="$2"
                shift 2
                ;;
            --json)
                json_output=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    if [[ ! -f "$test_file" ]]; then
        log_warn "No test results file found: $test_file"
        if [[ "$json_output" == "true" ]]; then
            echo '{"passed": 0, "failed": 0, "skipped": 0, "total": 0, "success": false}'
        else
            echo "No test results available"
        fi
        return 0
    fi

    local test_data
    test_data=$(cat "$test_file")

    if [[ "$json_output" == "true" ]]; then
        echo "$test_data" | jq '{
            framework: .framework,
            passed: .results.passed,
            failed: .results.failed,
            skipped: .results.skipped,
            total: .results.total,
            success: .results.success,
            duration_seconds: .duration_seconds
        }'
    else
        local passed failed skipped total framework
        framework=$(echo "$test_data" | jq -r '.framework // "unknown"')
        passed=$(echo "$test_data" | jq -r '.results.passed // 0')
        failed=$(echo "$test_data" | jq -r '.results.failed // 0')
        skipped=$(echo "$test_data" | jq -r '.results.skipped // 0')
        total=$(echo "$test_data" | jq -r '.results.total // 0')

        echo "Test Metrics ($framework)"
        echo "========================="
        echo "Total:   $total"
        echo "Passed:  $passed"
        echo "Failed:  $failed"
        echo "Skipped: $skipped"
    fi

    return 0
}

#------------------------------------------------------------------------------
# Session Metrics
#------------------------------------------------------------------------------

# Collect session information
# Usage: collect_session_metrics [--json]
collect_session_metrics() {
    local json_output=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --json)
                json_output=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    # Get current branch
    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

    # Get current commit
    local current_commit
    current_commit=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

    # Get hostname and user
    local hostname user
    hostname=$(hostname 2>/dev/null || echo "unknown")
    user=$(whoami 2>/dev/null || echo "unknown")

    # Get timestamp
    local timestamp
    timestamp=$(date -Iseconds)

    # Check for active checkpoint
    local has_checkpoint=false
    local checkpoint_epic=""
    local checkpoint_story=""
    if [[ -f ".sage/state/current-checkpoint.json" ]]; then
        has_checkpoint=true
        checkpoint_epic=$(jq -r '.epic_id // ""' .sage/state/current-checkpoint.json 2>/dev/null || echo "")
        checkpoint_story=$(jq -r '.story_id // ""' .sage/state/current-checkpoint.json 2>/dev/null || echo "")
    fi

    if [[ "$json_output" == "true" ]]; then
        cat << EOF
{
  "timestamp": "$timestamp",
  "branch": "$current_branch",
  "commit": "$current_commit",
  "hostname": "$hostname",
  "user": "$user",
  "has_checkpoint": $has_checkpoint,
  "epic_id": $(if [[ -n "$checkpoint_epic" ]]; then echo "\"$checkpoint_epic\""; else echo "null"; fi),
  "story_id": $(if [[ -n "$checkpoint_story" ]]; then echo "\"$checkpoint_story\""; else echo "null"; fi)
}
EOF
    else
        echo "Session Info"
        echo "============"
        echo "Branch:   $current_branch"
        echo "Commit:   $current_commit"
        echo "Host:     $hostname"
        echo "User:     $user"
        echo "Time:     $timestamp"
        if [[ "$has_checkpoint" == "true" ]]; then
            echo "Epic:     $checkpoint_epic"
            echo "Story:    $checkpoint_story"
        fi
    fi

    return 0
}

#------------------------------------------------------------------------------
# Full Metrics Collection
#------------------------------------------------------------------------------

# Collect all metrics
# Usage: full_metrics [--epic EPIC_ID] [--story STORY_ID] [--base BASE] [--start START_TIME]
full_metrics() {
    local epic_id=""
    local story_id=""
    local base="main"
    local start_time=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --epic)
                epic_id="$2"
                shift 2
                ;;
            --story)
                story_id="$2"
                shift 2
                ;;
            --base)
                base="$2"
                shift 2
                ;;
            --start)
                start_time="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    log_info "Collecting full metrics..."

    local git_metrics time_metrics test_metrics session_metrics
    git_metrics=$(collect_git_metrics --base "$base" --json)
    time_metrics=$(collect_time_metrics --start "$start_time" --json)
    test_metrics=$(collect_test_metrics --json)
    session_metrics=$(collect_session_metrics --json)

    # Build complete metrics object
    cat << EOF
{
  "collected_at": "$(date -Iseconds)",
  "epic_id": $(if [[ -n "$epic_id" ]]; then echo "\"$epic_id\""; else echo "null"; fi),
  "story_id": $(if [[ -n "$story_id" ]]; then echo "\"$story_id\""; else echo "null"; fi),
  "git": $git_metrics,
  "time": $time_metrics,
  "tests": $test_metrics,
  "session": $session_metrics
}
EOF

    return 0
}

#------------------------------------------------------------------------------
# Metrics File Operations
#------------------------------------------------------------------------------

# Write metrics to file
# Usage: write_metrics <metrics_json> [--file FILE] [--append]
write_metrics() {
    local metrics=""
    local output_file=""
    local append_mode=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --file)
                output_file="$2"
                shift 2
                ;;
            --append)
                append_mode=true
                shift
                ;;
            *)
                if [[ -z "$metrics" ]]; then
                    metrics="$1"
                fi
                shift
                ;;
        esac
    done

    # Read from stdin if no metrics provided
    if [[ -z "$metrics" ]]; then
        metrics=$(cat)
    fi

    # Validate JSON
    if ! echo "$metrics" | jq -e '.' &>/dev/null; then
        log_error "Invalid JSON metrics"
        return 3
    fi

    # Default output file based on epic/story
    if [[ -z "$output_file" ]]; then
        local epic_id story_id
        epic_id=$(echo "$metrics" | jq -r '.epic_id // ""')
        story_id=$(echo "$metrics" | jq -r '.story_id // ""')

        if [[ -n "$epic_id" ]]; then
            output_file="$METRICS_DIR/epic-${epic_id}-metrics.json"
        else
            output_file="$METRICS_DIR/$DEFAULT_METRICS_FILE"
        fi
    fi

    # Ensure directory exists
    mkdir -p "$(dirname "$output_file")"

    if [[ "$append_mode" == "true" && -f "$output_file" ]]; then
        # Append to existing array or create new array
        local existing
        existing=$(cat "$output_file" 2>/dev/null || echo "[]")

        if echo "$existing" | jq -e 'type == "array"' &>/dev/null; then
            # Append to array
            echo "$existing" | jq --argjson new "$metrics" '. + [$new]' > "$output_file"
        else
            # Wrap existing and new in array
            echo "[$existing, $metrics]" | jq '.' > "$output_file"
        fi
    else
        # Write/overwrite
        echo "$metrics" | jq '.' > "$output_file"
    fi

    log_success "Metrics written to: $output_file"
    return 0
}

#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------

usage() {
    cat << 'EOF'
metrics-collect.sh - Metrics Collection for SAGE

Usage:
  metrics-collect.sh <command> [options]

Commands:
  git             Collect git metrics (commits, files, lines)
  time            Collect time/duration metrics
  test            Collect test metrics
  session         Collect session information
  full            Collect all metrics
  write           Write metrics to file

Options (git):
  --base BRANCH   Base branch for comparison (default: main)
  --head REF      Head ref (default: HEAD)
  --json          Output as JSON

Options (time):
  --start TIME    Start timestamp (ISO format)
  --end TIME      End timestamp (default: now)
  --json          Output as JSON

Options (test):
  --file FILE     Test results file (default: .sage/test-last-run.json)
  --json          Output as JSON

Options (full):
  --epic ID       Epic ID
  --story ID      Story ID
  --base BRANCH   Base branch for git metrics
  --start TIME    Start time for duration

Options (write):
  --file FILE     Output file path
  --append        Append to existing file/array

Global Options:
  -v, --verbose   Enable verbose output
  -h, --help      Show this help

Exit Codes:
  0 - Success
  1 - Invalid arguments
  2 - Collection error
  3 - Write error

Examples:
  # Collect git metrics
  metrics-collect.sh git --base dev --json

  # Collect all metrics for epic
  metrics-collect.sh full --epic epic-3 --story 3-1

  # Pipe full metrics to file
  metrics-collect.sh full | metrics-collect.sh write --file metrics.json

  # Append to metrics history
  metrics-collect.sh full | metrics-collect.sh write --append

EOF
}

main() {
    local command=""

    # Parse global options
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
            -*)
                break
                ;;
            *)
                command="$1"
                shift
                break
                ;;
        esac
    done

    # Initialize
    sage_init --require-git

    # Dispatch command
    case "$command" in
        git)
            collect_git_metrics "$@"
            ;;
        time)
            collect_time_metrics "$@"
            ;;
        test)
            collect_test_metrics "$@"
            ;;
        session)
            collect_session_metrics "$@"
            ;;
        full)
            full_metrics "$@"
            ;;
        write)
            write_metrics "$@"
            ;;
        "")
            log_error "No command specified"
            usage
            exit 1
            ;;
        *)
            log_error "Unknown command: $command"
            usage
            exit 1
            ;;
    esac
}

# Run if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
