# Automation Script Creation

## Prompt
>>At the end of that response, I asked if you wanted me to create the actual script file or if you preferred a different approach like a Bash script, but we didn't continue that part of the conversation.

please do this!!
yes, create those files!!

## Response
I'll create both the PowerShell and Bash automation scripts for your repository. I'll place these in a new `Scripts` directory:

1. Created PowerShell script: `c:\GIT-REPOS\API-Toolkit\Scripts\git-automation.ps1`
2. Created Bash script: `c:\GIT-REPOS\API-Toolkit\Scripts\git-automation.sh`

Both scripts implement the automation features you requested:
- Checking if the folder has a git repository and initializing if needed
- Adding a .gitignore file if not present
- Adding untracked files (respecting .gitignore)
- Creating commits with descriptive messages
- Pulling and pushing changes

The PowerShell script is optimized for Windows environments, while the Bash script provides cross-platform compatibility for macOS and Linux users.

To use the PowerShell script:
```
cd c:\GIT-REPOS\API-Toolkit
.\Scripts\git-automation.ps1
```

To use the Bash script:
```
cd /path/to/API-Toolkit
bash Scripts/git-automation.sh
```

Note: The Bash script requires execution permissions which can be set with:
```
chmod +x Scripts/git-automation.sh
```
