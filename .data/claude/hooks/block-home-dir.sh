#!/usr/bin/env bash
if [ "$PWD" = "$HOME" ]; then
  echo '{"error": "Claude Code should not be run from your home directory. Please cd into a project directory first."}' >&2
  exit 2
fi
