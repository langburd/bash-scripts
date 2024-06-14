#!/bin/bash

# =============================================================================
# Get K8S contexts from AWS EKS and Azure AKS - check prerequisites

# Check if AWS CLI is installed
if ! command -v aws >/dev/null 2>&1; then
    echo "AWS CLI is not installed. Please install AWS CLI - https://aws.amazon.com/cli"
    exit 1
fi

# Check if Azure CLI is installed
if ! command -v az >/dev/null 2>&1; then
    echo "Azure CLI is not installed. Please install Azure CLI - https://learn.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if kubelogin is installed
if ! command -v kubelogin >/dev/null 2>&1; then
    echo "kubelogin is not installed. Please install kubelogin - https://github.com/Azure/kubelogin"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl >/dev/null 2>&1; then
    echo "kubectl is not installed. Please install kubectl - https://kubernetes.io/docs/tasks/tools"
    exit 1
fi

# Check if jq is installed
if ! command -v jq >/dev/null 2>&1; then
    echo "jq is not installed. Please install jq - https://jqlang.github.io/jq"
    exit 1
fi

# =============================================================================
# Get K8S contexts from AWS EKS

# Predefine the AWS profile of the management account
MANAGEMENT_AWS_PROFILE="AdministratorAccess-123456789101"
echo "Please enter the name of your AWS Profile of the AWS Organization management account (Press Enter/Return if it's \"${MANAGEMENT_AWS_PROFILE}\"):"
read -r DEFINED_MANAGEMENT_AWS_PROFILE
[[ -n "${DEFINED_MANAGEMENT_AWS_PROFILE}" ]] && MANAGEMENT_AWS_PROFILE="${DEFINED_MANAGEMENT_AWS_PROFILE}"

# Check if the management account profile exist in the AWS configuration
if ! grep -q "${MANAGEMENT_AWS_PROFILE}" ~/.aws/config; then
    echo "AWS Profile \"${MANAGEMENT_AWS_PROFILE}\" does not exist in the AWS configuration file. Please add the profile to the AWS configuration file."
    echo "You can use the following script for this:"
    echo "https://github.com/langburd/bash-scripts/tree/master/aws_config"
    exit 1
fi

# Check if user is logged in
if ! aws sts get-caller-identity --profile "${MANAGEMENT_AWS_PROFILE}" >/dev/null 2>&1; then
    # Logging in to AWS SSO
    echo "Logging in to AWS SSO..."
    aws sso login --profile "${MANAGEMENT_AWS_PROFILE}"
fi

# Create the directory if it does not exist
mkdir -p "${HOME}/.kube"

# # Get list of organization accounts in AWS Organizations
ACCOUNTS=$(aws organizations list-accounts --profile "${MANAGEMENT_AWS_PROFILE}" --output json | jq -r '.Accounts[] | .Id' || true)

# Loop through each AWS account
for ACCOUNT_ID in ${ACCOUNTS}; do
    # Check if user has access to the account
    if aws sts get-caller-identity --profile "AdministratorAccess-${ACCOUNT_ID}" >/dev/null 2>&1; then
        echo ====================================
        echo "Processing AWS account: ${ACCOUNT_ID}"
        # Get all AWS regions
        AWS_REGIONS=$(aws ec2 describe-regions --profile "AdministratorAccess-${ACCOUNT_ID}" --output json | jq -r '.Regions[].RegionName' || true)
        # Loop through each region
        for REGION in ${AWS_REGIONS}; do
            # Get all EKS clusters in the account
            CLUSTER_NAMES=$(aws eks list-clusters --region "${REGION}" --profile "AdministratorAccess-${ACCOUNT_ID}" --output json | jq -r '.clusters[]' || true)
            # Loop through each cluster in the region
            for CLUSTER in ${CLUSTER_NAMES}; do
                # Convert the cluster name to lowercase
                CLUSTER_LOWER=$(echo "${CLUSTER}" | tr '[:upper:]' '[:lower:]')
                # Use the 'aws eks update-kubeconfig' command to create or update the kubeconfig file
                echo "  $(aws eks update-kubeconfig --region "${REGION}" --profile "AdministratorAccess-${ACCOUNT_ID}" --name "${CLUSTER}" --alias "${CLUSTER_LOWER}" --kubeconfig "${HOME}/.kube/config_${CLUSTER_LOWER}.yaml" || true)"
            done
        done
    fi
done

# =============================================================================
# Get K8S contexts from Azure AKS

echo ====================================
echo "Processing Microsoft Azure AKS:"

# Check if user is logged in
if ! az account show >/dev/null 2>&1; then
    # Logging in to Azure
    echo "Logging in to Azure..."
    az login && az account set --subscription "3a3e2779-7279-4b86-abb4-7672a3f56619"
fi

# Get list of AKS clusters
CLUSTERS=$(az aks list --query "[].{Name:name, ResourceGroup:resourceGroup}" --output json)

# Check if there are any clusters
if [[ -z "${CLUSTERS}" ]]; then
    echo "No AKS clusters found."
    exit 1
fi

# Loop through each cluster
for CLUSTER in $(echo "${CLUSTERS}" | jq -c '.[]'); do
    NAME=$(echo "${CLUSTER}" | jq -r '.Name')
    RESOURCE_GROUP=$(echo "${CLUSTER}" | jq -r '.ResourceGroup')

    # Set destination file
    export KUBECONFIG="${HOME}/.kube/config_${NAME}.yaml"

    # Get credentials for the cluster
    az aks get-credentials --resource-group "${RESOURCE_GROUP}" --name "${NAME}" --overwrite-existing --output yaml
done

# =============================================================================
# Set KUBECONFIG environment variable
# shellcheck disable=SC2016
KUBECONFIG=$(find ~/.kube -name "config_*.yaml" | tr '\n' ':' || true) && export KUBECONFIG

echo ===============================================================================
echo "Add the following line to your '~/.bashrc' or '~/.zshrc' file:"
# shellcheck disable=SC1012,SC2016,SC2026
echo 'KUBECONFIG=$(find ~/.kube -name "config_*.yaml" | tr '\n' ':' || true) && export KUBECONFIG'
