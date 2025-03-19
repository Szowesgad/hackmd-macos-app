#!/bin/bash

# Debug tools for HackMD macOS app
# This script provides various debugging utilities

set -e  # Exit on any error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

APP_NAME="HackMD"
BUNDLE_ID="com.szowesgad.hackmd"
APP_PATH="/Applications/${APP_NAME}.app"

echo -e "${BLUE}=== HackMD macOS App Debugging Tools ===${NC}"
echo -e "This script provides tools for debugging the HackMD macOS app."

function show_help {
    echo -e "\nUsage: $0 [command]"
    echo -e "\nCommands:"
    echo -e "  clean-prefs         Clear application preferences"
    echo -e "  clean-cache         Clear application caches"
    echo -e "  check-logs          Show relevant logs from Console"
    echo -e "  widget-data         Generate test data for widgets"
    echo -e "  inspect-app         Show app bundle information"
    echo -e "  full-reset          Reset app to factory state (preferences, cache, etc.)"
    echo -e "  help                Show this help message"
    echo -e "\nExamples:"
    echo -e "  $0 clean-prefs      # Clears all preferences for the app"
    echo -e "  $0 check-logs       # Shows recent logs from Console"
}

function clean_preferences {
    echo -e "${YELLOW}Clearing app preferences...${NC}"
    defaults delete "${BUNDLE_ID}" 2>/dev/null || echo "No preferences found to delete"
    echo -e "${GREEN}Preferences cleared.${NC}"
}

function clean_caches {
    echo -e "${YELLOW}Clearing app caches...${NC}"
    
    # Clear WebKit caches
    CACHE_DIR=~/Library/Caches/${BUNDLE_ID}
    if [ -d "$CACHE_DIR" ]; then
        rm -rf "$CACHE_DIR"
        echo "Removed $CACHE_DIR"
    else
        echo "No cache directory found at $CACHE_DIR"
    fi
    
    # Clear WebKit data
    WEBKIT_DIR=~/Library/WebKit/com.szowesgad.hackmd
    if [ -d "$WEBKIT_DIR" ]; then
        rm -rf "$WEBKIT_DIR"
        echo "Removed $WEBKIT_DIR"
    else
        echo "No WebKit directory found at $WEBKIT_DIR"
    fi
    
    echo -e "${GREEN}Caches cleared.${NC}"
}

function check_logs {
    echo -e "${YELLOW}Checking recent logs...${NC}"
    
    LOG_CMD="log show --predicate 'processImagePath contains \"${APP_NAME}\"' --info --debug --last 30m"
    echo "Running: $LOG_CMD"
    
    eval $LOG_CMD
    
    echo -e "\n${GREEN}Log check complete.${NC}"
    echo -e "To see more logs, use Console.app and filter for '${APP_NAME}'"
}

function generate_widget_data {
    echo -e "${YELLOW}Generating test data for widgets...${NC}"
    
    # Create a temporary directory
    TMP_DIR=$(mktemp -d)
    
    # Generate test data JSON
    cat > "$TMP_DIR/widget_data.json" << EOL
[
    {
        "id": "test1",
        "title": "Meeting Notes",
        "lastEdited": "$(date -v-30M -u +"%Y-%m-%dT%H:%M:%SZ")",
        "previewText": "# Important Meeting\n- Discussion points\n- Action items\n- Next steps",
        "collaborators": 3
    },
    {
        "id": "test2",
        "title": "Project Roadmap",
        "lastEdited": "$(date -v-2H -u +"%Y-%m-%dT%H:%M:%SZ")",
        "previewText": "# Q2 Roadmap\n1. Feature A\n2. Feature B\n3. Testing",
        "collaborators": 1
    },
    {
        "id": "test3",
        "title": "Personal Notes",
        "lastEdited": "$(date -v-1d -u +"%Y-%m-%dT%H:%M:%SZ")",
        "previewText": "Remember to check the latest version of the iOS app",
        "collaborators": 0
    }
]
EOL
    
    # Copy to shared container if it exists
    SHARED_CONTAINER="~/Library/Group Containers/group.com.szowesgad.hackmd"
    mkdir -p "$SHARED_CONTAINER" 2>/dev/null || echo "Could not create shared container (this is normal if not run as the correct user)"
    
    # Try to copy to various possible locations
    cp "$TMP_DIR/widget_data.json" "$SHARED_CONTAINER/widget_data.json" 2>/dev/null || echo "Could not copy to shared container"
    defaults write "group.com.szowesgad.hackmd" "recentNotes" -string "$(cat "$TMP_DIR/widget_data.json")" 2>/dev/null || echo "Could not write to shared defaults"
    
    echo -e "${GREEN}Widget test data generated.${NC}"
    echo -e "Data file saved to: ${TMP_DIR}/widget_data.json"
    echo -e "You may need to restart the app or widgets to see the changes."
}

function inspect_app {
    echo -e "${YELLOW}Inspecting app bundle...${NC}"
    
    if [ ! -d "$APP_PATH" ]; then
        echo -e "${RED}App not found at $APP_PATH${NC}"
        echo "Please install the app or provide the correct path."
        return 1
    fi
    
    echo -e "${BLUE}App bundle information:${NC}"
    echo "Path: $APP_PATH"
    
    # Extract version info
    VERSION=$(defaults read "${APP_PATH}/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo "Unknown")
    BUILD=$(defaults read "${APP_PATH}/Contents/Info" CFBundleVersion 2>/dev/null || echo "Unknown")
    BUNDLE_ID=$(defaults read "${APP_PATH}/Contents/Info" CFBundleIdentifier 2>/dev/null || echo "Unknown")
    
    echo "Version: $VERSION ($BUILD)"
    echo "Bundle ID: $BUNDLE_ID"
    
    # Check entitlements
    echo -e "\n${BLUE}Entitlements:${NC}"
    codesign -d --entitlements :- "$APP_PATH" 2>/dev/null || echo "Could not read entitlements"
    
    # Check code signing
    echo -e "\n${BLUE}Code signing information:${NC}"
    codesign -vv -d "$APP_PATH" 2>&1 || echo "App is not code signed"
    
    echo -e "\n${GREEN}Inspection complete.${NC}"
}

function full_reset {
    echo -e "${RED}WARNING: This will completely reset the app to factory state.${NC}"
    echo -e "All preferences, caches, and data will be deleted."
    read -p "Are you sure you want to continue? (y/n) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Kill the app if it's running
        pkill -x "HackMD" 2>/dev/null || echo "App not running"
        
        clean_preferences
        clean_caches
        
        # Remove app support directory
        APP_SUPPORT_DIR=~/Library/Application\ Support/${BUNDLE_ID}
        if [ -d "$APP_SUPPORT_DIR" ]; then
            rm -rf "$APP_SUPPORT_DIR"
            echo "Removed Application Support directory"
        fi
        
        echo -e "${GREEN}App has been reset to factory state.${NC}"
        echo "You can now restart the app."
    else
        echo "Operation cancelled."
    fi
}

# Check for command
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

# Process command
case "$1" in
    clean-prefs)
        clean_preferences
        ;;
    clean-cache)
        clean_caches
        ;;
    check-logs)
        check_logs
        ;;
    widget-data)
        generate_widget_data
        ;;
    inspect-app)
        inspect_app
        ;;
    full-reset)
        full_reset
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac

exit 0