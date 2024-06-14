# get_kubeconfig.sh

This folder contains a shell script, `get_kubeconfig.sh`, that helps to set up your local K8S configuration.

## Prerequisites

- `AWS CLI` installed. If not, the script will prompt you to install it. You can follow the instructions at [https://aws.amazon.com/cli](https://aws.amazon.com/cli).
- `Azure CLI` installed. If not, the script will prompt you to install it. You can follow the instructions at [https://learn.microsoft.com/en-us/cli/azure/install-azure-cli](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli).
- `Azure kubelogin` installed. If not, the script will prompt you to install it. You can follow the instructions at [https://github.com/Azure/kubelogin](https://github.com/Azure/kubelogin).
- `Kubernetes Tools` (`kubectl`) installed. If not, the script will prompt you to install it. You can follow the instructions at [ttps://kubernetes.io/docs/tasks/tools](ttps://kubernetes.io/docs/tasks/tools).
- `jq` installed. If not, the script will prompt you to install it. You can follow the instructions at [https://jqlang.github.io/jq](https://jqlang.github.io/jq).

## Description

`get_kubeconfig.sh` is a shell script used to retrieve the Kubernetes configuration file (kubeconfig) for all available K8S clusters (both in **AWS** & **Azure**).

## Usage

1. Run the script using the command `./get_kubeconfig.sh`.
2. The script will check if all prerequisites are installed. It will exit and prompt you to install the missing prerequisite (See [Prerequisites](#prerequisites)) in it finds one.
3. The script will ask you for the name of your local AWS Profile of the AWS Organization management account. If you want to use the predefined ID (`AdministratorAccess-123456789101`), just press Enter.
4. The script will receive the list of all AWS accounts (using `aws organizations list-accounts`), will go over all regions in all available AWS accounts, find there all EKS clusters and will try to add each of them  (or update it) to the separate kube-context file (using `aws eks update-kubeconfig`).
5. After it the script will recieve the array of available AKS clusters and their appropriate Resource Groups. It will create the separate K8S context file for each AKS cluster (using `az aks get-credentials`).
6. All K8S context files (both EKS & AKS) are starting with `config_`, so we can easily combine and use all of them inside one environment variable (`KUBECONFIG`).
7. Don't forget to add the following line to your `~/.zshrc` or `~/.bashrc` file:

```sh
KUBECONFIG=$(find ~/.kube -name "config_*.yaml" | tr '\n' ':' || true) && export KUBECONFIG
```

The advantage of this method of managing K8S contexts is the ease of deleting an irrelevant context (just delete the file with its name) and adding or updating new K8S contexts (just run the `get_kubeconfig.sh` script again).
