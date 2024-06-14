#!/usr/bin/env bash

function choose_cluster_to_add() {
    clear
    COLUMNS=1
    declare -A clusters
    clusters[dev]=dev-k8s.internal.company.io
    clusters[prd]=prd-k8s.internal.company.io
    clusters[stg]=stg-k8s.internal.company.io

    for configured in $(kubectl config get-contexts | awk 'NR>1 {print $2}' || true); do
        for entry in "${!clusters[@]}"; do
            if [[ ${entry} == "${configured}" ]]; then
                unset 'clusters[$entry]'
            fi
        done
    done

    if [[ "${clusters[*]}" == "" ]]; then
        echo "All available K8S clusters are already exist in your '~/.kube/config'."
        echo "To replace the context you would delete the desired one first."
        read -n 1 -s -r -p "Press any key to return to the main menu..."
        main_menu
    else
        PS3="Please select the K8S cluster to add to your '~/.kube/config': "
        select cluster in "${!clusters[@]}"; do
            case ${cluster} in
            "${cluster}")
                add_context "${cluster}" "${clusters[${cluster}]}"
                ;;
            *) echo "Invalid option ${REPLY}, please select one from the list" ;;
            esac
        done
    fi
}

function run_kubelogin() {
    if [[ -f "$(command -v kubelogin || true)" ]]; then
        "$(command -v kubelogin)"
    else
        echo ==================================================================================
        echo "The 'kubelogin' utility is not found. Please install it from here:"
        echo "https://github.com/int128/kubelogin"
        echo ==================================================================================
    fi
}

function add_context() {
    read -r -p "Enter your name [${USER}]: " USERNAME
    USERNAME=${USERNAME:-${USER}}
    curl -s -o "/tmp/${1}_ca.crt" "https://artifactory.company.io/releases-generic/devops/certificates/${1}_ca.crt"
    CLUSTER_NAME=$1
    CLUSTER_API_URL=https://$2:6443
    CLUSTER_DEX_URL=https://$2:32000/dex
    CLUSTER_API_CA_PATH="/tmp/${1}_ca.crt"
    CLUSTER_DEX_CA_DATA=$(curl -s "https://artifactory.company.io/releases-generic/devops/certificates/${1}_dex_ca.crt" | "${BASE64_BIN}" -w0 || true)

    kubectl config set-cluster "${CLUSTER_NAME}" \
        --server "${CLUSTER_API_URL}" \
        --certificate-authority "${CLUSTER_API_CA_PATH}" \
        --embed-certs=true
    kubectl config set-credentials "${USERNAME}"@"${CLUSTER_NAME}" \
        --auth-provider oidc \
        --auth-provider-arg idp-issuer-url="${CLUSTER_DEX_URL}" \
        --auth-provider-arg client-id=kubectl \
        --auth-provider-arg client-secret=company-kubectl \
        --auth-provider-arg idp-certificate-authority-data="${CLUSTER_DEX_CA_DATA}" \
        --auth-provider-arg=extra-scopes="offline_access openid profile email groups"
    kubectl config set-context "${CLUSTER_NAME}" \
        --cluster "${CLUSTER_NAME}" \
        --user "${USERNAME}"@"${CLUSTER_NAME}"
    kubectl config use-context "${CLUSTER_NAME}"
    run_kubelogin
    main_menu
}

function delete_context() {
    clear
    COLUMNS=1
    while IFS= read -r line; do
        contexts+=("${line}")
    done < <(kubectl config get-contexts -o name || true)

    PS3="Please select the K8S context to delete: "
    select context in "${contexts[@]}"; do
        case ${context} in
        "${context}")
            kubectl config delete-context "${context}"
            kubectl config delete-user "$(kubectl config get-users | grep "${context}" || true)"
            kubectl config unset current-context
            contexts=()
            main_menu
            ;;
        *) echo "invalid option ${REPLY}" ;;
        esac
    done
}

function main_menu() {
    clear
    COLUMNS=1
    echo ========================================================================================================
    echo ""
    echo "                                          DevOps Team"
    echo "                    Slack #devops channel: https://company.slack.com/archives/C0459CU2T"
    echo ""
    echo ========================================================================================================
    echo Hello, "${USER}"!
    if [[ "$(kubectl config get-contexts -o name || true)" == "" ]]; then
        echo "You have no configured K8S contexts yet"
        echo "Please choose option 1) in the menu below"
    else
        echo "Your current list of contexts:"
        echo
        kubectl config get-contexts
    fi
    echo
    echo ========================================================================================================
    echo
    echo "After adding the new context please run the 'kubelogin' utility"
    echo to receive authentication token from FreeIPA:
    echo https://github.com/int128/kubelogin
    echo
    echo Also there are some utilities highly recommended for use to all working with K8S:
    echo
    echo "* 'kubectx/kubens' is a set of utilities to manage and switch between K8S contexts:"
    echo https://github.com/ahmetb/kubectx
    echo
    echo "* 'fzf' - a general-purpose command-line fuzzy finder:"
    echo https://github.com/junegunn/fzf
    echo
    echo "* 'stern' allows you to tail multiple pods on Kubernetes and multiple containers within the pod."
    echo "Each result is color coded for quicker debugging."
    echo https://github.com/wercker/stern
    echo
    echo ========================================================================================================
    PS3='Please enter your choice: '
    options=("Add new K8S context" "Delete K8S context" "Quit")
    select opt in "${options[@]}"; do
        case ${opt} in
        "Add new K8S context")
            choose_cluster_to_add
            ;;
        "Delete K8S context")
            delete_context
            ;;
        "Quit")
            exit
            ;;
        *) echo "Invalid option ${REPLY}." ;;
        esac
    done
}

if [[ ${OSTYPE} == darwin* ]]; then
    if [[ ! -f /usr/local/bin/bash ]]; then
        echo ==================================================================================
        echo "The GNU version of 'bash' is not found, please install the latest version"
        echo "with Homebrew packet manager - https://formulae.brew.sh/formula/bash. Run:"
        echo "$ brew install bash"
        echo "$ sudo ln -s /opt/homebrew/bin/bash /usr/local/bin/bash"
        echo "$ echo '/usr/local/bin/bash' | sudo tee -a /etc/shells"
        echo ==================================================================================
    else
        BASE64_BIN=$(command -v gbase64)
    fi
    if [[ ! -f "$(command -v gbase64 || true)" ]]; then
        echo ==================================================================================
        echo "The GNU version of 'base64' utility is not found, please install 'GNU coreutils'"
        echo "with Homebrew packet manager - https://formulae.brew.sh/formula/coreutils. Run:"
        echo "$ brew install coreutils"
        echo "After it add the following string to your '~/.bashrc' or '~/.zshrc' file:"
        # shellcheck disable=SC2016
        echo 'export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"'
        echo ==================================================================================
        exit
    else
        BASE64_BIN=$(command -v gbase64)
    fi
elif [[ ${OSTYPE} == linux* ]]; then
    BASE64_BIN=$(command -v base64)
else
    echo ==================================================================================
    echo "Your Operating System is not supported, please contact the Operations team"
    echo ==================================================================================
    exit
fi

if [[ -f "$(command -v kubectl || true)" ]]; then
    main_menu
else
    echo ==================================================================================
    echo "The 'kubectl' utility is not found. Please install it prior running this script"
    echo "https://kubernetes.io/docs/tasks/tools/"
    echo ==================================================================================
    exit
fi
