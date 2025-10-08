#!/bin/bash
# Git Repository Automation Script for API-Toolkit
# This script automates common git operations with enhanced features:
# 1. Command-line parameters for non-interactive use
# 2. Configuration file support for customization
# 3. Git LFS integration and large file detection
# 4. Repository management and workflow automation

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default configuration
CONFIG_FILE=".gitautomation.json"
COMMIT_MESSAGE_TEMPLATE="Auto-commit: Repository update at {date}"
DEFAULT_BRANCH="main"
AUTO_DETECT_LFS=true
LFS_SIZE_THRESHOLD_MB=10
FILE_TYPES_TO_TRACK_WITH_LFS=("*.psd" "*.zip" "*.tar.gz" "*.mp4" "*.mov")
AUTO_PUSH=false

# Command line flags
INIT=false
ADD_IGNORE=false
ADD=false
COMMIT=false
PULL=false
PUSH=false
DETECT_LFS=false
CONFIGURE_LFS=false
ALL=false
HELP=false
COMMIT_MESSAGE=""

# Function to output status messages
status() {
    echo -e "${CYAN}[$(date +%H:%M:%S)]${NC} $1"
}

success() {
    echo -e "${GREEN}[$(date +%H:%M:%S)] ✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}[$(date +%H:%M:%S)] ⚠️ $1${NC}"
}

error() {
    echo -e "${RED}[$(date +%H:%M:%S)] ❌ $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +%H:%M:%S)] ℹ️ $1${NC}"
}

show_help() {
    echo -e "${CYAN}Git Repository Automation Script${NC}"
    echo -e "${CYAN}Usage: ./git-automation.sh [options]${NC}"
    echo ""
    echo "Options:"
    echo "  --init          Initialize Git repository if it doesn't exist"
    echo "  --add-ignore    Add .gitignore if it doesn't exist"
    echo "  --add           Add all untracked files respecting .gitignore"
    echo "  --commit        Create a commit with a descriptive message"
    echo "  --message, -m   Specify commit message"
    echo "  --pull          Pull latest changes from remote"
    echo "  --push          Push changes to remote"
    echo "  --detect-lfs    Detect files that should be tracked with Git LFS"
    echo "  --configure-lfs Configure Git LFS for recommended file types"
    echo "  --all           Run all operations (default if no options specified)"
    echo "  --help, -h      Show this help message"
    echo ""
    echo "Configuration:"
    echo "  Create a .gitautomation.json file in the repository root to customize behavior."
    echo "  Example configuration:"
    echo ""
    echo '{
  "commitMessageTemplate": "Auto-commit: Repository update at {date}",
  "defaultBranch": "main",
  "autoDetectLFS": true,
  "lfsSizeThresholdMB": 10,
  "fileTypesToTrackWithLFS": ["*.psd", "*.zip", "*.tar.gz", "*.mp4", "*.mov"],
  "autoPush": false
}'
    exit 0
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --init)
                INIT=true
                shift
                ;;
            --add-ignore)
                ADD_IGNORE=true
                shift
                ;;
            --add)
                ADD=true
                shift
                ;;
            --commit)
                COMMIT=true
                shift
                ;;
            --message|-m)
                COMMIT_MESSAGE="$2"
                shift 2
                ;;
            --pull)
                PULL=true
                shift
                ;;
            --push)
                PUSH=true
                shift
                ;;
            --detect-lfs)
                DETECT_LFS=true
                shift
                ;;
            --configure-lfs)
                CONFIGURE_LFS=true
                shift
                ;;
            --all)
                ALL=true
                shift
                ;;
            --help|-h)
                HELP=true
                shift
                ;;
            *)
                warning "Unknown option: $1"
                shift
                ;;
        esac
    done
    
    # If no specific operations selected, assume --all
    if [[ "$INIT" == "false" && "$ADD_IGNORE" == "false" && "$ADD" == "false" && "$COMMIT" == "false" && 
          "$PULL" == "false" && "$PUSH" == "false" && "$DETECT_LFS" == "false" && "$CONFIGURE_LFS" == "false" ]]; then
        ALL=true
    fi
}

# Load configuration if exists
load_configuration() {
    if [[ -f "$CONFIG_FILE" ]]; then
        status "Loading configuration from $CONFIG_FILE..."
        
        # Check if jq is available
        if command -v jq >/dev/null 2>&1; then
            if [[ -s "$CONFIG_FILE" ]]; then
                # Load config values with jq
                if COMMIT_TEMPLATE=$(jq -r '.commitMessageTemplate // empty' "$CONFIG_FILE" 2>/dev/null); then
                    [[ -n "$COMMIT_TEMPLATE" ]] && COMMIT_MESSAGE_TEMPLATE="$COMMIT_TEMPLATE"
                    
                    BRANCH=$(jq -r '.defaultBranch // empty' "$CONFIG_FILE")
                    [[ -n "$BRANCH" ]] && DEFAULT_BRANCH="$BRANCH"
                    
                    AUTO_LFS=$(jq -r '.autoDetectLFS // empty' "$CONFIG_FILE")
                    [[ "$AUTO_LFS" == "false" ]] && AUTO_DETECT_LFS=false
                    [[ "$AUTO_LFS" == "true" ]] && AUTO_DETECT_LFS=true
                    
                    THRESHOLD=$(jq -r '.lfsSizeThresholdMB // empty' "$CONFIG_FILE")
                    [[ -n "$THRESHOLD" ]] && LFS_SIZE_THRESHOLD_MB="$THRESHOLD"
                    
                    AUTO_PUSH_VAL=$(jq -r '.autoPush // empty' "$CONFIG_FILE")
                    [[ "$AUTO_PUSH_VAL" == "true" ]] && AUTO_PUSH=true
                    
                    # File types to track with LFS (more complex array handling)
                    if jq -e '.fileTypesToTrackWithLFS' "$CONFIG_FILE" >/dev/null 2>&1; then
                        readarray -t FILE_TYPES_TO_TRACK_WITH_LFS < <(jq -r '.fileTypesToTrackWithLFS[]' "$CONFIG_FILE")
                    fi
                    
                    success "Configuration loaded successfully."
                else
                    warning "Error parsing configuration file. Using default configuration."
                fi
            else
                warning "Configuration file is empty. Using default configuration."
            fi
        else
            warning "jq is not installed. Cannot parse JSON configuration."
            warning "Using default configuration."
        fi
    else
        info "No configuration file found at $CONFIG_FILE"
        info "Using default configuration."
    fi
}

# Detect large files that should be tracked with Git LFS
detect_large_files() {
    local threshold=$1
    
    status "Scanning for large files (>$threshold MB)..."
    
    # Check if Git LFS is installed
    if ! git lfs version &>/dev/null; then
        error "Git LFS is not installed. Large files cannot be automatically tracked."
        warning "Install Git LFS from: https://git-lfs.github.com/"
        return
    fi
    
    # Get list of tracked patterns in LFS
    local tracked_patterns=$(git lfs track 2>&1 | grep "Tracking" | sed "s/Tracking '\(.*\)'/\1/g")
    
    # Find large files
    status "Finding large files..."
    
    # This approach uses find and stat for better performance with large repos
    local threshold_bytes=$((threshold * 1024 * 1024))
    
    # Create temp files for results
    local large_files_tmp=$(mktemp)
    local extensions_tmp=$(mktemp)
    
    # Find files larger than threshold, excluding .git directory
    find . -type f -size +${threshold}M -not -path "./.git/*" | while read -r file; do
        # Check if file matches any tracked patterns
        local is_tracked=false
        for pattern in $tracked_patterns; do
            # Simple pattern matching (more sophisticated matching would need more complex code)
            if [[ "${file##*/}" == ${pattern/\*/} || "${file##*/}" == *${pattern#\*} ]]; then
                is_tracked=true
                break
            fi
        done
        
        if [[ "$is_tracked" == "false" ]]; then
            # Get file size in MB (using bc for floating point)
            local size_bytes=$(stat -c %s "$file" 2>/dev/null || stat -f %z "$file" 2>/dev/null)
            local size_mb=$(echo "scale=2; $size_bytes / 1048576" | bc)
            
            # Get file extension
            local extension=".${file##*.}"
            if [[ "$extension" == ".$file" ]]; then
                extension="(no extension)"
            fi
            
            echo "${file:2}|$size_mb|$extension" >> "$large_files_tmp"
            echo "$extension" >> "$extensions_tmp"
        fi
    done
    
    if [[ -s "$large_files_tmp" ]]; then
        local file_count=$(wc -l < "$large_files_tmp")
        warning "Found $file_count large files not tracked by Git LFS:"
        
        # Display files in table format
        echo -e "Path|Size (MB)|Extension"
        echo -e "----|---------|---------"
        cat "$large_files_tmp" | column -t -s'|'
        echo ""
        
        # Group by extension for recommendations
        echo -e "${CYAN}Recommended Git LFS tracking patterns:${NC}"
        sort "$extensions_tmp" | uniq -c | sort -nr | while read -r count ext; do
            if [[ "$count" -gt 0 && "$ext" != "(no extension)" ]]; then
                echo "  git lfs track \"*$ext\"  ($count files)"
            fi
        done
        echo ""
        
        # Configure LFS if requested or in non-interactive mode
        if [[ "$CONFIGURE_LFS" == "true" ]]; then
            configure_lfs=true
        elif [[ "$ALL" == "true" ]]; then
            read -p "Would you like to configure Git LFS for these patterns? (y/n): " configure_lfs
            [[ "$configure_lfs" == "y" ]] && configure_lfs=true || configure_lfs=false
        else
            configure_lfs=false
        fi
        
        if [[ "$configure_lfs" == "true" ]]; then
            sort "$extensions_tmp" | uniq | while read -r ext; do
                if [[ "$ext" != "(no extension)" ]]; then
                    status "Configuring Git LFS for *$ext..."
                    if git lfs track "*$ext"; then
                        success "Git LFS configured for *$ext"
                    else
                        error "Failed to configure Git LFS for *$ext"
                    fi
                fi
            done
            warning "Don't forget to add and commit the updated .gitattributes file!"
        fi
    else
        success "No large files found that need Git LFS tracking."
    fi
    
    # Clean up temp files
    rm -f "$large_files_tmp" "$extensions_tmp"
}

# Parse command line arguments
parse_args "$@"

# Show help if requested
if [[ "$HELP" == "true" ]]; then
    show_help
fi

# Load config first
load_configuration

# Check if running from repository root
if [[ ! -d ".git" && ! -f "README.md" ]]; then
    warning "This script should be run from the repository root directory."
    if [[ "$ALL" != "true" ]]; then
        continue="y"  # In non-interactive mode, continue anyway
    else
        read -p "Continue anyway? (y/n): " continue
    fi
    [[ "$continue" != "y" ]] && exit 0
fi

# 1. Check if git repo exists, if not initialize one
if [[ "$INIT" == "true" || "$ALL" == "true" ]]; then
    if [[ ! -d ".git" ]]; then
        status "Initializing Git repository..."
        if git init; then
            success "Git repository initialized."
        else
            error "Failed to initialize git repository."
            exit 1
        fi
    else
        success "Git repository already exists."
    fi
fi

# 2. Check if .gitignore exists, if not create it
if [[ "$ADD_IGNORE" == "true" || "$ALL" == "true" ]]; then
    if [[ ! -f ".gitignore" ]]; then
        status "Creating .gitignore file..."
        
        # Look for gitignore template in repository
        template_path=""
        possible_templates=(
            ".gitignore.template"
            "Templates/.gitignore"
            ".github/templates/.gitignore"
        )
        
        for template in "${possible_templates[@]}"; do
            if [[ -f "$template" ]]; then
                template_path="$template"
                break
            fi
        done
        
        if [[ -n "$template_path" ]]; then
            cp "$template_path" .gitignore
            success ".gitignore created from template: $template_path"
        else
            # Create a comprehensive .gitignore
            cat > .gitignore << 'EOL'
# This .gitignore file is designed to work across multiple programming languages and environments

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# IDE and editor files
.idea/
.vscode/
*.swp
*.swo
*~
.project
.settings/
.classpath

# Node.js
node_modules/
npm-debug.log
yarn-debug.log
yarn-error.log
package-lock.json
.npm/

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib64/
parts/
sdist/
var/
*.egg-info/
.installed.cfg
*.egg
.pytest_cache/
.coverage
htmlcov/
.venv
venv/
ENV/

# Video files
*.mp4
*.mov
*.avi
*.wmv
*.flv
*.webm
*.mkv
*.m4v
*.3gp
*.vob

# Large media files and archives
*.zip
*.tar.gz
*.rar
*.7z
*.iso
*.dmg

# Note: For large file management, consider using Git LFS
EOL
            success "Created comprehensive .gitignore file."
        fi
    else
        success ".gitignore file already exists."
    fi
fi

# 3. Detect large files and offer to configure Git LFS
if [[ "$DETECT_LFS" == "true" || "$CONFIGURE_LFS" == "true" || ("$ALL" == "true" && "$AUTO_DETECT_LFS" == "true") ]]; then
    detect_large_files "$LFS_SIZE_THRESHOLD_MB"
fi

# 4. Save all files
if [[ "$ALL" == "true" ]]; then
    status "Handling unsaved files..."
    if [[ "$TERM_PROGRAM" == "vscode" ]]; then
        warning "Please save all files in VS Code before continuing."
        warning "Use keyboard shortcut: Ctrl+K S (Windows/Linux) or Cmd+Option+S (Mac)"
    else
        warning "Please make sure all files are saved before continuing."
    fi
    read -p "Continue with git operations? (y/n): " continue
    if [[ "$continue" != "y" ]]; then
        exit 0
    fi
fi

# 5. Show status and add all untracked files respecting .gitignore
if [[ "$ADD" == "true" || "$ALL" == "true" ]]; then
    status "Current git status:"
    git status --short

    status "Adding untracked files to git..."
    if git add .; then
        success "Files added."
    else
        error "Failed to add files."
        exit 1
    fi

    # Show what's staged
    status "Files staged for commit:"
    git status --short
fi

# 6. Commit with descriptive message
if [[ "$COMMIT" == "true" || "$ALL" == "true" ]]; then
    date_str=$(date +"%Y-%m-%d %H:%M:%S")
    default_message="${COMMIT_MESSAGE_TEMPLATE//\{date\}/$date_str}"
    
    status "Creating commit..."
    
    # If message provided as parameter, use it
    if [[ -n "$COMMIT_MESSAGE" ]]; then
        commit_message="$COMMIT_MESSAGE"
    elif [[ "$ALL" == "true" ]]; then
        # Only prompt if in interactive mode
        echo "Enter commit message (leave blank for: '$default_message'):"
        read commit_message
    else
        commit_message=""
    fi
    
    [[ -z "$commit_message" ]] && commit_message="$default_message"

    # Check if there are staged changes
    if [[ -n "$(git diff --cached --name-only)" ]]; then
        if git commit -m "$commit_message"; then
            success "Commit created with message: $commit_message"
        else
            error "Failed to create commit."
            exit 1
        fi
    else
        info "No changes to commit."
    fi
fi

# 7. Pull latest changes
if [[ "$PULL" == "true" || "$ALL" == "true" ]]; then
    # Check if remote exists before pulling
    if [[ -n "$(git remote -v)" ]]; then
        status "Pulling latest changes..."
        if git pull; then
            success "Pull completed successfully."
        else
            warning "Pull operation had issues, you may need to resolve conflicts."
        fi
    else
        warning "No remote repository configured. Skipping pull operation."
    fi
fi

# 8. Push changes
if [[ "$PUSH" == "true" || "$ALL" == "true" || "$AUTO_PUSH" == "true" ]]; then
    # Check if remote exists before pushing
    if [[ -n "$(git remote -v)" ]]; then
        status "Pushing changes..."
        if git push; then
            success "Push completed successfully."
        else
            error "Push failed."
            warning "You may need to set tracking information for this branch."
            
            current_branch=$(git rev-parse --abbrev-ref HEAD)
            
            if [[ "$ALL" == "true" ]]; then
                echo "Set up tracking for branch '$current_branch'? (y/n)"
                read setup_tracking
            else
                setup_tracking="y"  # Default to yes in non-interactive mode
            fi
            
            if [[ "$setup_tracking" == "y" ]]; then
                remote_name=$(git remote show | head -n 1)
                if [[ -z "$remote_name" ]]; then
                    remote_name="origin"
                    
                    if [[ "$ALL" == "true" ]]; then
                        echo "Enter the remote repository URL:"
                        read remote_url
                    else
                        error "No remote URL specified in non-interactive mode."
                        exit 1
                    fi
                    
                    git remote add "$remote_name" "$remote_url"
                fi
                git push --set-upstream "$remote_name" "$current_branch"
            fi
        fi
    else
        if [[ "$ALL" == "true" ]]; then
            warning "No remote repository configured."
            echo "Would you like to set up a remote repository now? (y/n)"
            read setup_remote
            
            if [[ "$setup_remote" == "y" ]]; then
                echo "Enter the remote repository URL:"
                read remote_url
                git remote add origin "$remote_url"
                
                current_branch=$(git rev-parse --abbrev-ref HEAD)
                if git push -u origin "$current_branch"; then
                    success "Remote repository configured and changes pushed."
                else
                    error "Failed to push to remote repository."
                fi
            fi
        else
            warning "No remote repository configured. Skipping push operation."
        fi
    fi
fi

success "🎉 Git operations completed."
