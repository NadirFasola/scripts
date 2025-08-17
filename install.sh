#!/usr/bin/env sh
# Installs/uninstalls a script as a soft link to ~/.local/share/scripts,
# and manages PATH accordingly.

set -euo pipefail

# Determine target directory
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
TARGET_DIR="$XDG_DATA_HOME/scripts"

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

update_path() {
    # Ensure TARGET_DIR is in PATH, add to ~/.profile if needed
    if ! echo "$PATH" | grep -q "$TARGET_DIR"; then
        echo "Adding $TARGET_DIR to PATH in ~/.profile"
        echo "" >> ~/.profile
        echo "# Added by install.sh" >> ~/.profile
        echo "export PATH=\"$TARGET_DIR:\$PATH\"" >> ~/.profile
    fi
}

remove_from_path() {
    # Remove TARGET_DIR from ~/.profile
    if grep -q "$TARGET_DIR" ~/.profile; then
        echo "Removing $TARGET_DIR from PATH in ~/.profile"
        sed -i.bak "\|$TARGET_DIR|d" ~/.profile
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

# Get absolute path of the script
SCRIPT_PATH="$(realpath "$SCRIPT")"
LINK_PATH="$TARGET_DIR/$(basename "$SCRIPT")"

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
    echo "Creating link: $LINK_PATH -> $SCRIPT_PATH"
    ln -s "$SCRIPT_PATH" "$LINK_PATH"
    update_path
fi
