#!/bin/bash

# Inspired by https://ahmet.im/blog/mastering-kubeconfig/

# Put config file of the new cluster to your ~/.kube/ directory with '.config' extension:
# Like newcluster.config
# Then run this script. It will backup and merge you existing config and the new one into the single file.
# Then use 'https://github.com/ahmetb/kubectx' to switch between contexts.

export KUBECONFIG=~/.kube/config
mkdir -p ~/.kube/done
mv ~/.kube/config ~/.kube/$(date +%Y-%m-%d_%H-%M).config
for config_file in $(find ~/.kube -not -path '*/\.git*' -name "*config")
do
    OUT=${OUT:+$OUT:}$config_file
done
echo The following files will be merged:
echo $OUT
export KUBECONFIG=$OUT
kubectl config view --merge --flatten > ~/.kube/config
mv ~/.kube/$(date +%Y-%m-%d_%H-%M).config ~/.kube/done/$(date +%Y-%m-%d_%H-%M).config.bak
export KUBECONFIG=~/.kube/config
for imported_config_file in $(find ~/.kube/ -name "*.config")
do
    mv $imported_config_file ~/.kube/done/$(basename -- $imported_config_file).imported
done
