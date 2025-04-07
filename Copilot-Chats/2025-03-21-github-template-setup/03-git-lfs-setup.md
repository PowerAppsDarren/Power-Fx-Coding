# Setting Up Git LFS for Large Files

## Prompt
yes

## Response
I'll provide you with step-by-step instructions for setting up Git LFS (Large File Storage) for your repository to handle large files like videos more effectively.

### Setting Up Git LFS

1. **Install Git LFS**:
   - **Windows**:
     ```
     git lfs install
     ```
     (If Git LFS is not installed, download it from https://git-lfs.github.com/)
   
   - **macOS** (using Homebrew):
     ```
     brew install git-lfs
     git lfs install
     ```
   
   - **Linux** (Debian/Ubuntu):
     ```
     sudo apt install git-lfs
     git lfs install
     ```

2. **Track large file types** (from your repository root):
   ```
   # Track video files
   git lfs track "*.mp4"
   git lfs track "*.mov"
   git lfs track "*.avi"
   git lfs track "*.wmv"
   
   # Track other large files if needed
   git lfs track "*.psd"
   git lfs track "*.zip"
   ```

3. **Create/update a .gitattributes file**:
   - Git LFS automatically creates or updates the `.gitattributes` file
   - Make sure to commit this file:
     ```
     git add .gitattributes
     git commit -m "Add Git LFS tracking for large files"
     ```

4. **Using Git LFS**:
   - After setup, just use normal Git commands
   - LFS handles the tracking automatically
   - Example:
     ```
     git add large_video.mp4
     git commit -m "Add sample video"
     git push
     ```

5. **Verify LFS is working**:
   ```
   git lfs ls-files
   ```

### Additional Tips for Working with Git LFS

1. **For your template repository**:
   - Include the `.gitattributes` file in your template
   - Add LFS setup instructions in your README.md

2. **Set file size limits** (using pre-commit hook):
   - Create a file called `.git/hooks/pre-commit` with:

   ```bash
   #!/bin/bash
   
   # Maximum file size in bytes (e.g., 100MB = 104857600)
   max_size=104857600
   
   # Check for files larger than max_size
   large_files=$(git diff --cached --name-only | xargs ls -l 2>/dev/null | awk "\$5 > $max_size" | awk '{print $9}')
   
   if [ -n "$large_files" ]; then
     echo "Error: Attempting to commit the following files that exceed $((max_size/1048576))MB:"
     echo "$large_files"
     echo "Please use Git LFS for these files."
     exit 1
   fi
   
   exit 0
   ```

   - Make it executable:
   ```
   chmod +x .git/hooks/pre-commit
   ```

3. **For GitHub repositories**:
   - GitHub provides 1GB free LFS storage per repository
   - Bandwidth limited to 1GB/month for free accounts
   - Consider this when hosting very large files

Would you like me to create the `.gitattributes` file for your repository with the video file patterns already configured?
