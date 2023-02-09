#! /bin/bash
#
# executor_start.sh
# shellcheck disable=SC1090

PLAYBOOK_CONFIG_PATH=${PLAYBOOK_CONFIG_PATH:-/opt/config}
PLAYBOOK_CONFIG_FILE=${PLAYBOOK_CONFIG_FILE:-config.sh}

RETRIES=${RETRIES:-3}
RETRIES_INTERVAL=${RETRIES_INTERVAL:-10}

SSH_USER_NAME=${SSH_USER_NAME:-ansible}
SSH_KEYS_PATH=${SSH_KEYS_PATH:-keys}


function logs_format(){
    level="${1}"
    shift 
    msg="${*}"
    echo "{\"time\": \"$(date -Iseconds)\", \"level\": \"${level}\", \"msg\": \"${msg}\", \"namespace\": \"${ANSIBLE_EXECUTOR_NAMESPACE}\", \"name\": \"${ANSIBLE_EXECUTOR_NAME}\"}" >&2
}


function ssh_config(){
    cat << EOF >> "/home/${SSH_USER_NAME}/.ssh/config"
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF
    
    for key in /home/"${SSH_USER_NAME}"/"${SSH_KEYS_PATH}"/*; do
        logs_format info "Configuring SSH client with key ${key}"
        if [ -d "${key}/config" ]; then
            logs_format info "Adding SSH client configuration provided in configmap using identity file ${key}/ssh-privatekey"
            cat << EOF >> "/home/${SSH_USER_NAME}/.ssh/config"
$(cat "${key}/config/ssh_config")
  IdentityFile ${key}/ssh-privatekey
EOF
        fi
        if  [ -d "${key}/secret-config" ]; then
            logs_format info "Adding SSH client configuration provided in secret using identity file ${key}/ssh-privatekey"
            cat << EOF >> "/home/${SSH_USER_NAME}/.ssh/config"
$(cat "${key}/secret-config/ssh_config")
  IdentityFile ${key}/ssh-privatekey
EOF
        fi
        if [ ! -d "${key}/config" ] && [ ! -d "${key}/secret-config" ]; then
            logs_format info "No configuration provided, identity file ${key}/ssh-privatekey will used for all hosts"
            cat << EOF >> "/home/${SSH_USER_NAME}/.ssh/config"
Host *
  IdentityFile ${key}/ssh-privatekey
EOF
        fi
    done

    logs_format info "SSH client configured, setting restricted permissions for file /home/${SSH_USER_NAME}/.ssh/config"
    chmod 0600 "/home/${SSH_USER_NAME}/.ssh/config"
}

function git_repo_setup(){
    git_err=$(mktemp)
    logs_format info "Attempting to clone git repository ${GIT_REPO}, branch ${GIT_REPO_BRANCH} with ${RETRIES} retries"
    for retry in $(seq 1 "${RETRIES}"); do
        if git clone --depth=1 --branch "${GIT_REPO_BRANCH}" "${GIT_REPO}" "${PLAYBOOK_CONFIG_PATH}/repo" 2>"${git_err}" 1>/dev/null;
        then
            logs_format info "Git repository cloned successfully"
            break
        else
            logs_format warning "Git clone command failed with exit code $? on ${retry} try"
            git_err_formatted=$(tr -d '\r' < "${git_err}" | sed ':a;N;$!ba;s/\n/\\n /g') # For some reason there is '\r' in git's stderr
            logs_format warning "The exact git error was: \"${git_err_formatted}\""
        fi
        if [ "${retry}" -eq "${RETRIES}" ]; then
            logs_format error "Git repository was not cloned, exiting"
            exit 1
        fi
        sleep "${RETRIES_INTERVAL}"
    done
}

function install_requirements(){
    #path to requirements file
    path="${1}"

    logs_format info "Ansible requirements will be installed from ${path} with ${RETRIES} retries"
    for retry in $(seq 1 "${RETRIES}"); do
        if ansible-galaxy install -r "${path}" &>/dev/null;
        then
            logs_format info "Ansible requirements installed successfully on ${retry} try"
            break
        else
            logs_format info "Ansible galaxy install command failed with exit code $? on ${retry} try"
        fi
        if [ "${retry}" -eq "${RETRIES}" ]; then
            logs_format warning "Ansible requirements were not installed successfully"
        fi
        sleep "${RETRIES_INTERVAL}"
    done
}

function playbook_options(){
    inventory=''
    vault_password=''
    additional_vars=''
    additional_options=''

    if [ -d "${PLAYBOOK_CONFIG_PATH}/secret-inventory" ]; then
        logs_format info "Ansible inventory is provided in secret"
        for file in "${PLAYBOOK_CONFIG_PATH}"/secret-inventory/*; do
            inventory="${inventory} -i ${file}"
            logs_format info "Ansible inventory ${file} loaded"
        done
    fi
    if [ -d "${PLAYBOOK_CONFIG_PATH}/inventory" ]; then
        logs_format info "Ansible inventory is provided in configmap"
        for file in "${PLAYBOOK_CONFIG_PATH}"/inventory/*; do
            inventory="${inventory} -i ${file}"
            logs_format info "Ansible inventory ${file} loaded"
        done
    fi
    if [ -d "${PLAYBOOK_CONFIG_PATH}/vault" ]; then
        vault_dir=("${PLAYBOOK_CONFIG_PATH}"/vault/*)
        if [ ${#vault_dir[@]} -gt 1 ];then
            logs_format warning "More than 1 file is possible candidate for ansible vault password. This may lead for playbook execution failure."
            vault_file_path="${vault_dir[0]}"
            logs_format warning "First found file ${vault_file_path} will be used for vault password"
        else
            vault_file_path="${vault_dir[0]}"
            logs_format info "Ansible vault password will be loaded from file ${vault_file_path}"
        fi
        vault_password="--vault-password-file ${vault_file_path}"
    fi
    if [ -d "${PLAYBOOK_CONFIG_PATH}/vars/configmap" ]; then
        logs_format info "Additional ansible variables are provided in configmap"
        for file in "${PLAYBOOK_CONFIG_PATH}"/vars/configmap/*; do
            additional_vars="${additional_vars} -e @${file}"
            logs_format info "Additional variables from file ${file} loaded"
        done
    fi
    if [ -d "${PLAYBOOK_CONFIG_PATH}/vars/secret" ]; then
        logs_format info "Additional ansible variables are provided in secret"
        for file in "${PLAYBOOK_CONFIG_PATH}"/vars/secret/*; do
            additional_vars="${additional_vars} -e @${file}"
            logs_format info "Additional variables from file ${file} loaded"
        done
    fi
    if [ -d "${PLAYBOOK_CONFIG_PATH}/vars/vars-configmap" ]; then
        logs_format info "Additional ansible variables are provided"
        for file in "${PLAYBOOK_CONFIG_PATH}"/vars/vars-configmap/*; do
            additional_vars="${additional_vars} -e @${file}"
            logs_format info "Additional variables from file ${file} loaded"
        done
    fi
    if [ -f "${PLAYBOOK_CONFIG_PATH}/options/options.list" ]; then
        logs_format info "Additional ansible options are provided"
        while read -r option; do
            additional_options="${additional_options} ${option}"
            logs_format info "Option ${option} loaded"
        done < "${PLAYBOOK_CONFIG_PATH}/options/options.list"
    fi
    echo "${inventory} ${vault_password} ${additional_vars} ${additional_options}"

}


function start_playbook(){
    playbook_file_path=''
    options=$(playbook_options)

    if [ -n "${GIT_PLAYBOOK_NAME}" ]; then
        logs_format info "Ansible playbook with name ${GIT_PLAYBOOK_NAME} will be started from git repository ${GIT_REPO}/${GIT_REPO_PATH}"
        playbook_file_path="${PLAYBOOK_CONFIG_PATH}/repo/${GIT_REPO_PATH}/${GIT_PLAYBOOK_NAME}"
    else 
        playbook_dir=("${PLAYBOOK_CONFIG_PATH}"/playbook/*)
        if [ ${#playbook_dir[@]} -gt 1 ];then
            logs_format error "More than 1 file is possible candidate for ansible playbook, execution aborted"
            exit 1
        else
            playbook_file_path="${playbook_dir[0]}"
            logs_format info "Ansible playbook with name ${playbook_file_path} provided in secret/configmap will be started"
        fi
    fi

    logs_format info "Executing ansible playbook with options ${options}"
    if xargs ansible-playbook <<- EOF
${playbook_file_path} ${options}
EOF
then
    logs_format info "Ansible playbook execution is successful"
    else
        logs_format info "Ansible playbook execution failed with exit code $?, exiting"
        exit 1
    fi

}

function main(){
    if [ -d "/home/${SSH_USER_NAME}/${SSH_KEYS_PATH}" ]; then
        logs_format info "Keys directory /home/${SSH_USER_NAME}/${SSH_KEYS_PATH} exists, generating SSH client config"
        ssh_config
    fi
    if [ -f "${PLAYBOOK_CONFIG_PATH}/${PLAYBOOK_CONFIG_FILE}" ]; then
        logs_format info "Git repository configuration is provided, setting up git repo"
        source "${PLAYBOOK_CONFIG_PATH}/${PLAYBOOK_CONFIG_FILE}"
        git_repo_setup
    fi
    if [ -f "${PLAYBOOK_CONFIG_PATH}/requirements.yaml" ];then
        logs_format info "Ansible requirements configuration is provided, will install requirements with path ${PLAYBOOK_CONFIG_PATH}/requirements.yaml"
        install_requirements "${PLAYBOOK_CONFIG_PATH}/requirements.yaml"
    fi
    if [ -n "${GIT_REQUIREMENTS_NAME}" ];then
        logs_format info "Ansible requirements will be installed from git using path ${GIT_REPO_PATH}/${GIT_REQUIREMENTS_NAME}"
        install_requirements "${PLAYBOOK_CONFIG_PATH}/repo/${GIT_REPO_PATH}/${GIT_REQUIREMENTS_NAME}"
    fi
    start_playbook
}

main
