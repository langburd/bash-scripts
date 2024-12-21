#!/bin/bash
# shellcheck disable=all

# Set computer name - inspired by https://rafi.io/operating-systems/linux/shell/bash/pimp-up-your-shell/
hostname
export COMPUTER_NAME="MacAxV"
sudo scutil --set ComputerName "${COMPUTER_NAME}"
sudo scutil --set HostName "${COMPUTER_NAME}"
sudo scutil --set LocalHostName "${COMPUTER_NAME}"
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "${COMPUTER_NAME}"

# MacOS tweaks:
# https://github.com/mathiasbynens/dotfiles/blob/main/.macos

# Set TAB key to switch input sources
# https://apple.stackexchange.com/a/303773
hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x70000006D}]}'
# Then, go to System Preferences/Keyboard/Shortcuts/Input Sources, use key 'caps lock' to switch input source.

# Allow sudo without password, with fingerprint authentication
sed "s/^#auth/auth/" /etc/pam.d/sudo_local.template | sudo tee /etc/pam.d/sudo_local

# Install oh-my-zsh now
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh || true)"

# Install applications from Homebrew Cask
brew install --cask \
    adobe-acrobat-reader \
    firefox \
    google-chrome \
    google-drive \
    iterm2 \
    keepassxc \
    keybase \
    marked \
    mysqlworkbench \
    rectangle \
    remote-desktop-manager \
    slack \
    sourcetree \
    spotify \
    telegram \
    visual-studio-code \
    whatsapp \
    zoom

# Install Docker Desktop in case you have a licence
brew install --cask docker

# Clone ~/.ssh repository
mv ~/.ssh ~/.ssh.bak
git clone keybase://private/langburd/ssh ~/.ssh
chmod 700 ~/.ssh
mv ~/.zshrc ~/.zshrc.bak
ln -s ~/.ssh/.zshrc ~/.zshrc
mv ~/.p10k.zsh ~/.p10k.zsh.bak
ln -s ~/.ssh/.p10k.zsh ~/.p10k.zsh

# Clone ~/.kube repository
mv ~/.kube ~/.kube.bak
git clone keybase://private/langburd/kubeconfig ~/.kube

# Install Homebrew packages
brew install argocd                                               # Declarative GitOps continuous delivery tool for Kubernetes
brew install awscli                                               # Command-line interface for AWS services
brew install azure-cli                                            # Command-line interface for Microsoft Azure
brew install bash                                                 # Unix shell and command language
brew install bat                                                  # Cat clone with syntax highlighting and Git integration
brew install bc                                                   # Arbitrary-precision calculator language
brew install colima && brew services start colima && colima start # Container runtime for macOS, often used as a Docker Desktop replacement
brew install colordiff                                            # Tool that colorizes diff output
brew install coreutils                                            # Basic file, shell, and text manipulation utilities from GNU
brew install cosign                                               # Tool for signing and verifying container images
brew install ctop                                                 # Command-line monitoring tool for containers
brew install curl                                                 # Tool to transfer data from or to a server
brew install dive                                                 # Tool to analyze Docker images and reduce their size
brew install docker                                               # Platform for developing, shipping, and running containers
brew install font-meslo-for-powerlevel10k                         # Customized Meslo Nerd Font patched for Powerlevel10k
brew install fzf                                                  # General-purpose command-line fuzzy finder
brew install gawk                                                 # GNU implementation of the AWK programming language
brew install gh                                                   # GitHub command-line tool
brew install git                                                  # Distributed version control system
brew install git-cal                                              # Tool to generate a git contribution calendar
brew install git-extras                                           # Collection of useful git utilities
brew install git-flow                                             # Extensions to provide high-level operations for Vincent Driessen's branching model
brew install git-lfs                                              # Extension for managing large files with Git
brew install gnu-sed                                              # GNU version of the stream editor for text manipulation
brew install gnupg                                                # Complete and free implementation of OpenPGP for encryption and signing
brew install gnutls                                               # Secure communications library implementing SSL, TLS, and DTLS protocols
brew install go                                                   # Statically typed, compiled programming language designed by Google
brew install google-cloud-sdk                                     # Tools for managing Google Cloud resources and applications
brew install helm                                                 # Package manager for Kubernetes
brew install htop                                                 # Interactive process viewer for Unix systems
brew install httpie                                               # User-friendly HTTP client with JSON support
brew install httpstat                                             # Tool that visualizes curl statistics more readably
brew install icdiff                                               # Improved colored diff tool with side-by-side view
brew install iproute2mac                                          # IP routing utilities for macOS
brew install jq                                                   # Command-line JSON processor
brew install jsonnet                                              # Data templating language for defining structured data
brew install k9s                                                  # Terminal UI to interact with Kubernetes clusters
brew install keychain                                             # Manager for OpenSSH, GPG, and other types of keys
brew install kubecolor                                            # Tool to colorize kubectl output
brew install kubectx                                              # Tool to switch between Kubernetes contexts and namespaces
brew install kubernetes-cli                                       # `kubectl` command-line tool for Kubernetes
brew install kubeseal                                             # Tool to encrypt Kubernetes Secrets into SealedSecrets for safe Git storage
brew install kustomize                                            # Kubernetes configuration customization tool
brew install less                                                 # Terminal pager to view file contents one screen at a time
brew install lnav                                                 # Log file navigator with a console interface
brew install mas                                                  # Command-line interface for the Mac App Store
brew install minikube                                             # Tool to run a Kubernetes cluster locally
brew install ncdu                                                 # Disk usage analyzer with an ncurses interface
brew install neomutt                                              # Version of the `mutt` email client with added features
brew install netcat                                               # Networking utility for reading/writing to network connections
brew install nmap                                                 # Network scanning tool to discover hosts/services on a network
brew install node                                                 # JavaScript runtime built on Chrome's V8 engine
brew install p7zip                                                # Port of the 7-Zip file archiver to POSIX systems
brew install pass                                                 # Simple, standard Unix password manager
brew install peco                                                 # Interactive filtering tool
brew install pgcli                                                # Command-line interface for PostgreSQL with auto-completion
brew install pidof                                                # Utility to find the process ID of a running program
brew install powerlevel10k                                        # Zsh theme with a configuration wizard
brew install pre-commit                                           # Framework for managing multi-language pre-commit hooks
brew install progress                                             # Tool to show progress of coreutils commands
brew install pstree                                               # Tool to display running processes as a tree
brew install pyenv                                                # Python version management tool
brew install pylint                                               # Source code analyzer for Python code
brew install rclone                                               # Command-line program to manage cloud storage files
brew install readline                                             # Library for command-line editing
brew install ripgrep                                              # Line-oriented search tool to search directories for regex patterns
brew install rsync                                                # Utility for efficient file transfer and synchronization
brew install shellcheck                                           # Static analysis tool for shell scripts
brew install shfmt                                                # Shell script formatter
brew install stern                                                # Tool to tail multiple pods and containers on Kubernetes
brew install syncthing && brew services start syncthing           # Continuous file synchronization program
brew install tcpdump                                              # Packet analyzer to capture network packets
brew install tcping                                               # TCP ping tool to check the availability of a remote host
brew install terraform-docs                                       # Utility to generate documentation from Terraform modules
brew install tflint                                               # Linter for Terraform files
brew install tfsec                                                # Static analysis tool for securing Terraform code
brew install the_silver_searcher                                  # Fast code-searching tool similar to ack
brew install tidy-html5                                           # Tool to clean and correct invalid HTML and XML
brew install tig                                                  # Text-mode interface for git, providing a rich interface
brew install tmux                                                 # Terminal multiplexer to manage multiple terminal sessions
brew install tmux-mem-cpu-load                                    # `tmux` plugin to display system performance information
brew install tmux-xpanes                                          # `tmux` plugin to easily create/manage multiple panes
brew install tree                                                 # Command to display directories as trees
brew install ttyd                                                 # Command-line tool to share terminal over the web
brew install ttygif                                               # Tool to convert terminal recordings into animated GIFs
brew install ttyrec                                               # Terminal session recorder
brew install watch                                                # Command to run another command at regular intervals
brew install wget                                                 # Command-line tool to retrieve files from the web
brew install yamlfmt                                              # Tool to format YAML files
brew install yamllint                                             # Linter for YAML files
brew install yarn                                                 # Fast, reliable dependency management tool for JavaScript
brew install yq                                                   # Command-line YAML and JSON processor
brew install z                                                    # Tool to quickly jump to frequently used directories
brew install zsh                                                  # Powerful shell designed for interactive use
brew install zsh-autosuggestions                                  # Zsh plugin that suggests commands as you type
brew install zsh-completions                                      # Additional completion definitions for Zsh
brew install zsh-syntax-highlighting                              # Zsh plugin for syntax highlighting at the command line

# Add Homebrew binaries to PATH
# echo 'export PATH="/opt/homebrew/opt/bc/bin:${PATH}"' >> ~/.zshrc
# echo 'export PATH="/opt/homebrew/opt/curl/bin:${PATH}"' >> ~/.zshrc
# echo 'export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:${PATH}"' >> ~/.zshrc
# echo 'export PATH="/opt/homebrew/opt/gawk/libexec/gnubin:${PATH}"' >> ~/.zshrc
# echo 'export PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:${PATH}"' >> ~/.zshrc

# Install fzf key bindings and fuzzy completion
# /opt/homebrew/opt/fzf/install --all

# Add 'google-cloud-sdk' to PATH
# echo 'source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"' >> ~/.zshrc
# echo 'source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"' >> ~/.zshrc

# Install packages from custom Homebrew taps
brew install warrensbox/tap/tfswitch
brew install warrensbox/tap/tgswitch
brew install Azure/kubelogin/kubelogin
brew install ynqa/tap/jnv

# Install 'zsh-you-should-use' - Simple zsh plugin that reminds you that you should use one of your existing aliases for a command you just typed.
git clone https://github.com/MichaelAquilina/zsh-you-should-use.git $ZSH_CUSTOM/plugins/you-should-use
# Then add you-should-use to the plugins array in your .zshrc - plugins=(... you-should-use)

# Install 'zsh-autosuggestions' and 'zsh-syntax-highlighting'
git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting

# Install 'git open' - to open the repo website (GitHub, GitLab, Bitbucket) in your browser.
git clone https://github.com/paulirish/git-open.git $ZSH_CUSTOM/plugins/git-open
# Add git-open to your plugin list - edit ~/.zshrc and change plugins=(...) to plugins=(... git-open)
source ~/.zshrc

# Install fonts from custom Homebrew tap
brew tap corgibytes/cask-fonts

# Update system git config
git lfs install
sudo git lfs install --system

# Install Powerlevel10k theme for Oh My Zsh
brew install font-meslo-for-powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Install applications from App Store
brew install mas
# To find the id of an application, use `mas search <app name>`
mas install 526298438  # Lightshot Screenshot
mas install 1451685025 # WireGuard
mas install 1475387142 # Tailscale
mas install 1295203466 # Microsoft Remote Desktop
mas install 1187772509 # stts (2.21)

# Install kubectl krew and some plugins
# Run this command to download and install krew:
(
    set -x
    cd "$(mktemp -d)" &&
        OS="$(uname | tr '[:upper:]' '[:lower:]' || true)" &&
        ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/' || true)" &&
        KREW="krew-${OS}_${ARCH}" &&
        curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
        tar zxvf "${KREW}.tar.gz" &&
        ./"${KREW}" install krew
)

# Add the $HOME/.krew/bin directory to your PATH environment variable:
if ! grep -q 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' ~/.zshrc; then
    echo 'source "PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH""' >>~/.zshrc
fi

# Install kubectl plugins
kubectl krew install \
    tree \
    view-utilization \
    neat \
    get-all

# Configure Git to sign commits with SSH key
SSH_KEY_PATH=${HOME}/.ssh/id_rsa.pub
brew install gh
gh auth login
gh auth refresh -h github.com -s admin:ssh_signing_key
gh ssh-key add "${SSH_KEY_PATH}" --type signing
git config --global gpg.format ssh
git config --global user.signingkey "${SSH_KEY_PATH}"
git config --global commit.gpgsign true
