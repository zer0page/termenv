#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/termenv-agent-test-XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
	echo "FAIL: $*" >&2
	exit 1
}

make_fake_agent() {
	local name="$1"
	cat >"$TEST_ROOT/bin/$name" <<EOF
#!/usr/bin/env bash
printf '%s\\n' "\$@" >"$TEST_ROOT/$name.args"
EOF
	chmod +x "$TEST_ROOT/bin/$name"
}

run_yolo() {
	local agent="$1"
	shift
	rm -f "$TEST_ROOT/amp.args" "$TEST_ROOT/claude.args"
	cat >"$TEST_ROOT/home/.termenv.conf" <<EOF
TERMENV_AGENT=$agent
EOF
	HOME="$TEST_ROOT/home" PATH="$TEST_ROOT/bin:/usr/bin:/bin" \
		bash -c 'source "$1/shell/common.sh"; shift; yolo "$@"' _ "$ROOT" "$@"
}

mkdir -p "$TEST_ROOT/bin" "$TEST_ROOT/home"
make_fake_agent amp
make_fake_agent claude
cat >"$TEST_ROOT/bin/git" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
chmod +x "$TEST_ROOT/bin/git"

mkdir -p "$TEST_ROOT/home/.claude/claude-skills"
cat >"$TEST_ROOT/home/.claude/claude-skills/install" <<EOF
#!/usr/bin/env bash
printf '%s\\n' "\$@" >"$TEST_ROOT/skills-install.args"
EOF
chmod +x "$TEST_ROOT/home/.claude/claude-skills/install"

# Removing the TERMENV_AGENT dispatch would launch Claude instead of Amp.
run_yolo amp --help
[ -f "$TEST_ROOT/amp.args" ] || fail "yolo did not launch Amp when selected"
[ "$(<"$TEST_ROOT/amp.args")" = "--help" ] || fail "yolo changed Amp arguments"
[ ! -e "$TEST_ROOT/claude.args" ] || fail "yolo also launched Claude"

# Removing Claude's existing defaults would weaken the legacy yolo behavior.
run_yolo claude --help
cat >"$TEST_ROOT/expected-claude.args" <<'EOF'
--dangerously-skip-permissions
--teammate-mode
in-process
--help
EOF
cmp -s "$TEST_ROOT/expected-claude.args" "$TEST_ROOT/claude.args" ||
	fail "yolo did not preserve Claude defaults"

# Ignoring an explicit teammate mode would inject a conflicting default.
run_yolo claude --teammate-mode full --help
cat >"$TEST_ROOT/expected-override.args" <<'EOF'
--dangerously-skip-permissions
--teammate-mode
full
--help
EOF
cmp -s "$TEST_ROOT/expected-override.args" "$TEST_ROOT/claude.args" ||
	fail "yolo did not preserve the Claude teammate-mode override"

# Failing to persist the interactive choice would make installer reruns ineffective.
cat >"$TEST_ROOT/home/.termenv.conf" <<'EOF'
TERMENV_VIM_GO=1
TERMENV_AGENT=claude
EOF
printf '2\n' | HOME="$TEST_ROOT/home" PATH="$TEST_ROOT/bin:/usr/bin:/bin" \
	"$ROOT/agent/setup.sh"
grep -qx 'TERMENV_AGENT=amp' "$TEST_ROOT/home/.termenv.conf" ||
	fail "Amp selection was not persisted"
grep -qx 'TERMENV_VIM_GO=1' "$TEST_ROOT/home/.termenv.conf" ||
	fail "persisting the agent removed unrelated configuration"
[ "$(<"$TEST_ROOT/skills-install.args")" = "--skills-only" ] ||
	fail "Amp setup did not install portable personal skills"

# Reinstalling should update one setting rather than grow the config file.
HOME="$TEST_ROOT/home" PATH="$TEST_ROOT/bin:/usr/bin:/bin" \
	"$ROOT/agent/setup.sh" amp
[ "$(grep -c '^# Agent used by the yolo command$' "$TEST_ROOT/home/.termenv.conf")" -eq 1 ] ||
	fail "rerunning setup duplicated the agent configuration"

# Switching to Amp should remove Claude-only integrations left by an earlier install.
SWITCH_HOME="$TEST_ROOT/switch-home"
mkdir -p "$SWITCH_HOME/.vim/termenv/modules" "$SWITCH_HOME/.tmux/termenv/modules" \
	"$SWITCH_HOME/.tmux/termenv/scripts"
cat >"$SWITCH_HOME/.termenv.conf" <<'EOF'
TERMENV_AGENT=amp
EOF
ln -s "$ROOT/vim/modules/agent.vim" "$SWITCH_HOME/.vim/termenv/modules/agent.vim"
ln -s "$ROOT/tmux/modules/agent.conf" "$SWITCH_HOME/.tmux/termenv/modules/agent.conf"
ln -s "$ROOT/tmux/scripts/claude-cycle.sh" "$SWITCH_HOME/.tmux/termenv/scripts/claude-cycle.sh"
HOME="$SWITCH_HOME" TERMENV_CI=1 "$ROOT/install.sh" >/dev/null
[ ! -L "$SWITCH_HOME/.vim/termenv/modules/agent.vim" ] || fail "Amp install left Claude vim integration linked"
[ ! -L "$SWITCH_HOME/.tmux/termenv/modules/agent.conf" ] || fail "Amp install left Claude tmux integration linked"
[ ! -L "$SWITCH_HOME/.tmux/termenv/scripts/claude-cycle.sh" ] || fail "Amp install left Claude cycle script linked"

# Existing configs without an agent setting should retain legacy Claude behavior.
LEGACY_HOME="$TEST_ROOT/legacy-home"
mkdir -p "$LEGACY_HOME"
cat >"$LEGACY_HOME/.termenv.conf" <<'EOF'
TERMENV_VIM_GO=0
EOF
HOME="$LEGACY_HOME" TERMENV_CI=1 "$ROOT/install.sh" >/dev/null
[ -L "$LEGACY_HOME/.vim/termenv/modules/agent.vim" ] || fail "legacy config did not default to Claude vim integration"
[ -L "$LEGACY_HOME/.tmux/termenv/modules/agent.conf" ] || fail "legacy config did not default to Claude tmux integration"
[ -L "$LEGACY_HOME/.tmux/termenv/scripts/claude-cycle.sh" ] || fail "legacy config did not default to Claude cycle script"

# Declining agent setup should not enable Claude-specific integrations.
cat >"$TEST_ROOT/bin/brew" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat >"$TEST_ROOT/bin/vim" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat >"$TEST_ROOT/bin/just" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$TEST_ROOT/bin/brew" "$TEST_ROOT/bin/vim" "$TEST_ROOT/bin/just"
SKIP_HOME="$TEST_ROOT/skip-home"
mkdir -p "$SKIP_HOME/.vim/autoload" "$SKIP_HOME/.tmux/plugins/tpm"
touch "$SKIP_HOME/.vim/autoload/plug.vim"
cat >"$SKIP_HOME/.termenv.conf" <<'EOF'
TERMENV_AGENT=claude
EOF
printf 'n\n' | HOME="$SKIP_HOME" PATH="$TEST_ROOT/bin:/usr/bin:/bin" "$ROOT/install.sh" >/dev/null
[ ! -L "$SKIP_HOME/.vim/termenv/modules/agent.vim" ] || fail "skipping agent setup linked Claude vim integration"
[ ! -L "$SKIP_HOME/.tmux/termenv/modules/agent.conf" ] || fail "skipping agent setup linked Claude tmux integration"
[ ! -L "$SKIP_HOME/.tmux/termenv/scripts/claude-cycle.sh" ] || fail "skipping agent setup linked Claude cycle script"

# Using the old formula invocation would fail on current Homebrew installs.
cat >"$TEST_ROOT/bin/brew" <<EOF
#!/usr/bin/env bash
printf '%s\\n' "\$@" >"$TEST_ROOT/brew.args"
EOF
cat >"$TEST_ROOT/bin/curl" <<'EOF'
#!/usr/bin/env bash
while [ "$#" -gt 0 ]; do
	if [ "$1" = "-o" ]; then
		printf '#!/usr/bin/env bash\n' >"$2"
		exit 0
	fi
	shift
done
exit 1
EOF
cat >"$TEST_ROOT/bin/git" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
chmod +x "$TEST_ROOT/bin/brew" "$TEST_ROOT/bin/curl" "$TEST_ROOT/bin/git"
rm "$TEST_ROOT/bin/claude"
HOME="$TEST_ROOT/claude-home" PATH="$TEST_ROOT/bin:/usr/bin:/bin" \
	"$ROOT/agent/setup.sh" claude
cat >"$TEST_ROOT/expected-brew.args" <<'EOF'
install
--cask
claude-code
EOF
cmp -s "$TEST_ROOT/expected-brew.args" "$TEST_ROOT/brew.args" ||
	fail "Claude setup did not use the supported Homebrew cask"

echo "Agent selection tests passed."
