#!/usr/bin/env bash
# termenv — Cycle to the next/previous idle Claude Code pane.
#
# Reads the per-pane @claude_waiting variable (set by tmux-notify.sh hook
# from claude-skills) to find panes where Claude Code is waiting for input.
#
# Requires: tmux-notify.sh hooks installed in Claude Code settings.json
# (installed automatically by agent/setup.sh via claude-skills).
#
# Configuration (tmux global options):
#   @claude_cycle_scope    — "all" (default, all windows in session) or "window"
#   @claude_cycle_autozoom — "0" (default) no auto-zoom, "1" to enable
#
# Usage (called by tmux keybinding, not directly):
#   claude-cycle.sh next    (bound to C-Space)
#   claude-cycle.sh prev    (available if keybinding added)
set -euo pipefail

# Guard: silently exit if not running inside tmux.
[ -n "${TMUX_PANE:-}" ] || exit 0

ACTION="${1:-next}"
case "$ACTION" in
next | prev) ;;
*)
	tmux display-message "Invalid claude-cycle action: $ACTION (expected: next or prev)"
	exit 1
	;;
esac

# Read configuration.
SCOPE=$(tmux show-option -gqv @claude_cycle_scope 2>/dev/null) || true
SCOPE="${SCOPE:-all}"
AUTOZOOM=$(tmux show-option -gqv @claude_cycle_autozoom 2>/dev/null) || true
AUTOZOOM="${AUTOZOOM:-0}"

# Current pane info.
CURRENT_PANE="$TMUX_PANE"

# Collect candidate panes (id, @claude_waiting, pane_pid, command in one call).
pane_fmt='#{pane_id} #{@claude_waiting} #{pane_pid} #{pane_current_command}'
if [ "$SCOPE" = "window" ]; then
	pane_data=$(tmux list-panes -F "$pane_fmt" 2>/dev/null) || exit 0
else
	pane_data=$(tmux list-panes -s -F "$pane_fmt" 2>/dev/null) || exit 0
fi

# If a stored marker matches the current window name, remove it from the name
# and clear the corresponding @claude_applied_* window options.
strip_window_marker() {
	local win="$1"
	local marker position name marker_len stripped
	marker=$(tmux show-option -wqv -t "$win" @claude_applied_marker 2>/dev/null) || return 0
	[ -n "$marker" ] || return 0
	position=$(tmux show-option -wqv -t "$win" @claude_applied_position 2>/dev/null) || true
	name=$(tmux display-message -t "$win" -p '#{window_name}' 2>/dev/null) || return 0
	marker_len=${#marker}

	if [ "$position" = "append" ] && [ "${name: -marker_len}" = "$marker" ]; then
		stripped="${name:0:${#name}-marker_len}"
	elif [ "${name:0:marker_len}" = "$marker" ]; then
		stripped="${name:marker_len}"
	fi
	[ -n "$stripped" ] || return 0

	tmux rename-window -t "$win" -- "$stripped" 2>/dev/null || true
	tmux set-option -wu -t "$win" @claude_applied_marker 2>/dev/null || true
	tmux set-option -wu -t "$win" @claude_applied_position 2>/dev/null || true
}

# Filter to panes marked as waiting.
waiting_panes=()
cleaned_windows=""
while IFS=' ' read -r pane_id waiting pane_pid pane_cmd; do
	[ "$waiting" = "1" ] || continue

	# Validate pane_id format.
	[[ "$pane_id" =~ ^%[0-9]+$ ]] || continue

	# Verify a claude process is running (as child or as the pane command itself).
	if [ "$pane_cmd" != "claude" ] && ! pgrep -x claude -P "$pane_pid" >/dev/null 2>&1; then
		# Stale flag — unset it and clean up the window marker if needed.
		tmux set-option -pu -t "$pane_id" @claude_waiting 2>/dev/null || true

		win=$(tmux display-message -t "$pane_id" -p '#{window_id}' 2>/dev/null) || true
		if [ -n "$win" ]; then
			case " $cleaned_windows " in
				*" $win "*) ;;
				*)
					others=$(tmux list-panes -t "$win" -F '#{@claude_waiting}' 2>/dev/null) || true
					if ! echo "$others" | grep -qxF '1'; then
						strip_window_marker "$win"
						cleaned_windows="$cleaned_windows $win"
					fi
					;;
			esac
		fi

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
	tmux display-message "Already at the only idle Claude session"
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
if [ "$current_idx" -eq -1 ]; then
	if [ "$ACTION" = "prev" ]; then
		target_idx=$((count - 1))
	else
		target_idx=0
	fi
else
	if [ "$ACTION" = "prev" ]; then step=-1; else step=1; fi
	target_idx=$(((current_idx + step + count) % count))
fi

TARGET_PANE="${waiting_panes[$target_idx]}"

# Nothing to do if target wrapped back to current.
if [ "$TARGET_PANE" = "$CURRENT_PANE" ]; then
	tmux display-message "No other idle Claude sessions"
	exit 0
fi

# Zoom handling: unzoom current pane before switching (only when autozoom enabled).
if [ "$AUTOZOOM" = "1" ]; then
	current_zoomed=$(tmux display-message -p '#{window_zoomed_flag}' 2>/dev/null) || true
	if [ "$current_zoomed" = "1" ]; then
		tmux resize-pane -Z 2>/dev/null || true
	fi
fi

# Switch to the target pane (select-pane handles cross-window within a session).
tmux select-pane -t "$TARGET_PANE" 2>/dev/null || {
	tmux display-message "Failed to switch to idle Claude pane"
	exit 1
}

# Auto-zoom the target pane (only if not already zoomed in target window).
if [ "$AUTOZOOM" = "1" ]; then
	target_zoomed=$(tmux display-message -p '#{window_zoomed_flag}' 2>/dev/null) || true
	if [ "$target_zoomed" != "1" ]; then
		tmux resize-pane -Z -t "$TARGET_PANE" 2>/dev/null || true
	fi
fi
