### Builds
Two workflows are created to build and push operator and executor images.
#### Dev
The names of the branches with new versions of ansible operator should start with the letter "v" followed by version number MAJOR.MINOR.PATCH (https://semver.org/). For example, if the current version of the operator is v0.1.0 and bug fix is needed, the branch with the fix should be named "v0.1.1". Docker images built from this branch will be tagged "v0.1.1.dev"
#### Release
Docker images with released version are built only if tag with the corresponding version is pushed after merge to master. Tags should start with the letter "v" followed by version number MAJOR.MINOR.PATCH (https://semver.org/). For example, if tag v0.1.1 is pushed, docker image with tag "v0.1.1" will be built.

### [Makefile](../Makefile)
#### Vars
| Variable | Description | Default |
|--|--|--|
| VERSION | Docker images tag  | v0.1.0 |
| OPERATOR_IMAGE_TAG_BASE | Docker image registry for operator image  | internal registry |
| EXECUTOR_IMAGE_TAG_BASE | Docker image registry for executor image  | internal registry |
| HELM_VALUES_PATH | Path to custom helm value file  | helm_chart/ansible-operator/values.yaml |
| NAMESPACE | Namespace for operator's helm release  | ansible-operator |
| RELEASE_NAME | operator's helm release name  | ansible-operator |
| OPERATOR_DOCKERFILE | Path to operator's docker file  | docker/Dockerfile |
| EXECUTOR_DOCKERFILE | Path to executor's docker file  | docker/Dockerfile_ansible_executor |
#### Usage
##### Build

    make docker-build docker-push 

##### Deploy

    make deploy

Will install CRDs and operator

##### Clean-up

    make undeploy

Will delete CRDs, operator relese and namespace
### executor_start.sh
#### Variables
| Variable | Description | Default |
|--|--|--|
| PLAYBOOK_CONFIG_PATH | Path where all playbook configurations are mounted | /opt/config |
| PLAYBOOK_CONFIG_FILE | Name of the configuration file holding git repository configuration. Created as configmap by ansible operator and mounted onto executor's pod  | config.sh |
| RETRIES | The number of times the script will try to install ansible galaxy requirements and clone git repository. If the requirements are not installed successfully a warning message will be printed in the logs. If git repository clone fails ${RETRIES} times, the script will exit with error code. | 3 |
| RETRIES_INTERVAL | Interval in sencond between the retries. | 10 |
| SSH_USER_NAME |  Username of the user in container executing the playbook. | ansible |
| SSH_KEYS_PATH | Path where the ansible-operator mounts the SSH keys and SSH client configuration provided in CRDs. | keys |
| ANSIBLE_EXECUTOR_NAMESPACE | Kubernetes namespace where the executor is deployed | N/A |
| ANSIBLE_EXECUTOR_NAME | Name of the CRD. | N/A |
| GIT_REPO | Git repository provided in CRD | N/A |
| GIT_REPO_BRANCH | Git repository branch | N/A |
| GIT_PLAYBOOK_NAME | Name of ansibble playbook | N/A |
| GIT_REQUIREMENTS_NAME | Name of ansible requirements file | N/A |
| GIT_REPO_PATH | Path to playbook in git repository | N/A |
#### Directory structure of executor's container.

    /home
    └── ansible
        └── keys
            ├── key-0
            │   ├── config
            │   │   └── ssh_config
            │   └── ssh-privatekey
            └── key-1
                ├── secret-config
                │   └── ssh_config
                └── ssh-privatekey
    /opt
    └── config
        ├── config.sh
        ├── inventory
        │   ├── inventory1
        │   └── inventory2
        ├── options
        │   └── options.list
        ├── playbook
        │   └── playbook.yaml
        ├── requirements.yaml
        ├── secret-inventory
        │   └── inventory
        ├── vars
        │   ├── configmap
        │   │   └── vars.yaml
        │   ├── secret
        │   │   └── vars.yaml
        │   └── vars-configmap
        │       └── vars-b512d08214a275f29cdb7ba9cb5b8f93.yaml
        └── vault
            └── vault.password

