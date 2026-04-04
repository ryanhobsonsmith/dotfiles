#!/bin/bash
# Ensure directories managed by .chezmoiexternal git-repos are valid clones.
# Backs up existing files for safety, then fixes in place so chezmoi can
# update regardless of its internal state.

check_repo() {
  local dir="$1"
  local expected_repo="$2"  # e.g. "ryanhobsonsmith/nvim-config"
  local fallback_url="https://github.com/$expected_repo.git"

  [ -d "$dir" ] || return 0

  # No .git at all — back up then init in place
  if [ ! -d "$dir/.git" ]; then
    local backup="$dir-bak.$(date +%Y%m%d%H%M%S)"
    echo "WARNING: $dir exists but is not a git repo."
    echo "  Backing up to $backup, then initializing as clone of $fallback_url"
    cp -a "$dir" "$backup"
    git -C "$dir" init -q
    git -C "$dir" remote add origin "$fallback_url"
    git -C "$dir" fetch -q origin
    local default_branch
    default_branch=$(git -C "$dir" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
    default_branch="${default_branch:-main}"
    git -C "$dir" reset --hard "origin/$default_branch" >/dev/null 2>&1
    git -C "$dir" clean -fd >/dev/null 2>&1
    return 0
  fi

  # .git exists but remote points to a different repo — back up then fix
  local actual_url
  actual_url=$(git -C "$dir" remote get-url origin 2>/dev/null)
  if ! echo "$actual_url" | grep -q "$expected_repo"; then
    local backup="$dir-bak.$(date +%Y%m%d%H%M%S)"
    echo "WARNING: $dir has unexpected remote ($actual_url)."
    echo "  Expected repo: $expected_repo"
    echo "  Backing up to $backup, then updating remote to $fallback_url"
    cp -a "$dir" "$backup"
    git -C "$dir" remote set-url origin "$fallback_url"
    git -C "$dir" fetch -q origin
    local default_branch
    default_branch=$(git -C "$dir" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
    default_branch="${default_branch:-main}"
    git -C "$dir" reset --hard "origin/$default_branch" >/dev/null 2>&1
    git -C "$dir" clean -fd >/dev/null 2>&1
    return 0
  fi
}

check_repo "$HOME/.config/nvim" "ryanhobsonsmith/nvim-config"
check_repo "$HOME/.tmux/plugins/tpm" "tmux-plugins/tpm"
