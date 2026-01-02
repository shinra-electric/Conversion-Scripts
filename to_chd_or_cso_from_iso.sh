#!/usr/bin/env zsh

# ANSI color codes
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# This gets the location that the script is being run from and moves there.
SCRIPT_DIR=${0:a:h}
cd "$SCRIPT_DIR"

set_vars() {
	CORES=$(sysctl -n hw.ncpu)
	ARCH="$(uname -m)"
	DEPS=( libuv rom-tools )
}


# Introduction
introduction() {
	echo "${PURPLE}\nThis script will search the current folder and convert all ISOs it finds to either ${GREEN}CSO${PURPLE} or ${GREEN}CHD${PURPLE} format\n${NC}"
	
	echo "${PURPLE}It uses ${GREEN}chdman${PURPLE} and ${GREEN}maxcso${PURPLE} to handle the conversions\n${NC}"
	
	echo "${GREEN}Homebrew${PURPLE} and the ${GREEN}Xcode command-line tools${PURPLE} are required${NC}"
	echo "${PURPLE}If they are not present you will be prompted to install them${NC}\n"
	
	echo "${PURPLE}The CHD conversion tool will use a hunk size of 2048 so it will be compatible with PPSSPP\n${NC}"
}

# Functions for checking for Homebrew installation
homebrew_check() {
	echo "${PURPLE}Checking for Homebrew...${NC}"
	if ! command -v brew &> /dev/null; then
		echo "${RED}Homebrew has not been detected${NC}\n"
		homebrew_install_menu
	else
		echo "${GREEN}Homebrew has been detected${NC}\n"
		homebrew_update_menu
	fi
}

homebrew_install_menu() {
	echo "${GREEN}Homebrew${PURPLE} and the ${GREEN}Xcode command-line tools${PURPLE} are required${NC}\n"
	PS3='Would you like to install Homebrew? '
	OPTIONS=(
		"Install"
		"Quit")
	select opt in $OPTIONS[@]
	do
		case $opt in
			"Install")
				install_homebrew
				dependencies_check
				break
				;;
			"Quit")
				echo "${PURPLE}The script cannot run without Homebrew${NC}"
				echo "${RED}Quitting${NC}"
				exit 0
				;;
			*) 
				echo "\"$REPLY\" is not one of the options..."
				echo "Enter the number of the option and press enter to select"
				;;
		esac
	done
}

homebrew_update_menu() {
	echo "${PURPLE}You may need to install or update Homebrew packages${NC}"
	echo "${PURPLE}It is recommended to perform this check if it your first time running the script${NC}\n"
	PS3='Would you like to check dependencies? '
	OPTIONS=(
		"Continue without checking"
		"Install / Update")
	select opt in $OPTIONS[@]
	do
		case $opt in
			"Continue without checking")
				echo "\n${RED}Skipping Homebrew checks${NC}"
				echo "${PURPLE}The script will fail if any of the dependencies are missing${NC}\n"
				break
				;;
			"Install / Update")
				update_homebrew
				dependencies_check
				break
				;;
			*) 
				echo "\"$REPLY\" is not one of the options..."
				echo "Enter the number of the option and press enter to select"
				;;
		esac
	done
}

install_homebrew() {
	echo "${PURPLE}Installing Homebrew...${NC}"
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	if [[ "${ARCH}" == "arm64" ]]; then 
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
}

update_homebrew() {
	echo "${PURPLE}Updating Homebrew...${NC}"
	brew update
	
	# Check for errors
	if [ $? -ne 0 ]; then
		echo "${RED}There was an issue updating Homebrew${NC}"
		echo "${PURPLE}Quitting script...${NC}"	
		exit 1
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

dependencies_check() {
	echo "${PURPLE}Checking for Homebrew dependencies...${NC}"
	for dep in $DEPS[@]
	do 
		single_dependency_check $dep
	done
}

download_maxcso() {
	curl -OL https://github.com/shinra-electric/maxcso/releases/download/v1.13.0b/maxcso-macOS-Universal.tar
	tar -xf maxcso-macOS-Universal.tar	
	rm maxcso-macOS-Universal.tar
	
	if [[ -f maxcso ]]; then 
		echo "${PURPLE}Download of maxcso successful${NC}"
	else 
		echo "${RED}Could not download maxcso${NC}"	
	fi
}

cso_conversion() {
	for file in ${PWD}/*.(iso|ISO); 
		do 
			echo "\n${PURPLE}Converting ${GREEN}$(basename "${file%.*}")${NC}";
			./maxcso --threads=$(sysctl -n hw.ncpu) "${file%.*}.iso"; 
	done
	
	if [ $? -eq 0 ]; then
		echo "${GREEN}Conversion completed${NC}"
	else
		echo "${RED}Error encountered...${NC}"
	fi
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

cleanup() {
	if [[ -f maxcso ]]; then 
		rm -rf maxcso
	fi
	
	if [[ -f chdman ]]; then 
		rm -rf chdman
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
					echo "${PURPLE}maxcso tool not found. Downloading...${NC}"
					download_maxcso
				fi
				# single_dependency_check libuv
				cso_conversion
				cleanup
				break
				;;
			"CHD")
				# single_dependency_check rom-tools
				chd_conversion
				cleanup
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
set_vars
introduction
homebrew_check
main_menu