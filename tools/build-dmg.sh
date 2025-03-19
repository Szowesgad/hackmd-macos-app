#!/bin/bash

# Script to build HackMD macOS app and package it in a DMG
# Requires Xcode, create-dmg

set -e  # Exit on any error

# Configuration
APP_NAME="HackMD"
XCODE_PROJECT="${APP_NAME}.xcodeproj"
SCHEME="${APP_NAME}"
CONFIGURATION="Release"
BUILD_DIR="build"
ARTIFACTS_DIR="artifacts"
DMG_NAME="${APP_NAME}.dmg"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Building ${APP_NAME} for macOS ===${NC}"

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}Error: Xcode command line tools not found${NC}"
    echo "Please install Xcode from the App Store or run 'xcode-select --install'"
    exit 1
fi

# Check if create-dmg is installed
if ! command -v create-dmg &> /dev/null; then
    echo -e "${YELLOW}Warning: create-dmg not found, installing via Homebrew${NC}"
    brew install create-dmg || {
        echo -e "${RED}Error: Failed to install create-dmg${NC}"
        echo "Please install create-dmg manually: brew install create-dmg"
        exit 1
    }
fi

# Create build directory
mkdir -p "${BUILD_DIR}"
mkdir -p "${ARTIFACTS_DIR}"

# Clean previous build
echo -e "${GREEN}Cleaning previous build...${NC}"
xcodebuild clean -project "${XCODE_PROJECT}" -scheme "${SCHEME}" -configuration "${CONFIGURATION}"

# Build the app
echo -e "${GREEN}Building ${APP_NAME}...${NC}"
xcodebuild build \
    -project "${XCODE_PROJECT}" \
    -scheme "${SCHEME}" \
    -configuration "${CONFIGURATION}" \
    -derivedDataPath "${BUILD_DIR}" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    MACOSX_DEPLOYMENT_TARGET=13.0

# Find the built app
APP_PATH=$(find "${BUILD_DIR}" -name "*.app" -type d)
if [ -z "${APP_PATH}" ]; then
    echo -e "${RED}Error: App not found after build${NC}"
    echo "Check build logs for errors"
    exit 1
fi

echo -e "${GREEN}App built successfully at: ${APP_PATH}${NC}"

# Get version from Info.plist
VERSION=$(defaults read "${APP_PATH}/Contents/Info" CFBundleShortVersionString)
BUILD=$(defaults read "${APP_PATH}/Contents/Info" CFBundleVersion)

echo -e "${GREEN}App version: ${VERSION} (${BUILD})${NC}"

# Create a folder with content for DMG
DMG_BUILD_DIR="${BUILD_DIR}/dmg_build"
mkdir -p "${DMG_BUILD_DIR}"
cp -r "${APP_PATH}" "${DMG_BUILD_DIR}/"

# Create background folder
mkdir -p "${DMG_BUILD_DIR}/.background"

# Copy license
cp LICENSE "${DMG_BUILD_DIR}/LICENSE.txt" 2>/dev/null || echo "No LICENSE file to include"

# Create README
cat > "${DMG_BUILD_DIR}/README.txt" << EOL
HackMD for macOS
Version ${VERSION} (${BUILD})

Thank you for downloading HackMD for macOS.
To install, drag the HackMD app to your Applications folder.

For help and documentation, visit:
https://github.com/Szowesgad/hackmd-macos-app
EOL

# Create DMG
echo -e "${GREEN}Creating DMG package...${NC}"
DMG_FILE="${ARTIFACTS_DIR}/${APP_NAME}-${VERSION}.dmg"

# Options for a more professional DMG
create-dmg \
    --volname "${APP_NAME} ${VERSION}" \
    --window-size 600 450 \
    --window-pos 200 120 \
    --icon-size 100 \
    --icon "${APP_NAME}.app" 150 180 \
    --hide-extension "${APP_NAME}.app" \
    --app-drop-link 450 180 \
    --add-file "README.txt" 150 300 \
    --add-file "LICENSE.txt" 450 300 \
    --no-internet-enable \
    "${DMG_FILE}" \
    "${DMG_BUILD_DIR}/" || {
        echo -e "${RED}Error: Failed to create DMG${NC}"
        exit 1
    }

# Create a standard zip as alternative
echo -e "${GREEN}Creating ZIP backup...${NC}"
ZIP_FILE="${ARTIFACTS_DIR}/${APP_NAME}-${VERSION}.zip"
ditto -c -k --keepParent "${APP_PATH}" "${ZIP_FILE}"

# Also keep a copy with constant filename for auto-update
cp "${DMG_FILE}" "${ARTIFACTS_DIR}/${DMG_NAME}"
cp "${ZIP_FILE}" "${ARTIFACTS_DIR}/${APP_NAME}.zip"

# Generate a basic appcast.xml for Sparkle
if [ ! -z "${VERSION}" ]; then
    echo -e "${GREEN}Creating basic appcast.xml for Sparkle...${NC}"
    APPCAST="${ARTIFACTS_DIR}/appcast.xml"
    
    # Check if we're running in GitHub Actions
    if [ "${GITHUB_ACTIONS}" = "true" ]; then
        DOWNLOAD_BASE_URL="https://github.com/${GITHUB_REPOSITORY}/releases/download/${VERSION}"
    else
        DOWNLOAD_BASE_URL="https://github.com/Szowesgad/hackmd-macos-app/releases/download/${VERSION}"
    fi
    
    # Get file sizes
    DMG_SIZE=$(stat -f%z "${DMG_FILE}")
    ZIP_SIZE=$(stat -f%z "${ZIP_FILE}")
    
    # Generate current date in RFC 2822 format
    PUB_DATE=$(date -R)
    
    cat > "${APPCAST}" << EOL
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
    <channel>
        <title>HackMD for macOS Updates</title>
        <link>https://github.com/Szowesgad/hackmd-macos-app</link>
        <description>Most recent changes with links to updates.</description>
        <language>en</language>
        <item>
            <title>Version ${VERSION}</title>
            <description>
                <![CDATA[
                    <h2>HackMD for macOS ${VERSION}</h2>
                    <p>What's new:</p>
                    <ul>
                        <li>Export to PDF and Markdown</li>
                        <li>Improved notification system</li>
                        <li>macOS widgets</li>
                        <li>Tab management</li>
                        <li>Various UI improvements</li>
                    </ul>
                ]]>
            </description>
            <pubDate>${PUB_DATE}</pubDate>
            <enclosure 
                url="${DOWNLOAD_BASE_URL}/${APP_NAME}.zip" 
                sparkle:version="${BUILD}" 
                sparkle:shortVersionString="${VERSION}" 
                length="${ZIP_SIZE}" 
                type="application/octet-stream" 
            />
        </item>
    </channel>
</rss>
EOL
    
    echo -e "${GREEN}Created appcast.xml at: ${APPCAST}${NC}"
fi

echo -e "${GREEN}=== Build Complete ===${NC}"
echo -e "DMG created at: ${DMG_FILE}"
echo -e "ZIP created at: ${ZIP_FILE}"
echo -e "Artifacts stored in: ${ARTIFACTS_DIR}"
echo -e ""
echo -e "${YELLOW}To install, open the DMG and drag the app to your Applications folder.${NC}"