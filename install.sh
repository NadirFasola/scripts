#!/usr/bin/env sh
# Installs/uninstalls a script as a soft link to ~/.local/share/scripts,
# and manages PATH accordingly.

set -euo pipefail

# Determine target directory
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
TARGET_DIR="$XDG_DATA_HOME/scripts"

# Repo root (assume this script lives in the repo root)
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$REPO_ROOT/src"

# Ensure the target directory exists (for installation)
mkdir -p "$TARGET_DIR"

# Parse flags
UNINSTALL=0
UNINSTALL_ALL=0
SCRIPT=""

while [ $# -gt 0 ]; do
    case "$1" in
        -u|--uninstall)
            UNINSTALL=1
            shift
            ;;
        -U|--uninstall-all)
            UNINSTALL_ALL=1
            shift
            ;;
        *)
            if [ -z "$SCRIPT" ]; then
                SCRIPT="$1"
                shift
            else
                echo "Unexpected argument: $1"
                exit 1
            fi
            ;;
    esac
done

get_shell_rc_file() {
    case "$(basename "$SHELL")" in
        bash)
            echo "$HOME/.bashrc"
            ;;
        zsh)
            echo "$HOME/.zprofile"   # better than .zshrc for PATH setup
            ;;
        fish)
            echo "$HOME/.config/fish/config.fish"
            ;;
        *)
            echo "$HOME/.profile"    # fallback
            ;;
    esac
}

update_path() {
    RC_FILE="$(get_shell_rc_file)"
    if ! echo "$PATH" | grep -q "$TARGET_DIR"; then
        echo "Adding $TARGET_DIR to PATH in $RC_FILE"
        {
            echo ""
            echo "# Added by install.sh"
            if [ "$(basename "$SHELL")" = "fish" ]; then
                echo "set -Ux PATH $TARGET_DIR \$PATH"
            else
                echo "export PATH=\"$TARGET_DIR:\$PATH\""
            fi
        } >> "$RC_FILE"
        eval "export PATH=$TARGET_DIR:$PATH"
    fi
}

remove_from_path() {
    RC_FILE="$(get_shell_rc_file)"
    if [ -f "$RC_FILE" ] && grep -q "$TARGET_DIR" "$RC_FILE"; then
        echo "Removing $TARGET_DIR from PATH in $RC_FILE"
        sed -i.bak "\|$TARGET_DIR|d" "$RC_FILE"
    fi
}

if [ "$UNINSTALL_ALL" -eq 1 ]; then
    if [ -d "$TARGET_DIR" ]; then
        echo "Removing entire scripts directory: $TARGET_DIR"
        rm -rf "$TARGET_DIR"
        remove_from_path
    else
        echo "Scripts directory does not exist: $TARGET_DIR"
    fi
    exit 0
fi

if [ -z "$SCRIPT" ]; then
    echo "No script specified."
    exit 1
fi

# Resolve script path relative to src/ if it exists there
if [ -f "$SCRIPT" ]; then
    SCRIPT_PATH="$(realpath "$SCRIPT")"
elif [ -f "$SRC_DIR/$SCRIPT" ]; then
    SCRIPT_PATH="$(realpath "$SRC_DIR/$SCRIPT")"
else
    echo "Script not found: $SCRIPT"
    exit 1
fi

LINK_PATH="$TARGET_DIR/$(basename "$SCRIPT_PATH")"

if [ "$UNINSTALL" -eq 1 ]; then
    if [ -L "$LINK_PATH" ]; then
        echo "Removing link: $LINK_PATH"
        rm "$LINK_PATH"
    else
        echo "No link found at $LINK_PATH"
    fi

    # If scripts folder is empty, remove it and remove from PATH
    if [ -d "$TARGET_DIR" ] && [ ! "$(ls -A "$TARGET_DIR")" ]; then
        echo "Scripts folder is empty, removing $TARGET_DIR"
        rmdir "$TARGET_DIR"
        remove_from_path
    fi
else
    if [ -e "$LINK_PATH" ]; then
        echo "Link or file already exists at $LINK_PATH"
        exit 1
    fi

    # Ensure the script is executable
    if [ ! -x "$SCRIPT_PATH" ]; then
        echo "Making $SCRIPT_PATH executable"
        chmod +x "$SCRIPT_PATH"
    fi

    echo "Creating link: $LINK_PATH -> $SCRIPT_PATH"
    ln -s "$SCRIPT_PATH" "$LINK_PATH"
    update_path
fi
