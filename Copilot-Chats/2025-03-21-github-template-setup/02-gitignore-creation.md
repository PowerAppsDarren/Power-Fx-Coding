# Creating GitIgnore File

## Prompt
> Would you like me to create any of these additional template files for your repository?

help create a gitignore file for this repo. I'm not sure what coding language I'll use tho. But put in the ignore file to exclude video files (mp4, mov, etc.). can we somehow add file sizes to the gitignore file? is that even possilbe?

## Response
I've created a comprehensive `.gitignore` file for your repository that:

1. Includes common patterns for multiple programming languages
2. Specifically excludes video files (mp4, mov, etc.)
3. Contains comments explaining each section

Regarding file size limitations: Git doesn't natively support ignoring files based on size in the `.gitignore` file. However, you have two options for handling large files:

1. **Git LFS (Large File Storage)**:
   - Install Git LFS and track large file types
   - Example: `git lfs track "*.mp4"`
   - This stores large files separately from your main repository

2. **Pre-commit hook**:
   - Create a custom script that checks file sizes before commits
   - You can set a maximum file size limit
   - Prevents large files from being committed

The `.gitignore` file has been created at the repository root with comprehensive patterns for various environments.
