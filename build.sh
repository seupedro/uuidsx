#!/bin/bash

# Set error handling
set -e

# Configuration
SWIFT_FILE="main.swift"
METAL_FILE="shader.metal"
OUTPUT_NAME="uuidx"
METALLIB_NAME="default.metallib"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check for Xcode Command Line Tools
if ! command -v xcrun &> /dev/null; then
    echo -e "${RED}Error: xcrun not found${NC}"
    echo "Please install Xcode Command Line Tools by running:"
    echo -e "${YELLOW}xcode-select --install${NC}"
    exit 1
fi

# Check for Xcode installation
if [ ! -d "/Applications/Xcode.app" ]; then
    echo -e "${RED}Error: Xcode.app not found${NC}"
    echo "Please install Xcode from the App Store"
    exit 1
fi

# Try to set Xcode path if metal compiler isn't found
if ! xcrun -f metal &> /dev/null; then
    echo -e "${YELLOW}Attempting to set Xcode path...${NC}"
    sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
    
    # Check again
    if ! xcrun -f metal &> /dev/null; then
        echo -e "${RED}Error: Unable to locate Metal compiler${NC}"
        echo "Please ensure Xcode is properly installed and try running:"
        echo -e "${YELLOW}sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}Starting build process...${NC}"

# Compile Metal shader
echo "Compiling Metal shader..."
xcrun -sdk macosx metal -c "$METAL_FILE" -o "${METAL_FILE}.air"
xcrun -sdk macosx metallib "${METAL_FILE}.air" -o "$METALLIB_NAME"

# Compile Swift code
echo "Compiling Swift code..."
swiftc "$SWIFT_FILE" \
    -sdk $(xcrun --show-sdk-path) \
    -framework Metal \
    -framework Foundation \
    -o "$OUTPUT_NAME"

# Check if compilation was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Build completed successfully!${NC}"
    echo "Executable: ./$OUTPUT_NAME"
else
    echo -e "${RED}Build failed!${NC}"
    exit 1
fi

# Make the output file executable
chmod +x "$OUTPUT_NAME"
