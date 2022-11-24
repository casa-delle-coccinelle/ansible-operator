#! /bin/bash
#
# start.sh


PLAYBOOK_CONFIG_PATH=${PLAYBOOK_CONFIG_PATH:-/opt/config}
PLAYBOOK_CONFIG_FILE=${PLAYBOOK_CONFIG_FILE:-config.sh}

RETRIES=${RETRIES:-3}
RETRIES_INTERVAL=${RETRIES_INTERVAL:-10}

SSH_USER_NAME=${SSH_USER_NAME:-ansible}
SSH_KEYS_PATH=${SSH_KEYS_PATH:-keys}

env

function logs_format(){
    level="${1}"
    shift 
    msg="${@}"
    echo "{\"time\": \"$(date -Iseconds)\", \"level\": \"${level}\", \"msg\": \"${msg}\", \"namespace\": \"${ANSIBLE_EXECUTOR_NAMESPACE}\", \"name\": \"${ANSIBLE_EXECUTOR_NAME}\"}" >&2
}


function ssh_config(){
    cat << EOF >> /home/${SSH_USER_NAME}/.ssh/config
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF
    
    for key in $(ls /home/${SSH_USER_NAME}/${SSH_KEYS_PATH}); do
        if [ -d /home/${SSH_USER_NAME}/${SSH_KEYS_PATH}/${key}/config ]; then
            cat << EOF >> /home/${SSH_USER_NAME}/.ssh/config
$(cat /home/${SSH_USER_NAME}/${SSH_KEYS_PATH}/${key}/config/ssh_config)
  IdentityFile /home/${SSH_USER_NAME}/${SSH_KEYS_PATH}/${key}/ssh-privatekey
EOF
        fi
        if  [ -d /home/${SSH_USER_NAME}/${SSH_KEYS_PATH}/${key}/secret-config ]; then
            cat << EOF >> /home/${SSH_USER_NAME}/.ssh/config
$(cat /home/${SSH_USER_NAME}/${SSH_KEYS_PATH}/${key}/secret-config/ssh_config)
  IdentityFile /home/${SSH_USER_NAME}/${SSH_KEYS_PATH}/${key}/ssh-privatekey
EOF
        fi
        if [ ! -d /home/${SSH_USER_NAME}/${SSH_KEYS_PATH}/${key}/config ] && [ ! -d /home/${SSH_USER_NAME}/${SSH_KEYS_PATH}/${key}/secret-config ]; then
            cat << EOF >> /home/${SSH_USER_NAME}/.ssh/config
Host *
  IdentityFile /home/${SSH_USER_NAME}/${SSH_KEYS_PATH}/${key}/ssh-privatekey
EOF
        fi
    done
    
    chmod 0600 /home/${SSH_USER_NAME}/.ssh/config
}

function git_repo_setup(){
    for retry in $(seq 1 ${RETRIES}); do
        git clone ${GIT_REPO} ${PLAYBOOK_CONFIG_PATH}/repo
        if [ $? -eq 0 ];then
            break
        fi
        if [ ${retry} -eq ${RETRIES} ]; then
            exit 1
        fi
        sleep ${RETRIES_INTERVAL}
    done
    cd ${PLAYBOOK_CONFIG_PATH}/repo
    git checkout ${GIT_REPO_BRANCH}
}

function install_requirements(){
    #path to requirements file
    path="${1}"

    logs_format info "Ansible requirements will be installed from ${path} with ${RETRIES} retries"
    for retry in $(seq 1 ${RETRIES}); do
        ansible-galaxy install -r "${path}"
        if [ $? -eq 0 ];then
            logs_format info "Ansible requirements installed successfully on ${retry} try"
            break
        else
            logs_format info "Ansible requirements were not installed on ${retry} try"
        fi
        if [ ${retry} -eq ${RETRIES} ]; then
            logs_format warning "Ansible requirements were not installed successfully"
        fi
        sleep ${RETRIES_INTERVAL}
    done
}

function playbook_options(){
    inventory=''
    vault_password=''
    additional_vars=''
    additional_options=''

    if [ -d "${PLAYBOOK_CONFIG_PATH}/secret-inventory" ]; then
        logs_format info "Ansible inventory is provided in secret"
        for file in $(ls "${PLAYBOOK_CONFIG_PATH}/secret-inventory"); do
            inventory=$(echo "${inventory} -i ${PLAYBOOK_CONFIG_PATH}/secret-inventory/${file}")
            logs_format info "Ansible inventory ${PLAYBOOK_CONFIG_PATH}/secret-inventory/${file} loaded"
        done
    fi
    if [ -d "${PLAYBOOK_CONFIG_PATH}/inventory" ]; then
        logs_format info "Ansible inventory is provided in configmap"
        for file in $(ls "${PLAYBOOK_CONFIG_PATH}/inventory"); do
            inventory=$(echo "${inventory} -i ${PLAYBOOK_CONFIG_PATH}/inventory/${file}")
            logs_format info "Ansible inventory ${PLAYBOOK_CONFIG_PATH}/inventory/${file} loaded"
        done
    fi
    if [ -f ${PLAYBOOK_CONFIG_PATH}/vault.pass ]; then
        logs_format info "Ansible vault password is provided"
        vault_password=$(echo "--vault-password-file ${PLAYBOOK_CONFIG_PATH}/vault.pass")
    fi
    if [ -d ${PLAYBOOK_CONFIG_PATH}/vars/configmap ]; then
        logs_format info "Additional ansible variables are provided in configmap"
        for file in $(ls "${PLAYBOOK_CONFIG_PATH}/vars/configmap"); do
            additional_vars=$(echo "${additional_vars} -e @${PLAYBOOK_CONFIG_PATH}/vars/configmap/${file}")
            logs_format info "Additional variables from file ${PLAYBOOK_CONFIG_PATH}/vars/configmap/${file} loaded"
        done
    fi
    if [ -d ${PLAYBOOK_CONFIG_PATH}/vars/secret ]; then
        logs_format info "Additional ansible variables are provided in secret"
        for file in $(ls "${PLAYBOOK_CONFIG_PATH}/vars/secret"); do
            additional_vars=$(echo "${additional_vars} -e @${PLAYBOOK_CONFIG_PATH}/vars/secret/${file}")
            logs_format info "Additional variables from file ${PLAYBOOK_CONFIG_PATH}/vars/secret/${file} loaded"
        done
    fi
    if [ -f ${PLAYBOOK_CONFIG_PATH}/options/options.list ]; then
        logs_format info "Additional ansible options are provided"
        while read -r option; do
            additional_options=$(echo "${additional_options} ${option}")
            logs_format info "Option ${option} loaded"
        done < ${PLAYBOOK_CONFIG_PATH}/options/options.list
    fi
    echo "${inventory} ${vault_password} ${additional_vars} ${additional_options}"

}


function start_playbook(){
#TODO: Add retry and exit code check
    if [ ! -z "${GIT_PLAYBOOK_NAME+x}" ]; then
        logs_format info "Ansible playbook with name ${GIT_PLAYBOOK_NAME} will be started from git repository ${GIT_REPO}/${GIT_REPO_PATH}"
        echo "$(playbook_options)" | xargs ansible-playbook ${PLAYBOOK_CONFIG_PATH}/repo/${GIT_REPO_PATH}/${GIT_PLAYBOOK_NAME}
    elif [ -f $(ls ${PLAYBOOK_CONFIG_PATH}/playbook) ]; then
        logs_format info "Ansible playbook with name $(ls ${PLAYBOOK_CONFIG_PATH}/playbook) provided in secret/configmap will be started"
        echo "$(playbook_options)" | xargs ansible-playbook $(ls ${PLAYBOOK_CONFIG_PATH}/playbook)
    fi

}

function main(){
    if [ -d /home/${SSH_USER_NAME}/${KEYS_PATH} ]; then
        logs_format info "Keys directory /home/${SSH_USER_NAME}/${KEYS_PATH} exists, generating SSH client config"
        ssh_config
    fi
    if [ -f ${PLAYBOOK_CONFIG_PATH}/${PLAYBOOK_CONFIG_FILE} ]; then
        logs_format info "Git repository configuration is provided, setting up git repo"
        source ${PLAYBOOK_CONFIG_PATH}/${PLAYBOOK_CONFIG_FILE}
        git_repo_setup
    fi
    if [ -f ${PLAYBOOK_CONFIG_PATH}/requirements.yaml ];then
        logs_format info "Ansible requirements configuration is provided, will install requirements with path ${PLAYBOOK_CONFIG_PATH}/requirements.yaml"
        install_requirements "${PLAYBOOK_CONFIG_PATH}/requirements.yaml"
    fi
    if [ ! -z "${GIT_REQUIREMENTS_NAME+x}" ];then
        logs_format info "Ansible requirements will be installed from git using path ${GIT_REPO_PATH}/${GIT_REQUIREMENTS_NAME}"
        install_requirements ${PLAYBOOK_CONFIG_PATH}/repo/${GIT_REPO_PATH}/${GIT_REQUIREMENTS_NAME}
    fi
    start_playbook
}

main
