#!/usr/bin/env bash
# shellcheck disable=SC2034  # exports consumed by other scripts
# OS and platform detection for termenv
# Sourced by install.sh and can be sourced in shell profiles

case "$(uname -s)" in
Darwin)
	export TERMENV_OS=mac
	export TERMENV_CLIP_COPY="pbcopy"
	export TERMENV_CLIP_PASTE="pbpaste"
	export TERMENV_OPEN="open"
	;;
Linux)
	export TERMENV_OS=linux
	if [ -n "$WAYLAND_DISPLAY" ]; then
		export TERMENV_CLIP_COPY="wl-copy"
		export TERMENV_CLIP_PASTE="wl-paste"
	else
		export TERMENV_CLIP_COPY="xclip -selection clipboard"
		export TERMENV_CLIP_PASTE="xclip -selection clipboard -o"
	fi
	export TERMENV_OPEN="xdg-open"
	;;
*)
	export TERMENV_OS=unknown
	export TERMENV_CLIP_COPY="cat"
	export TERMENV_CLIP_PASTE="cat"
	export TERMENV_OPEN="echo"
	;;
esac

# Load user module preferences
if [ -f "$HOME/.termenv.conf" ]; then
	source "$HOME/.termenv.conf"
fi
