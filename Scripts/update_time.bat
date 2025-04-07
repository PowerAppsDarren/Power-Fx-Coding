@echo off
echo Updating current time information...
python "%~dp0\utils\current_time.py"
echo.
echo Done! Time information updated.
echo You can now reference #file:Resources-for-AI/current_time.md in your AI conversations.
pause
