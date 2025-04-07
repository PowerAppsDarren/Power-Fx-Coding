#!/bin/bash
echo "Updating current time information..."
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
python "$SCRIPT_DIR/utils/current_time.py"
echo ""
echo "Done! Time information updated."
echo "You can now reference #file:Resources-for-AI/current_time.md in your AI conversations."
