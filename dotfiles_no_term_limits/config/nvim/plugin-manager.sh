#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$SCRIPT_DIR/plugins.json"
PLUGIN_DIR="$SCRIPT_DIR/pack/plugins/start"

command_install() {
  echo "Installing plugins from manifest..."
  mkdir -p "$PLUGIN_DIR"

  # Get list of plugins from manifest
  local plugins=$(jq -r '.plugins | keys[]' "$MANIFEST")

  for plugin_name in $plugins; do
    local repo=$(jq -r ".plugins[\"$plugin_name\"].repo" "$MANIFEST")
    local commit=$(jq -r ".plugins[\"$plugin_name\"].commit" "$MANIFEST")

    if [ ! -d "$PLUGIN_DIR/$plugin_name" ]; then
      echo "  Cloning $plugin_name..."
      git clone --quiet "https://github.com/$repo" "$PLUGIN_DIR/$plugin_name"
    else
      echo "  $plugin_name already exists"
    fi

    cd "$PLUGIN_DIR/$plugin_name"
    if [ "$commit" = "latest" ]; then
      echo "    Using latest commit"
    else
      echo "    Checking out commit: $commit"
      git checkout --quiet "$commit"
    fi
    cd "$SCRIPT_DIR"
  done

  # Remove plugins not in manifest
  if [ -d "$PLUGIN_DIR" ]; then
    for installed_plugin in "$PLUGIN_DIR"/*; do
      if [ -d "$installed_plugin" ]; then
        plugin_name=$(basename "$installed_plugin")
        if ! echo "$plugins" | grep -q "^${plugin_name}$"; then
          echo "  Removing $plugin_name (not in manifest)"
          rm -rf "$installed_plugin"
        fi
      fi
    done
  fi

  echo ""
  echo "✓ All plugins installed!"
}

command_update() {
  local plugin_name=$1

  if [ -z "$plugin_name" ]; then
    # Update all plugins
    echo "Updating all plugins..."
    local plugins=$(jq -r '.plugins | keys[]' "$MANIFEST")
    for plugin_name in $plugins; do
      update_single_plugin "$plugin_name"
    done
  else
    # Update single plugin
    update_single_plugin "$plugin_name"
  fi

  echo ""
  echo "✓ Update complete!"
}

update_single_plugin() {
  local plugin_name=$1
  local repo=$(jq -r ".plugins[\"$plugin_name\"].repo" "$MANIFEST" 2>/dev/null)

  if [ "$repo" = "null" ] || [ -z "$repo" ]; then
    echo "  Error: Plugin '$plugin_name' not found in manifest"
    return 1
  fi

  if [ ! -d "$PLUGIN_DIR/$plugin_name" ]; then
    echo "  Error: Plugin '$plugin_name' not installed"
    return 1
  fi

  echo "  Updating $plugin_name..."
  cd "$PLUGIN_DIR/$plugin_name"
  git fetch --quiet
  local old_commit=$(git rev-parse --short HEAD)
  git pull --quiet
  local new_commit=$(git rev-parse --short HEAD)

  if [ "$old_commit" != "$new_commit" ]; then
    echo "    Updated: $old_commit → $new_commit"
  else
    echo "    Already up to date"
  fi

  cd "$SCRIPT_DIR"
}

command_pin() {
  local plugin_name=$1
  local commit=$2

  if [ -z "$plugin_name" ] || [ -z "$commit" ]; then
    echo "Usage: $0 pin <plugin-name> <commit-hash>"
    exit 1
  fi

  # Check if plugin exists in manifest
  local repo=$(jq -r ".plugins[\"$plugin_name\"].repo" "$MANIFEST" 2>/dev/null)
  if [ "$repo" = "null" ] || [ -z "$repo" ]; then
    echo "Error: Plugin '$plugin_name' not found in manifest"
    exit 1
  fi

  # Update manifest
  jq ".plugins[\"$plugin_name\"].commit = \"$commit\"" "$MANIFEST" > "$MANIFEST.tmp"
  mv "$MANIFEST.tmp" "$MANIFEST"

  # Checkout the commit
  if [ -d "$PLUGIN_DIR/$plugin_name" ]; then
    cd "$PLUGIN_DIR/$plugin_name"
    echo "Checking out $plugin_name at $commit..."
    git fetch --quiet
    git checkout --quiet "$commit"
    echo "✓ Pinned $plugin_name to $commit"
  else
    echo "✓ Updated manifest. Run 'install' to apply changes."
  fi
}

command_list() {
  echo "Installed plugins:"
  echo ""

  local plugins=$(jq -r '.plugins | keys[]' "$MANIFEST")
  for plugin_name in $plugins; do
    local repo=$(jq -r ".plugins[\"$plugin_name\"].repo" "$MANIFEST")
    local pinned=$(jq -r ".plugins[\"$plugin_name\"].commit" "$MANIFEST")

    if [ -d "$PLUGIN_DIR/$plugin_name" ]; then
      cd "$PLUGIN_DIR/$plugin_name"
      local current=$(git rev-parse --short HEAD)
      local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "detached")

      if [ "$pinned" = "latest" ]; then
        echo "  $plugin_name ($repo) - $current [$branch]"
      else
        echo "  $plugin_name ($repo) - $current [pinned: $pinned]"
      fi
    else
      echo "  $plugin_name ($repo) - NOT INSTALLED"
    fi
  done
}

# Main command dispatcher
case "${1:-install}" in
  install)
    command_install
    ;;
  update)
    command_update "$2"
    ;;
  pin)
    command_pin "$2" "$3"
    ;;
  list)
    command_list
    ;;
  *)
    echo "Usage: $0 {install|update [plugin]|pin <plugin> <commit>|list}"
    echo ""
    echo "Commands:"
    echo "  install           Install all plugins from manifest"
    echo "  update [plugin]   Update all plugins or specific plugin to latest"
    echo "  pin <name> <hash> Pin plugin to specific commit"
    echo "  list              List all plugins and their versions"
    exit 1
    ;;
esac
