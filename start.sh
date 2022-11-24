#! /bin/bash
#
# start.sh

set -x

PLAYBOOK_CONFIG_PATH=${PLAYBOOK_CONFIG_PATH:-/opt/config}
PLAYBOOK_CONFIG_FILE=${PLAYBOOK_CONFIG_FILE:-config.sh}

RETRIES=${RETRIES:-3}
RETRIES_INTERVAL=${RETRIES_INTERVAL:-10}

SSH_USER_NAME=${SSH_USER_NAME:-ansible}
SSH_KEYS_PATH=${SSH_KEYS_PATH:-keys}

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

    ansible-galaxy install -r "${path}"
}

function playbook_options(){
    inventory=''
    vault_password=''
    additional_vars=''
    additional_options=''

    if [ -d "${PLAYBOOK_CONFIG_PATH}/secret-inventory" ]; then
        for file in $(ls "${PLAYBOOK_CONFIG_PATH}/secret-inventory"); do
            inventory=$(echo "${inventory} -i ${PLAYBOOK_CONFIG_PATH}/secret-inventory/${file}")
        done
    fi
    if [ -d "${PLAYBOOK_CONFIG_PATH}/inventory" ]; then
        for file in $(ls "${PLAYBOOK_CONFIG_PATH}/inventory"); do
            inventory=$(echo "${inventory} -i ${PLAYBOOK_CONFIG_PATH}/inventory/${file}")
        done
    fi
    if [ -f ${PLAYBOOK_CONFIG_PATH}/vault.pass ]; then
        vault_password=$(echo "--vault-password-file ${PLAYBOOK_CONFIG_PATH}/vault.pass")
    fi
    if [ -d ${PLAYBOOK_CONFIG_PATH}/vars/configmap ]; then
        for file in $(ls "${PLAYBOOK_CONFIG_PATH}/vars/configmap"); do
            additional_vars=$(echo "${additional_vars} -e @${PLAYBOOK_CONFIG_PATH}/vars/configmap/${file}")
        done
    fi
    if [ -d ${PLAYBOOK_CONFIG_PATH}/vars/secret ]; then
        for file in $(ls "${PLAYBOOK_CONFIG_PATH}/vars/secret"); do
            additional_vars=$(echo "${additional_vars} -e @${PLAYBOOK_CONFIG_PATH}/vars/secret/${file}")
        done
    fi
    if [ -f ${PLAYBOOK_CONFIG_PATH}/options/options.list ]; then
        while read -r option; do
            additional_options=$(echo "${additional_options} ${option}")
        done < ${PLAYBOOK_CONFIG_PATH}/options/options.list
    fi
    echo "${inventory} ${vault_password} ${additional_vars} ${additional_options}"

}


function start_playbook(){

    if [ ! -z "${GIT_PLAYBOOK_NAME+x}" ]; then
        echo "$(playbook_options)" | xargs ansible-playbook ${PLAYBOOK_CONFIG_PATH}/repo/${GIT_REPO_PATH}/${GIT_PLAYBOOK_NAME}
    elif [ -f $(ls ${PLAYBOOK_CONFIG_PATH}/playbook) ]; then
        echo "$(playbook_options)" | xargs ansible-playbook $(ls ${PLAYBOOK_CONFIG_PATH}/playbook)
    fi

}

function main(){
    if [ -d /home/${SSH_USER_NAME}/${KEYS_PATH} ];then
        ssh_config
    fi
    if [ -f ${PLAYBOOK_CONFIG_PATH}/${PLAYBOOK_CONFIG_FILE} ];then
        source ${PLAYBOOK_CONFIG_PATH}/${PLAYBOOK_CONFIG_FILE}
        git_repo_setup
    fi
    if [ -f ${PLAYBOOK_CONFIG_PATH}/requirements.yaml ];then
        install_requirements "${PLAYBOOK_CONFIG_PATH}/requirements.yaml"
    fi
    if [ ! -z "${GIT_REQUIREMENTS_NAME+x}" ];then
        install_requirements ${PLAYBOOK_CONFIG_PATH}/repo/${GIT_REPO_PATH}/${GIT_REQUIREMENTS_NAME}
    fi
    start_playbook
}

main
