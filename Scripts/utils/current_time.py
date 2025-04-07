#!/usr/bin/env python3
"""
Current Time Updater
This script fetches the current time from the internet and updates a file
in the repository with this information for AI tools to reference.
"""

import os
import json
import urllib.request
from datetime import datetime
import platform
import subprocess

# File path where time information will be stored
# Using relative path to work regardless of where the script is run from
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))
TIME_FILE_PATH = os.path.join(REPO_ROOT, "Resources-for-AI", "current_time.md")

def get_time_from_internet():
    """Fetch current time from WorldTimeAPI"""
    try:
        # Use WorldTimeAPI which provides time information in JSON format
        response = urllib.request.urlopen("http://worldtimeapi.org/api/ip")
        data = json.loads(response.read().decode())
        
        # Extract relevant information
        datetime_str = data['datetime']
        timezone = data['timezone']
        
        # Parse the datetime string
        dt = datetime.fromisoformat(datetime_str.replace('Z', '+00:00'))
        
        return {
            'iso_time': dt.isoformat(),
            'formatted_time': dt.strftime('%Y-%m-%d %H:%M:%S'),
            'date': dt.strftime('%Y-%m-%d'),
            'time': dt.strftime('%H:%M:%S'),
            'timezone': timezone,
            'timestamp': dt.timestamp(),
            'unix_time': int(dt.timestamp())
        }
    except Exception as e:
        # Fallback to system time if internet fetch fails
        print(f"Error fetching time from internet: {e}")
        print("Falling back to system time...")
        
        now = datetime.now()
        return {
            'iso_time': now.isoformat(),
            'formatted_time': now.strftime('%Y-%m-%d %H:%M:%S'),
            'date': now.strftime('%Y-%m-%d'),
            'time': now.strftime('%H:%M:%S'),
            'timezone': 'System local timezone',
            'timestamp': now.timestamp(),
            'unix_time': int(now.timestamp()),
            'note': 'Generated from system time (internet fetch failed)'
        }

def update_time_file(time_data):
    """Update the markdown file with current time information"""
    # Create directory if it doesn't exist
    os.makedirs(os.path.dirname(TIME_FILE_PATH), exist_ok=True)
    
    with open(TIME_FILE_PATH, 'w') as f:
        f.write("# Current Time Information\n\n")
        f.write("This file is automatically updated with current time information for AI tools.\n\n")
        f.write(f"Last Updated: {time_data['formatted_time']} ({time_data['timezone']})\n\n")
        f.write("## Time Data\n\n")
        f.write("```json\n")
        f.write(json.dumps(time_data, indent=2))
        f.write("\n```\n\n")
        f.write("## Usage\n\n")
        f.write("When working with AI tools like GitHub Copilot, reference this file to provide current time information:\n\n")
        f.write("```\n#file:Resources-for-AI/current_time.md\n```\n")

def setup_git_hook():
    """Set up a pre-commit git hook to update the time file"""
    hooks_dir = os.path.join(REPO_ROOT, ".git", "hooks")
    hook_path = os.path.join(hooks_dir, "pre-commit")
    
    # Skip if hooks directory doesn't exist (not a git repo)
    if not os.path.exists(hooks_dir):
        print("Not a git repository. Skipping git hook setup.")
        return
    
    # Create the hook script
    with open(hook_path, 'w') as f:
        f.write(f"""#!/bin/sh
# Pre-commit hook to update the current time file

# Run the time update script
python "{os.path.abspath(__file__)}"

# Add the updated time file to the commit
git add "{os.path.relpath(TIME_FILE_PATH, REPO_ROOT)}"
""")
    
    # Make the hook executable
    try:
        os.chmod(hook_path, 0o755)
        print(f"Git pre-commit hook set up at {hook_path}")
    except Exception as e:
        print(f"Failed to make git hook executable: {e}")
        print(f"Please run: chmod +x {hook_path}")

def main():
    """Main function to update the time file"""
    time_data = get_time_from_internet()
    update_time_file(time_data)
    print(f"Updated time file at {TIME_FILE_PATH}")
    print(f"Current time: {time_data['formatted_time']} ({time_data['timezone']})")
    
    # Offer to set up git hook
    if os.path.exists(os.path.join(REPO_ROOT, ".git")):
        answer = input("Would you like to set up a git pre-commit hook to automatically update this file? (y/n): ")
        if answer.lower() in ('y', 'yes'):
            setup_git_hook()

if __name__ == "__main__":
    main()
```
