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

[ -f ~/.tmux.conf ] && mv ~/.tmux.conf ~/.tmux.conf.backup-in-place-for-ksp; ln ~/.ksp/.tmux.conf ~/
[ -f ~/.p10k.zsh ] && mv ~/.p10k.zsh ~/.p10k.zsh.backup-in-place-for-ksp; ln ~/.ksp/.p10k.zsh ~/
[ -f ~/.zshrc ] && mv ~/.zshrc ~/.zshrc.backup-in-place-for-ksp; ln ~/.ksp/.zshrc ~/
[ -f ~/.ideavimrc ] && mv ~/.ideavimrc ~/.ideavimrc.backup-in-place-for-ksp; ln ~/.ksp/.ideavimrc ~/
[ -f ~/.vimrc ] && mv ~/.vimrc ~/.vimrc.backup-in-place-for-ksp; ln ~/.ksp/.vimrc ~/
[ -f ~/.ssh.conf ] && mv ~/.ssh.conf ~/.ssh.conf.backup-in-place-for-ksp; ln ~/.ksp/.ssh.conf ~/
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
