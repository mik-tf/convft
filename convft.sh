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
    echo -e "${CYAN}A simple CLI tool for converting between file structures${NC}"
    echo -e "${CYAN}and single text file representations. Ideal for AI work, backup,${NC}"
    echo -e "${CYAN}sharing, and reconstructing complex directory hierarchies.${NC}"
    echo
    echo -e "${MAGENTA}Repository:${NC} ${BOLD}https://github.com/mik-tf/convft${NC}"
    echo -e "${MAGENTA}License:${NC}    ${BOLD}Apache 2.0${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC} ${BOLD}convft [COMMAND] [OPTIONS]${NC}"
    echo
    echo -e "${GREEN}Commands:${NC}"
    echo -e "  ${BOLD}ft${NC}         Convert files to text"
    echo -e "  ${BOLD}tf${NC}         Convert text to files"
    echo -e "  ${BOLD}install${NC}    Install ConvFT (requires sudo)"
    echo -e "  ${BOLD}uninstall${NC}  Uninstall ConvFT (requires sudo)"
    echo -e "  ${BOLD}help${NC}       Display this help message"
    echo
    echo -e "${GREEN}Options for ft:${NC}"
    echo -e "  ${BOLD}-i --include [PATH...]${NC}   Include specific directories or files (defaults to current directory)"
    echo -e "  ${BOLD}-e --exclude [PATH...]${NC}   Exclude specific directories or files"
    echo -e "  ${BOLD}-t --tree-depth [DEPTH]${NC}  Set directory tree depth (default 1)"
    echo
    echo -e "${YELLOW}Examples:${NC}"
    echo -e "  ${BOLD}convft ft -i /my/project -t 3 -e /my/project/temp /my/project/build.sh${NC}"
    echo -e "  ${BOLD}convft ft -i /path/to/file1.txt /path/to/file2.c${NC}"
    echo -e "  ${BOLD}convft tf${NC}"
    echo -e "  ${BOLD}sudo convft install${NC}"
    echo -e "  ${BOLD}sudo convft uninstall${NC}"
    echo
}

# Function to get directory tree
get_directory_tree() {
    local depth=$1
    if ! command -v tree &> /dev/null; then
        echo -e "${RED}Error: tree command not found. Please install it first.${NC}"
        exit 1
    fi
    tree -a -L "$depth" -I '.git|.DS_Store' --noreport
}

# Function to process a single file
process_file() {
    local file="$1"
    local output_file="$2"
    
    # Skip the output file itself
    if [[ -f "$file" && "$file" != "./$output_file" && -r "$file" ]]; then
        # Check if it's a text file or shell script
        if file "$file" | grep -qE "text|shell script|ASCII|empty"; then
            echo -e "${CYAN}Processing:${NC} $file"
            echo "Filepath: $file" >> "$output_file"
            echo "Content:" >> "$output_file"
            cat "$file" >> "$output_file"
            echo -e "\n" >> "$output_file"
        else
            echo -e "${YELLOW}Skipping binary file:${NC} $file"
        fi
    fi
}

# Function to convert files to text
file_to_text() {
    local output_file="all_files_text.txt"
    local dirs=(".")
    local depth=1
    local exclude=(".git")  # Automatically exclude .git

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -i|--include)
                shift
                dirs=()
                while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
                    dirs+=("$1")
                    shift
                done
                ;;
            -e|--exclude)
                shift
                while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
                    exclude+=("$1")
                    shift
                done
                ;;
            -t|--tree-depth)
                shift
                depth="$1"
                shift
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                exit 1
                ;;
        esac
    done

    echo -e "${YELLOW}Starting conversion of files to text...${NC}"
    
    # Clear the output file if it exists
    > "$output_file"
    
    # Add directory tree at the beginning
    echo "DirectoryTree:" >> "$output_file"
    get_directory_tree "$depth" >> "$output_file"
    echo "EndDirectoryTree" >> "$output_file"
    echo >> "$output_file"
    
    # Process files excluding excluded paths
    for dir in "${dirs[@]}"; do
        find "$dir" -type f | while read -r file; do
            local skip=0
            for excluded in "${exclude[@]}"; do
                if [[ "$file" == *"$excluded"* ]]; then
                    skip=1
                    break
                fi
            done
            if [[ $skip -eq 0 ]]; then
                process_file "$file" "$output_file"
            fi
        done
    done
    
    echo -e "${GREEN}Conversion completed. Output saved to ${BOLD}$output_file${NC}"
}

# Function to convert text back to files
text_to_file() {
    local input_file="all_files_text.txt"
    
    if [[ ! -f "$input_file" ]]; then
        echo -e "${RED}Error: $input_file not found${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Starting conversion of text to files...${NC}"
    
    local in_tree_section=false
    local current_file=""
    
    while IFS= read -r line; do
        if [[ "$line" == "DirectoryTree:" ]]; then
            in_tree_section=true
            continue
        fi
        if [[ "$line" == "EndDirectoryTree" ]]; then
            in_tree_section=false
            continue
        fi
        if [[ "$in_tree_section" == true ]]; then
            continue
        fi
        
        if [[ "$line" == "Filepath:"* ]]; then
            current_file="${line#Filepath: }"
            # Skip if the file path contains .git
            if [[ "$current_file" == *".git"* ]]; then
                current_file=""
                continue
            fi
            echo -e "${CYAN}Creating:${NC} $current_file"
            mkdir -p "$(dirname "$current_file")"
            > "$current_file"
        elif [[ "$line" != "Content:" && -n "$current_file" ]]; then
            echo "$line" >> "$current_file"
        fi
    done < "$input_file"
    
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
        shift
        file_to_text "$@"
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

