#!/bin/bash

# Get the absolute path of the script
SCRIPT_PATH=$(readlink -f "$0")
SCRIPT_NAME=$(basename "$SCRIPT_PATH")

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Help function
help() {
    clear
    echo -e "${BOLD}${BLUE}=========================================${NC}"
    echo -e "${BOLD}${BLUE}       ConvFT: File-Text Conversion     ${NC}"
    echo -e "${BOLD}${BLUE}=========================================${NC}"
    echo
    echo -e "${CYAN}A powerful CLI tool for converting between file structures${NC}"
    echo -e "${CYAN}and single text file representations. Ideal for backup,${NC}"
    echo -e "${CYAN}sharing, and reconstructing complex directory hierarchies.${NC}"
    echo
    echo -e "${MAGENTA}Repository:${NC} ${BOLD}https://github.com/Mik-TF/convft${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC} ${BOLD}convft [OPTION]${NC}"
    echo
    echo -e "${GREEN}Options:${NC}"
    echo -e "  ${BOLD}ft${NC}         Convert files to text"
    echo -e "  ${BOLD}tf${NC}         Convert text to files"
    echo -e "  ${BOLD}install${NC}    Install ConvFT (requires sudo)"
    echo -e "  ${BOLD}uninstall${NC}  Uninstall ConvFT (requires sudo)"
    echo -e "  ${BOLD}help${NC}       Display this help message"
    echo
    echo -e "${YELLOW}Examples:${NC}"
    echo -e "  ${BOLD}convft ft${NC}              # Convert current directory to 'all_files_text.txt'"
    echo -e "  ${BOLD}convft tf${NC}              # Reconstruct files from 'all_files_text.txt'"
    echo -e "  ${BOLD}sudo bash convft.sh install${NC}    # Install ConvFT system-wide"
    echo -e "  ${BOLD}sudo convft uninstall${NC}  # Remove ConvFT from the system"
    echo
    echo -e "${BLUE}=========================================${NC}"
}

# Function to convert files to text
file_to_text() {
    output_file="all_files_text.txt"
    
    echo -e "${YELLOW}Starting conversion of files to text...${NC}"
    
    # Clear the output file if it exists
    > "$output_file"
    
    # Recursively find all files and process them
    find . -type f | while read -r file; do
        # Get absolute path of the current file
        abs_file=$(readlink -f "$file")
        
        # Skip the output file itself and the script file
        if [[ "$abs_file" != "$SCRIPT_PATH" && "$(basename "$file")" != "$output_file" && "$(basename "$file")" != "$SCRIPT_NAME" ]]; then
            echo -e "${CYAN}Processing:${NC} $file"
            echo "Filename: $file" >> "$output_file"
            echo "Content:" >> "$output_file"
            cat "$file" >> "$output_file"
            echo -e "\n" >> "$output_file"
        fi
    done
    
    echo -e "${GREEN}Conversion completed. Output saved to ${BOLD}$output_file${NC}"
}

# Function to convert text back to files
text_to_file() {
    input_file="all_files_text.txt"
    
    if [[ ! -f "$input_file" ]]; then
        echo -e "${RED}Error: $input_file not found${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Starting conversion of text to files...${NC}"
    
    # Create a temporary directory for processing
    temp_dir=$(mktemp -d)
    
    # Process the input file
    current_file=""
    while IFS= read -r line; do
        if [[ "$line" == "Filename:"* ]]; then
            current_file="${line#Filename: }"
            echo -e "${CYAN}Creating:${NC} $current_file"
            mkdir -p "$(dirname "$temp_dir/$current_file")"
            > "$temp_dir/$current_file"
        elif [[ "$line" != "Content:" ]]; then
            echo "$line" >> "$temp_dir/$current_file"
        fi
    done < "$input_file"
    
    # Move files from temp directory to current directory
    mv "$temp_dir"/* .
    rm -rf "$temp_dir"
    
    echo -e "${GREEN}Conversion completed. Files have been recreated.${NC}"
}

# Function to install the script
install() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Please run the install function with sudo.${NC}"
        exit 1
    fi
    
    cp "$SCRIPT_PATH" /usr/local/bin/convft
    chmod +x /usr/local/bin/convft
    
    echo -e "${GREEN}Installation successful. You can now use 'convft' from any directory.${NC}"
}

# Function to uninstall the script
uninstall() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Please run the uninstall function with sudo.${NC}"
        exit 1
    fi
    
    if [ -f /usr/local/bin/convft ]; then
        rm /usr/local/bin/convft
        echo -e "${GREEN}ConvFT has been uninstalled successfully.${NC}"
    else
        echo -e "${YELLOW}ConvFT is not installed in /usr/local/bin.${NC}"
    fi
}

# Main script logic
if [[ $# -eq 0 ]]; then
    help
    exit 0
fi

case "$1" in
    "ft")
        file_to_text
        ;;
    "tf")
        text_to_file
        ;;
    "install")
        install
        ;;
    "uninstall")
        uninstall
        ;;
    "help")
        help
        ;;
    *)
        echo -e "${RED}Invalid option. Use 'convft help' for usage information.${NC}"
        exit 1
        ;;
esac