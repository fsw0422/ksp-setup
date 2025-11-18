#!/bin/bash

rm -f ~/.tmux.conf
[ -f ~/.tmux.conf.backup-in-place-for-ksp ] && mv ~/.tmux.conf.backup-in-place-for-ksp ~/.tmux.conf

rm -f ~/.p10k.zsh
[ -f ~/.p10k.zsh.backup-in-place-for-ksp ] && mv ~/.p10k.zsh.backup-in-place-for-ksp ~/.p10k.zsh

rm -f ~/.zshrc
[ -f ~/.zshrc.backup-in-place-for-ksp ] && mv ~/.zshrc.backup-in-place-for-ksp ~/.zshrc

rm -f ~/.ideavimrc
[ -f ~/.ideavimrc.backup-in-place-for-ksp ] && mv ~/.ideavimrc.backup-in-place-for-ksp ~/.ideavimrc

rm -f ~/.vimrc
[ -f ~/.vimrc.backup-in-place-for-ksp ] && mv ~/.vimrc.backup-in-place-for-ksp ~/.vimrc

rm -f ~/.ssh.conf
[ -f ~/.ssh.conf.backup-in-place-for-ksp ] && mv ~/.ssh.conf.backup-in-place-for-ksp ~/.ssh.conf

# If ~/.ssh/config exists, remove the custom SSH config inclusion line
if [ -f ~/.ssh/config ]; then
	sed -i '/Include ~\/\.ssh\.conf/d' ~/.ssh/config

	# If the file is now empty, remove it
	if [ ! -s ~/.ssh/config ]; then
		rm ~/.ssh/config
	fi
fi

rm -rf ~/.ksp

echo "Uninstallation complete. All KSP configurations have been removed and backups restored where applicable. However, installed packages remain intact."