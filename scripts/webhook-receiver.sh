#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════════════
# SAGE Webhook Receiver
# ════════════════════════════════════════════════════════════════════════════
#
# Lightweight HTTP server that receives GitHub webhooks and triggers
# Claude Code resume when HitL responses are detected.
#
# Usage:
#   ./webhook-receiver.sh [port]
#
# Default port: 9876
#
# GitHub Webhook Setup:
#   1. Expose this port via ngrok/cloudflare tunnel
#   2. Add webhook to repo: Settings → Webhooks → Add
#   3. Payload URL: https://your-tunnel-url/webhook
#   4. Content type: application/json
#   5. Events: Issue comments, Pull request reviews
#
# ════════════════════════════════════════════════════════════════════════════

set -uo pipefail

PORT="${1:-9876}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_FILE="${PROJECT_ROOT}/.sage/logs/webhook.log"
STATE_DIR="${PROJECT_ROOT}/.sage/state"

# Ensure directories exist
mkdir -p "$(dirname "$LOG_FILE")" "$STATE_DIR"

log() {
    local timestamp
    timestamp=$(date -Iseconds)
    echo "[$timestamp] $*" | tee -a "$LOG_FILE"
}

# Keywords that indicate approval
APPROVE_KEYWORDS="approved|lgtm|ship it|looks good|go ahead|yes|approve"
REVISE_KEYWORDS="needs work|changes requested|revise|fix|reject|no"
DISCUSS_KEYWORDS="let's discuss|questions|need to think|discuss"
HALT_KEYWORDS="blocked|stop|halt|pause|wait"

parse_response() {
    local comment="$1"
    local comment_lower
    comment_lower=$(echo "$comment" | tr '[:upper:]' '[:lower:]')

    if echo "$comment_lower" | grep -qE "$DISCUSS_KEYWORDS"; then
        echo "DISCUSS"
    elif echo "$comment_lower" | grep -qE "$HALT_KEYWORDS"; then
        echo "HALT"
    elif echo "$comment_lower" | grep -qE "$APPROVE_KEYWORDS"; then
        # Check for conditional approval
        if echo "$comment_lower" | grep -qE "but|however|although|except"; then
            echo "DISCUSS"
        else
            echo "APPROVED"
        fi
    elif echo "$comment_lower" | grep -qE "$REVISE_KEYWORDS"; then
        echo "REVISE"
    else
        echo "UNCLEAR"
    fi
}

update_checkpoint() {
    local status="$1"
    local comment="$2"

    # Find most recent checkpoint
    local checkpoint
    checkpoint=$(ls -t "$STATE_DIR"/*.json 2>/dev/null | head -1)

    if [[ -z "$checkpoint" ]]; then
        log "ERROR: No checkpoint file found"
        return 1
    fi

    log "Updating checkpoint: $checkpoint with status: $status"

    # Update checkpoint with response (requires jq)
    if command -v jq &>/dev/null; then
        local tmp_file="${checkpoint}.tmp"
        jq --arg status "$status" \
           --arg comment "$comment" \
           --arg timestamp "$(date -Iseconds)" \
           '.hitl.response_status = $status |
            .hitl.response_comment = $comment |
            .hitl.response_at = $timestamp |
            .next_action.type = (if $status == "APPROVED" then "continue" elif $status == "REVISE" then "revise" else "hitl" end)' \
           "$checkpoint" > "$tmp_file" && mv "$tmp_file" "$checkpoint"
    fi
}

trigger_resume() {
    local status="$1"

    log "Triggering Claude Code resume with status: $status"

    # Create a signal file that can be detected
    echo "{\"status\": \"$status\", \"timestamp\": \"$(date -Iseconds)\"}" > "$STATE_DIR/.resume-signal"

    # Option 1: If Claude Code is running with a FIFO/socket, write to it
    # Option 2: Use claude CLI to send a message
    # Option 3: Just update checkpoint and let next /assistant load handle it

    log "Resume signal written to $STATE_DIR/.resume-signal"
    log "Run '/assistant' or '*resume' to continue orchestration"
}

handle_webhook() {
    local payload="$1"

    # Parse webhook payload
    local action
    local comment_body
    local issue_number
    local sender

    action=$(echo "$payload" | jq -r '.action // empty')
    comment_body=$(echo "$payload" | jq -r '.comment.body // empty')
    issue_number=$(echo "$payload" | jq -r '.issue.number // empty')
    sender=$(echo "$payload" | jq -r '.sender.login // empty')

    log "═══════════════════════════════════════════════════════════════════"
    log "WEBHOOK RECEIVED"
    log "  Action: $action"
    log "  Issue: #$issue_number"
    log "  Sender: $sender"
    log "  Comment: ${comment_body:0:100}..."

    # Only process issue_comment created events
    if [[ "$action" != "created" ]] || [[ -z "$comment_body" ]]; then
        log "  Skipping: Not a new comment"
        log "═══════════════════════════════════════════════════════════════════"
        return
    fi

    # Ignore bot comments
    if [[ "$sender" == *"[bot]"* ]] || [[ "$sender" == "github-actions" ]]; then
        log "  Skipping: Bot comment"
        log "═══════════════════════════════════════════════════════════════════"
        return
    fi

    # Parse the response
    local response_status
    response_status=$(parse_response "$comment_body")

    log "  Parsed Status: $response_status"
    log "═══════════════════════════════════════════════════════════════════"

    # Update checkpoint and trigger resume
    update_checkpoint "$response_status" "$comment_body"
    trigger_resume "$response_status"
}

# Simple HTTP server using netcat
serve() {
    log "Starting webhook receiver on port $PORT"
    log "Waiting for GitHub webhooks..."

    while true; do
        # Read HTTP request
        {
            # Read request line and headers
            read -r request_line
            content_length=0
            while read -r header; do
                header=$(echo "$header" | tr -d '\r')
                [[ -z "$header" ]] && break
                if [[ "$header" =~ ^Content-Length:\ ([0-9]+) ]]; then
                    content_length="${BASH_REMATCH[1]}"
                fi
            done

            # Read body
            body=""
            if [[ "$content_length" -gt 0 ]]; then
                body=$(head -c "$content_length")
            fi

            # Process webhook
            if [[ "$request_line" == *"POST"* ]]; then
                handle_webhook "$body"
            fi

            # Send response
            echo -e "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nOK"

        } | nc -l -p "$PORT" -q 1
    done
}

# Main
log "════════════════════════════════════════════════════════════════════════════"
log "SAGE Webhook Receiver Starting"
log "  Port: $PORT"
log "  Project: $PROJECT_ROOT"
log "  Log: $LOG_FILE"
log "════════════════════════════════════════════════════════════════════════════"

serve
