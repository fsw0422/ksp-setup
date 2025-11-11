#!/bin/bash

KSP_DIR="${KSP_DIR:-$HOME/.ksp}"

if [ ! -d "$KSP_DIR" ]; then
    echo "Error: $KSP_DIR directory not found"
    echo "Please clone your config repository first"
    exit 1
fi

if [ ! -d "$KSP_DIR/.git" ]; then
    echo "Error: $KSP_DIR is not a git repository"
    exit 1
fi

echo "Installing git hooks in $KSP_DIR..."
mkdir -p "$KSP_DIR/.git/hooks"

HOOK_SCRIPT='#!/bin/bash

rm -f ~/.gitconfig && ln ~/.ksp/.gitconfig ~/
rm -f ~/.tmux.conf && ln ~/.ksp/.tmux.conf ~/
rm -f ~/.p10k.zsh && ln ~/.ksp/.p10k.zsh ~/
rm -f ~/.zshrc && ln ~/.ksp/.zshrc ~/
rm -f ~/.ideavimrc && ln ~/.ksp/.ideavimrc ~/
rm -f ~/.vimrc && ln ~/.ksp/.vimrc ~/
echo "Config files updated"
'

echo "$HOOK_SCRIPT" > "$KSP_DIR/.git/hooks/post-merge"
chmod +x "$KSP_DIR/.git/hooks/post-merge"

echo "$HOOK_SCRIPT" > "$KSP_DIR/.git/hooks/post-commit"
chmod +x "$KSP_DIR/.git/hooks/post-commit"

echo "$HOOK_SCRIPT" > "$KSP_DIR/.git/hooks/post-checkout"
chmod +x "$KSP_DIR/.git/hooks/post-checkout"

echo "Git hooks installed successfully!"
echo "Hooks created:"
echo "  - post-merge"
echo "  - post-commit"
echo "  - post-checkout"
