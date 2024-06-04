#!/usr/bin/env zsh

# ANSI color codes
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# This gets the location that the script is being run from and moves there.
SCRIPT_DIR=${0:a:h}
cd "$SCRIPT_DIR"

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
	echo -e "${PURPLE}Homebrew not found. Installing Homebrew...${NC}"
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
	echo -e "${PURPLE}Homebrew found. Updating Homebrew...${NC}"
	brew update
fi

## Homebrew dependencies
# Install required dependencies
echo -e "${PURPLE}Checking for rom-tools installation...${NC}"

if [ -d "$(brew --prefix)/opt/rom-tools" ]; then
	echo -e "${GREEN}Found chdman. Checking for updates...${NC}"
	brew upgrade rom-tools
else
	echo -e "${PURPLE}Did not find chdman. Installing rom-tools...${NC}"
	brew install rom-tools
fi

# Conversion
echo -e "${PURPLE}Starting conversion...${NC}"
for file in ${PWD}/*.(iso|ISO); 
	do chdman createdvd --hunksize 2048 -i "${file%.*}.iso" -o "${file%.*}.chd" -c zstd; 
done

if [ $? -eq 0 ]; then
	echo -e "${GREEN}Conversion completed${NC}"
else
	echo -e "${RED}Error encountered...${NC}"
fi