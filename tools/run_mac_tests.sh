#!/bin/bash

# Run tests for HackMD macOS app
# This script runs unit tests and generates test reports

set -e  # Exit on any error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

APP_NAME="HackMD"
SCHEME="${APP_NAME}"
PROJECT="${APP_NAME}.xcodeproj"
REPORTS_DIR="test_reports"

echo -e "${BLUE}=== Running Tests for ${APP_NAME} ===${NC}"

# Create reports directory
mkdir -p "${REPORTS_DIR}"

# Check if xcpretty is installed - makes output nicer
if ! command -v xcpretty &> /dev/null; then
    echo -e "${YELLOW}xcpretty not found, installing...${NC}"
    gem install xcpretty || echo "Could not install xcpretty, will show raw output"
fi

# Run the unit tests
echo -e "${YELLOW}Running unit tests...${NC}"

XCPRETTY_CMD=""
if command -v xcpretty &> /dev/null; then
    XCPRETTY_CMD="| xcpretty -r junit -o ${REPORTS_DIR}/junit.xml"
fi

# Extract available simulators
SIMULATOR_ID=$(xcrun simctl list devices available | grep -i 'macos' | sort -r | head -n 1 | awk -F "[()]" '{print $2}')
if [ -z "$SIMULATOR_ID" ]; then
    echo -e "${YELLOW}No macOS simulator found, using generic destination${NC}"
    DESTINATION="platform=macOS"
else
    DESTINATION="platform=macOS,id=${SIMULATOR_ID}"
fi

# Run tests with or without xcpretty
TEST_CMD="xcodebuild test -project \"${PROJECT}\" -scheme \"${SCHEME}\" -destination \"${DESTINATION}\" -resultBundlePath \"${REPORTS_DIR}/TestResults.xcresult\""

if [ -n "$XCPRETTY_CMD" ]; then
    eval "${TEST_CMD} ${XCPRETTY_CMD}"
else
    eval "${TEST_CMD}"
fi

if [ $? -ne 0 ]; then
    echo -e "${RED}Tests failed!${NC}"
    exit 1
fi

echo -e "${GREEN}Unit tests completed successfully!${NC}"

# Generate HTML report from xcresult bundle
echo -e "${YELLOW}Generating HTML test report...${NC}"
mkdir -p "${REPORTS_DIR}/html"

if command -v xcresultparser &> /dev/null; then
    xcresultparser "${REPORTS_DIR}/TestResults.xcresult" "${REPORTS_DIR}/html"
    echo -e "${GREEN}HTML report generated at ${REPORTS_DIR}/html/index.html${NC}"
else
    echo -e "${YELLOW}xcresultparser not found, skipping HTML report generation${NC}"
    echo -e "To install: brew install michaeleisel/zld/xcresultparser"
fi

# Run code coverage
echo -e "${YELLOW}Generating code coverage report...${NC}"
if xcrun xccov view --report --json "${REPORTS_DIR}/TestResults.xcresult" > "${REPORTS_DIR}/coverage.json"; then
    echo -e "${GREEN}Code coverage report generated at ${REPORTS_DIR}/coverage.json${NC}"
    
    # Extract overall coverage
    COVERAGE=$(cat "${REPORTS_DIR}/coverage.json" | grep -o '"lineCoverage":[0-9.]*' | head -n 1 | cut -d ':' -f 2)
    if [ -n "$COVERAGE" ]; then
        COVERAGE_PCT=$(echo "$COVERAGE * 100" | bc -l | xargs printf "%.2f")
        echo -e "${BLUE}Overall code coverage: ${COVERAGE_PCT}%${NC}"
    fi
else
    echo -e "${YELLOW}Failed to generate code coverage report.${NC}"
fi

echo -e "\n${GREEN}=== All tests completed successfully ===${NC}"
echo -e "Test reports saved to: ${REPORTS_DIR}"