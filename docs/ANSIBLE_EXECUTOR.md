ansible-executor
=========

Ansible role for creating Kubernetes cronjob or jobs based on configuration provided in custom resources of type AnsibleCron and AnsibleJob

Requirements
------------

collections:
- name: community.kubernetes
- name: operator_sdk.util
- name: kubernetes.core
- name: cloud.common

Role Variables
--------------


| Variable | Description | Default | Required | 
|--|--|--|--|
| k8s_resource_type | Type of Kubernetes resource to create. Valid values are "cronjob" or "job"  | N/A | Yes |
| ansible_config_volume | Mount location for the provided playbook configurations. | /opt/config | No |
| ansible_user_home | Home directory of the executor's user, where SSH keys will be mounted. | /home/ansible | No |
| schedule | Execution schedule for Kubernetes cronjob  | N/A | Yes, if k8s_resource_type="cronjob"  |
| roles | List with ansible galaxy roles needed for executor's playbook. | N/A | No |
| collections | List with ansible galaxy collections needed for executor's playbook. | N/A | No |
| vault_password | Ansible vault password. If defined, a Kubernetes secret will be created and mounted onto the executor's pod. | N/A | No |
| vault_password_secret.secret_ref.name | Name of Kubernetes secret holding ansible vault password. If defined, it will be mounted onto the executor's pod.  | N/A | No |
| ssh_keys | List of SSH keys configuration. | N/A | No |
| ssh_keys.name | Name for the SSH key. It will be used in volume mounts name construction  | N/A | Yes |
| ssh_keys.secret_ref.name | Name of the Kubernetes secret holding private SSH key | N/A | Yes |
| ssh_keys.config | SSH client configurations for the key. | N/A | No  |
| ssh_keys.config.config_map_ref.name | Kubernetes configmap holding SSH client configuration for the key.  | N/A | No |
| ssh_keys.config.secret_ref.name | Kubernetes secret holding SSH client configuration for the key.  | N/A | No |
| inventory | List of configmaps and secrets with ansible inventory | N/A | No |
| inventory.config_map_ref.name | Name of Kubernetes configmap holding ansible inventory. If defined, it will be mounted onto the executor's pod. | N/A | No |
| inventory.secret_ref.name | Name of Kubernetes secret holding ansible inventory. If defined, it will be mounted onto the executor's pod. | N/A | No |
| playbook | Object holding ansible playbook information. At least one of *git*, *config_map_ref.name* and *secret_ref.name* must be defined, see bellow. | N/A | Yes |
| playbook.git.repo | URL to git repository. | N/A | Yes  |
| playbook.git.repo_path | Path to ansible playbook in git repository. Defaults to repository root.  | / | No |
| playbook.git.playbook_name | Name of ansible playbook.  | playbook.yaml  | No |
| playbook.git.requirements_name | Name of ansible requirements file | N/A  | No |
| playbook.git.repo_branch | Git repository branch or tag. | master  | No |
| playbook.config_map_ref.name | Name of Kubernetes configmap holding ansible playbook. If defined, it will be mounted onto the executor's pod.  | N/A | No |
| playbook.secret_ref.name | Name of Kubernetes secret holding ansible playbook. If defined, it will be mounted onto the executor's pod. | N/A | No |
| additional_vars | List with additional ansible playbook variables. | N/A | No |
| additional_vars.name | Name of ansible variable | N/A | No |
| additional_vars.value | Value of ansible variable. If both additional_vars.name and additional_vars.value are defined, a Kubernetes configmap will be created and mounted onto the executor's pod. | N/A | No |
| additional_vars.config_map_ref.name | Name of Kubernetes configmap holding ansible playbook variables. If defined, it will be mounted onto the executor's pod.  | N/A | No |
| additional_vars.secret_ref.name | Name of Kubernetes secret holding ansible playbook variables. If defined, it will be mounted onto the executor's pod. | N/A | No |
| additional_ansible_options | List of ansible playbook options (e.g. --force-handlers). If defined, a configmap holding the options one per line will be created and mounted onto the executor's pod. | N/A | No |
| additional_env | List of environment variables to be added to executor's pod env. | N/A | No |
| additional_env.name | Environment variable name. | N/A | No |
| additional_env.value | Environment variable value. | N/A | No  |
| job_backoff_limit | Job backoff limit for executor's pod. | N/A | Yes |
| job_restart_policy | Job restart policy for executor's pod. | N/A | Yes |
| ansible_executor_image | Ansible executor image. | N/A | Yes |
| ansible_executor_image_tag | Ansible executor image tag. | N/A | Yes |
| ansible_executor_image_pull_policy | Ansible executor image pull policy  | N/A | Yes |


Dependencies
------------

N/A

Example Playbook
----------------

#### Deploy Kuberentes job

    - hosts: localhost
      vars:
        k8s_resource_type: "job"
      roles:
         - ansible-executor

#### Deploy Kubernetes cronjob

    - hosts: localhost
      vars:
        k8s_resource_type: "cronjob"
      roles:
         - ansible-executor
License
-------

MIT

