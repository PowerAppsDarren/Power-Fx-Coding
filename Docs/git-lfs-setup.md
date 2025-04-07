# Setting Up Git LFS for Large Files

This guide explains how to set up Git Large File Storage (LFS) for managing large files in your repository.


<a href='https://git-lfs.com/' target='_blank'><img src='https://git-lfs.com/images/graphic.gif' /></a>
## What is Git LFS?

Git LFS is an extension to Git that replaces large files with text pointers inside Git, while storing the file content on a remote server. This helps keep your repository size manageable while still tracking large files.

## Included Files

This template includes a pre-configured `.gitattributes` file that already sets up Git LFS tracking for common large file types:

- Video files (mp4, mov, avi, etc.)
- Archive files (zip, tar.gz, etc.)
- Large image files (when appropriate)
- Other binary files that tend to be large

## Setting Up Git LFS

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

2. **The `.gitattributes` File**:
   This repository includes a pre-configured `.gitattributes` file with these settings:
   ```
   # Video files
   *.mp4 filter=lfs diff=lfs merge=lfs -text
   *.mov filter=lfs diff=lfs merge=lfs -text
   # ...other file types...
   ```

3. **Track Additional File Types** (if needed):
   ```
   git lfs track "*.your-file-extension"
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

## Setting File Size Limits

Git doesn't natively support ignoring files by size in the `.gitignore` file, but you can create a pre-commit hook:

1. Create a file called `.git/hooks/pre-commit`:

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

2. Make it executable:
   ```
   chmod +x .git/hooks/pre-commit
   ```

## GitHub LFS Limitations

- GitHub provides 1GB free LFS storage per repository
- Bandwidth limited to 1GB/month for free accounts
- Consider these limits when hosting large files

## Customizing LFS for Your Project

If your project needs additional file types tracked with LFS, add them to the `.gitattributes` file following the same pattern:

```
*.your-file-extension filter=lfs diff=lfs merge=lfs -text
```

Then commit and push the updated `.gitattributes` file.
