#!/usr/bin/env bash
# termenv — agent/AI tooling setup
# Installs Claude Code, Prism status line, and claude-skills.
# Can be run standalone or called from install.sh.

set -eo pipefail

SKILLS_REPO="$HOME/.claude/claude-skills"

if [ "$1" = "--uninstall" ]; then
	echo "Uninstalling agent tooling..."
	if [ -x "$SKILLS_REPO/install" ]; then
		"$SKILLS_REPO/install" --uninstall || echo "  WARNING: claude-skills uninstall failed; continuing"
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
if command -v git &>/dev/null; then
	mkdir -p "$(dirname "$SKILLS_REPO")"
	if [ -d "$SKILLS_REPO/.git" ]; then
		echo "  Updating claude-skills..."
		git -C "$SKILLS_REPO" pull --ff-only --quiet || echo "  WARNING: claude-skills pull failed; using existing version"
	elif [ -d "$SKILLS_REPO" ]; then
		echo "  WARNING: $SKILLS_REPO exists but is not a git repo; skipping claude-skills"
	else
		echo "  Cloning claude-skills..."
		git clone --quiet https://github.com/zer0page/claude-skills.git "$SKILLS_REPO"
	fi
	if [ -x "$SKILLS_REPO/install" ]; then
		"$SKILLS_REPO/install"
	else
		echo "  WARNING: claude-skills install script not found; skipping"
	fi
else
	echo "  WARNING: git not found; skipping claude-skills install"
fi

echo "Agent tooling setup complete!"
