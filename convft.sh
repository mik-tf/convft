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
    echo -e "  ${BOLD}ftd${NC}        Convert files to text with directory selection"
    echo -e "  ${BOLD}tf${NC}         Convert text to files"
    echo -e "  ${BOLD}install${NC}    Install ConvFT (requires sudo)"
    echo -e "  ${BOLD}uninstall${NC}  Uninstall ConvFT (requires sudo)"
    echo -e "  ${BOLD}help${NC}       Display this help message"
    echo
    echo -e "${YELLOW}Examples:${NC}"
    echo -e "  ${BOLD}convft ft${NC}              # Convert current directory to 'all_files_text.txt'"
    echo -e "  ${BOLD}convft ftd${NC}             # Convert selected directories to 'all_files_text.txt'"
    echo -e "  ${BOLD}convft tf${NC}              # Reconstruct files from 'all_files_text.txt'"
    echo -e "  ${BOLD}sudo bash convft.sh install${NC}    # Install ConvFT system-wide"
    echo -e "  ${BOLD}sudo convft uninstall${NC}  # Remove ConvFT from the system"
    echo
    echo -e "${BLUE}=========================================${NC}"
}

# Function to get directory tree
get_directory_tree() {
    if ! command -v tree &> /dev/null; then
        echo -e "${RED}Error: tree command not found. Please install it first.${NC}"
        exit 1
    fi
    # Remove the -L 2 flag to show full directory structure
    tree -a -I '.git|.DS_Store' --noreport
}

# Function to get subdirectories
get_subdirectories() {
    local dirs=()
    
    # Get all subdirectories except .git
    while IFS= read -r dir; do
        if [[ -d "$dir" && ! "$dir" =~ ^\. && "$dir" != ".git/" ]]; then
            dirs+=("$dir")
        fi
    done < <(ls -d */)

    if [ ${#dirs[@]} -eq 0 ]; then
        echo -e "${RED}No subdirectories found in current directory${NC}"
        exit 1
    fi

    echo -e "${YELLOW}\nAvailable subdirectories:${NC}"
    for i in "${!dirs[@]}"; do
        echo "$((i+1)). ${dirs[$i]}"
    done

    echo -e "${CYAN}\nEnter directory numbers to include (comma-separated, e.g., \"1,3,4\"), or \"all\" for all directories:${NC}"
    read -p "> " input

    local selected_dirs=()
    if [[ "${input,,}" == "all" ]]; then
        selected_dirs=("${dirs[@]}")
    else
        IFS=',' read -ra numbers <<< "$input"
        for num in "${numbers[@]}"; do
            idx=$((num-1))
            if [[ $idx -ge 0 && $idx -lt ${#dirs[@]} ]]; then
                selected_dirs+=("${dirs[$idx]}")
            fi
        done
    fi

    if [ ${#selected_dirs[@]} -eq 0 ]; then
        echo -e "${RED}No valid directories selected${NC}"
        exit 1
    fi

    printf "%s\n" "${selected_dirs[@]}"
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
    
    echo -e "${YELLOW}Starting conversion of files to text...${NC}"
    
    # Clear the output file if it exists
    > "$output_file"
    
    # Add directory tree at the beginning
    echo "DirectoryTree:" >> "$output_file"
    get_directory_tree >> "$output_file"
    echo "EndDirectoryTree" >> "$output_file"
    echo >> "$output_file"
    
    # Process files excluding .git directory
    find . -type f -not -path '*/\.git/*' | while read -r file; do
        # Skip the output file itself and the script file
        if [[ "$file" != "./$output_file" && "$file" != "$SCRIPT_PATH" ]]; then
            process_file "$file" "$output_file"
        fi
    done
    
    echo -e "${GREEN}Conversion completed. Output saved to ${BOLD}$output_file${NC}"
}

# Function to convert files to text with directory selection
file_to_text_with_dirs() {
    local output_file="all_files_text.txt"
    
    echo -e "${YELLOW}Starting directory selection process...${NC}"
    
    # Get selected directories
    mapfile -t selected_dirs < <(get_subdirectories)
    
    echo -e "${YELLOW}\nStarting conversion of files to text in selected directories...${NC}"
    
    # Clear the output file if it exists
    > "$output_file"
    
    # Add directory tree at the beginning
    echo "DirectoryTree:" >> "$output_file"
    get_directory_tree >> "$output_file"
    echo "EndDirectoryTree" >> "$output_file"
    echo >> "$output_file"
    
    # Process files in selected directories excluding .git
    for dir in "${selected_dirs[@]}"; do
        echo -e "${CYAN}\nProcessing directory: ${BOLD}$dir${NC}"
        find "$dir" -type f -not -path '*/\.git/*' | while read -r file; do
            process_file "$file" "$output_file"
        done
    done
    
    echo -e "${GREEN}\nConversion completed. Output saved to ${BOLD}$output_file${NC}"
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
        file_to_text
        ;;
    "ftd")
        file_to_text_with_dirs
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