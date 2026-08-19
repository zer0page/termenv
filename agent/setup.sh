#!/usr/bin/env bash
# termenv — agent/AI tooling setup
# Installs the selected agent CLI and its supporting tools.
# Can be run standalone or called from install.sh.

set -eo pipefail

CONFIG_FILE="$HOME/.termenv.conf"
SKILLS_REPO="$HOME/.claude/claude-skills"

if [ "$1" = "--uninstall" ]; then
	echo "Uninstalling agent tooling..."
	if [ -x "$SKILLS_REPO/install" ]; then
		"$SKILLS_REPO/install" --uninstall || echo "  WARNING: claude-skills uninstall failed; continuing"
	fi
	echo "  Remove Claude Code and Prism manually if desired."
	exit 0
fi

CURRENT_AGENT=claude
if [ -f "$CONFIG_FILE" ]; then
	# shellcheck disable=SC1090
	source "$CONFIG_FILE"
	CURRENT_AGENT="${TERMENV_AGENT:-claude}"
fi

SELECTED_AGENT="${1:-}"
while [ -z "$SELECTED_AGENT" ]; do
	printf "Select agent CLI (current: %s):\n  1) Claude Code\n  2) Amp\nChoice [keep current]: " "$CURRENT_AGENT"
	read -r AGENT_REPLY
	case "$AGENT_REPLY" in
	"") SELECTED_AGENT="$CURRENT_AGENT" ;;
	1 | claude) SELECTED_AGENT=claude ;;
	2 | amp) SELECTED_AGENT=amp ;;
	*) echo "  Enter 1 for Claude Code or 2 for Amp." ;;
	esac
done

case "$SELECTED_AGENT" in
claude | amp) ;;
*)
	echo "Unknown agent '$SELECTED_AGENT' (expected claude or amp)" >&2
	exit 2
	;;
esac

mkdir -p "$(dirname "$CONFIG_FILE")"
touch "$CONFIG_FILE"
config_tmp="$(mktemp "${TMPDIR:-/tmp}/termenv-conf.XXXXXX")"
awk '$0 != "# Agent used by the yolo command" && !/^TERMENV_AGENT=/' "$CONFIG_FILE" >"$config_tmp"
printf '# Agent used by the yolo command\nTERMENV_AGENT=%s\n' "$SELECTED_AGENT" >>"$config_tmp"
mv "$config_tmp" "$CONFIG_FILE"

echo "Setting up $SELECTED_AGENT agent tooling..."

install_personal_skills() {
	local install_args=("$@")
	if ! command -v git &>/dev/null; then
		echo "  WARNING: git not found; skipping personal skills install"
		return
	fi

	mkdir -p "$(dirname "$SKILLS_REPO")"
	if [ -d "$SKILLS_REPO/.git" ]; then
		echo "  Updating personal skills..."
		git -C "$SKILLS_REPO" pull --ff-only --quiet || echo "  WARNING: personal skills pull failed; using existing version"
	elif [ -d "$SKILLS_REPO" ]; then
		echo "  Using existing personal skills at $SKILLS_REPO"
	else
		echo "  Cloning personal skills..."
		if ! git clone --quiet https://github.com/zer0page/claude-skills.git "$SKILLS_REPO"; then
			echo "  WARNING: personal skills clone failed; skipping"
			rm -rf "$SKILLS_REPO"
			return
		fi
	fi

	if [ -x "$SKILLS_REPO/install" ]; then
		"$SKILLS_REPO/install" "${install_args[@]}" || echo "  WARNING: personal skills install failed; continuing"
	else
		echo "  WARNING: personal skills install script not found; skipping"
	fi
}

if [ "$SELECTED_AGENT" = "amp" ]; then
	if command -v amp &>/dev/null; then
		echo "  Amp already installed"
	elif command -v brew &>/dev/null; then
		echo "  Installing Amp via brew..."
		brew install ampcode/tap/ampcode
	else
		echo "  Installing Amp via official installer..."
		tmp="$(mktemp "${TMPDIR:-/tmp}/amp-install.XXXXXX")"
		trap 'rm -f "$tmp"' EXIT
		if curl -fsSL https://ampcode.com/install.sh -o "$tmp"; then
			bash "$tmp" || echo "  WARNING: Amp install failed — install manually: https://ampcode.com/manual"
		else
			echo "  WARNING: Failed to download Amp installer — install manually: https://ampcode.com/manual"
		fi
	fi
	install_personal_skills --skills-only
	echo "Agent tooling setup complete!"
	exit 0
fi

# Install Claude Code
if ! command -v claude &>/dev/null; then
	if command -v brew &>/dev/null; then
		echo "  Installing Claude Code via brew..."
		brew install --cask claude-code
	elif command -v npm &>/dev/null; then
		echo "  Installing Claude Code via npm..."
		npm install -g @anthropic-ai/claude-code
	else
		echo "  WARNING: Cannot install Claude Code (need brew or npm)"
	fi
else
	echo "  Claude Code already installed"
fi

# Install Prism status line (handles settings.json wiring itself)
echo "  Installing Prism..."
tmp=$(mktemp "${TMPDIR:-/tmp}/prism-install.XXXXXX")
trap 'rm -f "$tmp"' EXIT
if curl -fsSL https://raw.githubusercontent.com/himattm/prism/main/install.sh -o "$tmp"; then
	bash "$tmp" || echo "  WARNING: Prism install failed — install manually: https://github.com/himattm/prism"
else
	echo "  WARNING: Failed to download Prism installer — install manually: https://github.com/himattm/prism"
fi

# Install portable personal skills and offer optional Claude-specific tmux hooks.
install_personal_skills

echo "Agent tooling setup complete!"
