#!/bin/bash

CONFIG_ONLY=false
if [[ "$1" == "--only-config" ]]; then
	CONFIG_ONLY=true
	echo "Config only mode enabled"
fi

if [ "$CONFIG_ONLY" = false ]; then
	echo "Installing Dependencies"
	if [[ "$OSTYPE" == "darwin"* ]]; then
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
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
			vim \
			ncurses \
			libevent \
			utf8proc
	else
		sudo apt update
		sudo DEBIAN_FRONTEND=noninteractive apt install -y \
			zsh \
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
			apt-transport-https \
			software-properties-common \
			bison \
			libncurses5-dev:amd64 \
			libevent-dev
	fi


	echo "Setting up Locale to 'en_US.UTF-8'"
	if [[ "$OSTYPE" == "darwin"* ]]; then
		echo "MacOS does not need Locale configuration"
	else
		sudo sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
		sudo locale-gen
		sudo update-locale LANG=en_US.UTF-8
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


	echo "Installing Docker"
	if [[ "$OSTYPE" == "darwin"* ]] || [ -d "/run/WSL" ]; then
		echo "Please Install Docker Desktop. If you have, press any key to continue..."
		read response
	else
		# Install Docker if using native Linux
		curl -fsSL https://get.docker.com -o get-docker.sh
		chmod +x get-docker.sh
		sudo ./get-docker.sh
		sudo usermod -aG docker $USER
		rm -f get-docker.sh
	fi


	echo "Installing Kubernetes Tools"
	if [[ "$OSTYPE" == "darwin"* ]]; then
		brew install kubectl helm k9s
	else
		# kubectl
		curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
		sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
		echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
		sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list
		sudo apt-get update
		sudo apt-get install -y kubectl

		# helm
		curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
		echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
		sudo apt-get update
		sudo apt-get install helm

		# k9s
		wget https://github.com/derailed/k9s/releases/latest/download/k9s_linux_amd64.deb
		sudo apt install ./k9s_linux_amd64.deb
		sudo rm k9s_linux_amd64.deb
	fi


	echo "Generating SSH key for Github clone access"
	mkdir -p ~/.ssh
	if [ ! -f ~/.ssh/github ]; then
		ssh-keygen -t rsa -b 4096 -f ~/.ssh/github -N ""
		echo "SSH key generated at ~/.ssh/github"
	else
		echo "SSH key already exists at ~/.ssh/github"
	fi
	echo ""
	echo "=========================================="
	echo "SSH Public Key:"
	echo "=========================================="
	cat ~/.ssh/github.pub
	echo "=========================================="
	echo ""
	echo "Please add this key to your GitHub account:"
	echo "1. Go to https://github.com/settings/ssh/new"
	echo "2. Copy the key above and paste it"
	echo "3. Give it a descriptive title (e.g., 'Dev Container Key')"
	echo ""
	echo "Press any key after you've added the key to GitHub..."
	read response


	echo "Installing UV"
	curl -LsSf https://astral.sh/uv/install.sh | sh
	echo "Please install and set a global Python version (to override the default system one). If you have, press any key to continue..."
	read response


	echo "Installing FNM"
	curl -fsSL https://fnm.vercel.app/install | bash
	echo "Please install and set a global Node version. If you have, press any key to continue..."
	read response
fi


echo "Installing Oh My ZSH plugins..."
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
echo "Please download and install all MesloLGS fonts from https://github.com/romkatv/powerlevel10k-media and set it as your font for terminal. If you have, press any key to continue..."
read response


# Hard link is used as devcontainer cannot recognize symlink properly
echo "Installing configs..."
git clone https://github.com/fsw0422/.ksp.git ~/.ksp
[ -f ~/.tmux.conf ] && mv ~/.tmux.conf ~/.tmux.conf.backup-in-place-for-ksp; ln ~/.ksp/.tmux.conf ~/
[ -f ~/.p10k.zsh ] && mv ~/.p10k.zsh ~/.p10k.zsh.backup-in-place-for-ksp; ln ~/.ksp/.p10k.zsh ~/
[ -f ~/.zshrc ] && mv ~/.zshrc ~/.zshrc.backup-in-place-for-ksp; ln ~/.ksp/.zshrc ~/
[ -f ~/.ideavimrc ] && mv ~/.ideavimrc ~/.ideavimrc.backup-in-place-for-ksp; ln ~/.ksp/.ideavimrc ~/
[ -f ~/.vimrc ] && mv ~/.vimrc ~/.vimrc.backup-in-place-for-ksp; ln ~/.ksp/.vimrc ~/


# Include custom ssh_config in ~/.ssh/config
mkdir -p ~/.ssh
if [ -f ~/.ssh/config ]; then
	if ! grep -q "Include ~/.ksp/ssh_config" ~/.ssh/config; then
		echo "Include ~/.ksp/ssh_config" >> ~/.ssh/config
	fi
else
	echo "Include ~/.ksp/ssh_config" > ~/.ssh/config
fi

echo "Installing git hooks..."
bash "$(dirname "$0")/setup-git-hooks.sh"


echo "********** Installation Complete **********"
echo "Please proceed to OneDrive README file and finish platform-specific settings"
if [ "$CONFIG_ONLY" = false ]; then
	echo "Press any key to start a new Tmux session"
	read response
	tmux
fi
