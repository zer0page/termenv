#!/usr/bin/env bash
# termenv — agent/AI tooling setup
# Installs Claude Code and Prism status line.
# Can be run standalone or called from install.sh.

set -eo pipefail

if [ "$1" = "--uninstall" ]; then
	echo "Uninstalling agent tooling..."
	SKILLS_REPO="$HOME/.claude/claude-skills"
	if [ -x "$SKILLS_REPO/install" ]; then
		"$SKILLS_REPO/install" --uninstall
	fi
	echo "  Remove Claude Code and Prism manually if desired."
	exit 0
fi

echo "Setting up agent tooling..."

# Install Claude Code
if ! command -v claude &>/dev/null; then
	if command -v brew &>/dev/null; then
		echo "  Installing Claude Code via brew..."
		brew install claude-code
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

# Install claude-skills (shared Claude Code skills)
SKILLS_REPO="$HOME/.claude/claude-skills"
if [ -d "$SKILLS_REPO/.git" ]; then
	echo "  Updating claude-skills..."
	git -C "$SKILLS_REPO" pull --quiet
else
	echo "  Cloning claude-skills..."
	git clone --quiet https://github.com/zer0page/claude-skills.git "$SKILLS_REPO"
fi
"$SKILLS_REPO/install"

echo "Agent tooling setup complete!"
