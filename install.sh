#!/bin/bash

# Requirement check: ZSH must be installed and set as default shell
if [[ "$(basename "$SHELL")" != "zsh" ]]; then
	echo "This script requires ZSH to be installed and set as your default shell."
	echo "Current shell: $SHELL"
	echo "Please install ZSH, set it as your default shell, and re-run this script."
	exit 1
fi

# Detect CPU architecture
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
	DEB_ARCH="amd64"
elif [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
	DEB_ARCH="arm64"
else
	echo "Unsupported architecture: $ARCH"
	exit 1
fi
echo "Detected architecture: $ARCH (deb: $DEB_ARCH)"


echo "Installing Platform-Specific Dependencies"
if [[ "$OSTYPE" == "darwin"* ]]; then
	# Homebrew
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	if [[ -x /opt/homebrew/bin/brew ]]; then
		eval "$(/opt/homebrew/bin/brew shellenv)"
	elif [[ -x /usr/local/bin/brew ]]; then
		eval "$(/usr/local/bin/brew shellenv)"
	else
		echo "Homebrew was installed but brew is not on PATH yet. Restart your shell or add it manually."
		exit 1
	fi

	# Dependencies + CLI Tools + Kubernetes Tools
	brew install \
		coreutils \
		findutils \
		gnu-tar \
		gnu-sed \
		gawk \
		gnutls \
		gnu-indent \
		gnu-getopt \
		grep \
		git \
		wget \
		pkg-config \
		vim \
		ncurses \
		libevent \
		utf8proc \
		gh \
		ripgrep \
		yq \
		jq \
		kubectl \
		helm \
		k9s

	# Git Credential Manager
	echo "Installing Git Credential Manager"
	brew install --cask git-credential-manager
	git-credential-manager configure
else
	# Prerequisites needed before setting up APT repositories
	echo "Installing prerequisites (curl, wget, gpg)"
	sudo apt update
	sudo apt install -y curl wget gpg gnupg apt-transport-https ca-certificates

	# Locale
	echo "Setting up Locale to 'en_US.UTF-8'"
	sudo sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
	sudo locale-gen
	sudo update-locale LANG=en_US.UTF-8

	# APT repository: GitHub CLI
	curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
	sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
	echo "deb [arch=${DEB_ARCH} signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

	# APT repository: kubectl
	curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
	sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
	echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
	sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list

	# APT repository: helm
	curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
	echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list

	# yq (Mike Farah's version) - direct binary download
	echo "Installing yq"
	sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${DEB_ARCH} -O /usr/local/bin/yq
	sudo chmod +x /usr/local/bin/yq

	# k9s - direct deb download
	rm -f k9s_linux_${DEB_ARCH}.deb k9s_linux_${DEB_ARCH}.deb.*
	wget -O k9s_linux_${DEB_ARCH}.deb https://github.com/derailed/k9s/releases/latest/download/k9s_linux_${DEB_ARCH}.deb

	# Single apt update + install for all packages
	echo "Installing all APT packages"
	sudo apt update
	sudo DEBIAN_FRONTEND=noninteractive apt install -y \
		dnsutils \
		locales \
		tzdata \
		git \
		xclip \
		curl \
		wget \
		gpg \
		apt-transport-https \
		gnupg \
		vim-gtk3 \
		build-essential \
		openssh-client \
		software-properties-common \
		bison \
		libncurses5-dev:${DEB_ARCH} \
		libevent-dev \
		gh \
		ripgrep \
		jq \
		kubectl \
		helm \
		./k9s_linux_${DEB_ARCH}.deb
	rm -f k9s_linux_${DEB_ARCH}.deb k9s_linux_${DEB_ARCH}.deb.*
fi


echo "Installing Oh-My-ZSH"
export RUNZSH=no
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"


echo "Installing tmux 3.5"
rm -f tmux-3.5.tar.gz && rm -rf tmux-3.5
wget https://github.com/tmux/tmux/releases/download/3.5/tmux-3.5.tar.gz -O tmux-3.5.tar.gz
tar zxvf tmux-3.5.tar.gz
if [[ "$OSTYPE" == "darwin"* ]]; then
	(cd tmux-3.5 && ./configure --enable-utf8proc && make && sudo make install)
else
	(cd tmux-3.5 && ./configure && make && sudo make install)
fi
tmux kill-server
rm -f tmux-3.5.tar.gz && rm -rf tmux-3.5


echo "Installing UV"
curl -LsSf https://astral.sh/uv/install.sh | sh
echo "Please install and set a global Python version (to override the default system one). If you've understood, press any key to continue..."
read response


echo "Installing FNM"
curl -fsSL https://fnm.vercel.app/install | bash
echo "Please install and set a global Node version. If you've understood, press any key to continue..."
read response


echo "Installing Oh My ZSH plugins..."
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
echo "Please download and install all MesloLGS fonts from https://github.com/romkatv/powerlevel10k-media and set it as your font for terminal. If you've understood, press any key to continue..."
read response


echo "Installing configs..."
git clone https://github.com/fsw0422/.ksp.git ~/.ksp
[ -f ~/.tmux.conf ] && rm ~/.tmux.conf; ln -s ~/.ksp/.tmux.conf ~/.tmux.conf
[ -f ~/.p10k.zsh ] && rm ~/.p10k.zsh; ln -s ~/.ksp/.p10k.zsh ~/.p10k.zsh
[ -f ~/.zshrc ] && rm ~/.zshrc; ln -s ~/.ksp/.zshrc ~/.zshrc
[ -f ~/.ideavimrc ] && rm ~/.ideavimrc; ln -s ~/.ksp/.ideavimrc ~/.ideavimrc
[ -f ~/.vimrc ] && rm ~/.vimrc; ln -s ~/.ksp/.vimrc ~/.vimrc


echo "********** Installation Complete **********"
echo "Please proceed to README file and finish platform-specific settings"
echo "Press any key to start a new Tmux session"
read response
tmux
