# Git Repository Automation Script for API-Toolkit
# This script automates common git operations with enhanced features:
# 1. Command-line parameters for non-interactive use
# 2. Configuration file support for customization
# 3. Git LFS integration and large file detection
# 4. Repository management and workflow automation

param (
    [switch]$Init,
    [switch]$AddIgnore,
    [switch]$Add,
    [switch]$Commit,
    [switch]$Pull,
    [switch]$Push,
    [string]$Message,
    [switch]$DetectLFS,
    [switch]$ConfigureLFS,
    [switch]$All,
    [switch]$Help
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Configuration file path
$configFilePath = ".gitautomation.json"
$defaultConfig = @{
    "commitMessageTemplate" = "Auto-commit: Repository update at {date}"
    "defaultBranch" = "main"
    "autoDetectLFS" = $true
    "lfsSizeThresholdMB" = 10
    "fileTypesToTrackWithLFS" = @("*.psd", "*.zip", "*.tar.gz", "*.mp4", "*.mov")
    "autoPush" = $false
}
$config = $defaultConfig.Clone()

function Write-Status {
    param (
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] $Message" -ForegroundColor $Color
}

function Show-Help {
    Write-Host "Git Repository Automation Script" -ForegroundColor Cyan
    Write-Host "Usage: .\git-automation.ps1 [options]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Init          Initialize Git repository if it doesn't exist"
    Write-Host "  -AddIgnore     Add .gitignore if it doesn't exist"
    Write-Host "  -Add           Add all untracked files respecting .gitignore"
    Write-Host "  -Commit        Create a commit with a descriptive message"
    Write-Host "  -Pull          Pull latest changes from remote"
    Write-Host "  -Push          Push changes to remote"
    Write-Host "  -Message       Specify commit message"
    Write-Host "  -DetectLFS     Detect files that should be tracked with Git LFS"
    Write-Host "  -ConfigureLFS  Configure Git LFS for recommended file types"
    Write-Host "  -All           Run all operations (default if no options specified)"
    Write-Host "  -Help          Show this help message"
    Write-Host ""
    Write-Host "Configuration:"
    Write-Host "  Create a .gitautomation.json file in the repository root to customize behavior."
    Write-Host "  Example configuration:"
    Write-Host ""
    Write-Host (ConvertTo-Json $defaultConfig -Depth 3)
    exit 0
}

# Load configuration if exists
function Load-Configuration {
    if (Test-Path $configFilePath) {
        try {
            Write-Status "Loading configuration from $configFilePath..." -Color Blue
            $fileContent = Get-Content $configFilePath -Raw
            $loadedConfig = ConvertFrom-Json $fileContent -AsHashtable
            
            # Merge loaded config with default config
            foreach ($key in $loadedConfig.Keys) {
                $config[$key] = $loadedConfig[$key]
            }
            Write-Status "Configuration loaded successfully." -Color Green
        }
        catch {
            Write-Status "Error loading configuration: $_" -Color Red
            Write-Status "Using default configuration." -Color Yellow
        }
    }
    else {
        Write-Status "No configuration file found at $configFilePath" -Color Blue
        Write-Status "Using default configuration." -Color Blue
    }
}

# Check for large files and offer to set up Git LFS
function Detect-LargeFiles {
    param (
        [int]$ThresholdMB = 10
    )
    
    Write-Status "Scanning for large files (>$ThresholdMB MB)..." -Color Yellow
    
    # Check if Git LFS is installed
    $lfsInstalled = $null
    try {
        $lfsInstalled = git lfs version 2>&1
        if ($LASTEXITCODE -ne 0) {
            $lfsInstalled = $null
        }
    }
    catch {
        $lfsInstalled = $null
    }
    
    if (-not $lfsInstalled) {
        Write-Status "Git LFS is not installed. Large files cannot be automatically tracked." -Color Red
        Write-Status "Install Git LFS from: https://git-lfs.github.com/" -Color Yellow
        return
    }
    
    # Get list of tracked files in LFS
    $trackedPatterns = git lfs track 2>&1 | 
        Where-Object { $_ -like "Tracking *" } | 
        ForEach-Object { $_.Replace("Tracking ", "").Replace("'", "").Trim() }
    
    # Find large files
    $largeFiles = @()
    $allFiles = Get-ChildItem -Recurse -File | 
        Where-Object { 
            $_.Length -gt ($ThresholdMB * 1MB) -and
            -not (Test-Path (Join-Path ".git" $_.FullName.Substring((Get-Location).Path.Length + 1).Replace("\", "/"))) 
        }
    
    foreach ($file in $allFiles) {
        $isTracked = $false
        foreach ($pattern in $trackedPatterns) {
            if ($file.Name -like $pattern.Replace("*", "*")) {
                $isTracked = $true
                break
            }
        }
        
        if (-not $isTracked) {
            $largeFiles += @{
                Path = $file.FullName.Substring((Get-Location).Path.Length + 1)
                Size = [math]::Round($file.Length / 1MB, 2)
                Extension = $file.Extension
            }
        }
    }
    
    if ($largeFiles.Count -gt 0) {
        Write-Status "Found $($largeFiles.Count) large files not tracked by Git LFS:" -Color Yellow
        $largeFiles | Format-Table -Property Path, Size, Extension -AutoSize
        
        # Group by extension to recommend patterns
        $extensionGroups = $largeFiles | Group-Object -Property Extension
        
        Write-Status "Recommended Git LFS tracking patterns:" -Color Cyan
        foreach ($group in $extensionGroups) {
            Write-Host "  git lfs track `"*$($group.Name)`"  ($($group.Count) files)"
        }
        
        if ($ConfigureLFS) {
            $confirmLFS = "y"
        }
        else {
            $confirmLFS = Read-Host "Would you like to configure Git LFS for these patterns? (y/n)"
        }
        
        if ($confirmLFS -eq "y") {
            foreach ($group in $extensionGroups) {
                Write-Status "Configuring Git LFS for *$($group.Name)..." -Color Yellow
                git lfs track "*$($group.Name)"
                if ($LASTEXITCODE -eq 0) {
                    Write-Status "✅ Git LFS configured for *$($group.Name)" -Color Green
                }
                else {
                    Write-Status "❌ Failed to configure Git LFS for *$($group.Name)" -Color Red
                }
            }
            Write-Status "Don't forget to add and commit the updated .gitattributes file!" -Color Yellow
        }
    }
    else {
        Write-Status "No large files found that need Git LFS tracking." -Color Green
    }
}

# Show help if requested
if ($Help) {
    Show-Help
}

# Load config first
Load-Configuration

# If no specific operations selected, assume -All
if (-not ($Init -or $AddIgnore -or $Add -or $Commit -or $Pull -or $Push -or $DetectLFS -or $ConfigureLFS)) {
    $All = $true
}

# Check if running from repository root
if (-not (Test-Path ".git" -PathType Container) -and -not (Test-Path "README.md" -PathType Leaf)) {
    Write-Status "⚠️ Warning: This script should be run from the repository root directory." -Color Yellow
    if (-not $All) {
        $continue = "y"  # In non-interactive mode, continue anyway
    }
    else {
        $continue = Read-Host "Continue anyway? (y/n)"
    }
    if ($continue -ne "y") {
        exit
    }
}

# 1. Check if git repo exists, if not initialize one
if ($Init -or $All) {
    if (-not (Test-Path -Path ".git" -PathType Container)) {
        Write-Status "Initializing Git repository..." -Color Yellow
        git init
        if ($LASTEXITCODE -ne 0) {
            Write-Status "❌ Failed to initialize git repository." -Color Red
            exit 1
        }
        Write-Status "✅ Git repository initialized." -Color Green
    } else {
        Write-Status "✅ Git repository already exists." -Color Green
    }
}

# 2. Check if .gitignore exists, if not create it
if ($AddIgnore -or $All) {
    if (-not (Test-Path -Path ".gitignore")) {
        Write-Status "Creating .gitignore file..." -Color Yellow
        
        # Look for gitignore template in repository
        $templatePath = $null
        $possibleTemplates = @(
            ".gitignore.template",
            "Templates\.gitignore",
            ".github\templates\.gitignore"
        )
        
        foreach ($template in $possibleTemplates) {
            if (Test-Path $template) {
                $templatePath = $template
                break
            }
        }
        
        if ($templatePath) {
            Copy-Item -Path $templatePath -Destination ".gitignore"
            Write-Status "✅ .gitignore created from template: $templatePath" -Color Green
        } else {
            # Create a comprehensive .gitignore
            @"
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
"@ | Out-File -FilePath ".gitignore" -Encoding utf8
            Write-Status "✅ Created comprehensive .gitignore file." -Color Green
        }
    } else {
        Write-Status "✅ .gitignore file already exists." -Color Green
    }
}

# 3. Detect large files and offer to configure Git LFS
if ($DetectLFS -or $ConfigureLFS -or ($All -and $config.autoDetectLFS)) {
    Detect-LargeFiles -ThresholdMB $config.lfsSizeThresholdMB
}

# 4. Save all files (integration with VS Code if running in integrated terminal)
if ($All) {
    Write-Status "Attempting to save all open files..." -Color Yellow
    try {
        if ($env:TERM_PROGRAM -eq "vscode") {
            # This is a best-effort approach - not guaranteed to work in all VS Code setups
            # Send Ctrl+K S keystroke to VS Code
            $wshell = New-Object -ComObject wscript.shell
            $wshell.SendKeys("^k")
            Start-Sleep -Milliseconds 100
            $wshell.SendKeys("s")
            Write-Status "✅ Save all command sent to VS Code." -Color Green
        } else {
            Write-Status "⚠️ Cannot save unsaved files: Not running in VS Code integrated terminal." -Color Yellow
            Write-Status "   Please save your files before continuing." -Color Yellow
            $continue = Read-Host "Continue? (y/n)"
            if ($continue -ne "y") {
                exit
            }
        }
    } catch {
        Write-Status "⚠️ Failed to send save command to editor: $_" -Color Yellow
        Write-Status "   Please save your files manually before continuing." -Color Yellow
        $continue = Read-Host "Continue? (y/n)"
        if ($continue -ne "y") {
            exit
        }
    }
}

# 5. Show status and add all untracked files respecting .gitignore
if ($Add -or $All) {
    Write-Status "Current git status:" -Color Cyan
    git status --short

    Write-Status "Adding untracked files to git..." -Color Yellow
    git add .
    if ($LASTEXITCODE -ne 0) {
        Write-Status "❌ Failed to add files." -Color Red
        exit 1
    }
    Write-Status "✅ Files added." -Color Green

    # Show what's staged
    Write-Status "Files staged for commit:" -Color Cyan
    git status --short
}

# 6. Commit with descriptive message
if ($Commit -or $All) {
    $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $defaultMessage = $config.commitMessageTemplate.Replace("{date}", $date)
    
    Write-Status "Creating commit..." -Color Yellow
    
    # If message provided as parameter, use it
    if ($Message) {
        $commitMessage = $Message
    }
    elseif ($All) {
        # Only prompt if in interactive mode
        $commitMessage = Read-Host "Enter commit message (leave blank for: '$defaultMessage')"
    }
    else {
        $commitMessage = ""
    }
    
    if ([string]::IsNullOrWhiteSpace($commitMessage)) {
        $commitMessage = $defaultMessage
    }

    $stagedChanges = git diff --cached --name-only
    if ($stagedChanges) {
        git commit -m "$commitMessage"
        if ($LASTEXITCODE -ne 0) {
            Write-Status "❌ Failed to create commit." -Color Red
            exit 1
        }
        Write-Status "✅ Commit created with message: $commitMessage" -Color Green
    } else {
        Write-Status "ℹ️ No changes to commit." -Color Cyan
    }
}

# 7. Pull latest changes
if ($Pull -or $All) {
    # Check if remote exists before pulling
    $remoteExists = git remote -v
    if ($remoteExists) {
        # Pull latest changes
        Write-Status "Pulling latest changes..." -Color Yellow
        git pull
        if ($LASTEXITCODE -ne 0) {
            Write-Status "⚠️ Pull operation had issues, you may need to resolve conflicts." -Color Yellow
        } else {
            Write-Status "✅ Pull completed successfully." -Color Green
        }
    }
    else {
        Write-Status "⚠️ No remote repository configured. Skipping pull operation." -Color Yellow
    }
}

# 8. Push changes
if ($Push -or $All -or $config.autoPush) {
    # Check if remote exists before pushing
    $remoteExists = git remote -v
    if ($remoteExists) {
        Write-Status "Pushing changes..." -Color Yellow
        git push
        if ($LASTEXITCODE -ne 0) {
            Write-Status "❌ Push failed." -Color Red
            Write-Status "You may need to set tracking information for this branch." -Color Yellow
            
            $currentBranch = git rev-parse --abbrev-ref HEAD
            
            if ($All) {
                $setupTracking = Read-Host "Set up tracking for branch '$currentBranch'? (y/n)"
            }
            else {
                $setupTracking = "y"  # Default to yes in non-interactive mode
            }
            
            if ($setupTracking -eq "y") {
                $remoteName = git remote show
                if (-not $remoteName) {
                    $remoteName = "origin"
                    
                    if ($All) {
                        $remoteUrl = Read-Host "Enter the remote repository URL"
                    }
                    else {
                        Write-Status "❌ No remote URL specified in non-interactive mode." -Color Red
                        exit 1
                    }
                    
                    git remote add $remoteName $remoteUrl
                }
                git push --set-upstream $remoteName $currentBranch
            }
        } else {
            Write-Status "✅ Push completed successfully." -Color Green
        }
    } else {
        if ($All) {
            Write-Status "⚠️ No remote repository configured." -Color Yellow
            $setupRemote = Read-Host "Would you like to set up a remote repository now? (y/n)"
            
            if ($setupRemote -eq "y") {
                $remoteUrl = Read-Host "Enter the remote repository URL"
                git remote add origin $remoteUrl
                
                $currentBranch = git rev-parse --abbrev-ref HEAD
                git push -u origin $currentBranch
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Status "✅ Remote repository configured and changes pushed." -Color Green
                } else {
                    Write-Status "❌ Failed to push to remote repository." -Color Red
                }
            }
        }
        else {
            Write-Status "⚠️ No remote repository configured. Skipping push operation." -Color Yellow
        }
    }
}

Write-Status "🎉 Git operations completed." -Color Cyan
