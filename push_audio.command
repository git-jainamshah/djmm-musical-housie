#!/bin/bash
# DRL Musical Housie — Push audio files to GitHub
# Double-click this in Finder to run.

cd "$(dirname "$0")"

echo "===================================="
echo "  DRL Musical Housie — Audio Push"
echo "===================================="
echo ""
echo "Fixing git index if needed..."
rm -f .git/index.lock

echo "Staging all files..."
git add -A

echo "Committing..."
git commit -m "chore: add mp3 audio files for all 30 songs" || echo "(nothing new to commit)"

echo ""
echo "Pushing to GitHub (force — this may take 1-2 minutes for 224MB)..."
git push --force origin main

echo ""
echo "===================================="
echo "  Done! Check above for any errors."
echo "===================================="
echo ""
read -p "Press Enter to close..."
