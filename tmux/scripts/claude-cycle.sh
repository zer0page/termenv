#!/usr/bin/env bash
# termenv — Cycle to the next/previous idle Claude Code pane.
#
# Reads the per-pane @claude_waiting variable (set by tmux-notify.sh hook)
# to find panes where Claude Code is waiting for user input.
#
# Configuration (tmux global options):
#   @claude_cycle_scope    — "all" (default) or "window" (current window only)
#   @claude_cycle_autozoom — "1" (default) auto-zoom target, "0" to disable
#
# Usage (called by tmux keybinding, not directly):
#   claude-cycle.sh next
#   claude-cycle.sh prev
set -euo pipefail

# Guard: silently exit if not running inside tmux.
[ -n "${TMUX_PANE:-}" ] || exit 0

ACTION="${1:-next}"

# Read configuration.
SCOPE=$(tmux show-option -gqv @claude_cycle_scope 2>/dev/null) || true
SCOPE="${SCOPE:-all}"
AUTOZOOM=$(tmux show-option -gqv @claude_cycle_autozoom 2>/dev/null) || true
AUTOZOOM="${AUTOZOOM:-1}"

# Current pane info.
CURRENT_PANE="$TMUX_PANE"

# Collect candidate panes (id and @claude_waiting value).
if [ "$SCOPE" = "window" ]; then
	pane_data=$(tmux list-panes -F '#{pane_id} #{@claude_waiting}' 2>/dev/null) || exit 0
else
	pane_data=$(tmux list-panes -a -F '#{pane_id} #{@claude_waiting}' 2>/dev/null) || exit 0
fi

# Filter to panes marked as waiting.
waiting_panes=()
while IFS=' ' read -r pane_id waiting; do
	[ "$waiting" = "1" ] || continue

	# Verify a claude process is actually running in this pane.
	pane_pid=$(tmux display-message -t "$pane_id" -p '#{pane_pid}' 2>/dev/null) || continue
	if ! pgrep -x claude -P "$pane_pid" >/dev/null 2>&1; then
		# Stale flag — clear it and skip.
		tmux set-option -p -t "$pane_id" -u @claude_waiting 2>/dev/null || true
		continue
	fi

	waiting_panes+=("$pane_id")
done <<<"$pane_data"

# No idle panes found.
if [ ${#waiting_panes[@]} -eq 0 ]; then
	tmux display-message "No idle Claude sessions"
	exit 0
fi

# Only one idle pane and it's the current one.
if [ ${#waiting_panes[@]} -eq 1 ] && [ "${waiting_panes[0]}" = "$CURRENT_PANE" ]; then
	tmux display-message "No other idle Claude sessions"
	exit 0
fi

# Find current pane's position in the list (may not be in the list at all).
current_idx=-1
for i in "${!waiting_panes[@]}"; do
	if [ "${waiting_panes[$i]}" = "$CURRENT_PANE" ]; then
		current_idx=$i
		break
	fi
done

# Pick next or previous, wrapping around.
count=${#waiting_panes[@]}
if [ "$ACTION" = "prev" ]; then
	if [ "$current_idx" -ge 0 ]; then
		target_idx=$(((current_idx - 1 + count) % count))
	else
		target_idx=$((count - 1))
	fi
else
	if [ "$current_idx" -ge 0 ]; then
		target_idx=$(((current_idx + 1) % count))
	else
		target_idx=0
	fi
fi

TARGET_PANE="${waiting_panes[$target_idx]}"

# Nothing to do if target is already current.
if [ "$TARGET_PANE" = "$CURRENT_PANE" ]; then
	tmux display-message "No other idle Claude sessions"
	exit 0
fi

# Zoom handling: unzoom current pane if zoomed.
current_zoomed=$(tmux display-message -p '#{window_zoomed_flag}' 2>/dev/null) || true
if [ "$current_zoomed" = "1" ]; then
	tmux resize-pane -Z 2>/dev/null || true
fi

# Switch to target pane (handles cross-window switching).
tmux switch-client -t "$TARGET_PANE" 2>/dev/null ||
	tmux select-pane -t "$TARGET_PANE" 2>/dev/null || exit 0

# Auto-zoom the target pane.
if [ "$AUTOZOOM" = "1" ]; then
	tmux resize-pane -Z -t "$TARGET_PANE" 2>/dev/null || true
fi
