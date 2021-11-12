#!/usr/bin/env bash

# Inspired by https://ahmet.im/blog/mastering-kubeconfig/

# Put config file of the new cluster to your $HOME/.kube/ directory with ".config" extension:
# Like "newcluster.config"
# Then run this script. It will backup your existing config and will merge the new one into the single file.

# Then use "https://github.com/ahmetb/kubectx" to switch between contexts.

# Preparations
export KUBECONFIG=$HOME/.kube/config
mkdir -p "$HOME/.kube/done"
DATE=$(date +%Y-%m-%d_%H-%M-%S)

# Rename the existing config with the .config extension
mv "$HOME/.kube/config" "$HOME/.kube/$DATE.config"

# Get List of all .config files
echo The following files will be merged:
while IFS= read -r -d '' config_file
do
    OUT=${OUT:+$OUT:}$config_file
    echo "$config_file"
done < <(find "$HOME/.kube" -not -path "*/\.git*" -name "*config" -print0)

# Merge all configurations into one file
export KUBECONFIG=$OUT
kubectl config view --merge --flatten > "$HOME/.kube/config"

# Backup the previous config for reference
mv "$HOME/.kube/$DATE.config" "$HOME/.kube/done/$DATE.config.bak"

# Move all imported configurations to the ./done folder
while IFS= read -r -d '' imported_config_file
do
    mv "$imported_config_file" "$HOME/.kube/done/$(basename -- "$imported_config_file").imported"
done < <(find "$HOME/.kube/" -name "*.config" -print0)

# Restore $KUBECONFIG environment variable
export KUBECONFIG=$HOME/.kube/config
chmod 600 "$HOME/.kube/config"
