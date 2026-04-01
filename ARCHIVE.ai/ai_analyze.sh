#!/bin/bash

PROJECT="/mnt/c/Projects/ROBLOX/PASRAHPHOBIA"

echo "AI analyzing repository changes..."

cd $PROJECT

git diff --name-only > .ai/changed_files.txt

if [ ! -s .ai/changed_files.txt ]; then
    echo "No changes detected"
    exit 0
fi

echo "Files changed:"
cat .ai/changed_files.txt

echo "Running AI analysis..."

aider \
--model ollama/deepseek-coder:33b \
--message "Analyze the changed Roblox Lua scripts and suggest improvements for architecture, bugs, and multiplayer safety."

