#!/usr/bin/env zsh

# ANSI color codes
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# This gets the location that the script is being run from and moves there.
SCRIPT_DIR=${0:a:h}
cd "$SCRIPT_DIR"

# Introduction
echo "${PURPLE}\nThis script will search the current folder and convert all ISOs it finds to either ${GREEN}CSO${PURPLE} or ${GREEN}CHD${PURPLE} format\n${NC}"

echo "${PURPLE}It uses ${GREEN}chdman${PURPLE} and ${GREEN}maxcso${PURPLE} to handle the conversions\n${NC}"

echo "${GREEN}Homebrew${PURPLE} and the ${GREEN}Xcode command-line tools${PURPLE} are required${NC}"
echo "${PURPLE}If they are not present you will be prompted to install them${NC}\n"

echo "${PURPLE}The CHD conversion tool will use a hunk size of 2048 so it will be compatible with PPSSPP\n${NC}"

echo "${PURPLE}If you are converting to CSO files the ${GREEN}maxcso${PURPLE} utility will need to be compiled${NC}\n"


# Functions for checking for Homebrew installation
homebrew_check() {
	echo "${PURPLE}Checking for Homebrew...${NC}"
	if ! command -v brew &> /dev/null; then
		echo -e "${PURPLE}Homebrew not found. Installing Homebrew...${NC}"
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		if [[ "${ARCH_NAME}" == "arm64" ]]; then 
			(echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> $HOME/.zprofile
			eval "$(/opt/homebrew/bin/brew shellenv)"
			else 
			(echo; echo 'eval "$(/usr/local/bin/brew shellenv)"') >> $HOME/.zprofile
			eval "$(/usr/local/bin/brew shellenv)"
		fi
		
		# Check for errors
		if [ $? -ne 0 ]; then
			echo "${RED}There was an issue installing Homebrew${NC}"
			echo "${PURPLE}Quitting script...${NC}"	
			exit 1
		fi
	else
		echo -e "${PURPLE}Homebrew found. Updating Homebrew...${NC}"
		brew update
	fi
}

# Function for checking for an individual dependency
single_dependency_check() {
	if [ -d "$(brew --prefix)/opt/$1" ]; then
		echo -e "${GREEN}Found $1. Checking for updates...${NC}"
			brew upgrade $1
	else
		 echo -e "${PURPLE}Did not find $1. Installing...${NC}"
		brew install $1
	fi
}

build_maxcso() {
	homebrew_check
	single_dependency_check lz4
	single_dependency_check libuv
	single_dependency_check libdeflate
	
	git clone --recursive https://github.com/unknownbrackets/maxcso
	mv maxcso maxcso-source 
	cd maxcso-source
	make 
	cp maxcso ..
	cd ..
	rm -rf maxcso-source
}

cso_conversion() {
	for file in ${PWD}/*.(iso|ISO); 
		do 
			echo "\n${PURPLE}Converting ${GREEN}$(basename "${file%.*}")${NC}";
			./maxcso "${file%.*}.iso"; 
	done
}

chd_conversion() {
	for file in ${PWD}/*.(iso|ISO); 
		do
			echo "\n${PURPLE}Converting ${GREEN}$(basename "${file%.*}")${NC}";
			chdman createdvd --hunksize 2048 -i "${file%.*}.iso" -o "${file%.*}.chd" -c zstd; 
	done
	
	if [ $? -eq 0 ]; then
		echo "${GREEN}Conversion completed${NC}"
	else
		echo "${RED}Error encountered...${NC}"
	fi
}

main_menu() {
	# Ask the user to select which game to build
	PS3='Select which format to convert your ISOs to: '
	OPTIONS=(
		"CSO"
		"CHD")
	select opt in $OPTIONS[@]
	do
		case $opt in
			"CSO")
				if [ ! -f maxcso ]; then
					echo "${PURPLE}maxcso tool not found. Building from source...${NC}"
					build_maxcso
				fi
				cso_conversion
				break
				;;
			"CHD")
				homebrew_check
				single_dependency_check rom-tools
				chd_conversion
				break
				;;
			*) 
				echo "\"$REPLY\" is not one of the options..."
				echo "Enter the number of the option and press enter to select"
				;;
		esac
	done
}

# main
main_menu