#!/bin/bash

# Set the root directory to the current directory where the script is run
ROOT_DIR="$(pwd)"
SUMMARY_FILE="$ROOT_DIR/SUMMARY.md"

# Initialize SUMMARY.md with header
echo "# Table of contents" > "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"
echo "* [Welcome](README.md)" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"

# Function to generate section title from folder name
format_title() {
    local folder=$1
    # Replace hyphens with spaces, capitalize first letter of each word
    echo "$folder" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1'
}

# Function to add a markdown file to the summary with proper indentation
add_file_to_summary() {
    local file=$1
    local indent=$2
    local rel_path=${file#$ROOT_DIR/}
    
    # Skip SUMMARY.md itself
    if [[ "$rel_path" == "SUMMARY.md" ]]; then
        return
    fi
    
    # Extract title from file (first # heading) or use filename
    local title=$(grep -m 1 "^# " "$file" 2>/dev/null | sed 's/^# //')
    
    # If no title found, use the filename without extension and formatted
    if [[ -z "$title" ]]; then
        local filename=$(basename "$file" .md)
        title=$(format_title "$filename")
    fi
    
    echo "$indent* [$title]($rel_path)" >> "$SUMMARY_FILE"
}

# Function to process a directory and add its contents to SUMMARY.md
process_directory() {
    local dir=$1
    local indent=$2
    local rel_dir=${dir#$ROOT_DIR/}
    
    # Skip node_modules, .git, and other hidden directories
    if [[ "$rel_dir" == "node_modules"* || "$rel_dir" == ".git"* || "$rel_dir" == ".*" ]]; then
        return
    fi
    
    # Only add section headers for non-root directories
    if [[ "$dir" != "$ROOT_DIR" ]]; then
        local section_title=$(format_title "$(basename "$dir")")
        echo "" >> "$SUMMARY_FILE"
        echo "$indent## $section_title" >> "$SUMMARY_FILE"
        echo "" >> "$SUMMARY_FILE"
        
        # Check if directory has a README.md and add it first
        if [[ -f "$dir/README.md" ]]; then
            add_file_to_summary "$dir/README.md" "$indent"
        fi
    fi
    
    # Process all other markdown files in this directory (excluding README.md which was already processed)
    find "$dir" -maxdepth 1 -name "*.md" | sort | while read -r file; do
        if [[ "$(basename "$file")" != "README.md" && "$(basename "$file")" != "SUMMARY.md" ]]; then
            add_file_to_summary "$file" "$indent"
        fi
    done
    
    # Process subdirectories
    find "$dir" -mindepth 1 -maxdepth 1 -type d | sort | while read -r subdir; do
        if [[ "$(basename "$subdir")" != "node_modules" && "$(basename "$subdir")" != ".git" && ! "$(basename "$subdir")" =~ ^\. ]]; then
            # For nested directories, increase the indentation
            process_directory "$subdir" "$indent  "
        fi
    done
}

# Start processing from the root directory
echo "Generating SUMMARY.md based on directory structure..."
process_directory "$ROOT_DIR" ""

echo "SUMMARY.md has been updated successfully!"