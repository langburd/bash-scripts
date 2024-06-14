#!/bin/bash
# shellcheck disable=all

# Set computer name - inspired by https://rafi.io/operating-systems/linux/shell/bash/pimp-up-your-shell/
hostname
export COMPUTER_NAME="avi-a2992-mac"
sudo scutil --set ComputerName "${COMPUTER_NAME}"
sudo scutil --set HostName "${COMPUTER_NAME}"
sudo scutil --set LocalHostName "${COMPUTER_NAME}"
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "${COMPUTER_NAME}"

# MacOS tweaks:
# https://github.com/mathiasbynens/dotfiles/blob/main/.macos

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh || true)"

# Install Homebrew packages
brew install \
    coreutils gnutls bash bash-completion@2 less z mas entr tmux bc \
    tmux-mem-cpu-load tmux-xpanes reattach-to-user-namespace tree \
    colordiff pstree jq yq urlview tcpdump nmap readline rsync aria2 \
    curl netcat ttyrec ttygif ttyd the_silver_searcher id3lib tcping \
    libexif libmms faad2 terminal-notifier figlet fortune gnu-sed \
    keychain p7zip tarsnap spark exiv2 lnav ncdu calc tidy-html5 \
    pngcrush watch pidof pinfo atool exif cloc gnupg grc pango bat \
    poppler icdiff gh git git-cal git-extras pass peco ranger wget fd \
    xmlstarlet highlight shellcheck sshfs ccat editorconfig ctop \
    htop progress httpstat catimg fzf fzy ripgrep httpie pgcli syncthing \
    go node yarn zsh fish diff-so-fancy proselint yamllint pre-commit \
    mpc ncmpcpp mpv neomutt jrnl rclone task vit tig glyr jsonnet \
    kubernetes-cli helm kubectx stern gawk docker colima exa dive \
    awscli azure-cli google-cloud-sdk argocd kustomize k9s kubeseal \
    zsh-syntax-highlighting zsh-autosuggestions iproute2mac \
    terraform-docs tfsec tflint cosign tenv yamlfmt

# brew services start colima
# colima start
brew services start syncthing

brew install warrensbox/tap/tfswitch
brew install warrensbox/tap/tgswitch
brew install Azure/kubelogin/kubelogin
brew install ynqa/tap/jnv

# echo 'export PATH="/opt/homebrew/opt/bc/bin:$PATH"' >> ~/.zshrc
# echo 'export PATH="/opt/homebrew/opt/curl/bin:$PATH"' >> ~/.zshrc

# /opt/homebrew/opt/fzf/install --all
# echo 'source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"' >> ~/.zshrc
# echo 'source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"' >> ~/.zshrc
# echo 'export PATH="/opt/homebrew/opt/gawk/libexec/gnubin:$PATH"' >> ~/.zshrc

# Install applications from App Store
brew install mas
# To find the id of an application, use `mas search <app name>`
mas install 526298438  # Lightshot Screenshot
mas install 1451685025 # WireGuard
mas install 1475387142 # Tailscale
mas install 1295203466 # Microsoft Remote Desktop
mas install 1187772509 # stts (2.21)

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
    remote-desktop-manager \
    slack \
    sourcetree \
    spotify \
    telegram \
    visual-studio-code \
    whatsapp \
    zoom

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

# Install 'zsh-you-should-use' - Simple zsh plugin that reminds you that you should use one of your existing aliases for a command you just typed.
git clone https://github.com/MichaelAquilina/zsh-you-should-use.git $ZSH_CUSTOM/plugins/you-should-use
# Then add you-should-use to the plugins array in your .zshrc - plugins=(... you-should-use)

# Install 'git open' - to open the repo website (GitHub, GitLab, Bitbucket) in your browser.
git clone https://github.com/paulirish/git-open.git $ZSH_CUSTOM/plugins/git-open
# Add git-open to your plugin list - edit ~/.zshrc and change plugins=(...) to plugins=(... git-open)
source ~/.zshrc
